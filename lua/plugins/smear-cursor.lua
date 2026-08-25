return {
	"sphamba/smear-cursor.nvim",
	event = "VeryLazy", -- carga después del arranque, no bloquea startup
	opts = {
		stiffness = 0.8,
		trailing_stiffness = 0.5,
		distance_stop_animating = 0.5,
		smear_between_buffers = true,
		smear_between_neighbor_lines = true,
		scroll_buffer_space = true,
		legacy_computing_symbols_support = false,
	},
}
