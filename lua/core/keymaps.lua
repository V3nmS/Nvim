vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- For conciseness
local opts = { noremap = true, silent = true }

-- save file
vim.keymap.set("n", "<C-s>", "<cmd> w <CR>", opts)

-- save file without auto-formatting
vim.keymap.set("n", "<C-ss>", "<cmd>noautocmd w <CR>", opts)

-- quit file
vim.keymap.set("n", "<C-w>", "<cmd> q <CR>", opts)
vim.keymap.set("n", "<C-ww>", "<cmd> q! <CR>", opts)

-- delete single character without copying into register
vim.keymap.set("n", "x", '"_x', opts)

-- Vertical scroll and center
vim.keymap.set("n", "<C-d>", "<C-d>zz", opts)
vim.keymap.set("n", "<C-u>", "<C-u>zz", opts)

-- Find and center
vim.keymap.set("n", "n", "nzzzv", opts)
vim.keymap.set("n", "N", "Nzzzv", opts)

-- Resize with arrows
vim.keymap.set("n", "<S-k>", ":horizontal resize -2<CR>", opts)
vim.keymap.set("n", "<S-j>", ":horizontal resize +2<CR>", opts)
vim.keymap.set("n", "<S-h>", ":vertical resize +2<CR>", opts)
vim.keymap.set("n", "<S-l>", ":vertical resize -2<CR>", opts)

-- Buffers (con scope por split: ver lua/core/bufscope.lua)
vim.keymap.set("n", "<Tab>", function()
	require("core.bufscope").cycle(1)
end, { noremap = true, silent = true, desc = "Siguiente buffer de este split" })

vim.keymap.set("n", "<S-Tab>", function()
	require("core.bufscope").cycle(-1)
end, { noremap = true, silent = true, desc = "Buffer anterior de este split" })

-- Saca el buffer de ESTE split; solo lo borra de verdad si ya no vive en otro
vim.keymap.set("n", "<leader>x", function()
	require("core.bufscope").close(true)
end, { noremap = true, silent = true, desc = "Cerrar buffer en este split" })

-- Ciclado global, por si necesito alcanzar un buffer que no está en este split
vim.keymap.set("n", "<leader><Tab>", ":bnext<CR>", opts)
vim.keymap.set("n", "<leader><S-Tab>", ":bprevious<CR>", opts)

vim.keymap.set("n", "<leader>b", "<cmd> enew <CR>", opts) -- new buffer

-- Window management
vim.keymap.set("n", "<leader>h", "<C-w>v", opts) -- split window vertically
vim.keymap.set("n", "<leader>v", "<C-w>s", opts) -- split window horizontally
vim.keymap.set("n", "<leader>se", "<C-w>=", opts) -- make split windows equal width & height
vim.keymap.set("n", "<leader>xs", ":close<CR>", opts) -- close current split window

-- Navigate between splits
vim.keymap.set("n", "<C-k>", "<cmd>wincmd k<CR>", opts)
vim.keymap.set("n", "<C-j>", "<cmd>wincmd j<CR>", opts)
vim.keymap.set("n", "<C-h>", "<cmd>wincmd h<CR>", opts)
vim.keymap.set("n", "<C-l>", "<cmd>wincmd l<CR>", opts)

-- Tabs
-- vim.keymap.set("n", "<A-w>", ":tabclose<CR>", opts) -- close current tab
-- vim.keymap.set("n", "<A-S-Right>", ":tabn<CR>", opts) --  go to next tab
-- vim.keymap.set("n", "<A-S-Left>", ":tabp<CR>", opts) --  go to previous tab

-- Toggle line wrapping
vim.keymap.set("n", "<leader>lw", "<cmd>set wrap!<CR>", opts)

-- Stay in indent mode
vim.keymap.set("n", ">", "<<", opts)
vim.keymap.set("n", "<", ">>", opts)

-- Keep last yanked when pasting
vim.keymap.set("v", "p", '"_dP', opts)

-- Diagnostic keymaps
vim.keymap.set("n", "[d", function()
	vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Go to previous diagnostic message" })

vim.keymap.set("n", "]d", function()
	vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Go to next diagnostic message" })

vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "Open floating diagnostic message" })
vim.keymap.set("n", "<leader>q", vim.diagnostic.setloclist, { desc = "Open diagnostics list" })

-- vim.keymap.set("n", "<C-z>", "u", { noremap = true, silent = true })
-- vim.keymap.set("i", "<C-z>", "<C-o>u", { noremap = true, silent = true })

