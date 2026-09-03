-- ============================================================
-- table-zoom: visor y formateador de tablas markdown
-- ============================================================
-- El terminal no puede cambiar el tamaño de fuente por ventana, así que
-- "hacer zoom a la tabla" aquí significa: sacarla del buffer y mostrarla
-- sola, en un flotante casi de pantalla completa, sin wrap y con scroll
-- horizontal. Si aun así no cabe, el modo "tarjetas" la rompe en bloques
-- verticales (una fila = un bloque `Header: valor`), que sí cabe siempre.
--
-- API:
--   require("core.table-zoom").zoom()    -> abre el flotante
--   require("core.table-zoom").format()  -> alinea la tabla en el buffer real

local M = {}

local state = {
	win = nil,
	buf = nil,
	mode = "grid",
	tbl = nil,
	-- De dónde salió la tabla, para poder escribirla de vuelta.
	src_buf = nil,
	src_s = nil,
	src_e = nil,
	indent = "",
	-- Snapshot de lo último dibujado, para saber si hay ediciones sin guardar.
	rendered = nil,
}

-- Ancho en celdas de pantalla, no en bytes: cuenta bien acentos, CJK y emoji.
local function dw(s)
	return vim.fn.strdisplaywidth(s)
end

local function pad(s, w, align)
	local d = w - dw(s)
	if d <= 0 then
		return s
	end
	if align == "right" then
		return string.rep(" ", d) .. s
	elseif align == "center" then
		local l = math.floor(d / 2)
		return string.rep(" ", l) .. s .. string.rep(" ", d - l)
	end
	return s .. string.rep(" ", d)
end

-- ------------------------------------------------------------
-- Parseo
-- ------------------------------------------------------------

local function is_table_line(line)
	return line ~= nil and line:match("^%s*|") ~= nil
end

