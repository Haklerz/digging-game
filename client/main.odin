package client

import "../common"
import "core:fmt"
import sdl "vendor:sdl3"

WINDOW_TITLE        :: "Digging Game"

TARGET_SIZE         :: [2]i32{ 320, 240}
WINDOW_SIZE_INIT    :: [2]i32{ 320 * 2, 240 * 2}

ATLAS_PATH          :: "res/atlas.bmp"

make_chunk :: proc(world_state: ^common.World_State, chunk: common.Chunk_Position) {
    using world_state
    assert(chunk_count < common.MAX_LOADED_CHUNKS)

    chunks[chunk_count].position = chunk
    for &block in chunks[chunk_count].blocks {
        block = .CAVE_WALL if sdl.rand(5) == 0 else .CAVE_FLOOR
    }

    chunk_count += 1
}

Framerate_Info :: struct {
    next_sample_time_ms: u64,
    sample_frame_count: uint
}

main :: proc() {
    // Init
    if !sdl.Init({.VIDEO}) do return

    window: ^sdl.Window
    renderer: ^sdl.Renderer
    if !sdl.CreateWindowAndRenderer(WINDOW_TITLE, WINDOW_SIZE_INIT.x, WINDOW_SIZE_INIT.y, {.RESIZABLE}, &window, &renderer) do return
    defer sdl.DestroyWindow(window)
    defer sdl.DestroyRenderer(renderer)

    sdl.SetWindowMinimumSize(window, TARGET_SIZE.x, TARGET_SIZE.y)
    sdl.SetRenderVSync(renderer, 1)
    
    min_component :: proc(v: [2]i32) -> i32 {
        return min(v.x, v.y)
    }
    render_target := sdl.CreateTexture(renderer, .RGBA8888, .STREAMING, TARGET_SIZE.x, TARGET_SIZE.y) // TODO: Rename this
    sdl.SetTextureScaleMode(render_target, .NEAREST)

    // Init render state
    render_state: Render_State
    render_state.tile_atlas = sdl.LoadBMP(ATLAS_PATH)

    // Make temporary game state
    game_state := common.Game_State{}
    make_chunk(&game_state.world_state, {0, 0})
    make_chunk(&game_state.world_state, {1, 1})
    make_chunk(&game_state.world_state, {2, 1})

    sync_world_renderer(&render_state.world_renderer, &game_state.world_state)

    framerate_info := Framerate_Info{}

    // TODO: Start internal server

    event: sdl.Event
    main_loop: for {
        current_time_ms := sdl.GetTicks()
        defer framerate_info.sample_frame_count += 1
        if current_time_ms > framerate_info.next_sample_time_ms {
            fmt.println("FPS:", framerate_info.sample_frame_count)

            framerate_info.sample_frame_count = 0
            framerate_info.next_sample_time_ms += 1000
        }

        // Handle events
        for sdl.PollEvent(&event) {
            #partial switch event.type {
            case .QUIT:
                break main_loop
            }
        }

        // TODO: Update stuff here

        // Draw to rendering target
        target_surface: ^sdl.Surface
        if sdl.LockTextureToSurface(render_target, nil, &target_surface) {
            defer sdl.UnlockTexture(render_target)

            sdl.ClearSurface(target_surface, 0, 0, 0, sdl.ALPHA_OPAQUE_FLOAT)
            render(target_surface, &render_state)
        }

        // Calculate letterboxing
        window_size: [2]i32
        sdl.GetCurrentRenderOutputSize(renderer, &window_size.x, &window_size.y)
        scaled_target_size := min_component(window_size / TARGET_SIZE) * TARGET_SIZE
        target_position := (window_size - scaled_target_size) / 2

        // Draw rendering target to screen
        sdl.SetRenderDrawColor(renderer, 0x0c, 0x0c, 0x0c, sdl.ALPHA_OPAQUE)
        sdl.RenderClear(renderer)

        // TODO: Render FPS

        destination_rect := sdl.FRect{
            x = f32(target_position.x),
            y = f32(target_position.y),
            w = f32(scaled_target_size.x),
            h = f32(scaled_target_size.y)
        }
        sdl.RenderTexture(renderer, render_target, nil, &destination_rect)
        sdl.RenderPresent(renderer)
    }
}