vim.keymap.set("n", "<leader><CR>", "o<Esc>", { noremap = true, silent = true })

-- Neotree
-- vim.keymap.set("n", "<C-e>", ":Neotree toggle<CR>", { silent = true }

-- Python / C++ Keymap

-- Resuelve el intérprete de Python sin depender de $PATH:
-- 1) venv activo heredado por nvim, 2) .venv/venv del proyecto (subiendo
-- desde el archivo), 3) ~/.venv de respaldo, 4) python3 del sistema.
local function python_interpreter(file)
	local candidates = {}

	if vim.env.VIRTUAL_ENV then
		table.insert(candidates, vim.env.VIRTUAL_ENV .. "/bin/python")
	end

	local found = vim.fs.find({ ".venv", "venv" }, {
		upward = true,
		type = "directory",
		path = vim.fn.fnamemodify(file, ":h"),
	})[1]
	if found then
		table.insert(candidates, found .. "/bin/python")
	end

	table.insert(candidates, vim.env.HOME .. "/.venv/bin/python")

	for _, py in ipairs(candidates) do
		if vim.fn.executable(py) == 1 then
			return py
		end
	end

	return "python3"
end

vim.keymap.set("n", "<F5>", function()
	vim.cmd("w")
	local ext = vim.fn.expand("%:e")
	local file = vim.fn.expand("%:p")
	local cmd

	if ext == "cpp" or ext == "cc" or ext == "cxx" then
		local output = vim.fn.expand("%:p:r")
		cmd = "g++ -std=c++20 "
			.. vim.fn.shellescape(file)
			.. " -o "
			.. vim.fn.shellescape(output)
			.. " && "
			.. vim.fn.shellescape(output)
	elseif ext == "py" then
		-- -u: salida sin buffer, para que los print aparezcan al instante
		cmd = vim.fn.shellescape(python_interpreter(file)) .. " -u " .. vim.fn.shellescape(file)
	else
		print("No hay runner configurado para ." .. ext)
		return
	end

	vim.cmd("botright split")
	vim.cmd("resize 15")
	vim.cmd("terminal " .. cmd)
end, { noremap = true, silent = true, desc = "Compile/Run C++ or Python" })

local keymap = vim.keymap

-- COPIAR (Ctrl + C)
keymap.set("v", "<C-c>", '"+y') -- copiar selección
keymap.set("n", "<C-c>", '"+yy') -- copiar línea

-- PEGAR (Ctrl + V)
keymap.set("n", "<C-v>", '"+p') -- pegar en normal
keymap.set("i", "<C-v>", "<C-r>+") -- pegar en insert
keymap.set("v", "<C-v>", '"+p') -- reemplazar selección

-- CORTAR (Ctrl + X)
keymap.set("v", "<C-x>", '"+d') -- cortar selección
keymap.set("n", "<C-x>", '"+dd') -- cortar línea

-- DESHACER / REHACER
keymap.set("n", "<C-z>", "u") -- undo
keymap.set("n", "<C-y>", "<C-r>") -- redo

-- SELECCIONAR TODO (Ctrl + A)
keymap.set("n", "<C-a>", "ggVG")

-- New tab terminal
-- vim.keymap.set("n", "<leader>t", function()
-- vim.cmd("tabnew | terminal")
-- end)

-- Split terminal
-- vim.keymap.set("n", "<leader>tv", function()
-- vim.cmd("vsplit | terminal")
-- end)

-- Salir de terminal con ESC
-- vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]])

vim.o.mouse = ""

vim.keymap.set("n", "<leader>m", function()
	if vim.o.mouse == "" then
		vim.o.mouse = "a"
		print("Mouse ON")
	else
		vim.o.mouse = ""
		print("Mouse OFF")
	end
end, { desc = "Toggle mouse" })

-- TOGGLE COMMENT CON CTRL + SHIFT + -
-- En terminal Linux normalmente Ctrl+Shift+- llega como Ctrl+_
vim.keymap.set("n", "<C-_>", function()
	require("Comment.api").toggle.linewise.current()
end, { noremap = true, silent = true, desc = "Toggle comment line" })

vim.keymap.set("v", "<C-_>", function()
	local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
	vim.api.nvim_feedkeys(esc, "nx", false)
	require("Comment.api").toggle.linewise(vim.fn.visualmode())
end, { noremap = true, silent = true, desc = "Toggle comment selection" })
