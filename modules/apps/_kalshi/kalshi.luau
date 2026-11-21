-- Kalshi cash balance. Hidden ("••••") until clicked; a click toggles it and
-- refreshes on reveal. @BALANCE@ is replaced with the script's store path by
-- modules/apps/kalshi.nix, so this doesn't depend on noctalia.service's PATH.
noctalia.setUpdateInterval(1000)

local REFRESH = 300 -- seconds
local elapsed = REFRESH -- fetch on the first tick
local revealed = false
local amount = nil -- last good balance text
local err = nil -- last failure, cleared on success
local updatedAt = nil

function refresh()
	elapsed = 0
	noctalia.runAsync("@BALANCE@", function(res)
		local out = noctalia.string.trim(res.stdout or "")
		if res.exitCode == 0 then
			amount, err = out, nil
			updatedAt = noctalia.formatTime("%H:%M")
		else
			err = out ~= "" and out or "kalshi-balance failed"
		end
	end)
end

function update()
	elapsed += 1
	if elapsed >= REFRESH then
		refresh()
	end
	if err then
		-- No stale number: show the failure instead.
		barWidget.setGlyph("alert-triangle")
		barWidget.setGlyphColor("error")
		barWidget.setText(revealed and "error" or "••••")
		barWidget.setTooltip("Kalshi: " .. err)
		return
	end
	barWidget.setGlyph("coins")
	barWidget.setGlyphColor("on_surface")
	barWidget.setText(revealed and (amount or "…") or "••••")
	barWidget.setTooltip(updatedAt and ("Kalshi cash, updated " .. updatedAt) or "Kalshi cash")
end

function onClick()
	revealed = not revealed
	if revealed then
		refresh()
	end
end
