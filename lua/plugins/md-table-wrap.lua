-- ============================================================
-- Tablas markdown que caben en la ventana, con wrap prendido
-- ============================================================
-- render-markdown no puede dibujar tablas bien con `wrap`: Neovim parte la
-- línea cruda antes del conceal (limitación documentada, issue #82). Este
-- plugin oculta las líneas fuente con `conceal_lines` (nvim >= 0.11) y dibuja
-- en su lugar una tabla ajustada al ancho, con el texto envuelto dentro de
-- cada celda. El buffer nunca se modifica.
--
-- Con el cursor encima solo la fila actual se ve cruda; en insert vuelve el
-- markdown fuente para editar. `:MdTableWrap` lo apaga/prende en el buffer.
return {
	"walkersumida/md-table-wrap.nvim",
	ft = { "markdown" },
	opts = {
		min_col_width = 8,
	},
}
