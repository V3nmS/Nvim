-- ============================================================
-- Markdown: prosa con wrap, tablas sin cortar
-- ============================================================
-- `init.lua` deja `wrap = true` global y aquí se queda fijo, tablas incluidas:
-- md-table-wrap.nvim las dibuja ajustadas al ancho de la ventana, así que ya
-- no hace falta apagar el wrap al entrar a una. Para verla sola o editarla en
-- tarjetas, <leader>tz la abre en un flotante.

local tz = require("core.table-zoom")

-- Scroll horizontal columna a columna en vez de a saltos de media pantalla.
-- 'sidescroll' es global-only, no admite opt_local.
vim.o.sidescroll = 1
vim.opt_local.sidescrolloff = 6
vim.opt_local.wrap = true
vim.opt_local.linebreak = true
vim.opt_local.breakindent = true

-- ------------------------------------------------------------
-- Keymaps (solo en markdown)
-- ------------------------------------------------------------

local function map(lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { buffer = 0, silent = true, desc = desc })
end

map("<leader>tz", tz.zoom, "Tabla: verla sola en flotante (zoom)")
map("<leader>tf", tz.format, "Tabla: alinear pipes en el buffer")
