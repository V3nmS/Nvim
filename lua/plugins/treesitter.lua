return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	config = function()
		require("nvim-treesitter").install({
			"cpp",
			"c",
			"python",
			"lua",
			"bash",
			"javascript",
			"typescript",
		})

		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "cpp", "c", "python", "lua", "bash", "javascript", "typescript" },
			callback = function()
				vim.treesitter.start()
			end,
		})
	end,
}
