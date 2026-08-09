return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter").setup({
			ensure_installed = { "cpp", "c", "python", "lua", "bash", "vimdoc" },
		})

		-- Arranca treesitter (highlight + parsing) en los filetypes instalados
		-- En la rama `main` esto ya no es automático, hay que activarlo a mano
		-- markdown/markdown_inline van aquí porque render-markdown.nvim parsea
		-- el buffer con treesitter: sin `start()` no detecta headings ni bloques
		-- de código y no pinta nada.
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "cpp", "c", "python", "lua", "bash", "markdown" },
			callback = function()
				vim.treesitter.start()
			end,
		})
	end,
}
