package common

import "core:math/fixed"
import "core:math/rand"
import "core:thread"
import "core:time"
import "core:fmt"

MAX_LOADED_CHUNKS :: 32
CHUNK_SIZE : i32 : 8

Game_State :: struct {
    world_state: World_State
}

World_State :: struct {
    chunks: [MAX_LOADED_CHUNKS]Chunk,
    chunk_count: uint,
}

World_Position :: distinct [2]fixed.Fixed32_32
Block_Position :: distinct [2]i32
Chunk_Position :: distinct [2]i32

Block_Type :: enum {
    VOID,
    CAVE_FLOOR,
    CAVE_WALL,
    IRON_ORE,
}

Chunk :: struct {
    position: Chunk_Position,
    blocks: [CHUNK_SIZE * CHUNK_SIZE]Block_Type,
    is_dirty: bool,
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
    chunk.is_dirty = true
    return true
}

Simulation_State :: struct {
    game_state: Game_State,
    do_stop: bool,
}

simulation_thread_proc :: proc(state: ^Simulation_State) {
    using state

    delta :: 50 * time.Millisecond

    start_time := time.now()
    next_tick := time.Duration(0)

    tick_count: u64

    for !do_stop {
        elapsed := time.since(start_time)
        if elapsed < next_tick {
            time.sleep(10 * time.Millisecond)
            continue
        }

        defer {
            tick_count += 1
            next_tick += delta
        }

        update_game_state(tick_count, &game_state)
    }
    fmt.println("[Tick", tick_count, "]: Stop requested.")
}

// TODO: Will need to create a new copy of the game state, instead of modifying when rollback is implemented.
update_game_state :: proc(tick_count: u64, game_state: ^Game_State) {
    using game_state.world_state
    for &chunk in chunks[:chunk_count] {
        if rand.float32() > 0.01 do continue

        for y in 0..<CHUNK_SIZE do for x in 0..<CHUNK_SIZE {
            if chunk_get_block(&chunk, {x, y}) == .CAVE_WALL do continue
            if rand.float32() > 0.01 do continue

            chunk_set_block(&chunk, {x, y}, .CAVE_WALL)
            chunk.is_dirty = true
            fmt.println("[Sim", tick_count, "]: Block at", x, y, "turned to Wall.")
        }
    }
}