return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	config = function()
		-- Agrega el subdirectorio runtime/ al rtp para que se detecten los queries
		vim.opt.rtp:append(vim.fn.stdpath("data") .. "/lazy/nvim-treesitter/runtime")

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
