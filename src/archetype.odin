package app

import SDL "vendor:sdl2"

import regin "../extern/regin"
import geom "../extern/regin/geometry"
import cm "../extern/regin/physics/classical_mechanics"

//Entity
Archetype :: struct {
    count: int,

    transform: Maybe([dynamic]regin.Transform2D(f32)),
    health: Maybe([dynamic]Health),
    damage: Maybe([dynamic]Damage),
    sprite_renderer: Maybe([dynamic]SpriteRenderer),
    body: Maybe([dynamic]cm.Particle2D(f32)),
    structure: Maybe([dynamic]geom.CubeAAC(2,f32)),
}

remove_archetype :: proc(arch: ^Archetype, idx: int){
    assert(arch.count  > idx && idx >= 0)
    arch.count -= 1

    if v, ok := &arch.transform.?; ok {
        unordered_remove(v,idx)
    }

    if v, ok := &arch.damage.?; ok {
        unordered_remove(v,idx)
    }

    if v, ok := &arch.health.?; ok {
        unordered_remove(v,idx)
    }

    if v, ok := &arch.sprite_renderer.?; ok {
        unordered_remove(v,idx)
    }

    if v, ok := &arch.body.?; ok {
        unordered_remove(v,idx)
    }

    if v, ok := &arch.structure.?; ok {
        unordered_remove(v,idx)
    }
}

destroy_archetype :: proc(arch: ^Archetype) {
    if v, ok := &arch.transform.?; ok {
        free(v)
    }

    if v, ok := &arch.damage.?; ok {
        free(v)
    }

    if v, ok := &arch.health.?; ok {
        free(v)
    }

    if v, ok := &arch.sprite_renderer.?; ok {
        free(v)
    }

    if v, ok := &arch.body.?; ok {
        free(v)
    }

    if v, ok := &arch.structure.?; ok {
        free(v)
    }
}