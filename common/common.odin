package common

import "core:math/fixed"

MAX_LOADED_CHUNKS :: 32
CHUNK_SIZE :: 16

Game_State :: struct {
    world_state: World_State
}

World_State :: struct {
    chunks: [MAX_LOADED_CHUNKS]Chunk,
    chunk_count: uint
}

World_Position :: distinct [2]fixed.Fixed32_32
Block_Position :: distinct [2]i32
Chunk_Position :: distinct [2]i32

Block_Type :: enum {
    VOID,
    CAVE_FLOOR,
    CAVE_WALL,
    IRON_ORE
}

Chunk :: struct {
    position: Chunk_Position,
    blocks: [CHUNK_SIZE * CHUNK_SIZE]Block_Type
}

chunk_get_block :: proc(chunk: ^Chunk, block: Block_Position) -> Block_Type {
    if block.x < 0 || block.x >= CHUNK_SIZE do return .VOID
    if block.y < 0 || block.y >= CHUNK_SIZE do return .VOID

    return chunk.blocks[CHUNK_SIZE * block.y + block.x]
}

chunk_set_block :: proc(chunk: ^Chunk, block: Block_Position, type: Block_Type) -> bool {
    if block.x < 0 || block.x >= CHUNK_SIZE do return false
    if block.y < 0 || block.y >= CHUNK_SIZE do return false

    chunk.blocks[CHUNK_SIZE * block.y + block.x] = type
    return true
}