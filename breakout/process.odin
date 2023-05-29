package app

import time "core:time"
import fmt "core:fmt"
import json "core:encoding/json"
import lg "core:math/linalg"
import os "core:os"
import strings "core:strings"

import SDL "vendor:sdl2"
import IMG "vendor:sdl2/image"

import geom "../extern/regin/geometry"
import gcm "../extern/regin/physics/gcm"
import rg "../extern/regin"

Collision :: struct {
    eA: entity,
    eB: entity,
    ip: geom.IntersectionPoint(2,f32),
}

process_collision_detection :: proc(archetypes: []Archetype, collisions: ^[dynamic]Collision) {
    //Detect Collision between balls and the other archetype  
    iarchA := EntityTag.BALL
    archA := archetypes[iarchA]

    collidersA, has_colliderA := archA.collider.?
    transformsA, has_transformA := archA.transform.?

    for archB, iarchB in archetypes {

        if EntityTag(iarchB) != .BALL {

            collidersB, has_colliderB := archB.collider.?
            transformsB, has_transformB := archB.transform.?

            if has_colliderA && has_colliderB && has_transformA && has_transformB {

                for ieA in 0..<archA.count{

                    colliderA := collidersA[ieA]
                    transformA := transformsA[ieA]
                    
                    switch structA in &colliderA.structure {
                        case CCUBEAAC:
                            structA.position = ([2]f32)(rg.transform_position(transformA._global, rg.Vec2(structA.position)))
                            structA.halfsize = ([2]f32)((rg.Vec2(structA.halfsize) * rg.retrieve_scale(transformA._global)))
                    }

                    for ieB in 0..<archB.count {
                        colliderB := collidersB[ieB]
                        transformB := transformsB[ieB]


                        ip: geom.IntersectionPoint(2,f32)
                        intersected: bool

                        switch structA in &colliderA.structure {
                            case CCUBEAAC:
                                switch structB in &colliderB.structure {
                                    case CCUBEAAC:    
                                        structB.position = ([2]f32)(rg.transform_position(transformB._global, rg.Vec2(structB.position)))
                                        structB.halfsize = ([2]f32)(rg.Vec2(structB.halfsize) * rg.retrieve_scale(transformB._global))
                        
                                        ip, intersected = geom.mean_intersection_point(structA, structB)
                                }
                        }
                    
                        if intersected {
                            collision :Collision= {{EntityTag(iarchA),ieA},{EntityTag(iarchB),ieB},ip}

                            append(collisions, collision)
                        }    
                    }
                }
            }
        }
    }
}

process_collision_response :: proc(archetypes: []Archetype, collisions: []Collision, response: [][dynamic]gcm.Derivative2D(f32)) {

    for ir in 0..<len(response) {
        response[ir] = make([dynamic]gcm.Derivative2D(f32), archetypes[ir].count)
    }
    
    for collision in collisions {
        using collision

        bodiesA, has_bodyA := archetypes[eA.tag].body.?
        transformsA, has_transformA := archetypes[eA.tag].transform.?

        bodiesB, has_bodyB := archetypes[eB.tag].body.?
        transformsB, has_transformB := archetypes[eB.tag].transform.?

        if has_bodyA && has_bodyB && has_transformA && has_transformB {

            gbodyA := bodiesA[eA.idx].global
            gbodyB := bodiesB[eB.idx].global

            positionA := rg.retrieve_translation(transformsA[eA.idx]._global)
            positionB := rg.retrieve_translation(transformsB[eB.idx]._global)

            contact_points : [1]gcm.ContactPoint2D(f32) = { { rA= cast([2]f32)(positionA - rg.Vec2(ip.position)), rB= cast([2]f32)(positionB - rg.Vec2(ip.position)), normal=ip.normal, depth_penetration=ip.penetration} }
            derivatives := gcm.resolve_interpenetration(gbodyA, gbodyB, contact_points[:])

            for d in derivatives {
                response[eA.tag][eA.idx] = gcm.add(response[eA.tag][eA.idx], d[0])
                response[eB.tag][eB.idx] = gcm.add(response[eB.tag][eB.idx], d[1])
            }
        }
    }
}

process_physic_integration :: proc(archetypes: []Archetype, derivatives: [][dynamic]gcm.Derivative2D(f32)) {
    for arch, iarch in archetypes {
        bodies, has_body := arch.body.?
        
        derivatives[iarch] = make([dynamic]gcm.Derivative2D(f32), arch.count)

        if has_body {
            for ie in 0..<arch.count {

                gbody := &bodies[ie].global
    
                D := gcm.integrate_semiimplicit_euler(gbody^, DT)
                gbody.accumulator = gcm.EMPTY_ACCUMULATOR2D

                derivatives[iarch][ie] = D
            }
        }
    }
}

process_damage :: proc(archetypes: []Archetype, collisions: []Collision, damaged_entity: [][dynamic]int, killed_entity: [][dynamic]int) {

    for collision in collisions {
        using collision

        healthsA, has_healthA := archetypes[eA.tag].health.?
        damagesA, has_damageA := archetypes[eA.tag].damage.?    

        healthsB, has_healthB := archetypes[eB.tag].health.?
        damagesB, has_damageB := archetypes[eB.tag].damage.?

        if has_healthA && has_damageB && healthsA[eA.idx].hp > 0 {
            healthsA[eA.idx].hp -= damagesB[eB.idx].attack

            if damagesB[eB.idx].attack != 0 {
                append(&damaged_entity[eA.tag], eA.idx)
            }

            if healthsA[eA.idx].hp == 0 {
                append(&killed_entity[eA.tag], eA.idx)
            }
        }

        if has_healthB && has_damageA && healthsB[eB.idx].hp > 0 {
            healthsB[eB.idx].hp -= damagesA[eA.idx].attack

            if damagesA[eA.idx].attack != 0 {
                append(&damaged_entity[eB.tag], eB.idx)
            }

            if healthsB[eB.idx].hp == 0 {
                append(&killed_entity[eB.tag], eB.idx)
            }
        }
    }

    return
}

process_draw :: proc(renderer: ^SDL.Renderer, archetypes: []Archetype) {
    for arch, iarch in archetypes {
        when DEBUG {
            draw_outline_structure(renderer, arch)
        } else {
            draw_entities(renderer, arch, EntityTag(iarch))
        }
    }   
}