package app

import fmt "core:fmt"
import os "core:os"
import strings "core:strings"
import json "core:encoding/json"

import geom "../extern/regin/geometry"
import cm "../extern/regin/physics/gcm"
import regin "../extern/regin"

SceneDescriptor :: struct {
    assets: AssetsDescriptor,
    layout: LayoutDescriptor,
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

load_scene_json :: proc(scene: ^Scene, scene_path : string) {

    data, err_load := os.read_entire_file_from_filename(strings.concatenate({"data/",scene_path}))
	if !err_load {
        fmt.eprintln("Failed to load the file!", scene_path)
    }
    defer delete(data)

    scene_desc: SceneDescriptor

    err := json.unmarshal(data, &scene_desc)
    assert(err == nil, "Error Loading Scene")
    
    for sprite_name, sprite_desc in scene_desc.assets.sprites {
        load_resources_sprite(&scene.resources, sprite_name, strings.concatenate({"data/", sprite_desc.texture}), sprite_desc.clip, sprite_desc.ratio_pixel_unit)
    }

    ball:= Ball{
        health = {
            hp = 5,
            max_hp = 5,
        },
        damage = {
            attack=1,
        },
        rtransform = {
            position={0,1.5},
            rotation=0,
            scale={1,1},
        },
        sprite_renderer = init_sprite_renderer(scene.resources.sprites["ball"]),
        body = {
            particle = {
                material = {
                    imass = 0.1, 
                    iinertia = 0, 
                    restitution=1,
                },
            }
        },
        collider ={
            structure = CCUBEAAC{
                position={0,0}, 
                halfsize={0.5,0.5},
            },
        },
        hierarchy = init_hierarchy(),
    }
    add_archetype(&scene.archetypes[BALL0.tag], ball)

    player:= Player{
        rtransform = {
            position={0,0.5},
            rotation=0,
            scale={1,1},
        },
        sprite_renderer = init_sprite_renderer(scene.resources.sprites["player"]),
        body = {
            particle = {
                material = {
                    imass = 0, 
                    iinertia = 0, 
                    restitution=1,
                },
            }
        },
        collider ={
            structure = CCUBEAAC{
                position={0,0}, 
                halfsize={2,0.5},
            },
        },
        hierarchy = init_hierarchy(),
    }
    add_archetype(&scene.archetypes[PLAYER0.tag], player)

    add_hierarchy_parent_child(scene.archetypes[:], PLAYER0, BALL0)

    pfwall := Brick{
        health = {
            hp=-1,
            max_hp=5,
        },
        rtransform = {},
        sprite_renderer = init_sprite_renderer(sprite=scene.resources.sprites["solid_brick"]),
        body = {
            particle = {
                material = {
                    imass = 0, 
                    iinertia = 0, 
                    restitution=1,
                },
            }
        },
        collider = {
            structure = CCUBEAAC{
                position={},
                halfsize={2,2},
            },
        },
    }

    //Down
    {
        wall:= pfwall

        wall.rtransform = {
            position = {0,-2},
            rotation = 0,
            scale = {BOUNDS[0]*2,1},
        }
        wall.damage.attack = 1

        add_archetype(&scene.archetypes[EntityTag.WALL], wall)
    }

    //Up
    {
        wall := pfwall

        wall.rtransform = {
            position = {0,2*BOUNDS[1]+2},
            rotation = 0,
            scale = {BOUNDS[0]*2,1},
        }

        add_archetype(&scene.archetypes[EntityTag.WALL], wall)
    }

    //Left
    {
        wall := pfwall

        wall.rtransform = {
            position = {-BOUNDS[0]-2,0},
            rotation = 0,
            scale = {1,BOUNDS[1]*2},
        }

        add_archetype(&scene.archetypes[EntityTag.WALL], wall)
    }

    //Right
    {
        wall := pfwall

        wall.rtransform = {
            position = {BOUNDS[0]+2,0},
            rotation = 0,
            scale = {1,BOUNDS[1]*2},
        }

        add_archetype(&scene.archetypes[EntityTag.WALL], wall)
    }

    pfbrick := Brick{
        health = {
            max_hp=5,
        },
        damage = {
            attack=0,
        },
        rtransform = {},
        sprite_renderer = {},
        body = {
            particle = {
                material = {
                    imass= 0, 
                    iinertia= 0, 
                    restitution=1,
                },
            }
        },
        collider = {
            structure = CCUBEAAC{
                position={},
                halfsize={0.5,0.5},
            },
        },
    }

    //Live
    {
        text := Text{
            rtransform = {position={0,13.5}, scale={15,15}},
            sprite_renderer = init_sprite_renderer(),
        }

        text.sprite_renderer.sprite = load_resources_text(&scene.resources, "healthbar", fmt.tprint(ball.health.hp, "/", ball.health.max_hp)).sprite

        add_archetype(&scene.archetypes[EntityTag.TEXT], text)
    }

    for irow:= 0; irow < len(scene_desc.layout.grid); irow+=1 {
        grid_x_len := len(scene_desc.layout.grid[irow])
        for icol:= 0; icol < grid_x_len; icol+=1 {
            grid := scene_desc.layout.grid

            brick := pfbrick
    
            brick.health.hp = grid[irow][icol]

            brick.rtransform = {
                position = {f32(icol) - f32(len(grid[0]))/2.0 + 0.5, 2*BOUNDS[1] - f32(irow) - 0.5},
                rotation = 0,
                scale = {1,1},
            }

            tag :EntityTag= .UNDEFINED

            if grid[irow][icol] != -1 {
                brick.sprite_renderer = init_sprite_renderer(scene.resources.sprites["brick"])
                tag = .BRICK
            } else {
                brick.sprite_renderer = init_sprite_renderer(scene.resources.sprites["solid_brick"])
                tag = .SOLIDBRICK
            }

            switch brick.health.hp {
                case -1:
                    brick.sprite_renderer.color = WHITE
                case 1:
                    brick.sprite_renderer.color = RED
                case 2:
                    brick.sprite_renderer.color = ORANGE
                case 3:
                    brick.sprite_renderer.color = YELLOW
                case 4:
                    brick.sprite_renderer.color = GREEN
                case:
                    brick.sprite_renderer.color = CYAN
            }

            add_archetype(&scene.archetypes[tag], brick)    
        }
    }

    return
}
