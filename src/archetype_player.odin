package app

import SDL "vendor:sdl2"

import regin "../extern/regin"
import geom "../extern/regin/geometry"
import cm "../extern/regin/physics/classical_mechanics"

Player :: struct {
    sprite_renderer: SpriteRenderer,
    transform: regin.Transform2D(f32),
    body: cm.Particle2D(f32),
    structure: geom.CubeAAC(2,f32),
}

create_archetype_player :: proc() -> (arch: Archetype) {
    arch.transform = make([dynamic]regin.Transform2D(f32))
    arch.health =  nil
    arch.damage = nil
    arch.sprite_renderer = make([dynamic]SpriteRenderer)
    arch.body = make([dynamic]cm.Particle2D(f32))
    arch.structure = make([dynamic]geom.CubeAAC(2,f32))   

    return
}

add_archetype_player:: proc(arch: ^Archetype, player: Player) {
    arch.count += 1

    append(&arch.transform.?, player.transform)
    append(&arch.sprite_renderer.?, player.sprite_renderer)
    append(&arch.body.?, player.body)
    append(&arch.structure.?, player.structure)
}

handle_player_input :: proc(arch: ^Archetype, states: []u8) {
    nb_player := len(arch.transform.?)

    for iplayer in 0..<nb_player{
        body := &arch.body.?[iplayer]

        if bool(states[SDL.Scancode.W]) {
            body.velocity = {0,3}
        } else if bool(states[SDL.Scancode.S]) {
            body.velocity = {0,-3}
        } else if bool(states[SDL.Scancode.A]) {
            body.velocity = {-3,0}
        } else if bool(states[SDL.Scancode.D]) {
            body.velocity = {3,0}            
        } else if bool(states[SDL.Scancode.SPACE]) {
            // if is_locked(ent.ball^) {
            //     //    launch(ent.ball,{ent.body.velocity.x,1})
            //     } else {
            //         //reset_ball(&ent.ball, &ent.transform)
            //     }
        } else {
            body.velocity = {0,0}
        }
    }
}