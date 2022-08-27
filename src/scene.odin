package app

import time "core:time"
import fmt "core:fmt"
import json "core:encoding/json"
import lg "core:math/linalg"
import os "core:os"
import strings "core:strings"

import SDL "vendor:sdl2"
import IMG "vendor:sdl2/image"

import geom "../extern/regin/geometry"
import cm "../extern/regin/physics/classical_mechanics"
import regin "../extern/regin"

SceneDescriptor :: struct {
    meta: MetaDescriptor,
    assets: AssetsDescriptor,
    layout: LayoutDescriptor,
}

MetaDescriptor :: struct {
    ratio_pixel_unit: i32,
}

AssetsDescriptor :: struct {
    sprites: map[string]SpriteDescriptor,
}

SpriteDescriptor :: struct {
    texture: string,
    clip: [4]i32,
    ratio_pixel_unit: i32,
}

LayoutDescriptor :: struct {
    grid: [dynamic][dynamic]i32,
}

Scene :: struct {
    window : ^SDL.Window,
    renderer: ^SDL.Renderer,

    resources: Resources,
    archetypes: [4]Archetype,
}

TYPES :: enum int {BALL=0,PLAYER=1,BRICK=2,WALL=3}

Ent :: struct {
    types: TYPES,
    idx: int,
}

Collision :: struct {
    eA: Ent,
    eB: Ent,
    ip: geom.IntersectionPoint(2,f32),
}

create_scene :: proc() -> (scene: Scene) {
    assert(SDL.Init({.VIDEO, .EVENTS, .TIMER}) == 0, SDL.GetErrorString())

    scene.window = SDL.CreateWindow("Scene", SDL.WINDOWPOS_CENTERED,SDL.WINDOWPOS_CENTERED,SCREEN_WIDTH,SCREEN_HEIGHT,SDL.WINDOW_SHOWN)
    assert(scene.window != nil, SDL.GetErrorString())

    scene.renderer = SDL.CreateRenderer(scene.window,-1, {.SOFTWARE})
    assert(scene.renderer != nil, SDL.GetErrorString())

    IMG.Init({.PNG, .JPG})

    SDL.SetRenderDrawColor(scene.renderer,255,255,255,255);

    scene.resources = create_resources(scene.renderer)

    scene.archetypes[0] = create_archetype_ball()
    scene.archetypes[1] = create_archetype_player()
    scene.archetypes[2] = create_archetype_brick()
    scene.archetypes[3] = create_archetype_brick()



    return scene
}

destroy_scene :: proc(scene: ^Scene) {
    SDL.DestroyWindow(scene.window)
    SDL.DestroyRenderer(scene.renderer)
    SDL.Quit()
    IMG.Quit()

    for arch in &scene.archetypes {
        destroy_archetype(&arch)
    }
}

STATE :: enum{WIN,LOST}

check_condition :: proc(scene: ^Scene) -> bool {
    
    balls := scene.archetypes[TYPES.BALL]
    if(balls.count == 0) {
        fmt.println("LOSER!!")
        return true
    }

    bricks := scene.archetypes[TYPES.BRICK]
    if(bricks.count == 0){
        fmt.println("WIN!!")
        return true
    }

    return false
}

