return {
	"obsidian-nvim/obsidian.nvim",
	version = "*", -- usa el último release estable, no main
	lazy = true,
	-- Solo carga cuando abres un .md dentro del vault (arranque rápido)
	event = {
		"BufReadPre " .. vim.fn.expand("~") .. "/Portafolio/Obsidian-Vault/**.md",
		"BufNewFile " .. vim.fn.expand("~") .. "/Portafolio/Obsidian-Vault/**.md",
	},
	dependencies = {
		"nvim-lua/plenary.nvim", -- requerido
		"nvim-telescope/telescope.nvim", -- picker
	},
	opts = {
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
			date_format = "%Y-%m-%d",
			alias_format = "%d de %B, %Y",
			template = "diario.md",
		},

		templates = {
			folder = "99-templates",
			date_format = "%Y-%m-%d",
			time_format = "%H:%M",
		},

		attachments = {
			img_folder = "98-assets",
		},

		-- ============================================
		-- Comportamiento
		-- ============================================
		-- Nombre de archivo: usa el título que escribes, no un ID random.
		-- Si no das título, cae a timestamp para no colisionar.
		note_id_func = function(title)
			if title ~= nil then
				-- minúsculas, sin acentos raros, guiones en vez de espacios
				return title:gsub(" ", "-"):gsub("[^A-Za-z0-9-_À-ÿ]", ""):lower()
			end
			return tostring(os.time())
		end,

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

		-- Enlaces como [[nota|Alias bonito]] al autocompletar
		wiki_link_func = "prepend_note_id",
		preferred_link_style = "wiki",

		completion = {
			nvim_cmp = true, -- ya tienes nvim-cmp
			min_chars = 2,
		},

		picker = {
			name = "telescope.nvim",
		},

		-- Abrir URLs / imágenes con el visor del sistema
		follow_url_func = function(url)
			vim.fn.jobstart({ "xdg-open", url })
		end,
		follow_img_func = function(img)
			vim.fn.jobstart({ "xdg-open", img })
		end,

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
	},

	config = function(_, opts)
		require("obsidian").setup(opts)

		-- conceal necesario para que los [[links]] se vean limpios
		vim.opt_local.conceallevel = 2

		local map = function(lhs, rhs, desc)
			vim.keymap.set("n", lhs, rhs, { desc = desc, silent = true })
		end

		-- <leader>o... = Obsidian
		map("<leader>oo", "<cmd>Obsidian quick_switch<CR>", "Buscar nota por nombre")
		map("<leader>of", "<cmd>Obsidian search<CR>", "Grep en el vault")
		map("<leader>on", "<cmd>Obsidian new<CR>", "Nota nueva")
		map("<leader>ot", "<cmd>Obsidian today<CR>", "Diario de hoy")
		map("<leader>oy", "<cmd>Obsidian yesterday<CR>", "Diario de ayer")
		map("<leader>ob", "<cmd>Obsidian backlinks<CR>", "Qué notas apuntan a esta")
		map("<leader>ol", "<cmd>Obsidian links<CR>", "Links salientes de esta nota")
		map("<leader>og", "<cmd>Obsidian tags<CR>", "Buscar por tag")
		map("<leader>oT", "<cmd>Obsidian template<CR>", "Insertar template")
		map("<leader>or", "<cmd>Obsidian rename<CR>", "Renombrar nota (actualiza links)")
		map("<leader>op", "<cmd>Obsidian paste_img<CR>", "Pegar imagen del clipboard")
		map("<leader>oc", "<cmd>Obsidian toggle_checkbox<CR>", "Toggle checkbox")
		map("<leader>oO", "<cmd>Obsidian open<CR>", "Abrir esta nota en la app")

		-- gf funciona sobre [[wikilinks]]
		vim.keymap.set("n", "gf", function()
			if require("obsidian").util.cursor_on_markdown_link() then
				return "<cmd>Obsidian follow_link<CR>"
			end
			return "gf"
		end, { noremap = false, expr = true, desc = "Seguir link" })

		-- Enter también sigue el link (más natural para navegar)
		vim.keymap.set("n", "<CR>", function()
			if require("obsidian").util.cursor_on_markdown_link() then
				return "<cmd>Obsidian follow_link<CR>"
			end
			return "<CR>"
		end, { noremap = false, expr = true, buffer = true, desc = "Seguir link" })

		-- Crear nota desde selección visual: seleccionas texto -> se vuelve link + nota
		vim.keymap.set("v", "<leader>on", ":<C-u>Obsidian link_new<CR>", { desc = "Nota nueva desde selección" })
		vim.keymap.set("v", "<leader>ok", ":<C-u>Obsidian link<CR>", { desc = "Linkear selección a nota existente" })
	end,
}
