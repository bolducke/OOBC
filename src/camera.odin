package app

import lg "core:math/linalg"

world_to_view_biased :: proc( w_pos: [2]$T, ratio_pixel_unit: int, width_screen, height_screen: int) -> [2]T {
    return [2]T{T(width_screen/2.0),T(height_screen)} + [2]T{1.0,-1.0} * (T(ratio_pixel_unit) * w_pos)
}