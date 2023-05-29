package app

import fmt "core:fmt"
import strings "core:strings"

import SDL "vendor:sdl2"
import IMG "vendor:sdl2/image"
import TTF "vendor:sdl2/ttf"

SpriteResource :: struct {
    texture: ^SDL.Texture,
    clip: SDL.Rect,
    ratio_pixel_unit: i32,
}

TextResource :: struct {
    sprite: SpriteResource,
    value: string,
}

Resources :: struct {
    renderer: ^SDL.Renderer,
    font: ^TTF.Font,
    sprites: map[string]SpriteResource,
    texts: map[string]TextResource,
}

create_resources :: proc(renderer: ^SDL.Renderer, font: ^TTF.Font) -> (resources: Resources) {
    resources.renderer = renderer
    resources.font = font

    return resources
}

uncache_resources_text :: proc(resources: ^Resources, name:string) {
    SDL.DestroyTexture(resources.texts[name].sprite.texture)
}

cache_resources_text :: proc(resources: ^Resources, name:string, str:string) {
    cstr := strings.clone_to_cstring(str,context.temp_allocator)

    surface := TTF.RenderText_Solid(resources.font, cstr, {255,255,255,255})
    defer SDL.FreeSurface(surface)

    text_resource := TextResource{sprite=SpriteResource{ratio_pixel_unit=8},value=str}

    // create texture to render
    text_resource.sprite.texture = SDL.CreateTextureFromSurface(resources.renderer, surface)

    // destination SDL.Rect
    TTF.SizeText(resources.font, cstr, &text_resource.sprite.clip.w, &text_resource.sprite.clip.h)

    resources.texts[name] = text_resource
}

load_resources_text :: proc(resources: ^Resources, name:string, str:string) -> (TextResource) {
    if name in resources.texts {
        text_resource := resources.texts[name]

        if text_resource.value != str {
            uncache_resources_text(resources, name)
            cache_resources_text(resources, name, str)
        }
    } else {
        cache_resources_text(resources, name, str)
    }

    return resources.texts[name]
}

load_resources_sprite :: proc(resources: ^Resources, name: string, texture_path: string, clip: [4]i32, ratio_pixel_unit: i32) {
    
    texture := IMG.LoadTexture(resources.renderer, strings.clone_to_cstring(texture_path,context.temp_allocator))

    clip_rect: SDL.Rect

    if false {
        clip_rect = {clip[0], clip[1], clip[2], clip[3]}
    } else {
        tw, th: i32
        SDL.QueryTexture(texture, nil,nil,&tw,&th)
        clip_rect = {0, 0, tw, th}
    }

    resources.sprites[name] = {texture=texture,clip=clip_rect, ratio_pixel_unit=ratio_pixel_unit}
}

unload_resource_sprite :: proc(resources: ^Resources, name: string)
{
    SDL.DestroyTexture(resources.sprites[name].texture)
}

unload_resource_text :: proc(resources: ^Resources, name: string)
{
    uncache_resources_text(resources, name)
}