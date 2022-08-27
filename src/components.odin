package app

import "core:fmt"

import SDL "vendor:sdl2"

import regin "../extern/regin"
import geom "../extern/regin/geometry"
import cm "../extern/regin/physics/classical_mechanics"

//Components

Damage :: struct {
    attack: i32,
}

Health :: struct {
    hp : i32,
    max_hp : i32,
}

SpriteRenderer :: struct {
    using sprite: Sprite,
    color: [4]u8,
    flip: SDL.RendererFlip,
    offset: [2]f32,
}

init_sprite_renderer :: proc(sprite: Sprite) -> (renderer: SpriteRenderer) {
    renderer.sprite = sprite
    renderer.color = {255,255,255,255}
    renderer.flip = SDL.RendererFlip.NONE
    renderer.offset = {0.5,0.5}

    return renderer
}

draw_sprite :: proc(renderer : ^SDL.Renderer, spriter : SpriteRenderer, transform: regin.Transform2D($T))  {

    s_pos := world_to_view_biased(transform.position,RATIO_PIXEL_UNIT,SCREEN_WIDTH,SCREEN_HEIGHT)

    conversion :i32= 128/RATIO_PIXEL_UNIT

    src_rec := spriter.clip

    dst_rec := SDL.FRect{
        x = s_pos.x - f32(spriter.clip.w/conversion) * spriter.offset.x * transform.scale.x,
        y = s_pos.y - f32(spriter.clip.h/conversion) * spriter.offset.y * transform.scale.y,
        w = f32(spriter.clip.w/conversion) * transform.scale.x,
        h = f32(spriter.clip.h/conversion) * transform.scale.y,
    }

    SDL.SetTextureColorMod(spriter.texture,spriter.color.r,spriter.color.g,spriter.color.b)
    SDL.RenderCopyExF(renderer, spriter.texture, &src_rec, &dst_rec, f64(transform.rotation), nil, spriter.flip)
    SDL.SetTextureColorMod(spriter.texture, 255, 255, 255)
}