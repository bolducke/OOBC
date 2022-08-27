package app

import SDL "vendor:sdl2"

import regin "../extern/regin"
import geom "../extern/regin/geometry"
import cm "../extern/regin/physics/classical_mechanics"

Brick :: struct {
    health: Health,
    damage: Damage,
    sprite_renderer: SpriteRenderer,
    transform: regin.Transform2D(f32),
    body: cm.Particle2D(f32),
    structure: geom.CubeAAC(2,f32),
}

create_archetype_brick :: proc() -> (arch: Archetype) {
    arch.count = 0
    arch.transform = make([dynamic]regin.Transform2D(f32))
    arch.damage = make([dynamic]Damage)
    arch.health = make([dynamic]Health)
    arch.sprite_renderer = make([dynamic]SpriteRenderer)
    arch.body = make([dynamic]cm.Particle2D(f32))
    arch.structure = make([dynamic]geom.CubeAAC(2,f32))


    return
}

add_archetype_brick :: proc(arch: ^Archetype, brick: Brick) {
    arch.count += 1

    append(&arch.transform.?, brick.transform)
    append(&arch.health.?, brick.health)
    append(&arch.damage.?, brick.damage)
    append(&arch.sprite_renderer.?, brick.sprite_renderer)
    append(&arch.body.?, brick.body)
    append(&arch.structure.?, brick.structure)
}