package client

import "../common"
import sdl "vendor:sdl3"
import "core:math"

ATLAS_SIZE_TILES :: 32
TILE_SIZE :: 8

Render_State :: struct {
    tile_atlas: ^sdl.Surface,

    world_renderer: World_Renderer
}

World_Renderer :: struct {
    chunks          : [common.MAX_LOADED_CHUNKS]Chunk_Renderer,
    chunk_count     : uint,
}

render :: proc(target_surface: ^sdl.Surface, render_state: ^Render_State) {
    // Render world
    {
        using render_state.world_renderer
        for &chunk in chunks[:chunk_count] do render_chunk(target_surface, render_state.tile_atlas, &chunk)
    }

    // TODO: Render entities
}

Neighbour_Direction :: enum {
    EAST,
    SOUTH_EAST,
    SOUTH,
    SOUTH_WEST,
    WEST,
    NORTH_WEST,
    NORTH,
    NORTH_EAST,
}

// Used for querying blocks from a chunk and it's 8 neighbours.
Chunk_Neighbourhood :: struct {
    chunk: ^common.Chunk,
    neighbours: [Neighbour_Direction]^common.Chunk
}

chunk_neighbourhood_get_block :: proc(neighbourhood: Chunk_Neighbourhood, block: common.Block_Position) -> common.Block_Type {
    // TODO: Figure out which chunk we are in, and what block in that chunk.
    //       If a chunk is not loaded, return a VOID block.
    return .VOID
}

// TODO: Rename to sync_world_renderer
sync_world_renderer :: proc(world_renderer: ^World_Renderer, world_state: ^common.World_State) {
    world_renderer.chunk_count = world_state.chunk_count

    for &chunk, i in world_state.chunks[:world_state.chunk_count] {
        sync_chunk_renderer(&world_renderer.chunks[i], {chunk = &chunk})
    }
}

sync_chunk_renderer :: proc(chunk_renderer: ^Chunk_Renderer, neighbourhood: Chunk_Neighbourhood) {
    chunk_renderer.position = neighbourhood.chunk.position

    // Just map blocks to tiles right now.
    // TODO: Will need to change when dual grid tiles are introduced.
    for block, i in neighbourhood.chunk.blocks {
        #partial switch block {
        case .CAVE_FLOOR:
            chunk_renderer.tile_ids[i] = 0

        case .CAVE_WALL:
            chunk_renderer.tile_ids[i] = 1

        case:
            chunk_renderer.tile_ids[i] = 69
        }
    }
}

Chunk_Renderer :: struct {
    position: common.Chunk_Position,
    tile_ids: [common.CHUNK_SIZE * common.CHUNK_SIZE]u8
}

render_chunk :: proc(target_surface, tile_atlas: ^sdl.Surface, chunk: ^Chunk_Renderer) { // TODO: Take in camera

    for tile_id, i in chunk.tile_ids {
        atlas_rect := sdl.Rect{w = TILE_SIZE, h = TILE_SIZE}
        atlas_rect.y, atlas_rect.x = math.divmod(i32(tile_id), ATLAS_SIZE_TILES)

        // Convert to pixel-space
        atlas_rect.x *= TILE_SIZE
        atlas_rect.y *= TILE_SIZE

        // TODO: Target will need half a tile offset for dual grid tiles
        target_rect := sdl.Rect{w = TILE_SIZE, h = TILE_SIZE}
        target_rect.y, target_rect.x = math.divmod(i32(i), common.CHUNK_SIZE) // Offset within chunk
        target_rect.x += chunk.position.x * common.CHUNK_SIZE
        target_rect.y += chunk.position.y * common.CHUNK_SIZE

        // Convert to pixel-space
        target_rect.x *= TILE_SIZE
        target_rect.y *= TILE_SIZE

        sdl.BlitSurface(tile_atlas, atlas_rect, target_surface, target_rect)
    }

    // TODO: Draw debug outline
}