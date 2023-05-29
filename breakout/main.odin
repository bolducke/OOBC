package app

import "core:fmt"
import lg "core:math/linalg"

import rg "../extern/regin"

FPS :: 60
DELAY :: 1000 / FPS
DT :: 0.1

SCREEN_SIZE :: [2]i32{300,300}

SCREEN_WIDTH :i32: SCREEN_SIZE[0]
SCREEN_HEIGHT :i32: SCREEN_SIZE[1]
RATIO_PIXEL_UNIT :i32: 16

BOUNDS :: [2]f32{6,6}

VIEW_MATRIX := rg.mul(
                    
                      viewport_matrix(SCREEN_SIZE[0], SCREEN_SIZE[1]),
                      ortho_matrix( (f32(SCREEN_SIZE[0])/2.0)/f32(RATIO_PIXEL_UNIT), (f32(SCREEN_SIZE[1])/2.0)/f32(RATIO_PIXEL_UNIT)),
                      rg.translate(rg.Vec2{0, -BOUNDS[1]}),
                    )

DEBUG :: false

WHITE :[4]u8: {255,255,255,255}
RED :[4]u8: {255, 0, 0, 255}
ORANGE :[4]u8: {255, 165, 0, 255}
YELLOW :[4]u8: {255, 255, 0, 255}
GREEN :[4]u8: {0, 255, 0, 255}
CYAN :[4]u8: {255, 255, 0, 255}



main :: proc() {
    scene := create_scene()
    defer destroy_scene(&scene)

    load_scene_json(&scene, "scene/basic.json")
    run(&scene)
}       