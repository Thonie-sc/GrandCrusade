-- Crusader's Path :: Pace
-- Live reckoning of the crusade's pace from the player's actual experience:
-- undead remaining to the next holy ground, an ETA, and experience per hour.

local ADDON, ns = ...

local Pace = {}
ns.Pace = ns.RegisterModule(Pace)

local WINDOW = 600          -- seconds of history used for the xp/hour estimate
local MIN_SPAN = 30         -- need at least this much history before trusting a rate

local samples = {}          -- { {t = GetTime(), xp = sessionXP}, ... }
local sessionXP = 0         -- cumulative xp gained this session
local lastXP, lastXPMax
local killXPSum, killCount = 0, 0
local lastKillAt = 0
local eventFrame, ticker

-- Average xp per undead: measured once we have a handful of kills, else the
-- classic same-level fallback (level * 5 + 45).
local function AvgKillXP()
	if killCount >= 5 then
		return killXPSum / killCount
	end
	return UnitLevel("player") * 5 + 45
end

local function XPPerHour()
	local now = GetTime()
	-- oldest sample still inside the window
	local oldest
	for _, s in ipairs(samples) do
		if now - s.t <= WINDOW then oldest = s; break end
	end
	if not oldest then return 0 end
	local span = now - oldest.t
	if span < MIN_SPAN then return 0 end
	return (sessionXP - oldest.xp) / span * 3600
end

local function Record(gained)
	if gained <= 0 then return end
	sessionXP = sessionXP + gained
	local now = GetTime()
	samples[#samples + 1] = { t = now, xp = sessionXP }
	-- prune anything older than the window (keep one extra as the anchor)
	while #samples > 2 and (now - samples[1].t) > WINDOW do
		table.remove(samples, 1)
	end
	-- attribute to a kill if one landed a moment ago (excludes quest turn-ins)
	if now - lastKillAt <= 1.5 then
		killXPSum = killXPSum + gained
		killCount = killCount + 1
	end
end

local function Format(n)
	n = math.floor(n + 0.5)
	if n >= 10000 then return ("%.0fk"):format(n / 1000) end
	if n >= 1000 then return ("%.1fk"):format(n / 1000) end
	return tostring(n)
end

-- The live pace line for the guide panel.
function Pace:Summary(bracket)
	if not bracket or UnitLevel("player") >= 60 then
		return ns.Gold("The crusade nears its end.")
	end

	local xpToEnd = ns.XPToBracketEnd(bracket)
	if xpToEnd <= 0 then
		return ns.Gold("This ground is all but conquered - press on.")
	end

	local mobs = math.ceil(xpToEnd / AvgKillXP())
	local rate = XPPerHour()

	local parts = ("~%d undead"):format(mobs)
	if rate > 0 then
		local etaMin = math.ceil(xpToEnd / rate * 60)
		parts = parts .. (" * ~%dm"):format(etaMin)
		parts = parts .. (" * %s xp/hr"):format(Format(rate))
	end
	if (GetXPExhaustion() or 0) > 0 then
		parts = parts .. " " .. ns.Holy("(rested)")
	end
	return ns.Gold(parts)
end

local function RefreshGuide()
	if ns.GuidePanel and ns.GuidePanel.RefreshEstimate then
		ns.GuidePanel:RefreshEstimate()
	end
end

local function OnEvent(_, event, arg1)
	if event == "PLAYER_XP_UPDATE" then
		local cur = UnitXP("player") or 0
		local gained = cur - (lastXP or 0)
		if gained < 0 then gained = cur end          -- wrapped on a level-up
		Record(gained)
		lastXP, lastXPMax = cur, UnitXPMax("player")
		RefreshGuide()
	elseif event == "PLAYER_LEVEL_UP" then
		-- Count the remainder of the level just finished, then resync.
		if lastXP and lastXPMax then
			Record(math.max(0, lastXPMax - lastXP))
		end
		lastXP, lastXPMax = UnitXP("player") or 0, UnitXPMax("player")
		RefreshGuide()
	elseif event == "PLAYER_UPDATE_RESTING" then
		RefreshGuide()
	end
end

-- Called by Stats when the player lands a killing blow.
function Pace:NoteKill()
	lastKillAt = GetTime()
end

function Pace:OnEnable()
	lastXP, lastXPMax = UnitXP("player") or 0, UnitXPMax("player")

	eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("PLAYER_XP_UPDATE")
	eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
	eventFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
	eventFrame:SetScript("OnEvent", OnEvent)

	-- Keep the ETA / xp-hr fresh while the guide is open.
	if C_Timer and C_Timer.NewTicker then
		ticker = C_Timer.NewTicker(5, RefreshGuide)
	end
end