load_content :: proc(scene: ^Scene, scene_path : string) {

    data, err_load := os.read_entire_file_from_filename(strings.concatenate({"data/",scene_path}))
	if !err_load {
        fmt.eprintln("Failed to load the file!", scene_path)
    }
    defer delete(data)

    scene_desc: SceneDescriptor

    err := json.unmarshal(data, &scene_desc)
    assert(err == nil, "Error")
    
    for sprite_name, sprite_desc in scene_desc.assets.sprites {
        load_resources_sprite(&scene.resources, sprite_name, strings.concatenate({"data/",sprite_desc.texture}), sprite_desc.clip)
    }

    ball:= Ball{
        health = {
            hp = 5,
            max_hp = 5,
        },
        damage = {
            attack=1,
        },
        transform = {
            position={0,1.5},
            rotation=0,
            scale={1,1},
        },
        sprite_renderer = init_sprite_renderer(scene.resources.sprites["ball"]),
        body = {
            material = {
                imass = 0.1, 
                iinertia = 0, 
                restitution=1,
            },
        },
        structure = {
            position={0,0}, 
            halfsize={0.5,0.5},
        },
    }
    add_archetype_ball(&scene.archetypes[TYPES.BALL], ball)

    player:= Player{
        transform = {
            position={0,0.5},
            rotation=0,
            scale={1,1}
        },
        sprite_renderer = init_sprite_renderer(scene.resources.sprites["player"]),
        body = {
            material = {
                imass = 0, 
                iinertia = 0, 
                restitution=1,
            },
        },
        structure = {
            position={0,0}, 
            halfsize={2,0.5}
        },
    }
    add_archetype_player(&scene.archetypes[TYPES.PLAYER],player)

    borders := [2]f32{SCREEN_WIDTH/(2*RATIO_PIXEL_UNIT), SCREEN_HEIGHT/RATIO_PIXEL_UNIT}

    wall_template:= Brick{
        health = {
            hp=-1,
            max_hp=5
        },
        transform = {},
        sprite_renderer = init_sprite_renderer(sprite=scene.resources.sprites["solid_brick"]),
        body = {
            material = {
                imass = 0, 
                iinertia = 0, 
                restitution=1,
            },
        },
        structure = {
            position={},
            halfsize={0.5,0.5},
        },
    }

    //Down
    {
        wall:= wall_template

        wall.transform = {
            position = {0,-0.5},
            rotation = 0,
            scale = {f32(SCREEN_WIDTH)/f32(RATIO_PIXEL_UNIT),1},
        }
        wall.damage.attack = 1

        add_archetype_brick(&scene.archetypes[TYPES.WALL], wall)
    }

    //Up
    {
        wall := wall_template

        wall.transform = regin.Transform2D(f32) {
            position = {0,borders.y+0.5},
            rotation = 0,
            scale = {f32(SCREEN_WIDTH)/f32(RATIO_PIXEL_UNIT),1},
        }

        add_archetype_brick(&scene.archetypes[TYPES.WALL], wall)
    }

    //Right
    {
        wall := wall_template

        wall.transform = {
            position = {borders.x+1,borders.y/2},
            rotation = 0,
            scale = {1,f32(SCREEN_HEIGHT)/f32(RATIO_PIXEL_UNIT)},
        }

        add_archetype_brick(&scene.archetypes[TYPES.WALL], wall)
    }

    //Left
    {
        wall := wall_template

        wall.transform = {
            position = {-borders.x-1,borders.y/2},
            rotation = 0,
            scale = {1,f32(SCREEN_HEIGHT)/f32(RATIO_PIXEL_UNIT)},
        }

        add_archetype_brick(&scene.archetypes[TYPES.WALL], wall)
    }

    brick_template := Brick{
        health = {
            max_hp=5
        },
        damage = {
            attack=0,
        },
        transform = {},
        sprite_renderer = {},
        body = {
            material = {
                imass = 0, 
                iinertia = 0, 
                restitution=1,
            },
        },
        structure = {
            position={},
            halfsize={0.5,0.5},
        },
    }

    for irow:= 0; irow < len(scene_desc.layout.grid); irow+=1 {
        for icol:= 0; icol < len(scene_desc.layout.grid[0]); icol+=1 {
            grid := scene_desc.layout.grid

            brick := brick_template

            brick.health.hp = grid[irow][icol]

            brick.transform = {
                position = {f32(icol) * 2 - 4, f32(SCREEN_HEIGHT)/f32(RATIO_PIXEL_UNIT) - 1 - f32(irow) * 2},
                rotation = 0,
                scale = {1,1},
            }

            if grid[irow][icol] != -1 {
                brick.sprite_renderer = init_sprite_renderer(scene.resources.sprites["brick"])
                add_archetype_brick(&scene.archetypes[TYPES.BRICK], brick)    

            } else {
                brick.sprite_renderer = init_sprite_renderer(scene.resources.sprites["solid_brick"])
                add_archetype_brick(&scene.archetypes[TYPES.WALL], brick)    

            }
        }
    }

    return
}

