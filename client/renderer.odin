package client

import "../common"
import rl "vendor:raylib"

Render_State :: struct {
	tile_atlas		: rl.Texture2D,
	world_renderer	: World_Renderer,
	entity_renderer	: Entity_Renderer
}

render :: proc(render_state: ^Render_State) {

	// Render world
	{
		using render_state.world_renderer
		for &chunk in chunks[:chunk_count] do chunk_render(&chunk)
	}
}

World_Renderer :: struct {
	chunks: [common.MAX_LOADED_CHUNKS]Chunk_Renderer,
	chunk_count: uint
}

Chunk_Renderer :: struct {
	position: [2]int,
	tile_ids: [common.CHUNK_SIZE * common.CHUNK_SIZE]u8
}

chunk_render :: proc(chunk: ^Chunk_Renderer) {
	
	// TODO: Draw debug chunk outline
}

Entity_Renderer :: struct {}