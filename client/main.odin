package client

import "../common"
import "core:fmt"
import sdl "vendor:sdl3"
import "core:thread"

WINDOW_TITLE        :: "Digging Game"

TARGET_SIZE         :: [2]i32{ 480, 270}
WINDOW_SIZE_INIT    :: [2]i32{ 480 * 2, 270 * 2}

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

Frame_Info :: struct {
    next_sample_time_ms: u64,
    sample_frame_count: uint,
    last_frame_time_ms: u64,
    current_fps: uint
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

main :: proc() {
    // Init
    if !sdl.Init({.VIDEO}) do return

    window: ^sdl.Window
    window_renderer: ^sdl.Renderer
    if !sdl.CreateWindowAndRenderer(WINDOW_TITLE, WINDOW_SIZE_INIT.x, WINDOW_SIZE_INIT.y, {.RESIZABLE}, &window, &window_renderer) do return
    defer sdl.DestroyWindow(window)
    defer sdl.DestroyRenderer(window_renderer)

    sdl.SetWindowMinimumSize(window, TARGET_SIZE.x, TARGET_SIZE.y)
    sdl.SetRenderVSync(window_renderer, 1)

    min_component :: proc(v: [2]i32) -> i32 {
        return min(v.x, v.y)
    }
    render_target_texture := sdl.CreateTexture(window_renderer, .RGBA8888, .STREAMING, TARGET_SIZE.x, TARGET_SIZE.y)
    sdl.SetTextureScaleMode(render_target_texture, .NEAREST)

    // Init render state
    render_state: Render_State
    render_state.world_renderer.tile_atlas = sdl.LoadBMP(ATLAS_PATH)

    input_state: Input_State

    // Start the simulation thread
    simulation_state := common.Simulation_State{}
    make_chunk(&simulation_state.game_state.world_state, {0, 0})
    sync_world_renderer(&render_state.world_renderer, &simulation_state.game_state.world_state)
    simulation_thread := thread.create_and_start_with_poly_data(&simulation_state, common.simulation_thread_proc)
    defer thread.destroy(simulation_thread)

    frame_info := Frame_Info{}
    event: sdl.Event
    main_loop: for {
        // TODO: Use core:time instead of sdl for timing
        current_time_ms := sdl.GetTicks()
        delta_time := f32(current_time_ms - frame_info.last_frame_time_ms) / 1000
        defer {
            frame_info.last_frame_time_ms = current_time_ms
            frame_info.sample_frame_count += 1
        }

        if current_time_ms > frame_info.next_sample_time_ms {
            frame_info.current_fps = frame_info.sample_frame_count

            fmt.println("FPS:", frame_info.current_fps)

            // TODO: This is unsafe. Needs mutex
            sync_world_renderer(&render_state.world_renderer, &simulation_state.game_state.world_state)

            frame_info.sample_frame_count = 0
            frame_info.next_sample_time_ms += 1000
        }

        handle_input :: proc(input_state: ^Input_State, key: sdl.KeyboardEvent) {
            command: Input_Commands
            #partial switch key.scancode {
            case .W, .UP:
                command = {.UP}
            case .A, .LEFT:
                command = {.LEFT}
            case .S, .DOWN:
                command = {.DOWN}
            case .D, .RIGHT:
                command = {.RIGHT}
            }

            if key.down {
                input_state.is_down += command
            }
            else {
                input_state.is_down -= command
            }
        }

        // Handle events
        for sdl.PollEvent(&event) {
            #partial switch event.type {
            
            case .KEY_DOWN, .KEY_UP:
                handle_input(&input_state, event.key)
            case .QUIT:
                break main_loop
            }
        }

        update_render_state(&render_state, &input_state, delta_time)

        // Draw to rendering target
        target_surface: ^sdl.Surface
        if sdl.LockTextureToSurface(render_target_texture, nil, &target_surface) {
            defer sdl.UnlockTexture(render_target_texture)

            sdl.ClearSurface(target_surface, 0, 0, 0, sdl.ALPHA_OPAQUE_FLOAT)
            render_world(target_surface, &render_state.world_renderer, &render_state.camera)

            // Draw crosshair
            sdl.WriteSurfacePixel(target_surface, TARGET_SIZE.x / 2, TARGET_SIZE.y / 2, 255,255,255,255)
        }

        // Calculate letterboxing
        window_size: [2]i32
        sdl.GetCurrentRenderOutputSize(window_renderer, &window_size.x, &window_size.y)
        scaled_target_size := min_component(window_size / TARGET_SIZE) * TARGET_SIZE
        target_position := (window_size - scaled_target_size) / 2

        // Draw rendering target to screen
        sdl.SetRenderDrawColor(window_renderer, 0x0c, 0x0c, 0x0c, sdl.ALPHA_OPAQUE)
        sdl.RenderClear(window_renderer)

        destination_rect := sdl.FRect{
            x = f32(target_position.x),
            y = f32(target_position.y),
            w = f32(scaled_target_size.x),
            h = f32(scaled_target_size.y)
        }
        sdl.RenderTexture(window_renderer, render_target_texture, nil, &destination_rect)
        sdl.RenderPresent(window_renderer)
    }

    simulation_state.do_stop = true
    thread.join(simulation_thread)
}