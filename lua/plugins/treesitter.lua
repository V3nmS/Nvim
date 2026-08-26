return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	config = function()
		-- OJO: en la rama `main`, setup() SOLO acepta `install_dir`. Cualquier
		-- otra clave -- `ensure_installed` incluida -- se ignora en silencio:
		-- no da error, simplemente no instala nada. Por eso los parsers se
		-- piden aparte con install().
		require("nvim-treesitter").setup({})

		local parsers = {
			"cpp",
			"c",
			"python",
			"lua",
			"bash",
			"vimdoc",
			"markdown",
			"markdown_inline",
			-- `latex` no es para editar archivos .tex: es la inyección que
			-- markdown_inline le aplica a `$...$` y `$$...$$`.
			--
			-- render-markdown despacha sus handlers por lenguaje del árbol, y
			-- el de fórmulas solo corre sobre árboles de lenguaje `latex`. Sin
			-- este parser esa inyección nunca se materializa, el handler no
			-- llega a ejecutarse y las fórmulas se quedan en crudo -- aunque
			-- `latex.enabled = true` y utftex esté instalado.
			"latex",
		}

		-- install() es idempotente, pero es async y clona de red: filtrar lo
		-- ya instalado evita lanzar trabajo en cada arranque.
		local installed = require("nvim-treesitter.config").get_installed("parsers")
		local missing = vim.tbl_filter(function(lang)
			return not vim.tbl_contains(installed, lang)
		end, parsers)
		if #missing > 0 then
			require("nvim-treesitter").install(missing, { summary = true })
		end

		-- Arranca treesitter (highlight + parsing) en los filetypes instalados.
		-- En la rama `main` esto ya no es automático, hay que activarlo a mano.
		--
		-- `latex` no va en esta lista a propósito: no es un filetype que edites,
		-- entra solo como inyección cuando el parser de markdown la pide.
		vim.api.nvim_create_autocmd("FileType", {
			-- markdown lo necesita render-markdown.nvim para las tablas
			pattern = { "cpp", "c", "python", "lua", "bash", "markdown" },
			callback = function()
				vim.treesitter.start()
			end,
		})
	end,
}
