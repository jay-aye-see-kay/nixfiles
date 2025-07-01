return {
	{
		"andrewferrier/debugprint.nvim",
		lazy = true,
		event = "VeryLazy",
		opts = {
			print_tag = "DEBUG",
			display_location = false,
			filetypes = {
				["go"] = {
					left = 'fmt.Printf("',
					right = '\\n")',
					mid_var = '%+v\\n", ',
					right_var = ")",
				},
			},
			highlight_lines = false,
		},
	},
}
