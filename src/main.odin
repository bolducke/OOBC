package app

import "core:fmt"

main :: proc() {
    scene := create_scene()
    defer destroy_scene(&scene)

    load_content(&scene, "scene/basic.json")
    run(&scene)
}       