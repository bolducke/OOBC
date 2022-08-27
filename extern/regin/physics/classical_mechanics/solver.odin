package cm

import lg "core:math/linalg"

import math "core:math"

import "core:fmt"

ContactPoint2D :: struct(T: typeid) {
    position : [2]T,
    normal : [2]T,
    depth_penetration: T,
}

resolve_interpenetration_2D :: proc(bodyA,bodyB : ^Particle2D($T),  contact_points: [dynamic]ContactPoint2D(T)) {
    adjust_positions_2D(bodyA,bodyB,contact_points)
    adjust_velocities_2D(bodyA,bodyB,contact_points)
}

adjust_positions_2D :: proc(bodyA,bodyB : ^Particle2D($T),  contact_points: [dynamic]ContactPoint2D(T)) {
    max_pene_cp : ContactPoint2D(T) = contact_points[0]
    max_pene := contact_points[0].depth_penetration

    for cp in contact_points[1:] {
        pene := cp.depth_penetration

        if pene > max_pene {
            max_pene = pene
            max_pene_cp = cp
        }
    }

    rA := max_pene_cp.position - bodyA.position
    rB := max_pene_cp.position - bodyB.position

    mass_eff := bodyA.imass + bodyB.imass
    j := max_pene / mass_eff

    impulse := j * max_pene_cp.normal

    apply_impulse_at_rel(bodyA,-impulse,rA)
    apply_impulse_at_rel(bodyB,impulse,rB)
}

adjust_velocities_2D :: proc(bodyA, bodyB: ^Particle2D($T),  contact_points: [dynamic]ContactPoint2D(T)) {
    for cp in contact_points {

        rA := cp.position - bodyA.position
        rB := cp.position - bodyB.position

        rel_vit_AB := -(bodyA.velocity + lg.cross([3]f32{0,0,bodyA.angular_velocity},[3]f32{rA.x,rA.y,0}).xy)
        rel_vit_AB += (bodyB.velocity + lg.cross([3]f32{0,0,bodyB.angular_velocity},[3]f32{rB.x,rB.y,0}).xy)

        real_vel_normal := lg.dot(rel_vit_AB,cp.normal)

        if real_vel_normal > 0{
            break;
        }

        rA_cross_normal := bodyA.iinertia * math.pow(lg.cross(rA,cp.normal),2)
        rB_cross_normal := bodyB.iinertia * math.pow(lg.cross(rB,cp.normal),2)

        mass_eff := bodyA.imass + bodyB.imass + rA_cross_normal + rB_cross_normal
        j := -(1 + min(bodyA.restitution, bodyB.restitution)) * real_vel_normal/mass_eff
        
        impulse := j * cp.normal

        apply_impulse_at_rel(bodyA,-impulse,rA)
        apply_impulse_at_rel(bodyB, impulse, rB)
    }
}

resolve_interpenetration :: proc{resolve_interpenetration_2D}