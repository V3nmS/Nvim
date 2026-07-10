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

-- Cargar plugins
require("lazy").setup({
	{ import = "plugins" },
})