run :: proc(scene: ^Scene) {
    start_time, frame_time : u32

    for {
        start_time = SDL.GetTicks()
        event : SDL.Event

        for SDL.PollEvent(&event) {
            #partial switch event.type {
                case .QUIT:
                    return
            }
        }

        //Keyboard Handling
        keystates := SDL.GetKeyboardStateAsSlice()
        handle_player_input(&scene.archetypes[TYPES.PLAYER],keystates)

        SDL.RenderClear(scene.renderer)

        collisions : [dynamic]Collision
        defer delete(collisions)

        //Detect Collision
        for archA, iarchA in scene.archetypes { //Fpr each balls
            if TYPES(iarchA) == TYPES.BALL {
                structuresA, has_structureA := archA.structure.?
                transformsA, has_transformA := archA.transform.?

                for archB, iarchB in scene.archetypes {
                    if TYPES(iarchB) != TYPES.BALL {

                        structuresB, has_structureB := archB.structure.?
                        transformsB, has_transformB := archB.transform.?

                        if has_structureA && has_structureB && has_transformA && has_transformB {

                            for ieA in 0..<archA.count{
                                
                                structA := structuresA[ieA]
                                structA.position += transformsA[ieA].position
                                structA.halfsize *= transformsA[ieA].scale

                                for ieB in 0..<archB.count {
                
                                    structB := structuresB[ieB]
                                    structB.position += transformsB[ieB].position
                                    structB.halfsize *= transformsB[ieB].scale
                    
                                    ip, intersected := geom.nearest_intersection_point(structA,structB)
                    
                                    if intersected {
                                        collision :Collision= {{TYPES(iarchA),ieA},{TYPES(iarchB),ieB},ip}

                                        append(&collisions, collision)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        //Response
        for collision in collisions {
            using collision

            bodiesA, has_bodyA := scene.archetypes[eA.types].body.?
            transformsA, has_transformA := scene.archetypes[eA.types].transform.?

            bodiesB, has_bodyB := scene.archetypes[eB.types].body.?
            transformsB, has_transformB := scene.archetypes[eB.types].transform.?

            bodiesA[eA.idx].position = transformsA[eA.idx].position
            bodiesA[eA.idx].rotation = transformsA[eA.idx].rotation
            bodiesB[eB.idx].position = transformsB[eB.idx].position
            bodiesB[eB.idx].rotation = transformsB[eB.idx].rotation

            if has_bodyA && has_bodyB {
                contact_points := make([dynamic]cm.ContactPoint2D(f32))
                append(&contact_points, cm.ContactPoint2D(f32){
                                                                position=ip.position,
                                                                normal=ip.normal,
                                                                depth_penetration=ip.penetration,})

                cm.resolve_interpenetration(&bodiesA[eA.idx],&bodiesB[eB.idx],contact_points)

                transformsA[eA.idx].position = bodiesA[eA.idx].position
                transformsA[eA.idx].rotation = bodiesA[eA.idx].rotation 
                transformsB[eB.idx].position = bodiesB[eB.idx].position
                transformsB[eB.idx].rotation = bodiesB[eB.idx].rotation
                
                delete(contact_points)
            }
        }

        // //Trigger Callback/Events
        for collision in collisions {
            using collision

            healthsA, has_healthA := scene.archetypes[eA.types].health.?
            damagesA, has_damageA := scene.archetypes[eA.types].damage.?    
 
            healthsB, has_healthB := scene.archetypes[eB.types].health.?
            damagesB, has_damageB := scene.archetypes[eB.types].damage.?


            if has_healthA && has_damageB && healthsA[eA.idx].hp > 0 {
                healthsA[eA.idx].hp -= damagesB[eB.idx].attack

                if healthsA[eA.idx].hp == 0 {
                    remove_archetype(&scene.archetypes[eA.types], eA.idx)
                }
            }

            if has_healthB && has_damageA && healthsB[eB.idx].hp > 0 {
                healthsB[eB.idx].hp -= damagesA[eA.idx].attack

                if healthsB[eB.idx].hp == 0 {
                    remove_archetype(&scene.archetypes[eB.types], eB.idx)
                }
            }

            if check_condition(scene) {
                return
            }
        }

        for arch, iarch in &scene.archetypes {

            if TYPES(iarch) == TYPES.BALL || TYPES(iarch) == TYPES.PLAYER {
                transforms := arch.transform.?
                bodies := arch.body.?
                
                for i in 0..<arch.count {

                    bodies[i].position = transforms[i].position 
                    bodies[i].rotation = transforms[i].rotation

                    cm.integrate_semiimplicit_euler(&bodies[i],DT)
                    cm.clear_accumulator(&bodies[i])   

                    transforms[i].position = bodies[i].position
                    transforms[i].rotation = bodies[i].rotation
                }
            }
        }

        //draw
        for arch, iarch in scene.archetypes {

            sprite_renderers, has_sprite := arch.sprite_renderer.?
            transforms, has_transform := arch.transform.?
            structures, has_structure := arch.structure.?
            
            if has_sprite && has_transform {     

                for ie in 0..<arch.count {
                    draw_sprite(scene.renderer,sprite_renderers[ie],transforms[ie])
                }
            }

            if has_structure && DEBUG {
                for ie in 0..<arch.count {
                    s_pos := world_to_view_biased(transforms[ie].position,RATIO_PIXEL_UNIT,SCREEN_WIDTH,SCREEN_HEIGHT)
                    conversion :i32= 128/RATIO_PIXEL_UNIT

                    structure := structures[ie]
                    structure.position += s_pos
                    structure.halfsize *= f32(RATIO_PIXEL_UNIT) * transforms[ie].scale
                    
                    bottom := structure.position - structure.halfsize
                    rect:= SDL.Rect{
                        x=i32(bottom.x),
                        y=i32(bottom.y),
                        w=i32(2*structure.halfsize.x),
                        h=i32(2*structure.halfsize.y)
                    }
                    
                    SDL.SetRenderDrawColor(scene.renderer,0,255,0,255);
                    SDL.RenderDrawRect(scene.renderer,&rect)
                    SDL.SetRenderDrawColor(scene.renderer,255,255,255,255);
                }
            }
        }
        
        SDL.RenderPresent(scene.renderer)

        frame_time = SDL.GetTicks() - start_time

        if(DELAY > frame_time){
            SDL.Delay(DELAY - frame_time)
        }
    }
}