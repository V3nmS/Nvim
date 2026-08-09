-- ============================================
-- Preview de markdown en chromium, tileado a la derecha
-- ============================================
-- El preview NO se renderiza en la terminal: una terminal no sabe pintar HTML,
-- y todo lo bueno de Markdown Preview Enhanced (KaTeX para las fórmulas,
-- mermaid para los diagramas) es JavaScript corriendo en una página real.
--
-- Así que el plugin levanta un servidor local y chromium lo abre en modo --app
-- (sin barra de direcciones ni pestañas, solo el contenido). Hyprland lo tilea
-- a la derecha por una regla que hace match con --class=mdpreview.
--
-- El scroll sincronizado va por websocket: mueves el cursor en nvim y la página
-- se desplaza sola. Eso lo trae el plugin, no hay que programarlo.
--
-- Regla de Hyprland asociada: ~/.config/hypr/lua/windowrules.lua -> "mdpreview"
return {
	"iamcco/markdown-preview.nvim",
	-- Carga perezosa por comando: el servidor de node no arranca hasta que
	-- pides el preview, así que abrir un .md cualquiera no cuesta nada.
	cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
	ft = { "markdown" },
	-- El build documentado es `vim.fn["mkdp#util#install"]()`, pero truena con
	-- E117: lazy corre el build justo después del clone, cuando el plugin todavía
	-- no está en el runtimepath y su autoload no existe. Llamar al script directo
	-- se salta el problema; hace lo mismo: baja el binario del servidor a app/bin.
	build = "cd app && bash install.sh",

	-- El keymap va aquí y NO en `config`: con carga perezosa, `config` solo corre
	-- cuando el plugin ya cargó, así que un keymap definido ahí nunca existiría
	-- para dispararlo. `keys` registra un stub que carga el plugin al presionarlo.
	-- El `ft` lo hace buffer-local: <leader>mp solo vive dentro de un markdown.
	keys = {
		{
			"<leader>mp",
			"<cmd>MarkdownPreviewToggle<CR>",
			ft = "markdown",
			desc = "Preview de markdown (chromium a la derecha)",
		},
	},

	-- Las vim.g.mkdp_* van en `init`, NO en `config`: el plugin las lee al
	-- cargarse. Si las pones en config ya es tarde y se queda con los defaults.
	init = function()
		vim.g.mkdp_filetypes = { "markdown" }
		vim.g.mkdp_auto_start = 0 -- no abrir solo al entrar a un .md
		vim.g.mkdp_auto_close = 1 -- cerrar la ventana al salir del buffer
		vim.g.mkdp_refresh_slow = 0 -- refrescar mientras escribes, no solo al :w
		vim.g.mkdp_command_for_global = 0 -- comandos solo en los filetypes de arriba
		vim.g.mkdp_echo_preview_url = 0
		vim.g.mkdp_theme = "dark"

		-- SEGURIDAD: 0 = el servidor escucha solo en 127.0.0.1.
		-- En 1 lo expone a toda la red local, o sea cualquiera en tu wifi puede
		-- leer la nota que tengas abierta. Déjalo en 0.
		vim.g.mkdp_open_to_the_world = 0

		-- Reusar una sola ventana para todos los buffers en vez de abrir una por
		-- nota. Sin esto acabas con seis chromium tileados y la pantalla en confeti.
		vim.g.mkdp_combine_preview = 1
		vim.g.mkdp_combine_preview_auto_refresh = 1

		vim.g.mkdp_preview_options = {
			mkit = {}, -- opciones de markdown-it
			katex = {}, -- fórmulas $...$ y $$...$$
			uml = {}, -- PlantUML
			maid = {}, -- mermaid
			disable_sync_scroll = 0, -- 0 = la ventana sigue a tu cursor
			sync_scroll_type = "middle", -- la línea del cursor queda a media pantalla
			hide_yaml_meta = 1, -- ocultar el frontmatter de obsidian.nvim
			sequence_diagrams = {},
			flowchart_diagrams = {},
			content_editable = false,
			disable_filename = 0,
			toc = {},
		}

		-- ============================================
		-- Cómo se abre el navegador
		-- ============================================
		-- `mkdp_browser` solo acepta un ejecutable pelón, sin flags, y sin flags
		-- chromium abre una pestaña normal en tu sesión de siempre. Por eso se usa
		-- `mkdp_browserfunc`, que deja lanzarlo a mano.
		--
		-- El puente vimscript->lua es el mismo patrón que usas en obsidian.lua para
		-- el autocompletado de carpetas: el plugin hace `call Func(url)` en
		-- vimscript, así que la función tiene que existir de ese lado.
		-- OJO CON --class: en Wayland chromium la ignora por completo. Es una flag
		-- de X11. Verificado en tu máquina: lanzándolo con --class=mdpreview,
		-- Hyprland reportaba `chrome-localhost__-Default`.
		--
		-- El app_id real que chromium publica en Wayland tiene la forma
		--     chrome-<host_de_la_url>__-<nombre_del_perfil>
		-- así que la palanca para controlarlo es `--profile-directory`, no --class.
		-- Con --profile-directory=mdpreview el app_id queda en
		--     chrome-localhost__-mdpreview
		-- que es único y no cambia aunque el servidor agarre otro puerto.
		-- Ese string es el que matchea la regla en windowrules.lua: si cambias uno,
		-- cambia el otro.
		_G.__v3nom_mkdp_open = function(url)
			vim.fn.jobstart({
				"chromium",
				-- Modo app: ventana limpia, sin barra de direcciones ni pestañas.
				"--app=" .. url,
				-- Perfil aparte: no toca tu sesión, cookies ni extensiones, y evita
				-- que chromium se "reconecte" a tu instancia normal y abra el preview
				-- como una pestaña más (donde ninguna regla de ventana aplicaría).
				"--user-data-dir=" .. vim.fn.expand("~/.cache/mdpreview-chromium"),
				"--profile-directory=mdpreview",
				"--no-first-run",
				"--no-default-browser-check",
			}, { detach = true })
		end

		vim.cmd([[
			function! V3nomMkdpOpen(url) abort
				call v:lua.__v3nom_mkdp_open(a:url)
			endfunction
		]])

		vim.g.mkdp_browserfunc = "V3nomMkdpOpen"
	end,
}
