package app

import SDL "vendor:sdl2"

import rg "../extern/regin"
import geom "../extern/regin/geometry"
import cm "../extern/regin/physics/gcm"
import lg "core:math/linalg"

import fmt "core:fmt"

entity :: struct {
    tag: EntityTag,
    idx: int,
}

entity_nil :entity: {.UNDEFINED, -1}

add_hierarchy_parent_child :: proc(archetypes: []Archetype, parent: entity, child: entity) {
    _, has_phiers := archetypes[parent.tag].hierarchy.?
    _, has_ptran := archetypes[parent.tag].transform.?

    _, has_chiers := archetypes[child.tag].hierarchy.?
    _, has_ctran := archetypes[child.tag].transform.?

    if has_phiers == false || has_chiers == false || has_ptran == false || has_ctran == false{
        return
    }

    parent_hier := &archetypes[parent.tag].hierarchy.?[parent.idx]
    child_hier := &archetypes[child.tag].hierarchy.?[child.idx]

    parent_hier.children += 1
    first := parent_hier.first
    parent_hier.first = child

    if first != entity_nil {
        first_hier := &archetypes[first.tag].hierarchy.?[first.idx]
        first_hier.prev = child
        child_hier.next = first
    }
    
    child_hier.parent = parent
    child_hier.prev = entity_nil

    // Update the transform accordingly    
    ptran := &archetypes[parent.tag].transform.?[parent.idx]
    ctran := &archetypes[child.tag].transform.?[child.idx]

    ctran.local = rg.mul(rg.inverse(ptran._global), ctran._global)
}

remove_hierarchy_child :: proc(archetypes: []Archetype, child: entity) {
    child_hier := &archetypes[child.tag].hierarchy.?[child.idx]
    parent := child_hier.parent
    if parent == entity_nil {
        return
    }
    parent_hier := &archetypes[parent.tag].hierarchy.?[parent.idx]

    if parent_hier.first == child {
        parent_hier.first = child_hier.next
        child_hier.parent = entity_nil
        parent_hier.children -= 1
    }

    if child_hier.next != entity_nil {
        next_child_hier := &archetypes[child_hier.next.tag].hierarchy.?[child_hier.next.idx]
        next_child_hier.prev = child_hier.prev
        child_hier.parent = entity_nil
        parent_hier.children -= 1
    }
    
    if child_hier.prev != entity_nil {
        prev_child_hier := &archetypes[child_hier.prev.tag].hierarchy.?[child_hier.prev.idx]
        prev_child_hier.next = child_hier.next
        child_hier.parent = entity_nil
        parent_hier.children -= 1
    }

    ctran := &archetypes[child.tag].transform.?[child.idx]        
    ctran.local = ctran._global
}


EntityTag :: enum int {UNDEFINED=-1, BALL=0,PLAYER=1,BRICK=2,WALL=3,SOLIDBRICK=4, TEXT=5}

draw_entities_general :: proc(renderer: ^SDL.Renderer, arch: Archetype) {
    sprite_renderers, has_sprite := arch.sprite_renderer.?
    transforms, has_transform := arch.transform.?
    structures, has_structure := arch.collider.?
    
    if has_sprite && has_transform {  

        for ie in 0..<arch.count {
            tran := rg.mul(VIEW_MATRIX, transforms[ie]._global)
            spriter := sprite_renderers[ie]

            s_pos, s_rot, s_scale := rg.decompose_affine_transform(tran)
            sd := rg.Vec2{f32(spriter.clip.w), f32(spriter.clip.h)}/f32(spriter.ratio_pixel_unit) * rg.retrieve_scale(transforms[ie]._global)
                
            src_rec := spriter.clip
            dst_rec := SDL.FRect{
                x = s_pos.x - sd.x * spriter.offset.x,
                y = s_pos.y - sd.y * spriter.offset.y,
                w = sd.x,
                h = sd.y,
            }
        
            SDL.SetTextureColorMod(spriter.texture,spriter.color.r,spriter.color.g,spriter.color.b)
            SDL.RenderCopyExF(renderer, spriter.texture, &src_rec, &dst_rec, f64(s_rot), nil, spriter.flip)
            SDL.SetTextureColorMod(spriter.texture, 255, 255, 255)
        }
    }
}

