return {
	"numToStr/Comment.nvim",
	lazy = false,

	config = function()
		require("Comment").setup({
			pre_hook = function()
				return vim.bo.commentstring
			end,
		})

		local api = require("Comment.api")

		-- NORMAL: Ctrl + Shift + -
		vim.keymap.set("n", "<C-_>", function()
			api.toggle.linewise.current()
		end, { noremap = true, silent = true, desc = "Toggle comment line" })

		-- VISUAL: Ctrl + Shift + -
		vim.keymap.set("x", "<C-_>", function()
			local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
			vim.api.nvim_feedkeys(esc, "nx", false)
			api.toggle.linewise(vim.fn.visualmode())
		end, { noremap = true, silent = true, desc = "Toggle comment selection" })

		-- INSERT: Ctrl + Shift + -
		vim.keymap.set("i", "<C-_>", function()
			vim.cmd("stopinsert")
			api.toggle.linewise.current()
			vim.cmd("startinsert")
		end, { noremap = true, silent = true, desc = "Toggle comment insert" })
	end,
}
