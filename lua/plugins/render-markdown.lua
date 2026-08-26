return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown" },
	dependencies = {
		"nvim-treesitter/nvim-treesitter",
		"nvim-tree/nvim-web-devicons",
	},
	---@module 'render-markdown'
	---@type render.md.UserConfig
	opts = {
		file_types = { "markdown" },

		-- Con el cursor encima de un elemento se ve el texto crudo, para editarlo.
		anti_conceal = { enabled = true },

		-- ============================================
		-- Tablas: lo que resuelve el problema
		-- ============================================
		-- El texto fuente puede tener los pipes desalineados; esto los dibuja
		-- alineados de todas formas, con bordes reales en vez de `|` y `---`.
		pipe_table = {
			enabled = true,
			preset = "round", -- esquinas ╭ ╮ ╰ ╯
			style = "full", -- dibuja también el borde exterior
			cell = "trimmed", -- recorta padding sobrante: la tabla ocupa lo mínimo
			padding = 1,
			alignment_indicator = "━", -- marca las columnas con :---: / ---:
			border_virtual = false,
		},

		-- Sin `latex2text` instalado esto solo tira warnings en :checkhealth.
		latex = { enabled = false },

		-- Encabezados sin fondo de bloque: menos ruido, se parece más a
		-- lo que ya veías. Cambia a `false` si quieres el look completo.
		heading = {
			enabled = true,
			width = "block",
			position = "inline",
		},

		code = {
			enabled = true,
			style = "full",
			width = "block",
			left_pad = 1,
			right_pad = 1,
		},
	},
}
