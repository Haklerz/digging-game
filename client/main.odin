package client

import rl "vendor:raylib"

WINDOW_TITLE		:: "Digging Game"

TARGET_SIZE			:: [2]i32{ 426, 240}
WINDOW_SIZE_INIT	:: [2]i32{1280, 720}

ATLAS_PATH			:: "res/atlas.png"

min_component :: #force_inline proc(v: [2]i32) -> i32 {
	return min(v.x, v.y)
}

main :: proc() {
	// Init window
	rl.SetConfigFlags({.VSYNC_HINT, .WINDOW_RESIZABLE})
	rl.InitWindow(WINDOW_SIZE_INIT.x, WINDOW_SIZE_INIT.y, WINDOW_TITLE)
	rl.SetWindowMinSize(TARGET_SIZE.x, TARGET_SIZE.y)

	// Just in case v-sync is forced off for some reason
	rl.SetTargetFPS(240)

	render_target := rl.LoadRenderTexture(TARGET_SIZE.x, TARGET_SIZE.y)

	// Init render state
	render_state: Render_State
	render_state.tile_atlas = rl.LoadTexture(ATLAS_PATH)

	// TODO: Start internal server

	for !rl.WindowShouldClose() {
		// TODO: Update stuff here

		// Calculate letterboxing
		window_size			:= [2]i32{rl.GetScreenWidth(), rl.GetScreenHeight()}
		scaled_target_size	:= min_component(window_size / TARGET_SIZE) * TARGET_SIZE
		target_position		:= (window_size - scaled_target_size) / 2

		// Draw to rendering target
		rl.BeginTextureMode(render_target)
			rl.ClearBackground({0, 0, 0, 255})
			render(&render_state)

		rl.EndTextureMode()

		// Draw rendering target to screen
		rl.BeginDrawing()
			rl.ClearBackground({0x0c, 0x0c, 0x0c, 0xff})
			rl.DrawFPS(1, 1)
			rl.DrawTexturePro(render_target.texture,
				{0, 0, f32(TARGET_SIZE.x), -f32(TARGET_SIZE.y)},
				{f32(target_position.x), f32(target_position.y), f32(scaled_target_size.x), f32(scaled_target_size.y)},
				{0, 0}, 0, rl.WHITE
			)
		rl.EndDrawing()
	}
	rl.CloseWindow()
}