draw_entities :: proc(renderer: ^SDL.Renderer, arch: Archetype, tag: EntityTag) {
    #partial switch tag {
        case .WALL:
            draw_outline_structure(renderer, arch)
        case:
            draw_entities_general(renderer, arch)
    }
}

draw_outline_structure :: proc(renderer: ^SDL.Renderer, arch: Archetype) {
    transforms, has_transform := arch.transform.?
    colliders, has_structure := arch.collider.?

    if has_transform & has_structure {
        for ie in 0..<arch.count {
            collider := colliders[ie]

            tran := rg.mul(VIEW_MATRIX, transforms[ie]._global)

            switch structure in &collider.structure {
                case CCUBEAAC:
                    structure.position += cast([2]f32) (rg.retrieve_translation(tran))
                    structure.halfsize *= cast([2]f32) (rg.retrieve_scale(tran))
                    
                    bottom := structure.position - structure.halfsize
                    rect:= SDL.Rect{
                        x=i32(bottom.x),
                        y=i32(bottom.y),
                        w=i32(2*structure.halfsize.x),
                        h=i32(2*structure.halfsize.y),
                    }
                    
                    SDL.SetRenderDrawColor(renderer,0,255,0,255)
                    SDL.RenderDrawRect(renderer,&rect)
            }
        }
    }
}
handle_player_input :: proc(archetypes: []Archetype, prev_states: []u8, states: []u8) {
    arch_player := &archetypes[EntityTag.PLAYER]
    pbody := &archetypes[PLAYER0.tag].body.?[PLAYER0.idx].global
    ptran := &archetypes[PLAYER0.tag].transform.?[PLAYER0.idx]
    ppos := rg.retrieve_translation(ptran._global)

    pbody.velocity = {0,0}
    
    // if bool(states[SDL.Scancode.W]) {
    //     pbody.velocity += {0,3}
    // }
    
    // if bool(states[SDL.Scancode.S]) {
    //     pbody.velocity += {0,-3}
    // }
    
    if bool(states[SDL.Scancode.A]) {

        
        if (ppos[0] > -BOUNDS[0]+2.1) {
            pbody.velocity += {-3,0}
        }
    }
    
    if bool(states[SDL.Scancode.D]) {

        if (ppos[0] < BOUNDS[0]-2.1) {
            pbody.velocity += {3,0}
        }
    }
        
    if bool(states[SDL.Scancode.SPACE]) & !bool(prev_states[SDL.Scancode.SPACE]) {
        bhier := &archetypes[BALL0.tag].hierarchy.?[BALL0.idx]
        btran := &archetypes[BALL0.tag].transform.?[BALL0.idx]
        bbody := &archetypes[BALL0.tag].body.?[BALL0.idx].global

        if bhier.parent == PLAYER0 {
            bbody.velocity += pbody.velocity + {0,1}
            remove_hierarchy_child(archetypes, BALL0)
        } else {
            bbody.velocity = {0,0}

            add_hierarchy_parent_child(archetypes, PLAYER0, BALL0)
            btran.local = TRS({0,1}, 0, {0.75,0.75})
        }
    }
}

restrict_ball_movement :: proc(arch_player: ^Archetype) {
    nb_ball := len(arch_player.transform.?)
    bodies := &arch_player.body.?

    for iball in 0..<nb_ball{
        gbody := &bodies[iball].global

        if lg.vector_length(gbody.velocity) != 0 {
            gbody.velocity *= 3.5/lg.vector_length(gbody.velocity)                    
        }  
    }
}