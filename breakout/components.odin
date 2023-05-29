package app

import "core:fmt"

import SDL "vendor:sdl2"

import rg "../extern/regin"
import geom "../extern/regin/geometry"
import gcm "../extern/regin/physics/gcm"

import lg "core:math/linalg"

//Components

CCUBEAAC :: geom.CubeAAC(2,f32)
Collider2D :: struct {
    structure: union {CCUBEAAC},
}

Transform2D :: struct {
    local: rg.ATransform2D,
    _global: rg.ATransform2D,
}

TRS :: proc(position: lg.Vector2f32, rotate: f32, scale: lg.Vector2f32) -> rg.ATransform2D {
    return rg.mul(rg.translate(position), rg.rotate(rotate), rg.scale(scale))
}

SRT :: proc(scale: lg.Vector2f32, rotate: f32, position: lg.Vector2f32) -> rg.ATransform2D {
    return rg.mul(rg.scale(scale), rg.rotate(rotate), rg.translate(position))
}

Damage :: struct {
    attack: i32,
}

Health :: struct {
    hp : i32,
    max_hp : i32,
}

SpriteRenderer :: struct {
    using sprite: SpriteResource,
    color: [4]u8,
    flip: SDL.RendererFlip,
    offset: [2]f32,
}

Rigidbody2D :: struct {
    global: gcm.Particle2D(f32), // There is really no need for a local/global distinction. If the ball hit something, we should "remove" the hierarchy.
}

Hierarchy :: struct {
    parent: entity,

    children: int,
    first: entity,

    prev: entity,
    next: entity,
}

init_hierarchy :: proc() -> (h: Hierarchy) {
    h.children = 0
    h.first = entity_nil
    h.prev = entity_nil
    h.next = entity_nil
    h.parent = entity_nil
    return 
}

init_sprite_renderer_empty :: proc() -> (spriter: SpriteRenderer) {
    return init_sprite_renderer(SpriteResource{})
}

init_sprite_renderer_sprite :: proc(sprite: SpriteResource) -> (spriter: SpriteRenderer) {
    spriter.sprite = sprite
    spriter.color = {255,255,255,255}
    spriter.flip = SDL.RendererFlip.NONE
    spriter.offset = {0.5,0.5}

    return spriter
}

init_sprite_renderer :: proc{init_sprite_renderer_empty, init_sprite_renderer_sprite}