local lunajson = require("lunajson")
local file = require("utils.file")
local tbl = require("utils.tbl")

local function load_config()
	local config = {
		font = require("helpers.default_font"),
		icons = "sf-symbols", -- alternatively available: NerdFont
		weather = {
			location = false,
			use_shortcut = false,
		},
	}

	local config_filepath = os.getenv("CONFIG_DIR") .. "/config.json"
	local content, error = file.read(config_filepath)
	if not error then
		local json_content = lunajson.decode(content)
		tbl.merge(config, json_content)
	end
	return config
end

return load_config()
