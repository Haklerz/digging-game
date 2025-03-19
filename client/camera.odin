package client

import "core:math"

Camera :: struct {
    position: [2]f32
}

camera_approach :: proc(camera: ^Camera, target: [2]f32, decay: f32, delta_time: f32) {
    camera.position = target + (camera.position - target) * math.exp(-decay * delta_time)
}

camera_get_render_offset :: proc(camera: ^Camera) -> [2]i32 {
    pos: [2]i32
    pos.x = i32(camera.position.x * TILE_SIZE)
    pos.y = i32(camera.position.y * TILE_SIZE)
    return TARGET_SIZE / 2 - pos
}