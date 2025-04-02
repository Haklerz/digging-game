package common

import "core:math"
import "core:math/fixed"
import "core:math/rand"
import "core:thread"
import "core:sync"
import "core:time"
import "core:fmt"

MAX_LOADED_CHUNKS :: 32
CHUNK_SIZE : i32 : 16

Game_State :: struct {
    world_state: World_State,
    player: Entity, // The player will just be another one of the entities eventually.
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

Input_Command :: enum {
    UP,
    DOWN,
    LEFT,
    RIGHT,
    USE,
    CANCEL
}

Input_Commands :: bit_set[Input_Command]

Input_State :: struct {
    is_down: Input_Commands
}

Entity :: struct {
    id: uint,
    position: World_Position,
    input: Input_State,
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
    game_state_mutex: sync.Mutex,
    unsynced_ticks: sync.Sema,
    do_stop: bool,
}

get_chunk_index :: proc(world_state: ^World_State, position: Chunk_Position) -> (index: int, ok: bool) {
    for &chunk, i in world_state.chunks {
        if chunk.position == position do return i, true
    }

    return 0, false
}

load_chunk :: proc(world_state: ^World_State, chunk: Chunk_Position) {
    using world_state
    assert(chunk_count < MAX_LOADED_CHUNKS)

    chunks[chunk_count].position = chunk
    for &block in chunks[chunk_count].blocks {
        block = .VOID if rand.float32() < 0.4 else .CAVE_FLOOR
    }
    chunks[chunk_count].is_dirty = true

    chunk_count += 1
}

SPAWN_CHUNKS_RADIUS : i32 : 2

init_world_state :: proc(world_state: ^World_State) {
    // Load spawn chunks
    for y in -SPAWN_CHUNKS_RADIUS..=SPAWN_CHUNKS_RADIUS do for x in -SPAWN_CHUNKS_RADIUS..=SPAWN_CHUNKS_RADIUS {
        load_chunk(world_state, {x, y})
    }
}

DELTA_TIME :: 50 * time.Millisecond

simulation_thread_proc :: proc(state: ^Simulation_State) {
    using state

    init_world_state(&game_state.world_state)

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
            next_tick += DELTA_TIME
        }

        sync.lock(&game_state_mutex)
        update_game_state(tick_count, &game_state)
        sync.unlock(&game_state_mutex)

        sync.post(&unsynced_ticks)
    }
    fmt.println("[Tick", tick_count, "]: Stop requested.")
}

update_player :: proc(player: ^Entity) {
    delta_time_s := time.duration_seconds(DELTA_TIME) // TODO: No need to calculate this every tick.

    delta: [2]f64
    delta.x = f64(int(.RIGHT in player.input.is_down) - int(.LEFT in player.input.is_down))
    delta.y = f64(int(.DOWN in player.input.is_down) - int(.UP in player.input.is_down))

    // Normalize
    if delta.x * delta.x + delta.y * delta.y > 1 do delta /= math.SQRT_TWO

    delta *= 5.0 * delta_time_s

    delta_fixed: World_Position
    fixed.init_from_f64(&delta_fixed.x, delta.x)
    fixed.init_from_f64(&delta_fixed.y, delta.y)

    player.position.x = fixed.add(player.position.x, delta_fixed.x)
    player.position.y = fixed.add(player.position.y, delta_fixed.y)
}

// TODO: Will need to create a new copy of the game state, instead of modifying when rollback is implemented.
update_game_state :: proc(tick_count: u64, game_state: ^Game_State) {
    update_player(&game_state.player)
    {
        using game_state.world_state
        for &chunk in chunks[:chunk_count] {
            for y in 0..<CHUNK_SIZE do for x in 0..<CHUNK_SIZE {
                if rand.float32() > 0.00005 do continue
    
                block := chunk_get_block(&chunk, {x, y})
                #partial switch block {
                case .CAVE_FLOOR:
                    block = .VOID
                case .VOID:
                    block = .CAVE_FLOOR
                }
                chunk_set_block(&chunk, {x, y}, block)
            }
        }
    }
}