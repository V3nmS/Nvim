-- ============================================================
-- markdown-hl: color para markdown, sin fondos ni iconos
-- ============================================================
-- Los títulos ya no los dibuja render-markdown (heading.enabled = false),
-- así que el `# Título` se ve tal cual y el color lo pone treesitter.
-- La paleta es la misma que ya tienes en colortheme.lua: onedark apagado,
-- no los colores de fábrica.

local M = {}

local c = {
	red = "#c27a7a",
	orange = "#b08b68",
	yellow = "#b8a06b",
	green = "#8b9f7a",
	cyan = "#7d9ea3",
	blue = "#7a94b8",
	purple = "#9b8cb5",
	fg = "#abb2bf",
	bright = "#d7dae0",
	dim = "#6f7680",
	code_bg = "#2b2f37",
}

function M.apply()
	local hl = function(group, opts)
		vim.api.nvim_set_hl(0, group, opts)
	end

	-- ------------------------------------------------------------
	-- Títulos: rampa cálido -> frío. El número de `#` te da el nivel,
	-- el color te lo confirma de un vistazo.
	-- ------------------------------------------------------------
	local levels = { c.red, c.orange, c.yellow, c.green, c.cyan, c.blue }
	for i, color in ipairs(levels) do
		hl("@markup.heading." .. i .. ".markdown", { fg = color, bold = true })
		-- Por si algún día vuelves a activar el render de headings.
		hl("RenderMarkdownH" .. i, { fg = color, bold = true })
		hl("RenderMarkdownH" .. i .. "Bg", { fg = color, bold = true })
	end

	-- Encabezado de tabla (treesitter lo captura como @markup.heading pelón).
	hl("@markup.heading.markdown", { fg = c.blue, bold = true })

	-- ------------------------------------------------------------
	-- Texto en línea
	-- ------------------------------------------------------------
	hl("@markup.strong", { fg = c.bright, bold = true })
	hl("@markup.italic", { fg = c.fg, italic = true })
	hl("@markup.strikethrough", { fg = c.dim, strikethrough = true })

	-- `código en línea`
	hl("@markup.raw.markdown_inline", { fg = c.orange })
	hl("RenderMarkdownCodeInline", { fg = c.orange, bg = c.code_bg })

	-- Bloques de código: fondo apenas visible sobre tu tema transparente.
	hl("RenderMarkdownCode", { bg = c.code_bg })
	hl("RenderMarkdownCodeBorder", { fg = c.code_bg, bg = c.code_bg })

	-- ------------------------------------------------------------
	-- Links: los [[wikilinks]] del vault caen en @markup.link.label
	-- ------------------------------------------------------------
	hl("@markup.link.label.markdown_inline", { fg = c.purple, underline = true })
	hl("@markup.link.url.markdown_inline", { fg = c.dim })
	hl("@markup.link.markdown_inline", { fg = c.purple })

	-- ------------------------------------------------------------
	-- Listas, citas, separadores
	-- ------------------------------------------------------------
	hl("@markup.list.markdown", { fg = c.cyan })
	hl("RenderMarkdownBullet", { fg = c.cyan })
	hl("@markup.list.unchecked.markdown", { fg = c.dim })
	hl("@markup.list.checked.markdown", { fg = c.green })
	hl("RenderMarkdownUnchecked", { fg = c.dim })
	hl("RenderMarkdownChecked", { fg = c.green })

	-- Estados extra del ciclo de obsidian.nvim: [ ] -> [~] -> [!] -> [>] -> [x]
	hl("RenderMarkdownTodo", { fg = c.yellow }) -- [~] en curso
	hl("RenderMarkdownImportant", { fg = c.red, bold = true }) -- [!] urgente
	hl("RenderMarkdownDeferred", { fg = c.blue }) -- [>] pospuesto

	hl("@markup.quote.markdown", { fg = c.dim, italic = true })
	hl("RenderMarkdownQuote", { fg = c.dim })
	hl("RenderMarkdownDash", { fg = c.dim })

	-- ------------------------------------------------------------
	-- LaTeX
	-- ------------------------------------------------------------
	-- Las fórmulas renderizadas son virtual text, no texto real del buffer.
	-- El morado es el único color de la paleta que no usa ningún otro
	-- elemento de markdown: de un vistazo distingues "esto lo dibujó el
	-- plugin" de "esto lo escribí yo".
	hl("RenderMarkdownMath", { fg = c.purple, italic = true })

	-- El `$...$` crudo (cuando el cursor entra y anti_conceal lo destapa)
	-- en un tono apagado, para que el fuente no compita con el render.
	hl("@markup.math", { fg = c.dim })

	-- ------------------------------------------------------------
	-- Tablas
	-- ------------------------------------------------------------
	hl("RenderMarkdownTableHead", { fg = c.blue })
	hl("RenderMarkdownTableRow", { fg = c.dim })
	hl("RenderMarkdownTableFill", { fg = c.dim })
end

-- Aplica ahora y vuelve a aplicar si cambias de colorscheme.
function M.setup()
	M.apply()
	vim.api.nvim_create_autocmd("ColorScheme", {
		group = vim.api.nvim_create_augroup("MarkdownHl", { clear = true }),
		callback = M.apply,
	})
end

return M
