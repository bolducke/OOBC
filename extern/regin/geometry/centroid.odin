package geometry

centroid_cube_aac :: proc(structure : CubeAAC($D, $T)) -> [D]T {
   return structure.position
}

centroid_cube_aamm :: proc(structure: CubeAAMM($D,$T)) -> [D]T {
    return (structure.max - structure.min) * 0.5
}

centroid_sphere_c :: proc(structure: SphereC($D,$T) ) -> [D]T {
     return structure.position
}

centroid :: proc{centroid_cube_aac,
                 centroid_cube_aamm,
                 centroid_sphere_c,}