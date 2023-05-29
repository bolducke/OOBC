package cm

import "core:fmt"

Derivative2D :: struct(T: typeid) {
    dx: [2]T,
    dr: T,
    dv: [2]T,
    dw: T,
}

add :: proc(D0: Derivative2D($T), D1: Derivative2D(T)) -> Derivative2D(T) {
    return {
        dx = D0.dx + D1.dx,
        dr = D0.dr + D1.dr,
        dv = D0.dv + D1.dv,
        dw = D0.dw + D1.dw
    }
}

integrate_explicit_euler_2D :: proc(p: Particle2D($T), dt: f32) -> Derivative2D(T) {
    acc := p.accumulator.force * p.material.imass
    angular_acc := p.accumulator.torque * p.material.iinertia

    update := Derivative2D(T) {
        dv = p.accumulator.force * p.material.imass,
        dw = p.accumulator.torque * p.material.iinertia,
        dx = p.velocity * dt,
        dr = p.angular_acc * dt,
    }

    return update
}

integrate_semiimplicit_euler_2D :: proc(p: Particle2D($T), dt: f32) -> Derivative2D(T) {
    acc := p.accumulator.force * p.material.imass
    angular_acc := p.accumulator.torque * p.material.iinertia

    init := Derivative2D(T) {
        dv = p.accumulator.force * p.material.imass,
        dw = p.accumulator.torque * p.material.iinertia,
    }

    update := Derivative2D(T) {
        dv = init.dv,
        dw = init.dw,
        dx = (p.velocity + init.dv * dt) * dt,
        dr = (p.angular_velocity + init.dw * dt) * dt,
    }

    return update
}

rk4_compute_k :: proc(p: Particle2D($T), dt :f32, d: Derivative2D(T)) -> (out: Derivative2D(T)) {    
    //x := p.position + d.dx * dt
    //r := p.rotation + d.dr * dt

    v := p.velocity + d.dv * dt
    w := p.angular_velocity + d.dw * dt

    out = d
    out.dx = v
    out.dr = w

    return out
}

integrate_rk4_2D :: proc(p: Particle2D($T), dt: f32) -> Derivative2D(T) {

    init : Derivative2D(T)

    init.dv = p.accumulator.force * p.material.imass
    init.dw = p.accumulator.torque * p.material.iinertia

    k1 := rk4_compute_k(p, 0, init)
    k2 := rk4_compute_k(p, 0.5 * dt, k1)
    k3 := rk4_compute_k(p, 0.5 * dt, k2)
    k4 := rk4_compute_k(p, dt, k3)

    update :=Derivative2D(T){
        dx = ((k1.dx + 2 * (k2.dx + k3.dx) + k4.dx)/6.0) * dt,
        dr = ((k1.dr + 2 * (k2.dr + k3.dr) + k4.dr)/6.0) * dt,
        dv = ((k1.dv + 2 * (k2.dv + k3.dv) + k4.dv)/6.0) * dt,
        dw = ((k1.dw + 2 * (k2.dw + k3.dw) + k4.dw)/6.0) * dt,
    }

    return update
}

integrate_explicit_euler :: proc{integrate_explicit_euler_2D}
integrate_semiimplicit_euler :: proc{integrate_semiimplicit_euler_2D}
integrate_rk4 :: proc{integrate_rk4_2D}