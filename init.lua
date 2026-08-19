require("core.options")
require("core.keymaps")
require("core.snippets")

-- Instalar lazy.nvim si no existe
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"--branch=stable",
		"https://github.com/folke/lazy.nvim.git",
		lazypath,
	})
end

vim.opt.rtp:prepend(lazypath)
vim.opt.clipboard = "unnamedplus"

-- Wrap de nvim
vim.opt.wrap = true
vim.opt.linebreak = true -- corta bonito, no a mitad de palabra

-- Autocompletado
vim.cmd("filetype plugin indent on")

vim.api.nvim_create_autocmd("TermOpen", {
	pattern = "*",
	command = "startinsert",
})

vim.api.nvim_create_autocmd("BufEnter", {
	pattern = "term://*",
	command = "startinsert",
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "c", "cpp", "java", "javascript", "typescript" },
	callback = function()
		vim.bo.commentstring = "// %s"
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	pattern = { "python", "sh", "bash" },
	callback = function()
		vim.bo.commentstring = "# %s"
	end,
})

-- ============================================
-- Persistencia de folds (mkview/loadview)
-- ============================================
local fold_group = vim.api.nvim_create_augroup("PersistentFolds", { clear = true })

-- Guarda la vista (folds, cursor, etc) al salir del buffer o al guardar
vim.api.nvim_create_autocmd({ "BufWinLeave", "BufWritePost" }, {
	group = fold_group,
	pattern = "*",
	callback = function(args)
		if vim.bo[args.buf].buftype == "" and vim.fn.expand("%") ~= "" then
			vim.cmd("silent! mkview")
		end
	end,
})

-- Carga la vista al entrar al buffer (con delay para que treesitter alcance a parsear)
vim.api.nvim_create_autocmd("BufWinEnter", {
	group = fold_group,
	pattern = "*",
	callback = function(args)
		if vim.bo[args.buf].buftype == "" and vim.fn.expand("%") ~= "" then
			vim.defer_fn(function()
				vim.cmd("silent! loadview")
			end, 10)
		end
	end,
})

-- Cargar plugins
require("lazy").setup({
	{ import = "plugins" },
})
