package toolbox

Transform2D :: struct(T: typeid) {
    position: [2]T,
    rotation: T,
    scale: [2]T,
}

Transform3D :: struct(T: typeid) {
    position: [3]T,
    rotation: [3]T,
    scale: [3]T,
}