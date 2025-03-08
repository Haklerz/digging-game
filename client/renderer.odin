package client

import "../common"
import rl "vendor:raylib"
import "core:math"

TILE_SIZE :: 8

Render_State :: struct {
    tile_atlas      : rl.Texture2D,

    chunks          : [common.MAX_LOADED_CHUNKS]Chunk_Renderer,
    chunk_count     : uint,

    entity_renderer : Entity_Renderer
}

render :: proc(render_state: ^Render_State) {
    using render_state

    // Render world
    for &chunk in chunks[:chunk_count] do render_chunk(&render_state.tile_atlas, &chunk)

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
    position: [2]int,
    tile_ids: [common.CHUNK_SIZE * common.CHUNK_SIZE]u8
}

// draw_tile :: proc(atlas: ^rl.Texture2D, index: int, pos: IVec2) {
//     rl.DrawTextureRec(atlas^, {TILE_SIZE * f32(index % 32), TILE_SIZE * f32(index / 32), TILE_SIZE, TILE_SIZE}, {f32(pos.x), f32(pos.y)}, rl.WHITE)
// }

render_chunk :: proc(tile_atlas: ^rl.Texture2D, chunk: ^Chunk_Renderer) { // TODO: Take in camera

    for tile_id, i in chunk.tile_ids {
        tile_position, texture_source: [2]int

        // TODO: Will need half a tile offset for dual grid tiles.
        tile_position.y, tile_position.x = math.divmod(i, common.CHUNK_SIZE) // Tile offset from chunk in tile-space
        tile_position += chunk.position * common.CHUNK_SIZE // Chunk offset in tile-space
        tile_position *= TILE_SIZE

        texture_source.y, texture_source.x = math.divmod(int(tile_id), 32)
        texture_source *= TILE_SIZE

        rl.DrawTextureRec(
            tile_atlas^,
            {f32(texture_source.x), f32(texture_source.y), TILE_SIZE, TILE_SIZE},
            {f32(tile_position.x), f32(tile_position.y)},
            rl.WHITE
        )
    }

    rl.DrawRectangleLines(
        TILE_SIZE * common.CHUNK_SIZE * i32(chunk.position.x), TILE_SIZE * common.CHUNK_SIZE * i32(chunk.position.y),
        TILE_SIZE * common.CHUNK_SIZE, TILE_SIZE * common.CHUNK_SIZE,
        {0, 255, 0, 63}
    )
}

Entity_Renderer :: struct {}