-- Shared graph normalizer for the sketch-style items (network + disk IO).
--
-- Adaptive graph normalizer: EMA-smooths the raw rate, tracks a
-- rolling-window peak as the scale ceiling (so a burst dominates the
-- graph briefly, then ages out after the window samples rather than
-- fading out slowly), and applies a power curve (not log) so mid/low
-- activity stays visibly distinct instead of being squashed near the
-- bottom or over-inflated by log's generosity near the top.
local GRAPH_ALPHA = 0.4 -- EMA smoothing factor (higher = more responsive, jumpier)
local GRAPH_WINDOW = 8 -- samples of "peak memory" (10 * 2s update = ~20s)
local GRAPH_POWER = 0.45 -- <1 lifts low values; 1 = linear; higher = more log-like compression

-- window_size defaults to GRAPH_WINDOW; pass a larger value for graphs
-- that want a longer-lived peak (disk IO).
local function make_graph_normalizer(min_ceiling, window_size)
	window_size = window_size or GRAPH_WINDOW

	local ema = 0
	local window = {}
	return function(raw)
		ema = ema + GRAPH_ALPHA * (raw - ema)

		table.insert(window, ema)
		if #window > window_size then
			table.remove(window, 1)
		end

		local ceiling = min_ceiling
		for _, v in ipairs(window) do
			if v > ceiling then
				ceiling = v
			end
		end

		local ratio = math.min(ema / ceiling, 1)
		return math.max(ratio ^ GRAPH_POWER, 0.02)
	end
end

return {
	GRAPH_ALPHA = GRAPH_ALPHA,
	GRAPH_WINDOW = GRAPH_WINDOW,
	GRAPH_POWER = GRAPH_POWER,
	make_graph_normalizer = make_graph_normalizer,
}