-- ============================================================
-- bufscope: lista de buffers POR VENTANA (estilo editor groups)
-- ============================================================
-- Neovim no tiene scoping de buffers por ventana: `:ls` y `:bnext`
-- caminan una lista global. Aquí se lleva, por winid, la lista de
-- buffers que se han mostrado en ESA ventana, y:
--   * <Tab>/<S-Tab> ciclan solo dentro de esa lista
--   * bufferline filtra la barra con `custom_filter` para pintar
--     solo los buffers del split enfocado
--
-- Ojo con el alcance: esto NO aísla los buffers de verdad (siguen
-- siendo globales y `:b nombre` alcanza cualquiera). Es una vista
-- por ventana encima de la lista global.
-- ============================================================

local M = {}

--- winid -> { bufnr, ... } en orden de inserción
M.scopes = {}

--- Última ventana "normal" enfocada. Sirve para que la bufferline no se
--- vacíe cuando el foco se va a neo-tree, a un float o al prompt de telescope.
M.last_win = nil

-- ---------- helpers ----------

local function is_float(win)
	return vim.api.nvim_win_get_config(win).relative ~= ""
end

--- Una ventana se rastrea solo si es real (no flotante) y trae un buffer listado.
--- Con esto neo-tree, help, quickfix y telescope quedan fuera solitos.
local function trackable(win)
	if not win or not vim.api.nvim_win_is_valid(win) or is_float(win) then
		return false
	end
	local buf = vim.api.nvim_win_get_buf(win)
	return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted
end

--- Devuelve la lista de la ventana, ya limpia de buffers muertos o deslistados.
--- Muta y regresa la MISMA tabla guardada, para que quien la reciba pueda editarla.
function M.list(win)
	local s = M.scopes[win]
	if not s then
		s = {}
		M.scopes[win] = s
	end
	for i = #s, 1, -1 do
		local b = s[i]
		if not vim.api.nvim_buf_is_valid(b) or not vim.bo[b].buflisted then
			table.remove(s, i)
		end
	end
	return s
end

--- Da de alta el buffer de una ventana en su lista, si aplica.
function M.register(win, buf)
	win = win or vim.api.nvim_get_current_win()
	if not vim.api.nvim_win_is_valid(win) or is_float(win) then
		return
	end
	buf = buf or vim.api.nvim_win_get_buf(win)
	if not vim.api.nvim_buf_is_valid(buf) or not vim.bo[buf].buflisted then
		return
	end
	local s = M.list(win)
	for _, b in ipairs(s) do
		if b == buf then
			return
		end
	end
	table.insert(s, buf)
end

--- La ventana cuya lista debe mandar en la bufferline ahorita.
local function active_win()
	local win = vim.api.nvim_get_current_win()
	if trackable(win) then
		return win
	end
	if M.last_win and vim.api.nvim_win_is_valid(M.last_win) then
		return M.last_win
	end
	return nil
end

-- ---------- API pública ----------

--- Filtro para `options.custom_filter` de bufferline.
--- Regresa true si el buffer debe pintarse en la barra.
function M.filter(bufnr)
	local win = active_win()
	if not win then
		return true
	end
	local s = M.list(win)
	-- Si la ventana no tiene nada registrado, mejor mostrar todo que
	-- dejar la barra en blanco.
	if #s == 0 then
		return true
	end
	for _, b in ipairs(s) do
		if b == bufnr then
			return true
		end
	end
	return false
end

--- Cicla dentro de la lista de la ventana actual. dir = 1 siguiente, -1 anterior.
function M.cycle(dir)
	local win = vim.api.nvim_get_current_win()
	local s = M.list(win)
	if #s <= 1 then
		return
	end
	local cur = vim.api.nvim_win_get_buf(win)
	local idx = 1
	for i, b in ipairs(s) do
		if b == cur then
			idx = i
			break
		end
	end
	-- índices 1-based: bajar a 0-based, mover, módulo, subir otra vez
	local target = s[(idx - 1 + dir) % #s + 1]
	vim.api.nvim_win_set_buf(win, target)
end

--- Cierra el buffer actual EN ESTE SPLIT.
--- Si el buffer sigue vivo en otra ventana, solo sale de esta lista.
--- Si ya no lo usa nadie, entonces sí se hace :bdelete de verdad.
function M.close(force)
	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_win_get_buf(win)
	local s = M.list(win)

	local idx
	for i, b in ipairs(s) do
		if b == buf then
			idx = i
			table.remove(s, i)
			break
		end
	end

	-- Mover esta ventana a otro buffer de su propia lista
	if #s > 0 then
		vim.api.nvim_win_set_buf(win, s[math.min(idx or 1, #s)])
	else
		vim.cmd("enew")
	end

	local used_elsewhere = false
	for w, list in pairs(M.scopes) do
		if w ~= win and vim.api.nvim_win_is_valid(w) then
			for _, b in ipairs(list) do
				if b == buf then
					used_elsewhere = true
					break
				end
			end
		end
	end

	if not used_elsewhere and vim.api.nvim_buf_is_valid(buf) then
		pcall(vim.cmd, (force and "bdelete! " or "bdelete ") .. buf)
	end
end

-- ---------- autocmds ----------

local grp = vim.api.nvim_create_augroup("BufScope", { clear = true })

vim.api.nvim_create_autocmd({ "BufWinEnter", "BufEnter", "WinEnter" }, {
	group = grp,
	callback = function()
		local win = vim.api.nvim_get_current_win()
		M.register(win)
		if trackable(win) then
			M.last_win = win
		end
		pcall(vim.cmd, "redrawtabline")
	end,
})

vim.api.nvim_create_autocmd("WinClosed", {
	group = grp,
	callback = function(args)
		local win = tonumber(args.match)
		if win then
			M.scopes[win] = nil
			if M.last_win == win then
				M.last_win = nil
			end
		end
	end,
})

vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
	group = grp,
	callback = function(args)
		for _, list in pairs(M.scopes) do
			for i = #list, 1, -1 do
				if list[i] == args.buf then
					table.remove(list, i)
				end
			end
		end
		pcall(vim.cmd, "redrawtabline")
	end,
})

return M
