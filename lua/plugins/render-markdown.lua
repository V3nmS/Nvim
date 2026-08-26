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
		-- Títulos: los `#` desaparecen, queda solo el color
		-- ============================================
		-- `icons` vacío + `position = "inline"` oculta el marcador `#` (y su
		-- espacio) sin meter nada en su lugar: el título arranca en la columna
		-- 0. Nada de iconos, fondos de bloque, bordes ni sign column.
		--
		-- Detalle de implementación: el plugin solo oculta los `#` si el icono
		-- NO es nil y hay al menos un grupo de highlight. Por eso `foregrounds`
		-- se queda con el default (RenderMarkdownH1..H6, que colorea
		-- core/markdown-hl.lua) mientras `backgrounds` va vacío.
		--
		-- Para volver a ver los `#`: `heading = { enabled = false }`.
		heading = {
			enabled = true,
			sign = false,
			icons = function()
				return ""
			end,
			position = "inline",
			backgrounds = {}, -- sin fondo de bloque
			border = false,
			width = "block",
			left_pad = 0,
			right_pad = 0,
		},

		-- ============================================
		-- Viñetas: `-` normal, con anidamiento distinguible
		-- ============================================
		-- Por defecto el plugin sustituye '-'|'+'|'*' por ● ○ ◆ ◇, todos
		-- puntotes. Aquí manda lo que escribiste:
		--
		--   '-'  ->  rampa por nivel de anidamiento:  -  ◦  ▫
		--   '*'  ->  siempre ◆   (marcador distinto a propósito)
		--   '+'  ->  siempre ▸
		--
		-- Así, si anidas todo con '-' igual distingues el nivel; y si cambias
		-- de marcador a mano, se respeta. Un solo carácter por icono, para no
		-- correr el texto.
		bullet = {
			enabled = true,
			icons = function(ctx)
				local marker = vim.trim(ctx.value)
				if marker == "*" then
					return "◆"
				elseif marker == "+" then
					return "▸"
				end
				local ramp = { "-", "◦", "▫" }
				return ramp[math.min(ctx.level, #ramp)]
			end,
		},

		-- ============================================
		-- Checkboxes: el ciclo completo de obsidian.nvim
		-- ============================================
		-- Tu `checkbox.order` es { " ", "~", "!", ">", "x" }. Los dos extremos
		-- ([ ] y [x]) están en la gramática de markdown; los tres de en medio
		-- no, así que van como `custom` (match contra el texto crudo).
		checkbox = {
			enabled = true,
			right_pad = 1,
			unchecked = { icon = "󰄱 ", highlight = "RenderMarkdownUnchecked" },
			checked = { icon = "󰱒 ", highlight = "RenderMarkdownChecked" },
			custom = {
				in_progress = { raw = "[~]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
				important = { raw = "[!]", rendered = "󰀦 ", highlight = "RenderMarkdownImportant" },
				deferred = { raw = "[>]", rendered = "󰅂 ", highlight = "RenderMarkdownDeferred" },
			},
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
