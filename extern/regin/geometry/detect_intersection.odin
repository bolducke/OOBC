package geometry

detect_intersection_cube_aac :: proc(A, B : CubeAAC($T,$D)) -> bool {
    d := A.position - B.position;
    R := A.halfsize + B.halfsize

    return d.x < R.x && d.y < R.y
}

detect_intersection_sphere_c :: proc(A, B : SphereC($T,$D)) -> bool {
    sep := B.position - A.position
    d = A.radius + B.radius
    return d < (R * R)
}

detect_intersection :: proc{detect_intersection_cube_aac,
                            detect_intersection_sphere_c}