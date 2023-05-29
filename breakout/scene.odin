package app

import mem "core:mem"
import time "core:time"
import fmt "core:fmt"
import json "core:encoding/json"
import lg "core:math/linalg"
import os "core:os"
import strings "core:strings"
import "core:strconv"
import SDL "vendor:sdl2"
import IMG "vendor:sdl2/image"
import TTF "vendor:sdl2/ttf"

import geom "../extern/regin/geometry"
import gcm "../extern/regin/physics/gcm"
import rg "../extern/regin"


import slice "core:slice"

NB_ARCHETYPES :: 6
PLAYER0 :: entity{EntityTag.PLAYER, 0}
BALL0 :: entity{EntityTag.BALL, 0}

Scene :: struct {
    window: ^SDL.Window,
    renderer: ^SDL.Renderer,

    font: ^TTF.Font,
    resources: Resources,
    archetypes: [NB_ARCHETYPES]Archetype,
}

STATE :: enum{WIN,LOST}

check_win_condition :: proc(scene: ^Scene) -> bool {
    bricks := scene.archetypes[EntityTag.BRICK]
    if(bricks.count == 0){
        healthbar_spriter := &scene.archetypes[EntityTag.TEXT].sprite_renderer.?[0]
        
        healthbar_spriter.sprite = load_resources_text(&scene.resources, "healthbar", fmt.tprint("WIN")).sprite

        {
            walls := scene.archetypes[EntityTag.WALL]
        }

        return true
    }

    balls := scene.archetypes[EntityTag.BALL]
    if(balls.count == 0) {
        healthbar_spriter := &scene.archetypes[EntityTag.TEXT].sprite_renderer.?[0]

        healthbar_spriter.sprite = load_resources_text(&scene.resources, "healthbar", fmt.tprint("LOST")).sprite
        return true
    }

    return false
}

