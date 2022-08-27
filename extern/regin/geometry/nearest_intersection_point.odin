package geometry

import "core:intrinsics"

import "core:math"

import lag "core:math/linalg"

IntersectionPoint :: struct($D: int, $T: typeid) where intrinsics.type_is_numeric(T), D > 0 {
    position: [D]T,
    normal: [D]T,
    penetration: T,
}

nearest_intersection_point_cube_aac :: proc(A,B : CubeAAC($D, $T)) -> (ip: IntersectionPoint(D, T), ok: bool) where D == 2 #optional_ok {
    vec :: [D]T

    mid_a := centroid(A)
    mid_b := centroid(B)

    eA := A.halfsize
    eB := B.halfsize

    d := mid_b - mid_a

    dx := eA.x + eB.x - abs(d.x)
    if dx < 0 do return ip, false
    dy := eA.y + eB.y - abs(d.y)
    if dy < 0 do return ip, false

    ip.position = mid_a

    if dx < dy {
        ip.penetration = dx
        
        if d.x < 0 {
            ip.normal = vec{-1,0}
            ip.position -= vec{eA.x,0} // TODO: seems wrong. Will be at vertices and not mid edge
        } else {
            ip.normal = vec{1,0}
            ip.position += vec{eA.x, 0}
        }
    } else {
        ip.penetration = dy

        if d.y < 0 {
            ip.normal = vec{0,-1}
            ip.position -= vec{0,eA.y}
        } else {
            ip.normal = vec{0,1}
            ip.position += vec{0,eA.y}
        }
    }

    return ip, true
}

nearest_intersection_point_sphere_c :: proc(A,B : SphereC($D, $T)) -> (ip: IntersectionPoint(D, T), ok: bool) #optional_ok {
    vec :: [D]T

    separator := B.position - A.position
    d2 := lag.dot(separator,separator)
    R := A.radius + B.radius

    if d2 < R*R {
        norm := math.sqrt(d2)

        ip.normal = separator * (1.0 / norm) if norm != 0 else vec{}
        ip.penetration = R - norm
        ip.position = B.position - (B.radius * normal) 

        return ip, true
    }

    return ip, false
}

nearest_intersection_point :: proc{nearest_intersection_point_cube_aac, 
                                   nearest_intersection_point_sphere_c}