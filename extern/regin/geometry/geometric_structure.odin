package geometry

import "core:intrinsics"

Geometric_Structure :: struct {
}

CubeAAMM :: struct($D : int, $T : typeid) where intrinsics.type_is_numeric(T), D > 0 {
    min: [D]T,
    max: [D]T,
}

CubeAAC :: struct($D : int, $T : typeid) where intrinsics.type_is_numeric(T), D > 0 {
    position: [D]T,
    halfsize: [D]T,
}

SphereC :: struct($D : int, $T : typeid) where intrinsics.type_is_numeric(T), D > 0 {
    position: [D]T,
    radius: T,
}