package client

import "../common"
import sdl "vendor:sdl3"
import "core:math"

ATLAS_SIZE_TILES :: 32
TILE_SIZE :: 8

Render_State :: struct {
    camera: Camera,
    world_renderer: World_Renderer
}

World_Renderer :: struct {
    tile_atlas: ^sdl.Surface,
    chunks: [common.MAX_LOADED_CHUNKS]Chunk_Renderer,
    chunk_count: uint,
}

update_render_state :: proc(render_state: ^Render_State, input_state: ^Input_State, delta_time: f32) {
    input_delta := [2]f32{
        f32(i32(.RIGHT in input_state.is_down) - i32(.LEFT in input_state.is_down)),
        f32(i32(.DOWN in input_state.is_down) - i32(.UP in input_state.is_down))
    }

    // Normalize
    if input_delta.x * input_delta.x + input_delta.y * input_delta.y > 1 do input_delta /= math.SQRT_TWO

    render_state.camera.position += input_delta * 10 * delta_time
}

render_world :: proc(target_surface: ^sdl.Surface, world_renderer: ^World_Renderer, camera: ^Camera) {
    using world_renderer
    for &chunk in chunks[:chunk_count] do render_chunk(target_surface, world_renderer.tile_atlas, &chunk, camera)
}

Neighbour_Direction :: enum {
    WEST,
    NORTH_WEST,
    NORTH,
}

// Used for querying blocks from a chunk and it's 8 neighbours.
Chunk_Neighbourhood :: struct {
    chunk: ^common.Chunk,
    neighbours: [Neighbour_Direction]^common.Chunk
}

chunk_neighbourhood_get_block :: proc(neighbourhood: Chunk_Neighbourhood, block: common.Block_Position) -> common.Block_Type {
    block := block

    chunk : ^common.Chunk
    if block.x < 0 && block.y < 0 {
        block += {common.CHUNK_SIZE, common.CHUNK_SIZE}
        chunk = neighbourhood.neighbours[.NORTH_WEST]
    }
    else if block.x < 0 {
        block += {common.CHUNK_SIZE, 0}
        chunk = neighbourhood.neighbours[.WEST]
    }
    else if block.y < 0 {
        block += {0, common.CHUNK_SIZE}
        chunk = neighbourhood.neighbours[.NORTH]
    }
    else {
        chunk = neighbourhood.chunk
    }

    if chunk == nil do return .VOID

    return common.chunk_get_block(chunk, block)
}

sync_world_renderer :: proc(world_renderer: ^World_Renderer, world_state: ^common.World_State) {
    world_renderer.chunk_count = world_state.chunk_count

    for &chunk, i in world_state.chunks[:world_state.chunk_count] {
        neighbourhood := Chunk_Neighbourhood{chunk = &chunk}

        neighbour_index, ok := common.get_chunk_index(world_state, chunk.position + {0, -1})
        if ok do neighbourhood.neighbours[.NORTH] = &world_state.chunks[neighbour_index]

        neighbour_index, ok = common.get_chunk_index(world_state, chunk.position + {-1, 0})
        if ok do neighbourhood.neighbours[.WEST] = &world_state.chunks[neighbour_index]

        neighbour_index, ok = common.get_chunk_index(world_state, chunk.position + {-1, -1})
        if ok do neighbourhood.neighbours[.NORTH_WEST] = &world_state.chunks[neighbour_index]

        if chunk.is_dirty {
            sync_chunk_renderer(&world_renderer.chunks[i], neighbourhood)
            chunk.is_dirty = false
        }
    }
}

sync_chunk_renderer :: proc(chunk_renderer: ^Chunk_Renderer, neighbourhood: Chunk_Neighbourhood) {
    chunk_renderer.position = neighbourhood.chunk.position

    // TODO: Figure out what tile to use in a sane way. This is stupid.
    tile_id_mapping := [16]u8{
        96, 99, 64, 65,
        00, 67, 98, 35,
        97, 32, 01, 66,
        03, 02, 33, 34,
    }

    for tile_y in 0..<common.CHUNK_SIZE do for tile_x in 0..<common.CHUNK_SIZE {
        tile_id := u8(chunk_neighbourhood_get_block(neighbourhood, {tile_x - 1, tile_y - 1}) != .VOID)
        tile_id |= u8(chunk_neighbourhood_get_block(neighbourhood, {tile_x - 0, tile_y - 1}) != .VOID) << 1
        tile_id |= u8(chunk_neighbourhood_get_block(neighbourhood, {tile_x - 1, tile_y - 0}) != .VOID) << 2
        tile_id |= u8(chunk_neighbourhood_get_block(neighbourhood, {tile_x - 0, tile_y - 0}) != .VOID) << 3

        chunk_renderer.tile_ids[common.CHUNK_SIZE * tile_y + tile_x] = tile_id_mapping[tile_id]
    }
}

Chunk_Renderer :: struct {
    position: common.Chunk_Position,
    tile_ids: [common.CHUNK_SIZE * common.CHUNK_SIZE]u8,
}

render_chunk :: proc(target_surface, tile_atlas: ^sdl.Surface, chunk: ^Chunk_Renderer, camera: ^Camera) {

    render_offset := camera_get_render_offset(camera)
    for tile_id, i in chunk.tile_ids {
        atlas_rect := sdl.Rect{w = TILE_SIZE, h = TILE_SIZE}
        atlas_rect.y, atlas_rect.x = math.divmod(i32(tile_id), ATLAS_SIZE_TILES)

        // Convert to pixel-space
        atlas_rect.x *= TILE_SIZE
        atlas_rect.y *= TILE_SIZE

        target_rect := sdl.Rect{w = TILE_SIZE, h = TILE_SIZE}
        target_rect.y, target_rect.x = math.divmod(i32(i), common.CHUNK_SIZE) // Offset within chunk
        target_rect.x += chunk.position.x * common.CHUNK_SIZE
        target_rect.y += chunk.position.y * common.CHUNK_SIZE

        // Convert to pixel-space
        target_rect.x *= TILE_SIZE
        target_rect.y *= TILE_SIZE
        target_rect.x -= TILE_SIZE / 2
        target_rect.y -= TILE_SIZE / 2

        // Offset based on camera
        target_rect.x += render_offset.x
        target_rect.y += render_offset.y

        sdl.BlitSurface(tile_atlas, atlas_rect, target_surface, target_rect)
    }

    sdl.WriteSurfacePixel(target_surface, chunk.position.x * common.CHUNK_SIZE * TILE_SIZE + render_offset.x, chunk.position.y * common.CHUNK_SIZE * TILE_SIZE + render_offset.y, 0, 255, 0, 255)
    sdl.WriteSurfacePixel(target_surface, (chunk.position.x + 1) * common.CHUNK_SIZE * TILE_SIZE + render_offset.x, chunk.position.y * common.CHUNK_SIZE * TILE_SIZE + render_offset.y, 0, 255, 0, 255)
    sdl.WriteSurfacePixel(target_surface, chunk.position.x * common.CHUNK_SIZE * TILE_SIZE + render_offset.x, (chunk.position.y + 1) * common.CHUNK_SIZE * TILE_SIZE + render_offset.y, 0, 255, 0, 255)
    sdl.WriteSurfacePixel(target_surface, (chunk.position.x + 1) * common.CHUNK_SIZE * TILE_SIZE + render_offset.x, (chunk.position.y + 1) * common.CHUNK_SIZE * TILE_SIZE + render_offset.y, 0, 255, 0, 255)
}