return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	config = function()
		-- OJO: en la rama `main`, setup() SOLO acepta `install_dir` (ver la
		-- clase TSConfig en lua/nvim-treesitter/config.lua). `ensure_installed`
		-- ahí dentro se ignora en silencio: no da error, simplemente no instala.
		-- Por eso los parsers se piden aparte, con install().
		require("nvim-treesitter").setup({})

		local parsers = { "cpp", "c", "python", "lua", "bash", "vimdoc", "markdown", "markdown_inline" }

		-- install() es idempotente, pero es async y clona de red: filtrar contra
		-- lo ya instalado evita lanzar trabajo en cada arranque.
		local installed = require("nvim-treesitter.config").get_installed("parsers")
		local missing = vim.tbl_filter(function(lang)
			return not vim.tbl_contains(installed, lang)
		end, parsers)
		if #missing > 0 then
			require("nvim-treesitter").install(missing, { summary = true })
		end

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
