-- ============================================================
-- Markdown: prosa con wrap, tablas sin cortar
-- ============================================================
-- `init.lua` deja `wrap = true` global, que está bien para párrafos pero
-- parte las filas de tabla en dos y deja ese look "cortado". Aquí el wrap
-- se apaga solo mientras el cursor está dentro de una tabla, y se vuelve a
-- encender al salir. Para tablas que ni así caben, <leader>tz las abre
-- solas en un flotante.

local tz = require("core.table-zoom")

-- Scroll horizontal columna a columna en vez de a saltos de media pantalla.
-- 'sidescroll' es global-only, no admite opt_local.
vim.o.sidescroll = 1
vim.opt_local.sidescrolloff = 6
vim.opt_local.linebreak = true
vim.opt_local.breakindent = true

-- ------------------------------------------------------------
-- Wrap automático según contexto
-- ------------------------------------------------------------

if vim.g.md_table_autowrap == nil then
	vim.g.md_table_autowrap = true
end

local group = vim.api.nvim_create_augroup("MdTableWrap" .. vim.api.nvim_get_current_buf(), { clear = true })

local function sync_wrap()
	if not vim.g.md_table_autowrap then
		return
	end
	local want = not tz.cursor_in_table()
	if vim.wo.wrap ~= want then
		vim.wo.wrap = want
	end
end

vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufEnter" }, {
	group = group,
	buffer = 0,
	callback = sync_wrap,
})

-- ------------------------------------------------------------
-- Keymaps (solo en markdown)
-- ------------------------------------------------------------

local function map(lhs, rhs, desc)
	vim.keymap.set("n", lhs, rhs, { buffer = 0, silent = true, desc = desc })
end

map("<leader>tz", tz.zoom, "Tabla: verla sola en flotante (zoom)")
map("<leader>tf", tz.format, "Tabla: alinear pipes en el buffer")

map("<leader>tw", function()
	vim.g.md_table_autowrap = not vim.g.md_table_autowrap
	if vim.g.md_table_autowrap then
		sync_wrap()
		vim.notify("Wrap automático en tablas: ON")
	else
		-- Apagar el automático significa "quiero wrap siempre", tabla incluida.
		-- Sin esto, apagarlo estando parado en una fila dejaba wrap = false y el
		-- toggle parecía no hacer nada.
		vim.wo.wrap = true
		vim.notify("Wrap automático en tablas: OFF (wrap forzado a ON)")
	end
end, "Tabla: toggle wrap automático")

sync_wrap()
