package cm

import "core:fmt"

taylor :: proc(x: $T, v: T, dt: f32) -> T {
    return x + v * dt
}

integrate_explicit_euler_2D :: proc(body: ^Particle2D($T), dt: T) {
    acc := body.accumulated_force * body.material.imass
    angular_acc := body.accumulated_torque * body.material.iinertia

    vel := taylor(body.velocity, acc, dt)
    ang_vel := taylor(body.angular_velocity, angular_acc, dt)
    pos := taylor(body.position, body.velocity, dt)
    rot := taylor(body.rotation, body.angular_velocity, dt)

    body.velocity = vel
    body.angular_velocity = ang_vel
    body.position = pos
    body.rotation = rot
}

integrate_semiimplicit_euler_2D :: proc(body: ^Particle2D($T), dt: T) {
    acc := body.accumulated_force * body.material.imass
    angular_acc := body.accumulated_torque * body.material.iinertia

    vel := taylor(body.velocity, acc, dt)
    ang_vel := taylor(body.angular_velocity, angular_acc, dt)
    pos := taylor(body.position, vel, dt)
    rot := taylor(body.rotation, ang_vel, dt)

    body.velocity = vel
    body.angular_velocity = ang_vel
    body.position = pos
    body.rotation = rot
}

Derivative2D :: struct(T: typeid) {
    dx: [2]T,
    dr: T,
    dv: [2]T,
    dw: T,
}

rk4_compute_k :: proc(body: ^Particle2D($T), dt :f32, d: Derivative2D(T)) -> (out: Derivative2D(T)) {    
    x := body.position + d.dx * dt
    r := body.rotation + d.dr * dt

    v := body.velocity + d.dv * dt
    w := body.angular_velocity + d.dw * dt

    out = d
    out.dx = v
    out.dr = w

    return out
}

integrate_rk4_2D :: proc(body: ^Particle2D($T), dt: T) {

    init : Derivative2D(f32)

    init.dv = body.accumulated_force * body.material.imass
    init.dw = body.accumulated_torque * body.material.iinertia

    k1 := rk4_compute_k(body, 0, init)
    k2 := rk4_compute_k(body, 0.5 * dt, k1)
    k3 := rk4_compute_k(body, 0.5 * dt, k2)
    k4 := rk4_compute_k(body, dt, k3)

    dx := (k1.dx + 2 * (k2.dx + k3.dx) + k4.dx)/6.0
    dr := (k1.dr + 2 * (k2.dr + k3.dr) + k4.dr)/6.0

    dv := (k1.dv + 2 * (k2.dv + k3.dv) + k4.dv)/6.0
    dw := (k1.dw + 2 * (k2.dw + k3.dw) + k4.dw)/6.0

    body.position += dx * dt
    body.rotation += dr * dt
    body.velocity += dv * dt
    body.angular_velocity += dw * dt
}

integrate_explicit_euler :: proc{integrate_explicit_euler_2D}
integrate_semiimplicit_euler :: proc{integrate_semiimplicit_euler_2D}
integrate_rk4 :: proc{integrate_rk4_2D}