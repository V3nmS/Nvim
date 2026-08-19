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
		opts = {
			table = {
				enabled = false,
			},
			heading = {
				enabled = true,
				backgrounds = {},
				foregrounds = {
					"@markup.heading.1.markdown",
					"@markup.heading.2.markdown",
					"@markup.heading.3.markdown",
					"@markup.heading.4.markdown",
					"@markup.heading.5.markdown",
					"@markup.heading.6.markdown",
				},
			},
		},
	},
}
