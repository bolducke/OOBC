package app

import fmt "core:fmt"
import strings "core:strings"

import SDL "vendor:sdl2"
import IMG "vendor:sdl2/image"

Sprite :: struct {
    texture: ^SDL.Texture,
    clip: SDL.Rect,
    ratio_pixel_unit: i32,
}

Resources :: struct {
    renderer: ^SDL.Renderer,
    sprites: map[string]Sprite,
}

create_resources :: proc(renderer: ^SDL.Renderer) -> (resources: Resources) {
    resources.renderer = renderer

    return resources
}

load_resources_sprite :: proc(resources: ^Resources, name: string, texture_path: string, clip: [4]i32) {
    
    texture := IMG.LoadTexture(resources.renderer, strings.clone_to_cstring(texture_path,context.temp_allocator))

    clip_rect: SDL.Rect

    if false {
        clip_rect = {clip[0],clip[1],clip[2],clip[3]}
    } else {
        tw, th: i32
        SDL.QueryTexture(texture, nil,nil,&tw,&th)
        clip_rect = {0,0,tw,th}
    }

    resources.sprites[name] = {texture=texture,clip=clip_rect}
}

unload_resource_sprite :: proc(resources: ^Resources, name: string)
{
    SDL.DestroyTexture(resources.sprites[name].texture)
}