return {
	"folke/flash.nvim",
	event = "VeryLazy", -- necesario para que el modo `char` enganche f/F/t/T desde el arranque

	---@type Flash.Config
	opts = {
		-- Letras que se usan como etiquetas de salto (home row primero)
		labels = "asdfghjklqwertyuiopzxcvbnm",

		search = {
			multi_window = true, -- busca también en las otras ventanas del tab
			wrap = true,
		},

		jump = {
			nohlsearch = true, -- no deja el highlight pegado después de saltar
			autojump = false, -- con un solo match, igual pide confirmar (evita saltos sorpresa)
		},

		label = {
			uppercase = false, -- etiquetas solo en minúscula
			rainbow = { enabled = false },
		},

		modes = {
			-- `/` y `?`: flash apagado por defecto, se prende en vivo con <C-s>
			search = {
				enabled = false,
			},

			-- f / F / t / T / ; / ,
			char = {
				enabled = true,
				jump_labels = true, -- pone etiquetas al repetir, en vez de dar ;;;
				multi_line = true,
			},
		},
	},

	keys = {
		{
			"s",
			mode = { "n", "x", "o" },
			function()
				require("flash").jump()
			end,
			desc = "Flash: saltar",
		},
		{
			"S",
			mode = { "n", "x", "o" },
			function()
				require("flash").treesitter()
			end,
			desc = "Flash: seleccionar nodo treesitter",
		},
		{
			"r",
			mode = "o",
			function()
				require("flash").remote()
			end,
			desc = "Flash: operar a distancia (ej. yriw)",
		},
		{
			"R",
			mode = { "o", "x" },
			function()
				require("flash").treesitter_search()
			end,
			desc = "Flash: buscar nodo treesitter",
		},
		{
			"<C-s>",
			mode = "c",
			function()
				require("flash").toggle()
			end,
			desc = "Flash: toggle dentro de / y ?",
		},
	},
}
