package cm

import lg "core:math/linalg"

Accumulator2D :: struct(T: typeid) {
    force: [2]T,
    torque: T,
}

EMPTY_ACCUMULATOR2D :: Accumulator2D(f32){}


Particle2D :: struct(T: typeid) {
    material: Material,
    
    velocity: [2]T,
    angular_velocity: T,

    accumulator: Accumulator2D(T),
}

apply_force_at_2D :: proc(accumulator: Accumulator2D($T), force: [2]T, rel_pos: [2]T) -> Accumulator2D(T) {
    accumulator.torque += lg.cross(rel_pos, force).z
    accumulator.force += force

    return accumulator
}

apply_impulse_at_rel_2D :: proc(material: Material, impulse: [2]$T, rel_pos: [2]T) -> Derivative2D(T) {
    D := Derivative2D(f32) {
        dv = material.imass * impulse,
        dw = material.iinertia * lg.cross(rel_pos, impulse),
    }
    return D
}

apply_force_at :: proc{apply_force_at_2D}
apply_impulse_at_rel :: proc{apply_impulse_at_rel_2D}