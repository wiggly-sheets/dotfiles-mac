-- Reads the app -> glyph mapping from sketchybar-app-font.ttf's `meta` table (APPM).
local M = { exact = {}, prefix = {}, by_ligature = {}, release = nil }

local FONT_PATHS = {
	os.getenv("HOME") .. "/Library/Fonts/sketchybar-app-font.ttf",
	"/Library/Fonts/sketchybar-app-font.ttf",
}

local function read_file(path)
	local f = io.open(path, "rb")
	if not f then return nil end
	local d = f:read("a")
	f:close()
	return d
end

-- Minimal JSON decoder (null -> false)
local function decode_json(s)
	local pos = 1
	local value
	local function ws() pos = s:find("%S", pos) or (#s + 1) end
	local esc = { b = "\b", f = "\f", n = "\n", r = "\r", t = "\t" }

	local function str()
		local out, i = {}, pos + 1
		while true do
			local j = s:find('["\\]', i)
			out[#out + 1] = s:sub(i, j - 1)
			if s:sub(j, j) == '"' then pos = j + 1; break end
			local e = s:sub(j + 1, j + 1)
			if e == "u" then
				local cp = tonumber(s:sub(j + 2, j + 5), 16)
				i = j + 6
				if cp >= 0xD800 and cp < 0xDC00 and s:sub(i, i + 1) == "\\u" then
					local lo = tonumber(s:sub(i + 2, i + 5), 16)
					cp = 0x10000 + ((cp - 0xD800) << 10) + (lo - 0xDC00)
					i = i + 6
				end
				out[#out + 1] = utf8.char(cp)
			else
				out[#out + 1] = esc[e] or e
				i = j + 2
			end
		end
		return table.concat(out)
	end

	value = function()
		ws()
		local c = s:sub(pos, pos)
		if c == "[" then
			pos = pos + 1
			local arr = {}
			ws()
			if s:sub(pos, pos) == "]" then pos = pos + 1; return arr end
			while true do
				arr[#arr + 1] = value()
				ws()
				local d = s:sub(pos, pos); pos = pos + 1
				if d == "]" then return arr end
			end
		elseif c == "{" then
			pos = pos + 1
			local obj = {}
			ws()
			if s:sub(pos, pos) == "}" then pos = pos + 1; return obj end
			while true do
				ws(); local k = str(); ws(); pos = pos + 1 -- skip ':'
				obj[k] = value(); ws()
				local d = s:sub(pos, pos); pos = pos + 1
				if d == "}" then return obj end
			end
		elseif c == '"' then
			return str()
		elseif s:sub(pos, pos + 3) == "null" then pos = pos + 4; return false
		elseif s:sub(pos, pos + 3) == "true" then pos = pos + 4; return true
		elseif s:sub(pos, pos + 4) == "false" then pos = pos + 5; return false
		else
			local n = s:match("^-?%d+%.?%d*[eE]?[+-]?%d*", pos)
			pos = pos + #n
			return tonumber(n)
		end
	end

	return value()
end

local function load_appm(buf)
	local num_tables = string.unpack(">I2", buf, 5)
	local meta
	for i = 0, num_tables - 1 do
		local o = 12 + i * 16
		if buf:sub(o + 1, o + 4) == "meta" then
			meta = string.unpack(">I4", buf, o + 9)
			break
		end
	end
	if not meta then return nil end

	local count = string.unpack(">I4", buf, meta + 13)
	for j = 0, count - 1 do
		local r = meta + 16 + j * 12
		if buf:sub(r + 1, r + 4) == "APPM" then
			local off = string.unpack(">I4", buf, r + 5)
			local len = string.unpack(">I4", buf, r + 9)
			return decode_json(buf:sub(meta + off + 1, meta + off + len))
		end
	end
end

local function init()
	local buf
	for _, p in ipairs(FONT_PATHS) do
		buf = read_file(p)
		if buf then break end
	end
	if not buf then return end

	local ok, data = pcall(load_appm, buf)
	if not ok or not data then return end

	M.release = data.release
	for _, ic in ipairs(data.icons) do
		local lig, cp, names = ic[1], ic[2], ic[3]
		local ch = utf8.char(cp)
		M.by_ligature[lig] = ch
		if names then
			for _, n in ipairs(names) do
				if n:sub(-1) == "*" then
					M.prefix[#M.prefix + 1] = { n:sub(1, -2), ch }
				else
					M.exact[n] = ch
				end
			end
		end
	end
	table.sort(M.prefix, function(a, b) return #a[1] > #b[1] end) -- longest prefix wins
end

init()

M.default = M.by_ligature[":default:"]

local cache = {}
function M.get(app)
	local hit = cache[app]
	if hit ~= nil then return hit or nil end
	local r = M.exact[app]
	if not r then
		for _, p in ipairs(M.prefix) do
			if app:sub(1, #p[1]) == p[1] then r = p[2]; break end
		end
	end
	cache[app] = r or false
	return r
end

return M