return {
	"chrisbra/csv.vim",
	ft = { "csv" }, -- load only for CSV files
	config = function()
		vim.g.csv_delim = "," -- default delimiter
	end,
}
