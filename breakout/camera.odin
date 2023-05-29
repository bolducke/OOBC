package app

import rg "../extern/regin"

ortho_matrix_sym_bounds :: proc(w, h: f32) -> rg.ATransform2D {
    return ortho_matrix(w, -w, h, -h)
}

ortho_matrix_bounds :: proc(r, l, t, b: f32) -> rg.ATransform2D {
    return rg.ATransform2D{
        2/(r-l), 0, -(r+l)/(r-l),
        0, 2/(t-b), -(t+b)/(t-b),
        0, 0, 1,
    }
}

ortho_matrix :: proc{ortho_matrix_sym_bounds, ortho_matrix_bounds}

viewport_matrix :: proc(nx, ny: i32) -> rg.ATransform2D {
    return rg.ATransform2D{
        f32(nx/2.0), 0, f32(nx-1)/(2.0),
        0, -f32(ny/2.0), f32(ny-1)/(2.0),
        0, 0, 1,
    }
}