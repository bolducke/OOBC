package cm

import lg "core:math/linalg"

import math "core:math"

import "core:fmt"

ContactPoint2D :: struct(T: typeid) {
    rA: [2]T,
    rB: [2]T,
    normal : [2]T,
    depth_penetration: T,
}

resolve_interpenetration_2D :: proc(pA, pB : Particle2D($T),  contact_points: []ContactPoint2D(T)) -> (D: [2][2]Derivative2D(T)) {
    adjust_positions_2D(pA, pB, contact_points[:], &D[0])
    adjust_velocities_2D(pA, pB, contact_points[:], D[1:])

    return D
}

adjust_positions_2D :: proc(pA, pB : Particle2D($T),  contact_points: []ContactPoint2D(T), D: ^[2]Derivative2D(T)) {
    max_pene_cp : ContactPoint2D(T) = contact_points[0]
    max_pene := contact_points[0].depth_penetration

    for cp in contact_points[1:] {
        pene := cp.depth_penetration

        if pene > max_pene {
            max_pene = pene
            max_pene_cp = cp
        }
    }

    rA := max_pene_cp.rA
    rB := max_pene_cp.rB

    mass_eff := pA.material.imass + pB.material.imass
    j := max_pene / mass_eff

    impulse := j * max_pene_cp.normal

    D[0] = apply_impulse_at_rel(pA.material,-impulse,rA)
    D[1] = apply_impulse_at_rel(pB.material, impulse,rB)
}

adjust_velocities_2D :: proc(pA, pB: Particle2D($T),  contact_points: []ContactPoint2D(T), D: [][2]Derivative2D(T)) {
    for cp, icp in contact_points {
        rA := cp.rA
        rB := cp.rB

        rel_vit_AB := -(pA.velocity + lg.cross([3]f32{0,0,pA.angular_velocity},[3]f32{rA.x,rA.y,0}).xy)
        rel_vit_AB += (pB.velocity + lg.cross([3]f32{0,0,pB.angular_velocity},[3]f32{rB.x,rB.y,0}).xy)

        real_vel_normal := lg.dot(rel_vit_AB,cp.normal)

        if real_vel_normal > 0{
            break
        }

        rA_cross_normal := pA.material.iinertia * math.pow(lg.cross(cp.rA, cp.normal),2)
        rB_cross_normal := pB.material.iinertia * math.pow(lg.cross(cp.rB, cp.normal),2)

        mass_eff := pA.material.imass + pB.material.imass + rA_cross_normal + rB_cross_normal
        j := -(1 + min(pA.material.restitution, pB.material.restitution)) * real_vel_normal/mass_eff
        
        impulse := j * cp.normal

        D[icp][0] = apply_impulse_at_rel(pA.material,-impulse,rA)
        D[icp][1] = apply_impulse_at_rel(pB.material, impulse,rB)
    }
}

resolve_interpenetration :: proc{resolve_interpenetration_2D}