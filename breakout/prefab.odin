package app

import SDL "vendor:sdl2"

import rg "../extern/regin"
import geom "../extern/regin/geometry"
import gcm "../extern/regin/physics/gcm"

import lg "core:math/linalg"

PfTransform2D :: struct {
    position: lg.Vector2f32,
    rotation: f32,
    scale: lg.Vector2f32,
}

PfRigidBody2D :: struct {
    particle: gcm.Particle2D(f32),
}

Player :: struct {
    sprite_renderer: SpriteRenderer,
    rtransform: PfTransform2D,
    body: PfRigidBody2D,
    collider: Collider2D,
    hierarchy: Hierarchy,
}

create_archetype_player :: proc() -> (arch: Archetype) {
    arch.count = 0

    arch.transform = make([dynamic]Transform2D)
    arch.health =  nil
    arch.damage = nil
    arch.sprite_renderer = make([dynamic]SpriteRenderer)
    arch.body = make([dynamic]Rigidbody2D)
    arch.collider = make([dynamic]Collider2D)   
    arch.hierarchy = make([dynamic]Hierarchy)

    return
}

Brick :: struct {
    health: Health,
    damage: Damage,
    sprite_renderer: SpriteRenderer,
    rtransform: PfTransform2D,
    body: PfRigidBody2D,
    collider: Collider2D,
}

create_archetype_brick :: proc() -> (arch: Archetype) {
    arch.count = 0

    arch.transform = make([dynamic]Transform2D)
    arch.damage = make([dynamic]Damage)
    arch.health = make([dynamic]Health)
    arch.sprite_renderer = make([dynamic]SpriteRenderer)
    arch.body = make([dynamic]Rigidbody2D)
    arch.collider = make([dynamic]Collider2D)

    return
}

Ball :: struct {
    rtransform: PfTransform2D,
    health: Health,
    damage: Damage,
    sprite_renderer: SpriteRenderer,
    body: PfRigidBody2D,
    collider: Collider2D,

    hierarchy: Hierarchy,
}

create_archetype_ball :: proc() -> (arch: Archetype) {
    arch.count = 0

    arch.transform = make([dynamic]Transform2D)
    arch.health = make([dynamic]Health)
    arch.damage = make([dynamic]Damage)
    arch.sprite_renderer = make([dynamic]SpriteRenderer)
    arch.body = make([dynamic]Rigidbody2D)
    arch.collider = make([dynamic]Collider2D)  
    arch.hierarchy = make([dynamic]Hierarchy)
    
    return
}

Text :: struct {
    rtransform: PfTransform2D,
    sprite_renderer: SpriteRenderer,
}

create_archetype_text :: proc() -> (arch: Archetype) {
    arch.count = 0

    arch.transform = make([dynamic]Transform2D)
    arch.sprite_renderer = make([dynamic]SpriteRenderer)

    return arch
}

add_archetype_player:: proc(arch: ^Archetype, pf: Player) {
    arch.count += 1

    tran := TRS(pf.rtransform.position, pf.rtransform.rotation, pf.rtransform.scale)
    
    append(&arch.transform.?, Transform2D{_global=tran, local=tran})
    append(&arch.sprite_renderer.?, pf.sprite_renderer)
    append(&arch.body.?, Rigidbody2D{pf.body.particle})
    append(&arch.collider.?, pf.collider)
    append(&arch.hierarchy.?, pf.hierarchy)
}

add_archetype_ball :: proc(arch: ^Archetype, pf: Ball) {
    arch.count += 1

    tran := TRS(pf.rtransform.position, pf.rtransform.rotation, pf.rtransform.scale)

    append(&arch.transform.?, Transform2D{_global=tran, local=tran})
    append(&arch.health.?, pf.health)
    append(&arch.damage.?, pf.damage)
    append(&arch.sprite_renderer.?, pf.sprite_renderer)
    append(&arch.body.?, Rigidbody2D{pf.body.particle})
    append(&arch.collider.?, pf.collider)
    append(&arch.hierarchy.?, pf.hierarchy)
}

add_archetype_brick :: proc(arch: ^Archetype, pf: Brick) {
    arch.count += 1

    tran := TRS(pf.rtransform.position, pf.rtransform.rotation, pf.rtransform.scale)

    append(&arch.transform.?, Transform2D{_global=tran, local=tran})
    append(&arch.health.?, pf.health)
    append(&arch.damage.?, pf.damage)
    append(&arch.sprite_renderer.?, pf.sprite_renderer)
    append(&arch.body.?, Rigidbody2D{pf.body.particle})
    append(&arch.collider.?, pf.collider)
}

add_archetype_text :: proc(arch: ^Archetype, pf: Text) {
    arch.count += 1

    tran := TRS(pf.rtransform.position, pf.rtransform.rotation, pf.rtransform.scale)

    append(&arch.transform.?, Transform2D{_global=tran,local=tran})
    append(&arch.sprite_renderer.?, pf.sprite_renderer)
}

add_archetype :: proc{add_archetype_player, add_archetype_brick, add_archetype_ball, add_archetype_text}