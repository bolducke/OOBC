package toolbox

import math "core:math"
import lg "core:math/linalg"

ATransform2D :: distinct lg.Matrix3f32
Vec2 :: lg.Vector2f32
Vec3 :: lg.Vector3f32

default_atransform2d :: proc() -> ATransform2D {
    return ATransform2D(1)
}

mul2D_2 :: proc(A1: ATransform2D, A2: ATransform2D) -> (ATransform2D) {
    return lg.mul(A1, A2)
}

mul2D_3 :: proc(A1: ATransform2D, A2: ATransform2D, A3: ATransform2D) -> (ATransform2D) {
    return lg.mul(lg.mul(A1, A2),A3)
}

mul2D_4 :: proc(A1: ATransform2D, A2: ATransform2D, A3: ATransform2D, A4: ATransform2D) -> (ATransform2D) {
    return lg.mul(lg.mul(lg.mul(A1, A2),A3),A4)
}

rotate2D :: proc(theta: f32) -> ATransform2D {
    return lg.matrix3_rotate(theta, Vec3{0,0,1})
}

scale2D :: proc(s: Vec2) -> ATransform2D {
    return ATransform2D{
        s[0],  0,    0,
        0,     s[1], 0,
        0,     0,    1
    }
}

translate2D :: proc(t: Vec2) -> ATransform2D {
    return ATransform2D{
        1,  0,  t[0],
        0,  1,  t[1],
        0,  0,  1
    }
}

inverse2D :: proc(atran: ATransform2D) -> ATransform2D {
    return lg.matrix3_inverse(atran)
}

transform_position :: proc(atran: ATransform2D, p: Vec2) -> Vec2 {
    return lg.mul(atran, Vec3{p.x,p.y,1}).xy
}

transform_direction :: proc(atran: ATransform2D, v: Vec2) -> Vec2 {
    return lg.mul(atran, Vec3{v.x,v.y,0}).xy
}

retrieve_translation2D :: proc(atran: ATransform2D) -> lg.Vector2f32 {
    return Vec2{atran[0,2], atran[1,2]}
}

retrieve_scale2D :: proc(atran: ATransform2D) -> lg.Vector2f32 {
    s : Vec2 = { lg.length( Vec2{atran[0,0],atran[1,0]} ), lg.length( Vec2{atran[0,1], atran[1,1]} ) }

    return s
}

retrieve_angle2D :: proc(atran: ATransform2D) -> f32 {
    s :Vec2 = { lg.length( Vec2{atran[0,0],atran[1,0]} ), lg.length( Vec2{atran[0,1], atran[1,1]} ) }

    angle := math.acos(atran[0,0]/s[0])

    return angle
}
 
decompose_affine_transform2D :: proc(atran: ATransform2D) -> (lg.Vector2f32, f32, lg.Vector2f32) {
    t :Vec2 = {atran[0,2], atran[1,2]}

    s :Vec2 = { lg.length( Vec2{atran[0,0],atran[1,0]} ), lg.length( Vec2{atran[0,1], atran[1,1]} ) }

    theta := math.acos(atran[0,0]/s[0])

    return t, theta, s
}

mul :: proc{mul2D_2, mul2D_3, mul2D_4}

rotate :: proc{rotate2D}
scale :: proc{scale2D}
translate :: proc{translate2D}

inverse :: proc{inverse2D}

retrieve_translation :: proc{retrieve_translation2D}
retrieve_scale :: proc{retrieve_scale2D}
retrieve_angle :: proc{retrieve_angle2D}
decompose_affine_transform :: proc{decompose_affine_transform2D}