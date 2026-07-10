return {
	"navarasu/onedark.nvim",
	lazy = false,
	priority = 1000,

	config = function()
		require("onedark").setup({
			style = "dark",
			transparent = true,

			colors = {
				bg0 = "#282c34",

				fg = "#abb2bf",

				red = "#c27a7a",
				green = "#8b9f7a",
				yellow = "#b8a06b",
				blue = "#7a94b8",
				purple = "#9b8cb5",
				cyan = "#7d9ea3",
				orange = "#b08b68",
			},
		})

		require("onedark").load()

		vim.schedule(function()
			local groups = {
				"Normal",
				"NormalFloat",
				"NormalNC",
				"SignColumn",
				"EndOfBuffer",
				"MsgArea",
				"FloatBorder",
				"NvimTreeNormal",
			}

			for _, group in ipairs(groups) do
				vim.api.nvim_set_hl(0, group, { bg = "none" })
			end

			-- Comentarios más suaves
			vim.api.nvim_set_hl(0, "Comment", {
				fg = "#6f7680",
				italic = true,
			})

			-- Strings
			vim.api.nvim_set_hl(0, "String", {
				fg = "#8b9f7a",
			})

			-- Keywords
			vim.api.nvim_set_hl(0, "Keyword", {
				fg = "#9b8cb5",
			})

			-- Funciones
			vim.api.nvim_set_hl(0, "Function", {
				fg = "#7a94b8",
			})

			-- Tipos (int, double, string...)
			vim.api.nvim_set_hl(0, "Type", {
				fg = "#b8a06b",
			})

			-- Números
			vim.api.nvim_set_hl(0, "Number", {
				fg = "#b08b68",
			})
		end)
	end,
}
