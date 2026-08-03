return {
	"obsidian-nvim/obsidian.nvim",
	version = "*", -- último release estable, no main
	lazy = true,
	-- Solo carga al abrir un .md dentro del vault (arranque rápido)
	event = {
		"BufReadPre " .. vim.fn.expand("~") .. "/Portafolio/Obsidian-Vault/**.md",
		"BufNewFile " .. vim.fn.expand("~") .. "/Portafolio/Obsidian-Vault/**.md",
	},
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
		notes_subdir = "00-inbox", -- notas nuevas caen aquí por default
		new_notes_location = "notes_subdir",

		daily_notes = {
			folder = "01-diario",
			date_format = "YYYY-MM-DD",
			template = "diario.md",
			default_tags = { "diario" },
			workdays_only = false, -- también sábados y domingos
		},

		templates = {
			folder = "99-templates",
			date_format = "YYYY-MM-DD",
			time_format = "HH:mm",
		},

		attachments = {
			folder = "98-assets",
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
		note_frontmatter_func = function(note)
			if note.title then
				note:add_alias(note.title)
			end
			local out = {
				id = note.id,
				aliases = note.aliases,
				tags = note.tags,
				creado = os.date("%Y-%m-%d"),
			}
			-- respeta cualquier campo que hayas metido a mano
			if note.metadata ~= nil and not vim.tbl_isempty(note.metadata) then
				for k, v in pairs(note.metadata) do
					out[k] = v
				end
			end
			return out
		end,

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

		ui = {
			enable = true, -- checkboxes bonitos, conceal de links
			checkboxes = {
				[" "] = { char = "󰄱", hl_group = "ObsidianTodo" },
				["x"] = { char = "", hl_group = "ObsidianDone" },
				[">"] = { char = "", hl_group = "ObsidianRightArrow" },
				["~"] = { char = "󰰱", hl_group = "ObsidianTilde" },
				["!"] = { char = "", hl_group = "ObsidianImportant" },
			},
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

		local map = function(lhs, rhs, desc)
			vim.keymap.set("n", lhs, rhs, { desc = desc, silent = true })
		end

		-- <leader>o... = Obsidian
		map("<leader>oo", "<cmd>Obsidian quick_switch<CR>", "Buscar nota por nombre")
		map("<leader>of", "<cmd>Obsidian search<CR>", "Grep en el vault")
		map("<leader>on", "<cmd>Obsidian new<CR>", "Nota nueva")
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
		vim.keymap.set("v", "<leader>oe", ":<C-u>Obsidian extract_note<CR>", { desc = "Extraer selección a nota nueva" })
	end,
}
