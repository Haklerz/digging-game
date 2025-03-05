package client

import "../common"
import rl "vendor:raylib"

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
    for &chunk in chunks[:chunk_count] do render_chunk(&chunk)

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

render_chunk :: proc(chunk: ^Chunk_Renderer) { // TODO: Take in camera
    // TODO: Draw debug chunk outline

    rl.DrawRectangleLines(
        TILE_SIZE * common.CHUNK_SIZE * i32(chunk.position.x), TILE_SIZE * common.CHUNK_SIZE * i32(chunk.position.y),
        TILE_SIZE * common.CHUNK_SIZE, TILE_SIZE * common.CHUNK_SIZE,
        rl.GREEN
    )
}

Entity_Renderer :: struct {}