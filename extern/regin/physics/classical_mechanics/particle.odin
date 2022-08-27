package cm

import lag "core:math/linalg"

import regin "../.."

Particle2D :: struct(T: typeid) {
    using material: Material,

    position: [2]T,
    rotation: T,
    
    velocity: [2]T,
    angular_velocity: T,

    accumulated_force: [2]T,
    accumulated_torque: T,
}

apply_force_2D :: proc(body: ^Particle2D($T), force: [2]T) {
    body.accumulated_force += force
}

apply_torque_2D :: proc(body: ^Particle2D($T), torque: T){
    body.accumulated_torque += torque
}

apply_force_at_2D :: proc(body: ^Particle2D($T), force: [2]T, position: [2]T) {
    apply_torque(body, lag.cross(body.position - position,force).z)
    apply_force(body, force)
}

apply_impulse_at_rel_2D :: proc(body : ^Particle2D($T), impulse: [2]T, rel_pos: [2]T){
    body.velocity += body.material.imass * impulse
    body.angular_velocity += body.material.iinertia * lag.cross(rel_pos,impulse);
}

clear_accumulator_2D :: proc(body: ^Particle2D($T)) {
    body.accumulated_force = {0,0}
    body.accumulated_torque = 0
}

apply_force :: proc{apply_force_2D}
apply_torque :: proc{apply_torque_2D}
apply_force_at :: proc{apply_force_at_2D}
apply_impulse_at_rel :: proc{apply_impulse_at_rel_2D}
clear_accumulator :: proc{clear_accumulator_2D}