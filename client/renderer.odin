package client

import "../common"
import sdl "vendor:sdl3"
import "core:math"

TILE_SIZE :: 8

Render_State :: struct {
    tile_atlas      : ^sdl.Surface,

    // TODO: Re-introduce World_Renderer
    chunks          : [common.MAX_LOADED_CHUNKS]Chunk_Renderer,
    chunk_count     : uint,

    entity_renderer : Entity_Renderer
}

render :: proc(target_surface: ^sdl.Surface, render_state: ^Render_State) {
    using render_state

    // Render world
    for &chunk in chunks[:chunk_count] do render_chunk(target_surface, render_state.tile_atlas, &chunk)

    // TODO: Render entities
}

Direction :: enum {
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
    neighbours: [Direction]^common.Chunk
}

chunk_neighbourhood_get_block :: proc(neighbourhood: Chunk_Neighbourhood, block: [2]int) -> common.Block_Type {
    // TODO: Figure out which chunk we are in, and what block in that chunk.
    //       If a chunk is not loaded, return a VOID block.
    return .VOID
}

update_world_renderer :: proc(
    render_state: ^Render_State,
    game_state: ^common.Game_State // TODO: Re-introduce World_State and World_Renderer structs for this.
) {
    render_state.chunk_count = game_state.chunk_count
    
    for &chunk, i in game_state.chunks[:game_state.chunk_count] {
        update_chunk_renderer(&render_state.chunks[i], {chunk = &chunk})
    }
}

update_chunk_renderer :: proc(
    chunk_renderer: ^Chunk_Renderer,
    neighbourhood: Chunk_Neighbourhood
) {
    chunk_renderer.position.x = i32(neighbourhood.chunk.position.x)
    chunk_renderer.position.y = i32(neighbourhood.chunk.position.y)

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
    position: [2]i32,
    tile_ids: [common.CHUNK_SIZE * common.CHUNK_SIZE]u8
}

render_chunk :: proc(target_surface, tile_atlas: ^sdl.Surface, chunk: ^Chunk_Renderer) { // TODO: Take in camera

    for tile_id, i in chunk.tile_ids {
        tile_position, texture_source: [2]i32

        // TODO: Will need half a tile offset for dual grid tiles.
        tile_position.y, tile_position.x = math.divmod(i32(i), i32(common.CHUNK_SIZE)) // Tile offset from chunk in tile-space
        tile_position += chunk.position * i32(common.CHUNK_SIZE) // Chunk offset in tile-space
        tile_position *= TILE_SIZE

        texture_source.y, texture_source.x = math.divmod(i32(tile_id), 32)
        texture_source *= TILE_SIZE

        sdl.BlitSurface(
            tile_atlas, {
                texture_source.x, texture_source.y,
                TILE_SIZE, TILE_SIZE
            },
            target_surface, {
                tile_position.x, tile_position.y,
                TILE_SIZE, TILE_SIZE
            }
        )
    }

    // TODO: Draw debug outline
}

Entity_Renderer :: struct {}