-- Parte una fila en celdas respetando `\|` escapado.
local function split_row(line)
	local body = vim.trim(line)
	local cells, cur = {}, {}
	local i, n = 1, #body

	while i <= n do
		local c = body:sub(i, i)
		if c == "\\" and i < n then
			cur[#cur + 1] = body:sub(i, i + 1)
			i = i + 2
		elseif c == "|" then
			cells[#cells + 1] = table.concat(cur)
			cur = {}
			i = i + 1
		else
			cur[#cur + 1] = c
			i = i + 1
		end
	end
	cells[#cells + 1] = table.concat(cur)

	-- Una fila `| a | b |` deja vacíos el primer y el último elemento.
	if #cells > 0 and vim.trim(cells[1]) == "" then
		table.remove(cells, 1)
	end
	if #cells > 0 and vim.trim(cells[#cells]) == "" then
		table.remove(cells)
	end
	for k, v in ipairs(cells) do
		cells[k] = vim.trim(v)
	end
	return cells
end

-- Fila separadora: `|---|:--:|---:|`
local function is_delimiter(cells)
	if #cells == 0 then
		return false
	end
	for _, c in ipairs(cells) do
		if not c:match("^:?%-%-*:?$") then
			return false
		end
	end
	return true
end

local function alignment_of(cells)
	local aligns = {}
	for i, c in ipairs(cells) do
		local l, r = c:sub(1, 1) == ":", c:sub(-1) == ":"
		aligns[i] = (l and r and "center") or (r and "right") or "left"
	end
	return aligns
end

-- Encuentra los límites de la tabla que contiene a `lnum` (1-indexed).
local function table_range(buf, lnum)
	local total = vim.api.nvim_buf_line_count(buf)
	local function line_at(l)
		if l < 1 or l > total then
			return nil
		end
		return vim.api.nvim_buf_get_lines(buf, l - 1, l, false)[1]
	end

	if not is_table_line(line_at(lnum)) then
		return nil
	end

	local s, e = lnum, lnum
	while s > 1 and is_table_line(line_at(s - 1)) do
		s = s - 1
	end
	while e < total and is_table_line(line_at(e + 1)) do
		e = e + 1
	end
	return s, e
end

-- Devuelve { header = {...}, rows = {{...}}, aligns = {...}, ncols = n }
local function parse_table(lines)
	local rows, aligns, header = {}, nil, nil

	for _, line in ipairs(lines) do
		local cells = split_row(line)
		if is_delimiter(cells) then
			aligns = alignment_of(cells)
			if header == nil and #rows > 0 then
				header = table.remove(rows, #rows)
			end
		else
			rows[#rows + 1] = cells
		end
	end

	-- Sin separadora, la primera fila hace de header igual.
	if header == nil and #rows > 0 then
		header = table.remove(rows, 1)
	end
	if header == nil then
		return nil
	end

	local ncols = #header
	for _, r in ipairs(rows) do
		ncols = math.max(ncols, #r)
	end

	-- Rellena filas cortas para que la rejilla sea rectangular.
	local function fill(r)
		for i = 1, ncols do
			r[i] = r[i] or ""
		end
		return r
	end
	fill(header)
	for _, r in ipairs(rows) do
		fill(r)
	end

	aligns = aligns or {}
	for i = 1, ncols do
		aligns[i] = aligns[i] or "left"
	end

	return { header = header, rows = rows, aligns = aligns, ncols = ncols }
end

local function col_widths(tbl)
	local w = {}
	for i = 1, tbl.ncols do
		w[i] = dw(tbl.header[i])
	end
	for _, r in ipairs(tbl.rows) do
		for i = 1, tbl.ncols do
			w[i] = math.max(w[i], dw(r[i]))
		end
	end
	return w
end

-- ------------------------------------------------------------
-- Render: modo rejilla (box-drawing, sin wrap, scroll horizontal)
-- ------------------------------------------------------------

local function render_grid(tbl)
	local w = col_widths(tbl)
	local out = {}

	local function rule(left, mid, right)
		local parts = {}
		for i = 1, tbl.ncols do
			parts[i] = string.rep("─", w[i] + 2)
		end
		return left .. table.concat(parts, mid) .. right
	end

	local function row(cells, aligned)
		local parts = {}
		for i = 1, tbl.ncols do
			local a = aligned and tbl.aligns[i] or "left"
			parts[i] = " " .. pad(cells[i], w[i], a) .. " "
		end
		return "│" .. table.concat(parts, "│") .. "│"
	end

	out[#out + 1] = rule("╭", "┬", "╮")
	out[#out + 1] = row(tbl.header, false)
	out[#out + 1] = rule("├", "┼", "┤")
	for _, r in ipairs(tbl.rows) do
		out[#out + 1] = row(r, true)
	end
	out[#out + 1] = rule("╰", "┴", "╯")

	return out
end

-- ------------------------------------------------------------
-- Render: modo tarjetas (una fila = un bloque, siempre cabe)
-- ------------------------------------------------------------

local function wrap_text(s, width)
	if width < 8 then
		width = 8
	end
	local out, line = {}, ""
	for word in s:gmatch("%S+") do
		if line == "" then
			line = word
		elseif dw(line) + 1 + dw(word) <= width then
			line = line .. " " .. word
		else
			out[#out + 1] = line
			line = word
		end
	end
	if line ~= "" then
		out[#out + 1] = line
	end
	if #out == 0 then
		out[1] = ""
	end
	return out
end

local function render_cards(tbl, width)
	local label_w = 0
	for i = 1, tbl.ncols do
		label_w = math.max(label_w, dw(tbl.header[i]))
	end
	local text_w = math.max(width - label_w - 4, 20)
	local out = {}

	for n, r in ipairs(tbl.rows) do
		local title = " " .. n .. " "
		local dashes = math.max(width - dw(title) - 2, 3)
		out[#out + 1] = "──" .. title .. string.rep("─", dashes - 1)

		for i = 1, tbl.ncols do
			local wrapped = wrap_text(r[i], text_w)
			for k, chunk in ipairs(wrapped) do
				local label = (k == 1) and pad(tbl.header[i], label_w, "left") or string.rep(" ", label_w)
				out[#out + 1] = label .. " │ " .. chunk
			end
		end
		out[#out + 1] = ""
	end

	if #out > 0 and out[#out] == "" then
		table.remove(out)
	end
	return out
end

-- ------------------------------------------------------------
-- Parseo inverso: tarjetas editadas -> filas
-- ------------------------------------------------------------
-- El render de tarjetas es `Header │ texto`, con la etiqueta en blanco en las
-- líneas de continuación. Aquí se deshace: una tarjeta empieza en su regla
-- `── n ─────`, cada etiqueta conocida abre un campo, y toda línea con la
-- etiqueta vacía se pega al campo abierto con un espacio.
--
-- Limitación consciente: una celda que contenga `│` literal no sobrevive el
-- viaje de ida y vuelta. Es el único carácter prohibido dentro de una celda.

local function parse_cards(lines, header, ncols)
	local by_label = {}
	for i, h in ipairs(header) do
		by_label[vim.trim(h)] = i
	end

	local rows, cur, cur_idx = {}, nil, nil

	local function flush()
		if cur then
			-- Una tarjeta totalmente vacía se descarta: es una fila borrada.
			local any = false
			for i = 1, ncols do
				if cur[i] ~= "" then
					any = true
					break
				end
			end
			if any then
				rows[#rows + 1] = cur
			end
		end
		cur, cur_idx = nil, nil
	end

	for _, line in ipairs(lines) do
		if line:match("^%s*──") then
			flush()
			cur = {}
			for i = 1, ncols do
				cur[i] = ""
			end
		elseif cur then
			local label, text = line:match("^(.-)│(.*)$")
			if label then
				label = vim.trim(label)
				text = vim.trim(text)
				local idx = by_label[label]
				if label ~= "" and idx then
					cur_idx = idx
					cur[idx] = text
				elseif label == "" and cur_idx and text ~= "" then
					cur[cur_idx] = (cur[cur_idx] ~= "") and (cur[cur_idx] .. " " .. text) or text
				end
			end
		end
	end
	flush()

	return rows
end

-- Lee el buffer flotante en modo tarjetas y mete las ediciones en state.tbl.
local function sync_from_cards()
	if state.mode ~= "cards" or not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
		return false
	end
	local lines = vim.api.nvim_buf_get_lines(state.buf, 0, -1, false)
	local rows = parse_cards(lines, state.tbl.header, state.tbl.ncols)
	if #rows == 0 then
		vim.notify("No pude leer ninguna tarjeta; no toqué el archivo.", vim.log.levels.WARN)
		return false
	end
	state.tbl.rows = rows
	return true
end

-- ------------------------------------------------------------
-- Ventana flotante
-- ------------------------------------------------------------

local function close()
	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_close(state.win, true)
	end
	state.win, state.buf, state.tbl = nil, nil, nil
end

local function draw()
	local max_w = vim.o.columns - 6
	local max_h = vim.o.lines - vim.o.cmdheight - 6

	local lines
	if state.mode == "cards" then
		lines = render_cards(state.tbl, math.min(max_w, 100))
	else
		lines = render_grid(state.tbl)
	end

	local content_w = 0
	for _, l in ipairs(lines) do
		content_w = math.max(content_w, dw(l))
	end

	local w = math.max(math.min(content_w, max_w), 20)
	local h = math.max(math.min(#lines, max_h), 3)

	local cfg = {
		relative = "editor",
		width = w,
		height = h,
		row = math.floor((vim.o.lines - h) / 2) - 1,
		col = math.floor((vim.o.columns - w) / 2),
		style = "minimal",
		border = "rounded",
		title = state.mode == "grid" and " Tabla · <Tab> tarjetas · q cerrar "
			or " Tabla · editable · <C-s> guardar · <Tab> rejilla · q cerrar ",
		title_pos = "center",
	}

	-- La rejilla es solo lectura: sus columnas están padeadas a mano y editarlas
	-- rompe el ancho. Las tarjetas sí se editan, y `M.save` las escribe de vuelta.
	local editable = (state.mode == "cards")

	vim.bo[state.buf].modifiable = true
	vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
	vim.bo[state.buf].modifiable = editable
	vim.bo[state.buf].modified = false

	state.rendered = lines

	if state.win and vim.api.nvim_win_is_valid(state.win) then
		vim.api.nvim_win_set_config(state.win, cfg)
	else
		state.win = vim.api.nvim_open_win(state.buf, true, cfg)
	end

	local wo = vim.wo[state.win]
	wo.wrap = false
	wo.cursorline = true
	wo.number = false
	wo.relativenumber = false
	wo.signcolumn = "no"
	wo.sidescrolloff = 0
	wo.scrolloff = 0
	wo.winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder"

	vim.api.nvim_win_set_cursor(state.win, { 1, 0 })
end

function M.zoom()
	local buf = vim.api.nvim_get_current_buf()
	local lnum = vim.api.nvim_win_get_cursor(0)[1]

	local s, e = table_range(buf, lnum)
	if not s then
		vim.notify("El cursor no está sobre una tabla markdown.", vim.log.levels.WARN)
		return
	end

	local tbl = parse_table(vim.api.nvim_buf_get_lines(buf, s - 1, e, false))
	if not tbl then
		vim.notify("No pude parsear la tabla.", vim.log.levels.WARN)
		return
	end

	state.tbl = tbl
	state.src_buf = buf
	state.src_s = s
	state.src_e = e
	state.indent = vim.api.nvim_buf_get_lines(buf, s - 1, s, false)[1]:match("^%s*")

	state.buf = vim.api.nvim_create_buf(false, true)
	vim.bo[state.buf].bufhidden = "wipe"
	vim.bo[state.buf].filetype = "mdtablezoom"
	-- `acwrite` para que `:w` dispare BufWriteCmd en vez de quejarse.
	vim.bo[state.buf].buftype = "acwrite"
	vim.api.nvim_buf_set_name(state.buf, "mdtable://" .. vim.api.nvim_buf_get_name(buf))

	draw()

	local opts = { buffer = state.buf, nowait = true, silent = true }
	vim.keymap.set("n", "q", close, opts)
	vim.keymap.set("n", "<Esc>", close, opts)
	vim.keymap.set("n", "<Tab>", function()
		state.mode = (state.mode == "grid") and "cards" or "grid"
		draw()
	end, opts)
	-- Scroll horizontal rápido (dentro del flotante gana sobre el resize global).
	vim.keymap.set("n", "H", "10zh", opts)
	vim.keymap.set("n", "L", "10zl", opts)

	vim.api.nvim_create_autocmd("VimResized", {
		buffer = state.buf,
		callback = function()
			if state.win and vim.api.nvim_win_is_valid(state.win) then
				draw()
			end
		end,
	})
end

-- ------------------------------------------------------------
-- Formatear la tabla en el buffer real
-- ------------------------------------------------------------

-- Rinde la tabla como markdown alineado, con la indentación original.
local function format_lines(tbl, indent)
	local w = col_widths(tbl)
	for i = 1, tbl.ncols do
		w[i] = math.max(w[i], 3) -- el separador necesita `---` mínimo
	end

	local function row(cells, aligned)
		local parts = {}
		for i = 1, tbl.ncols do
			local a = aligned and tbl.aligns[i] or "left"
			parts[i] = " " .. pad(cells[i] or "", w[i], a) .. " "
		end
		return "|" .. table.concat(parts, "|") .. "|"
	end

	local sep = {}
	for i = 1, tbl.ncols do
		local a = tbl.aligns[i]
		if a == "center" then
			sep[i] = " :" .. string.rep("-", w[i] - 2) .. ": "
		elseif a == "right" then
			sep[i] = " " .. string.rep("-", w[i] - 1) .. ": "
		else
			sep[i] = " " .. string.rep("-", w[i]) .. " "
		end
	end

	local out = { row(tbl.header, false), "|" .. table.concat(sep, "|") .. "|" }
	for _, r in ipairs(tbl.rows) do
		out[#out + 1] = row(r, true)
	end

	if indent and indent ~= "" then
		for i, l in ipairs(out) do
			out[i] = indent .. l
		end
	end

	return out
end

function M.format()
	local buf = vim.api.nvim_get_current_buf()
	local lnum = vim.api.nvim_win_get_cursor(0)[1]

	local s, e = table_range(buf, lnum)
	if not s then
		vim.notify("El cursor no está sobre una tabla markdown.", vim.log.levels.WARN)
		return
	end

	local tbl = parse_table(vim.api.nvim_buf_get_lines(buf, s - 1, e, false))
	if not tbl then
		return
	end

	local indent = vim.api.nvim_buf_get_lines(buf, s - 1, s, false)[1]:match("^%s*")
	local out = format_lines(tbl, indent)

	vim.api.nvim_buf_set_lines(buf, s - 1, e, false, out)
	vim.notify(("Tabla alineada (%d columnas, %d filas)"):format(tbl.ncols, #tbl.rows))
end

-- ------------------------------------------------------------
-- Guardar: tarjetas editadas -> tabla en el buffer real
-- ------------------------------------------------------------

function M.save()
	if not (state.src_buf and vim.api.nvim_buf_is_valid(state.src_buf)) then
		vim.notify("El buffer original ya no existe; no guardé nada.", vim.log.levels.ERROR)
		return
	end

	if state.mode == "cards" and not sync_from_cards() then
		return
	end

	local out = format_lines(state.tbl, state.indent)
	vim.api.nvim_buf_set_lines(state.src_buf, state.src_s - 1, state.src_e, false, out)

	-- La tabla pudo cambiar de altura: mueve el rango para el siguiente guardado.
	state.src_e = state.src_s + #out - 1

	local cur = state.win and vim.api.nvim_win_is_valid(state.win) and vim.api.nvim_win_get_cursor(state.win)
	draw()
	if cur and state.win and vim.api.nvim_win_is_valid(state.win) then
		local last = vim.api.nvim_buf_line_count(state.buf)
		pcall(vim.api.nvim_win_set_cursor, state.win, { math.min(cur[1], last), cur[2] })
	end

	vim.notify(("Tabla escrita: %d filas."):format(#state.tbl.rows))
end

-- Expuesto para el ftplugin: ¿el cursor está dentro de una tabla?
function M.cursor_in_table()
	local line = vim.api.nvim_get_current_line()
	return is_table_line(line)
end

return M
