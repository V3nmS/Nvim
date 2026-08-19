return {
	"obsidian-nvim/obsidian.nvim",
	version = "*", -- último release estable, no main
	lazy = true,
	-- Dos disparadores, gana el que ocurra primero:
	--   ft      -> al abrir un markdown. IMPRESCINDIBLE: el plugin mete su
	--              lógica dentro de un autocmd FileType, así que si carga
	--              después (VeryLazy/VimEnter disparan hasta UIEnter, ya
	--              leído el archivo) ese evento ya pasó y el buffer se queda
	--              sin UI. Con `ft`, lazy re-emite el FileType al cargar.
	--   event   -> para tener los comandos disponibles desde cualquier buffer
	--              (crear nota desde un .cpp, por ejemplo).
	ft = { "markdown", "quarto" },
	event = "VeryLazy",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
	},
	-- opts como función: se evalúa DESPUÉS de que el plugin entra al runtimepath,
	-- si no, el require("obsidian.builtin") de abajo truena.
	opts = function()
		return {
			legacy_commands = false, -- solo `:Obsidian <sub>`, sin los viejos :ObsidianX

			workspaces = {
				{
					name = "vault",
					path = "~/Portafolio/Obsidian-Vault",
				},
			},

			-- ============================================
			-- Dónde vive cada cosa
			-- ============================================
			notes_subdir = "00-Inbox", -- notas nuevas caen aquí por default
			new_notes_location = "notes_subdir",

			daily_notes = {
				folder = "01-Daily",
				date_format = "YYYY-MM-DD",
				template = "Daily.md",
				default_tags = { "daily" },
				workdays_only = false, -- también sábados y domingos
			},

			templates = {
				folder = "99-Templates",
				date_format = "YYYY-MM-DD",
				time_format = "HH:mm",
			},

			attachments = {
				folder = "98-Assets",
			},

			-- ============================================
			-- Links y nombres de archivo
			-- ============================================
			link = {
				style = "wiki", -- [[nota]] en vez de [nota](nota.md)
				format = "shortest",
				auto_update = true, -- al renombrar/mover, arregla los links que apuntan ahí
			},

			-- Nombre de archivo legible (no ID random tipo 1690000000-abc123)
			note_id_func = require("obsidian.builtin").title_id,

			-- Frontmatter automático de cada nota nueva
			frontmatter = {
				enabled = true,
				func = function(note)
					if note.title then
						note:add_alias(note.title)
					end
					local out = {
						id = note.id,
						aliases = note.aliases,
						tags = note.tags,
						created = os.date("%Y-%m-%d"),
					}
					-- respeta cualquier campo que hayas metido a mano
					if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
						for k, v in pairs(note.metadata) do
							out[k] = v
						end
					end
					return out
				end,
			},

			completion = {
				min_chars = 2,
				create_new = true, -- autocompletar [[algo-que-no-existe]] la crea
			},

			picker = {
				name = "telescope.nvim",
				note_mappings = {
					new = "<C-x>", -- crear nota con lo que escribiste
					insert_link = "<C-l>", -- insertar link a la nota seleccionada
				},
			},

			search = {
				sort_by = "modified",
				sort_reversed = true,
			},

			-- Orden al ciclar con <leader>oc:  [ ] -> [~] -> [!] -> [>] -> [x]
			checkbox = {
				enabled = true,
				create_new = true,
				order = { " ", "~", "!", ">", "x" },
			},

			-- Los iconos/colores de checkbox vienen de los defaults del plugin
			-- (ui.checkboxes). Si los redefines aquí salta un warning aunque
			-- ya tengas checkbox.order, así que se dejan tal cual.
			ui = {
				enable = false, -- conceal de links, bullets, iconos
			},

			footer = {
				enabled = true, -- muestra backlinks/palabras al pie de la nota
			},
		}
	end,

	config = function(_, opts)
		require("obsidian").setup(opts)

		-- conceal para que los [[links]] se vean limpios
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "markdown",
			callback = function()
				vim.opt_local.conceallevel = 2
			end,
		})

		-- ============================================
		-- Resincronizar `id:` con el nombre del archivo
		-- ============================================
		-- `:Obsidian rename` (v3.16.6) reescribe el archivo y todos los links,
		-- pero deja el `id:` del frontmatter con el nombre viejo. Renombrar a
		-- mano con `mv` hace lo mismo. Esto lo corrige al guardar.
		--
		-- Va en `ObsidianNoteWritePre` a propósito: el plugin lo dispara justo
		-- ANTES de su propio `update_frontmatter`, así que él relee el buffer y
		-- persiste el id nuevo. El nombre viejo se conserva como alias para que
		-- ningún link que aún lo use se rompa.
		vim.api.nvim_create_autocmd("User", {
			pattern = "ObsidianNoteWritePre",
			group = vim.api.nvim_create_augroup("ObsidianSyncId", { clear = true }),
			callback = function(ev)
				local buf = ev.buf or vim.api.nvim_get_current_buf()
				if not vim.b[buf].obsidian_buffer then
					return
				end

				local fname = vim.api.nvim_buf_get_name(buf)
				if fname == "" then
					return
				end
				local stem = vim.fn.fnamemodify(fname, ":t:r")

				local ok, note = pcall(require("obsidian.note").from_buffer, buf)
				if not ok or not note or not note.id or note.id == stem then
					return
				end
				-- Reusa las exclusiones del propio plugin: templates, archivos
				-- ignorados, README/CHANGELOG, etc.
				if not note.has_frontmatter or not note:should_save_frontmatter() then
					return
				end

				note:add_alias(note.id) -- el nombre viejo sigue resolviendo
				note.id = stem
				note:save_to_buffer({ bufnr = buf })
			end,
		})

		local map = function(lhs, rhs, desc)
			vim.keymap.set("n", lhs, rhs, { desc = desc, silent = true })
		end

		-- <leader>o... = Obsidian
		map("<leader>oo", "<cmd>Obsidian quick_switch<CR>", "Buscar nota por nombre")
		map("<leader>of", "<cmd>Obsidian search<CR>", "Grep en el vault")
		-- ============================================
		-- Nota nueva SIEMPRE dentro del vault
		-- ============================================
		-- El `:Obsidian new` de fábrica abre un prompt con `completion = "file"`,
		-- que autocompleta contra tu cwd. La nota igual cae en el vault, pero el
		-- prompt te enseña la carpeta donde estás y confunde. Esto lo reemplaza:
		-- el autocompletado ofrece las carpetas DEL VAULT, y el input se sanea
		-- para que no se pueda escapar de ahí ni con rutas absolutas ni con `..`.
		local vault = vim.fn.expand("~/Portafolio/Obsidian-Vault")

		_G.__v3nom_obsidian_dirs = function(arglead)
			local dirs = {}
			for name, type_ in vim.fs.dir(vault) do
				if type_ == "directory" and not name:match("^%.") then
					table.insert(dirs, name .. "/")
				end
			end
			table.sort(dirs)
			if arglead == "" then
				return dirs
			end
			return vim.tbl_filter(function(d)
				return d:sub(1, #arglead) == arglead
			end, dirs)
		end

		vim.cmd([[
			function! V3nomObsidianDirComplete(ArgLead, CmdLine, CursorPos) abort
				return v:lua.__v3nom_obsidian_dirs(a:ArgLead)
			endfunction
		]])

		local function new_note_in_vault()
			vim.ui.input({
				prompt = "Nota nueva (Tab = carpetas del vault): ",
				completion = "customlist,V3nomObsidianDirComplete",
			}, function(input)
				if not input or vim.trim(input) == "" then
					return
				end
				-- Ancla al vault: fuera rutas absolutas, ~ y traversal
				local id = vim.trim(input):gsub("^~/", ""):gsub("^/+", ""):gsub("%.%./", "")
				if id == "" then
					return
				end
				require("obsidian.actions").new(id, function(note)
					note:open({ sync = true })
				end)
			end)
		end

		vim.keymap.set("n", "<leader>on", new_note_in_vault, { desc = "Nota nueva (en el vault)", silent = true })
		map("<leader>oN", "<cmd>Obsidian new_from_template<CR>", "Nota nueva desde template")
		map("<leader>ot", "<cmd>Obsidian today<CR>", "Diario de hoy")
		map("<leader>oy", "<cmd>Obsidian yesterday<CR>", "Diario de ayer")
		map("<leader>ob", "<cmd>Obsidian backlinks<CR>", "Qué notas apuntan a esta")
		map("<leader>ol", "<cmd>Obsidian links<CR>", "Links salientes de esta nota")
		map("<leader>og", "<cmd>Obsidian tags<CR>", "Buscar por tag")
		map("<leader>oT", "<cmd>Obsidian template<CR>", "Insertar template aquí")
		map("<leader>or", "<cmd>Obsidian rename<CR>", "Renombrar nota (actualiza links)")
		map("<leader>op", "<cmd>Obsidian paste_img<CR>", "Pegar imagen del clipboard")
		map("<leader>oc", "<cmd>Obsidian toggle_checkbox<CR>", "Toggle checkbox")
		map("<leader>oO", "<cmd>Obsidian open<CR>", "Abrir esta nota en la app")
		map("<leader>ow", "<cmd>Obsidian workspace<CR>", "Cambiar de vault")

		-- gf y <CR> siguen [[wikilinks]]
		local follow = function(fallback)
			return function()
				if require("obsidian").util.cursor_on_markdown_link() then
					return "<cmd>Obsidian follow_link<CR>"
				end
				return fallback
			end
		end
		vim.keymap.set("n", "gf", follow("gf"), { expr = true, desc = "Seguir link" })
		vim.keymap.set("n", "<CR>", follow("<CR>"), { expr = true, desc = "Seguir link" })

		-- Visual: seleccionas texto -> se vuelve link (+ nota nueva con <leader>on)
		vim.keymap.set("v", "<leader>on", ":<C-u>Obsidian link_new<CR>", { desc = "Nota nueva desde selección" })
		vim.keymap.set("v", "<leader>ok", ":<C-u>Obsidian link<CR>", { desc = "Linkear selección a nota existente" })
		vim.keymap.set(
			"v",
			"<leader>oe",
			":<C-u>Obsidian extract_note<CR>",
			{ desc = "Extraer selección a nota nueva" }
		)
	end,

	-- Pretty markdown
	{
		"MeanderingProgrammer/render-markdown.nvim",
		enable = true,
		opts = {},
		dependencies = { "nvim-treesitter/nvim-treesitter" },
	},

	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
		build = "cd app && yarn install",
		init = function()
			vim.g.mkdp_filetypes = { "markdown" }
		end,
		ft = { "markdown" },
	},
}
