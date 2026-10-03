-- Full bar: every item, including the ones hidden behind the toggle chevron.
return {
	items = {
		"items.left.spaces",
		"items.left.menus",
		"items.right.notifications",
		"items.right.date_time",
		"items.right.control_center",
		"items.right.time_machine",
		"items.right.caffeinate",
		"items.right.folder",
		"items.right.dnd",
		"items.right.bluetooth",
		"items.right.wifi",
		"items.right.battery",
		"items.right.display",
		"items.right.audio",
		"items.right.weather",
		"items.right.network",
		"items.right.temperature",
		"items.right.cpu_ram",
		"items.right.storage",
		-- must load last: it hides the items created by the modules above
		"items.right.toggle_items",
	},
	brackets = { "time", "toggle_items", "padding" },
}
