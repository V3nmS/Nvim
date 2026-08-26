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

		-- ============================================
		-- LaTeX: fórmulas renderizadas dentro del buffer
		-- ============================================
		-- El plugin NO compila TeX. Manda el contenido de `$...$` / `$$...$$`
		-- por stdin a un binario externo y pinta la salida como virtual lines.
		-- Por eso no necesitas texlive ni un visor aparte.
		--
		-- `converter` es una lista y se prueba en orden hasta el primer éxito:
		--   utftex     -> arte 2D de verdad (barras de fracción, ∫ grandes,
		--                 matrices). Viene de libtexprintf (AUR).
		--   latex2text -> fallback lineal, de python-pylatexenc (extra).
		--
		-- Si ninguno está instalado el handler se rinde en silencio y el
		-- markdown se sigue viendo igual; `:checkhealth render-markdown` lo dice.
		--
		-- El resultado se cachea por fórmula, así que reabrir la nota no
		-- vuelve a lanzar el proceso.
		latex = {
			enabled = true,
			converter = { "utftex", "latex2text" },
			inline = true, -- $x^2$ en medio del párrafo
			block = true, -- $$ ... $$ en su propio bloque
			highlight = "RenderMarkdownMath",

			-- `center` = la fórmula de una línea sustituye al texto crudo en su
			-- sitio; los bloques multilínea no caben centrados y el plugin cae
			-- solo a `above`. Es lo que quieres para notas: inline discreto,
			-- bloques dibujados encima del fuente.
			position = "center",

			-- OJO: dejar los pads en 0. El padding se mete en la salida ANTES
			-- de decidir el centro, así que con pad > 0 una fórmula inline
			-- también te abre líneas virtuales en blanco alrededor.
			top_pad = 0,
			bottom_pad = 0,
		},

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
