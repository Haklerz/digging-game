package digging_game

import "core:fmt"
import rl "vendor:raylib"

Camera :: struct {
    position: [2]i32
}

Game_State :: struct {
    loaded_chunks: map[u64]Chunk
    // Entities will go in here at some point.
}

Render_State :: struct {

}

Chunk_Renderer :: struct {
    tile_ids: [CHUNK_SIZE * CHUNK_SIZE]int
}

World_Renderer :: struct {
    chunks: map[u64]Chunk_Renderer
}





//////////// Rollback, Commands, and Netcode ////////////

Command_Type :: enum {
    MOVE_NORTH,
    MOVE_SOUTH,
    MOVE_EAST,
    MOVE_WEST
}

Command :: struct {
    tick: u32,
    type: Command_Type
}

Command_Buffer :: struct {
    buffer: []Command,
    start, end: u64
}

// The code needs to pull the commands from the command buffer every tick.
// If the commands happened on a previous tick then we need to roll back the gamestate to that tick and redo the application of the commands.

// We need to keep a circular buffer of gamestate "history"


/////////////////////////////////////////////////////////









// https://lospec.com/palette-list/lux2k

Block :: enum {
    VOID = 0,
    CAVE_FLOOR = 1,
    CAVE_WALL = 2
}

BLOCK_PROPERTIES :: [Block]bit_set[Block_Property] {
    .VOID = {.SOLID, .INDISTRUCTABLE},
    .CAVE_FLOOR = {},
    .CAVE_WALL = {.SOLID}
}

Block_Property :: enum {
    SOLID,
    INDISTRUCTABLE
}

// Side length of a chunk in number of blocks.
CHUNK_SIZE :: 16

// Side length of a tile.
TILE_SIZE :: 8

IVec2 :: [2]int

Chunk :: struct {
    pos: IVec2, // Position of chunk in chunk-space.
    blocks: [CHUNK_SIZE * CHUNK_SIZE]Block,
    is_dirty: bool
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

chunk_get_block :: proc(chunk: ^Chunk, block: IVec2) -> Block {
    return .VOID
}

// Used for querying blocks from a chunk and it's 8 neighbours.
Chunk_Neighbourhood :: struct {
    chunk: ^Chunk,
    neighbours: [Direction]^Chunk
}

chunk_neighbourhood_get_block :: proc(neighbourhood: ^Chunk_Neighbourhood, block: IVec2) -> Block {
    // TODO: Figure out which chunk we are in, and what block in that chunk.
    //       If a chunk is not loaded, return a VOID block.
    return .VOID
}

chunk_draw :: proc(neighbourhood: ^Chunk_Neighbourhood, camera: ^Camera) {

}

draw_chunk :: proc(atlas: ^rl.Texture2D, chunk: ^Chunk) {
    for y in 0..<CHUNK_SIZE do for x in 0..<CHUNK_SIZE {
        offset := IVec2{x, y}
        draw_tile(atlas, int(chunk.blocks[CHUNK_SIZE * y + x]), TILE_SIZE * (CHUNK_SIZE * chunk.pos + offset))
    }
}

draw_tile :: proc(atlas: ^rl.Texture2D, index: int, pos: IVec2) {
    rl.DrawTextureRec(atlas^, {TILE_SIZE * f32(index % 32), TILE_SIZE * f32(index / 32), TILE_SIZE, TILE_SIZE}, {f32(pos.x), f32(pos.y)}, rl.WHITE)
}

min_component :: proc(v: [2]i32) -> i32 {
    return min(v.x, v.y)
}


WINDOW_TITLE        :: "Digging Game"

TARGET_SIZE         :: [2]i32 {  426, 240 }
WINDOW_SIZE_INIT    :: [2]i32 { 1280, 720 }

ATLAS_PATH          :: "res/atlas.png"

init :: proc(game_state: ^Game_State) {
}

tick :: proc(game_state: ^Game_State, tick_count: u64, dt: f32) {
}

update :: proc(dt: f32, camera: ^Camera) {
    input_delta := [2]i32{
        i32(rl.IsKeyDown(rl.KeyboardKey.RIGHT)) - i32(rl.IsKeyDown(rl.KeyboardKey.LEFT)),
        i32(rl.IsKeyDown(rl.KeyboardKey.DOWN)) - i32(rl.IsKeyDown(rl.KeyboardKey.UP))
    }

    camera.position += input_delta
}

draw :: proc(atlas: ^rl.Texture2D, camera: Camera) {
}

main :: proc() {
    // Set up window.
    rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE})
    rl.InitWindow(WINDOW_SIZE_INIT.x, WINDOW_SIZE_INIT.y, WINDOW_TITLE)
    rl.SetWindowMinSize(TARGET_SIZE.x, TARGET_SIZE.y)
    rl.SetTargetFPS(120)

    atlas := rl.LoadTexture(ATLAS_PATH)
    target := rl.LoadRenderTexture(TARGET_SIZE.x, TARGET_SIZE.y)


    game_state: Game_State
    camera: Camera


    init(&game_state)

    TICK_INTERVAL :: 0.05
    next_tick_time: f64
    tick_count: u64

    for !rl.WindowShouldClose() {
        current_time := rl.GetTime()

        if current_time > next_tick_time {
            tick(&game_state, tick_count, TICK_INTERVAL)
            tick_count += 1
            next_tick_time = current_time + TICK_INTERVAL
        }

        update(rl.GetFrameTime(), &camera)

        window_size := [2]i32{rl.GetScreenWidth(), rl.GetScreenHeight()}
        scaled_target_size := min_component(window_size / TARGET_SIZE) * TARGET_SIZE
        target_pos := (window_size - scaled_target_size) / 2

        // Draw to target
        rl.BeginTextureMode(target)
            draw(&atlas, camera)
        rl.EndTextureMode()

        // Draw to screen
        rl.BeginDrawing()
            rl.ClearBackground({0x0c, 0x0c, 0x0c, 0xff})
            rl.DrawFPS(1, 1)
            rl.DrawTexturePro(target.texture,
                {0, 0, f32(TARGET_SIZE.x), -f32(TARGET_SIZE.y)},
                {f32(target_pos.x), f32(target_pos.y), f32(scaled_target_size.x), f32(scaled_target_size.y)},
                {0, 0}, 0, rl.WHITE
            )
        rl.EndDrawing()
    }
    rl.CloseWindow()
}