create_scene :: proc() -> (scene: Scene) {
    assert(SDL.Init({.VIDEO, .EVENTS, .TIMER}) == 0, SDL.GetErrorString())

    scene.window = SDL.CreateWindow("Scene", SDL.WINDOWPOS_CENTERED,SDL.WINDOWPOS_CENTERED,SCREEN_WIDTH,SCREEN_HEIGHT,SDL.WINDOW_SHOWN)
    assert(scene.window != nil, SDL.GetErrorString())

    scene.renderer = SDL.CreateRenderer(scene.window,-1, {.SOFTWARE})
    assert(scene.renderer != nil, SDL.GetErrorString())

    //TTF
    assert(TTF.Init() == 0, SDL.GetErrorString())
    scene.font = TTF.OpenFont("data/font/bitwise.ttf", 16)
    assert(scene.font != nil, SDL.GetErrorString())

    //IMG
    IMG.Init({.PNG, .JPG})

    scene.resources = create_resources(scene.renderer, scene.font)

    scene.archetypes[EntityTag.BALL] = create_archetype_ball()
    scene.archetypes[EntityTag.PLAYER] = create_archetype_player()
    scene.archetypes[EntityTag.BRICK] = create_archetype_brick()
    scene.archetypes[EntityTag.WALL] = create_archetype_brick()
    scene.archetypes[EntityTag.SOLIDBRICK] = create_archetype_brick()
    scene.archetypes[EntityTag.TEXT] = create_archetype_text()

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

run :: proc(scene: ^Scene) {
    start_time, frame_time : u32

    // A nice observation is that those could be components and I think it would make thing simpler.
    damaged_entity: [NB_ARCHETYPES][dynamic]int
    killed_entity: [NB_ARCHETYPES][dynamic]int
    for i in 0..<NB_ARCHETYPES {
        defer delete(damaged_entity[i])
        defer delete(killed_entity[i])
    }

    collisions : [dynamic]Collision
    defer delete(collisions)

    derivatives: [NB_ARCHETYPES][dynamic]gcm.Derivative2D(f32)
    for p in derivatives {
        defer delete(p)
    }

    responses: [NB_ARCHETYPES][dynamic]gcm.Derivative2D(f32)
    for r in responses {
        defer delete(r)
    }

    keystates :[]u8 = SDL.GetKeyboardStateAsSlice()
    prev_keystates :[]u8 = mem.clone_slice(keystates)

    reset: bool = false

    for {
        start_time = SDL.GetTicks()
        event : SDL.Event

        // Detect if there is an input evnet
        for SDL.PollEvent(&event) {
            #partial switch event.type {
                case .QUIT:
                    return
            }
        }

        // //Handle Inputs
        keystates = SDL.GetKeyboardStateAsSlice()
        handle_player_input(scene.archetypes[:], prev_keystates, keystates)
        restrict_ball_movement(&scene.archetypes[EntityTag.BALL])
        prev_keystates = mem.clone_slice(keystates)

        // // Detect if there is a collision/intersection
        clear_dynamic_array(&collisions)
        process_collision_detection(scene.archetypes[:], &collisions)

        for i in 0..<NB_ARCHETYPES {
            clear_dynamic_array(&damaged_entity[i])
            clear_dynamic_array(&killed_entity[i])
        }
        process_damage(scene.archetypes[:], collisions[:], damaged_entity[:], killed_entity[:])

        // Healthbar Callback
        {  
            healthbar_spriter := &scene.archetypes[EntityTag.TEXT].sprite_renderer.?[0]

            entities := damaged_entity[BALL0.tag]

            for entity in entities {
                if entity == BALL0.idx {
                    { // Update Healthnar
                        ball_health := scene.archetypes[BALL0.tag].health.?[BALL0.idx]
                        healthbar_spriter.sprite = load_resources_text(&scene.resources, "healthbar", fmt.tprint(ball_health.hp, "/", ball_health.max_hp)).sprite
    
                    }
                 
                    {   // Reset Ball
                        btran := &scene.archetypes[BALL0.tag].transform.?[BALL0.idx]
                        bbody := &scene.archetypes[BALL0.tag].body.?[BALL0.idx].global
                
                        bbody.velocity = {0,0}
    
                        add_hierarchy_parent_child(scene.archetypes[:], PLAYER0, BALL0)
                        btran.local = TRS({0,1}, 0, {1,1})
    
                        reset = true
                    }
                }
            }
        }

        // Alter brick color When Brick/Solidbrick is damaged
        {   
            arch_tag :: [2]EntityTag{.BRICK, .SOLIDBRICK}

            for tag in arch_tag {
                healths := &scene.archetypes[tag].health.?
                spriters := &scene.archetypes[tag].sprite_renderer.?
    
                for ie in damaged_entity[tag] {
                    spriter := &spriters[ie]
                    health := healths[ie]
    
                    switch health.hp {
                        case -1:
                            spriter.color = WHITE
                        case 1:
                            spriter.color = RED
                        case 2:
                            spriter.color = ORANGE
                        case 3:
                            spriter.color = YELLOW
                        case 4:
                            spriter.color = GREEN
                        case:
                            spriter.color = CYAN
                    }
                }
            }
        }

        // Sync Transform && Hierarchy Transform
        {
            for arch, iarch in scene.archetypes {

                hierarchies, has_hierarchy := arch.hierarchy.?
                transforms, has_transform := arch.transform.?

                if has_transform {
                    for ie in 0..<arch.count {

                        transforms[ie]._global = rg.default_atransform2d()
                        
                        curr : entity = {EntityTag(iarch), ie}

                        if has_hierarchy {
                            curr_hier := &arch.hierarchy.?[ie]

                            for curr_hier.parent != entity_nil {
                                transform := &scene.archetypes[curr.tag].transform.?[curr.idx]
        
                                transforms[ie]._global = rg.mul(transforms[ie]._global, transform.local)
        
                                curr = curr_hier.parent
                                curr_hier = &scene.archetypes[curr.tag].hierarchy.?[curr.idx]
                            }
                        }
                        transform := &scene.archetypes[curr.tag].transform.?[curr.idx]
                        transforms[ie]._global = rg.mul(transforms[ie]._global, transform.local)
                    } 
                }
            }
        }

        process_collision_response(scene.archetypes[:], collisions[:], responses[:])

        {   
            if reset {
                responses[BALL0.tag][BALL0.idx] = {}
                reset = false
            }
        }
        
        {
            for rep, iarch in responses {

                bodies, has_body := scene.archetypes[iarch].body.?

                if has_body {
                    for b, ie in &bodies {
                        b.global.velocity += responses[iarch][ie].dv
                        b.global.angular_velocity += responses[iarch][ie].dw
                    }
                }

                transforms, has_tran := scene.archetypes[iarch].transform.?

                if has_tran {
                    for tran, ie in &transforms {
                        tran._global = rg.mul(tran._global, TRS( rg.Vec2(responses[iarch][ie].dx),responses[iarch][ie].dr,rg.Vec2{1,1}))
                    }
                }

            }
        }

        //Delete in reverse so that we are never changing the order unexpectedly.
        for entities, iarch in killed_entity {
            tag := iarch
            slice.reverse_sort(entities[:])

            for entity in entities {
                remove_archetype(&scene.archetypes[iarch], entity)
            }            
        }

        // Physics Update
        for i in 0..<NB_ARCHETYPES {
            clear_dynamic_array(&derivatives[i])
        }
        process_physic_integration(scene.archetypes[:], derivatives[:])

        {
            prev_gtransforms : [NB_ARCHETYPES][dynamic]rg.ATransform2D
            for i in 0..<NB_ARCHETYPES {
                clear_dynamic_array(&prev_gtransforms[i])
            }
            for arch, iarch in scene.archetypes {
                for ie in 0..<arch.count {
                    append(&prev_gtransforms[iarch], arch.transform.?[ie]._global)
                }
            }

            // Update Each Global Transform And Body Accordingly
            for arch, iarch in scene.archetypes {

                hierarchies, has_hierarchy := arch.hierarchy.?
                transforms, has_transform := arch.transform.?

                for ie in 0..<arch.count {
                    D_final: gcm.Derivative2D(f32)

                    curr : entity = {EntityTag(iarch), ie}
                    if has_hierarchy {
                        curr_hier := &arch.hierarchy.?[ie]

                        for curr_hier.parent != entity_nil {
                            D_curr := derivatives[curr.tag][curr.idx]
                            
                            D_final.dx += D_curr.dx
                            D_final.dr += D_curr.dr
    
                            curr = curr_hier.parent
                            curr_hier = &scene.archetypes[curr.tag].hierarchy.?[curr.idx]
                        }
                    }
                    D_curr := derivatives[curr.tag][curr.idx]
                            
                    D_final.dx += D_curr.dx
                    D_final.dr += D_curr.dr

                    transforms[ie]._global = rg.mul(rg.translate( rg.Vec2(D_final.dx)) , rg.rotate(D_final.dr) , prev_gtransforms[iarch][ie])
                } 
            }

            // Update local transform
            for arch, iarch in scene.archetypes {
                hierarchies, has_hierarchy := &scene.archetypes[iarch].hierarchy.?
                _, has_transform := &scene.archetypes[iarch].transform.?

                for ie in 0..<arch.count {
                    if has_transform {
                        curr:entity = {EntityTag(iarch), ie}
                        tran := &scene.archetypes[curr.tag].transform.?[curr.idx]

                        if has_hierarchy {
                            hier := &scene.archetypes[curr.tag].hierarchy.?[curr.idx]

                            if hier.parent != entity_nil {
                                parent_tran := &scene.archetypes[hier.parent.tag].transform.?[hier.parent.idx]

                                tran.local = rg.mul(tran._global, rg.inverse(parent_tran._global))
                            } else {
                                tran.local = tran._global
                            }
                        }  else {
                            tran.local = tran._global
                        }
                    }
                }
            }
        }

        SDL.SetRenderDrawColor(scene.renderer,0,0,0,255)
        SDL.RenderClear(scene.renderer)

        process_draw(scene.renderer, scene.archetypes[:])

        //Render
        SDL.RenderPresent(scene.renderer)

        frame_time = SDL.GetTicks() - start_time

        if DELAY > frame_time {
            SDL.Delay(DELAY - frame_time)
        }

        check_win_condition(scene)
    }
}