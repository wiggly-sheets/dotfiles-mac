-- Update with path to stats_provider
sbar.exec('killall stats_provider >/dev/null; ~/.config/sketchybar/stats_provider-0.6.3-aarch64-apple-darwin/stats_provider --disk usage ')

-- Subscribe and use the `DISK_USAGE` var
local disk = sbar.add('item', 'disk', {
	position = 'right',
})
disk:subscribe('system_stats', function(env)
	disk:set { label = env.DISK_USAGE }
end)


