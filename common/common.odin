package common

MAX_LOADED_CHUNKS :: 32
CHUNK_SIZE :: 16

Game_State :: struct {
    chunks: [MAX_LOADED_CHUNKS]Chunk,
    chunk_count: uint
}

Block_Type :: enum {
    VOID,
    CAVE_FLOOR,
    CAVE_WALL,
    IRON_ORE
}

Chunk :: struct {
    position: [2]int,
    blocks: [CHUNK_SIZE * CHUNK_SIZE]Block_Type
}

chunk_get_block :: proc(chunk: ^Chunk, block: [2]int) -> Block_Type {
    if block.x < 0 || block.x >= CHUNK_SIZE do return .VOID
    if block.y < 0 || block.y >= CHUNK_SIZE do return .VOID

    return chunk.blocks[CHUNK_SIZE * block.y + block.x]
}

chunk_set_block :: proc(chunk: ^Chunk, block: [2]int, type: Block_Type) -> bool {
    if block.x < 0 || block.x >= CHUNK_SIZE do return false
    if block.y < 0 || block.y >= CHUNK_SIZE do return false

    chunk.blocks[CHUNK_SIZE * block.y + block.x] = type
	return true
}