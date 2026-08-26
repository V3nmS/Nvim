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
		-- Tablas: lo que resuelve el problema original
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

		-- ============================================
		-- Títulos: sin iconos, sin fondo, sin sign column
		-- ============================================
		-- El `# Título` se ve tal cual y el color lo pone treesitter desde
		-- core/markdown-hl.lua (rampa rojo -> azul por nivel).
		--
		-- Si algún día quieres esconder los `#` pero conservar el color, sin
		-- volver a los bloques de fondo, cambia esto por:
		--   heading = {
		--     enabled = true, sign = false, icons = "", position = "overlay",
		--     backgrounds = {}, border = false, width = "block",
		--   }
		heading = { enabled = false },

		-- ============================================
		-- Viñetas: `-` de toda la vida, no los puntotes
		-- ============================================
		-- Por defecto el plugin sustituye '-'|'+'|'*' por ● ○ ◆ ◇. Con un
		-- string plano, cualquier marcador se dibuja como '-' en todos los
		-- niveles. Si quieres distinguir anidamiento: { "-", "◦", "·" }.
		bullet = {
			enabled = true,
			icons = "-",
		},

		-- Sin `latex2text` instalado esto solo tira warnings en :checkhealth.
		latex = { enabled = false },

		code = {
			enabled = true,
			style = "full",
			width = "block",
			left_pad = 1,
			right_pad = 1,
		},
	},

	config = function(_, opts)
		require("render-markdown").setup(opts)
		-- Va después del setup: el plugin define sus grupos de highlight al
		-- arrancar y aquí los pisamos con la paleta apagada de tu tema.
		require("core.markdown-hl").setup()
	end,
}
