package app

import SDL "vendor:sdl2"

import regin "../extern/regin"
import geom "../extern/regin/geometry"
import cm "../extern/regin/physics/classical_mechanics"

Ball :: struct {
    transform: regin.Transform2D(f32),
    health: Health,
    damage: Damage,
    sprite_renderer: SpriteRenderer,
    body: cm.Particle2D(f32),
    structure: geom.CubeAAC(2,f32),
}

create_archetype_ball :: proc() -> (arch: Archetype) {
    arch.transform = make([dynamic]regin.Transform2D(f32))
    arch.health = make([dynamic]Health)
    arch.damage = make([dynamic]Damage)
    arch.sprite_renderer = make([dynamic]SpriteRenderer)
    arch.body = make([dynamic]cm.Particle2D(f32))
    arch.structure = make([dynamic]geom.CubeAAC(2,f32))  
    
    return
}

add_archetype_ball :: proc(arch: ^Archetype, ball: Ball) {
    arch.count += 1

    append(&arch.transform.?, ball.transform)
    append(&arch.health.?, ball.health)
    append(&arch.damage.?, ball.damage)
    append(&arch.sprite_renderer.?, ball.sprite_renderer)
    append(&arch.body.?, ball.body)
    append(&arch.structure.?, ball.structure)
}

reset_ball :: proc(ball: ^Ball, transform: ^regin.Transform2D) {
    ball.body.velocity = 0
    ball.transform.position = {0,0.1}
    //set parent
}

launch :: proc(ball: ^Ball, vel: [2]f32) {
    ball.body.velocity = vel
    //set parent
}

is_locked :: proc(ball: Ball) -> bool {
    return ball.body.velocity == [2]f32{0,0}
}