-- ============================================
-- Render in-buffer de markdown (estilo Live Preview de Obsidian)
-- ============================================
-- No hay split de preview a propósito: el buffer donde escribes ES el preview.
-- La línea del cursor se des-renderiza a markdown crudo (anti_conceal) para
-- que la puedas editar, el resto se queda dibujado.
--
-- Reparto de chamba:
--   render-markdown.nvim -> texto: headings, tablas, callouts, checkboxes, código
--   snacks.image         -> pixeles: imágenes del vault y fórmulas LaTeX (kitty)
return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		-- Mismos disparadores que obsidian.nvim: el render vive en autocmds de
		-- FileType, así que cargar en VeryLazy dejaría el primer buffer sin pintar.
		ft = { "markdown", "quarto" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			file_types = { "markdown", "quarto" },

			-- Modo híbrido: N líneas alrededor del cursor vuelven a crudo.
			-- 0/0 = solo la línea del cursor, igualito a Obsidian.
			anti_conceal = {
				enabled = true,
				above = 0,
				below = 0,
			},

			win_options = {
				-- `default` = lo que tenías antes de renderizar, se restaura al
				-- apagar el render con :RenderMarkdown toggle.
				conceallevel = { default = 0, rendered = 3 },
				concealcursor = { default = "", rendered = "" },
			},

			-- ============================================
			-- Headings
			-- ============================================
			heading = {
				sign = false, -- sin iconos en la signcolumn, ya van inline
				width = "block", -- el fondo llega hasta donde acaba el texto, no toda la ventana
				left_pad = 0,
				right_pad = 2,
				icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
			},

			-- ============================================
			-- Bloques de código
			-- ============================================
			code = {
				style = "full", -- lenguaje + fondo
				width = "block",
				left_pad = 2,
				right_pad = 2,
				border = "thick",
			},

			-- ============================================
			-- Listas y citas
			-- ============================================
			bullet = {
				icons = { "●", "○", "◆", "◇" },
			},

			quote = { icon = "▋" },

			dash = { icon = "─" },

			-- ============================================
			-- Checkboxes
			-- ============================================
			-- Espejo del `checkbox.order` de obsidian.lua:
			--   [ ] -> [~] -> [!] -> [>] -> [x]
			-- Si algún día cambias ese orden allá, cámbialo aquí también o los
			-- estados nuevos se quedan como texto pelón.
			checkbox = {
				enabled = true,
				unchecked = { icon = "󰄱 ", highlight = "RenderMarkdownUnchecked" },
				checked = { icon = "󰱒 ", highlight = "RenderMarkdownChecked" },
				custom = {
					wip = { raw = "[~]", rendered = "󰥔 ", highlight = "RenderMarkdownWarn" },
					urgente = { raw = "[!]", rendered = "󰀦 ", highlight = "RenderMarkdownError" },
					pospuesto = { raw = "[>]", rendered = "󰒭 ", highlight = "RenderMarkdownHint" },
				},
			},

			-- ============================================
			-- Tablas
			-- ============================================
			pipe_table = {
				style = "full",
				preset = "round",
				-- Alinea las celdas visualmente sin tocar el texto del archivo,
				-- así la nota sigue siendo markdown válido para Obsidian.
				cell = "padded",
			},

			-- ============================================
			-- Links
			-- ============================================
			link = {
				enabled = true,
				image = "󰥶 ",
				hyperlink = "󰌹 ",
				wiki = { icon = "󱗖 ", highlight = "RenderMarkdownWikiLink" },
			},

			-- ============================================
			-- LaTeX: apagado A PROPÓSITO
			-- ============================================
			-- El módulo `latex` de render-markdown traduce las fórmulas a unicode
			-- vía latex2text (se ve: ∫_0^∞ e^(-x²)dx = √(π)/2). snacks.image las
			-- compila con tectonic y las pinta como imagen de verdad. Si dejas los
			-- dos prendidos, se pelean por las mismas líneas y parpadea.
			latex = { enabled = false },

			-- Los callouts de Obsidian ([!note], [!warning], [!tip]...) vienen
			-- incluidos por default, no hay que declararlos.
		},
	},

	-- ============================================
	-- snacks.image: imágenes y fórmulas de verdad
	-- ============================================
	-- Pinta con el kitty graphics protocol. Requisitos ya cubiertos:
	--   kitty ✓   magick (ImageMagick 7) ✓   tectonic -> pacman -S tectonic
	--
	-- OJO CON TMUX: dentro de tmux el protocolo gráfico no pasa a menos que
	-- tengas `set -g allow-passthrough on` en el tmux.conf. Fuera de tmux jala solo.
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false, -- snacks se auto-lazifica por módulo, no hay que ayudarle
		opts = {
			image = {
				enabled = true,

				doc = {
					enabled = true,
					inline = true, -- la imagen se dibuja en su lugar dentro del texto
					float = true, -- fallback flotante si el terminal no puede inline
					max_width = 60,
					max_height = 30,
				},

				-- Fórmulas $...$ y $$...$$ compiladas con tectonic y convertidas
				-- a PNG con magick.
				math = {
					enabled = true,
					latex = {
						font_size = "Large",
						packages = { "amsmath", "amssymb", "amsfonts", "amscd", "mathtools" },
					},
				},
			},
		},
	},
}
