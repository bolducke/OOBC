package app

import SDL "vendor:sdl2"

import regin "../extern/regin"
import geom "../extern/regin/geometry"
import cm "../extern/regin/physics/gcm"

//Entity
Archetype :: struct {
    count: int,
    
    transform: Maybe([dynamic]Transform2D),
    health: Maybe([dynamic]Health),
    damage: Maybe([dynamic]Damage),
    sprite_renderer: Maybe([dynamic]SpriteRenderer),
    body: Maybe([dynamic]Rigidbody2D),
    collider: Maybe([dynamic]Collider2D),
    hierarchy: Maybe([dynamic]Hierarchy),
}

remove_archetype :: proc(arch: ^Archetype, idx: int){
    assert(arch.count > idx && idx >= 0)
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

    if v, ok := &arch.collider.?; ok {
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

    if v, ok := &arch.collider.?; ok {
        free(v)
    }
}