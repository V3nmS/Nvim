return {
	{
		"dhruvasagar/vim-table-mode",
		cmd = "TableModeToggle",
		keys = {
			{ "<leader>tm", "<cmd>TableModeToggle<cr>", desc = "Toggle table mode" },
		},
	},
	{
		"MeanderingProgrammer/markdown.nvim",
		main = "render-markdown",
		dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
		ft = { "markdown" },
		opts = {},
	},
}
