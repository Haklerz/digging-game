package client

import "../common"
import rl "vendor:raylib"

Render_State :: struct {
    tile_atlas      : rl.Texture2D,

    chunks          : [common.MAX_LOADED_CHUNKS]Chunk_Renderer,
    chunk_count     : uint,

    entity_renderer : Entity_Renderer
}

render :: proc(render_state: ^Render_State) {
    using render_state

    // Render world
    for &chunk in chunks[:chunk_count] do chunk_render(&chunk)

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

chunk_neighbourhood_get_block :: proc(neighbourhood: ^Chunk_Neighbourhood, block: [2]int) -> common.Block_Type {
    // TODO: Figure out which chunk we are in, and what block in that chunk.
    //       If a chunk is not loaded, return a VOID block.
    return .VOID
}

update_chunk_renderer :: proc(
    chunk_renderer: ^Chunk_Renderer,
    chunk_neighbourhood: ^Chunk_Neighbourhood
) {

}

Chunk_Renderer :: struct {
    position: [2]int,
    tile_ids: [common.CHUNK_SIZE * common.CHUNK_SIZE]u8
}

chunk_render :: proc(chunk: ^Chunk_Renderer) { // TODO: Take in camera
    // TODO: Draw debug chunk outline
}

Entity_Renderer :: struct {}