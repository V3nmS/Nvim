return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter").setup({
			ensure_installed = { "cpp", "c", "python", "lua", "bash", "vimdoc", "markdown", "markdown_inline" },
		})

		-- Arranca treesitter (highlight + parsing) en los filetypes instalados
		-- En la rama `main` esto ya no es automático, hay que activarlo a mano
		vim.api.nvim_create_autocmd("FileType", {
			-- markdown lo necesita render-markdown.nvim para dibujar las tablas
			pattern = { "cpp", "c", "python", "lua", "bash", "markdown" },
			callback = function()
				vim.treesitter.start()
			end,
		})
	end,
}
