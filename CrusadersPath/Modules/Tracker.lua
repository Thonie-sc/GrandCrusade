-- Crusader's Path :: Tracker
-- Watches the crusader's level and whereabouts. Advances the crusade, fires the
-- purge banner when an area is out-levelled, and - for those who do not begin at
-- level 1 - marks already-conquered grounds as fulfilled.

local ADDON, ns = ...

local Tracker = {}
ns.Tracker = ns.RegisterModule(Tracker)

local eventFrame
local wasInArea = false

-- Is the crusader standing in the zone of the given holy ground?
-- Granularity is the zone (the active ground is chosen by level, not position),
-- so a zone match is enough to surface that ground's quests.
function ns.IsInArea(bracket)
	if not bracket then return false end
	return GetZoneText() == bracket.zone
end

-- For installs that do not begin at level 1: mark every ground already below the
-- crusader's level as "met", and set the active ground to the first unfinished one.
function Tracker:Reconcile()
	local lvl = UnitLevel("player")
	local c = ns.db.char

	for _, b in ipairs(ns.Route) do
		if b.max <= lvl and not c.progress[b.id] then
			c.progress[b.id] = "met"
			ns.Stats:RecordArea(b.id, "met")
		end
	end

	local cur = ns.LastBracketId
	for _, b in ipairs(ns.Route) do
		if lvl < b.max then cur = b.id; break end
	end
	c.currentBracket = cur
	ns.Stats:SetActive(cur)
end

local function OnLevelUp(newLevel)
	newLevel = newLevel or UnitLevel("player")
	local c = ns.db.char

	while true do
		local b = ns.GetBracket(c.currentBracket)
		if not b then break end
		if newLevel >= b.max and c.progress[b.id] ~= "purged" then
			c.progress[b.id] = "purged"
			ns.Stats:RecordArea(b.id, "purged")
			ns.Notify:Purge(b.id)
			c.currentBracket = math.min(c.currentBracket + 1, ns.LastBracketId)
			ns.Stats:SetActive(c.currentBracket)
			if ns.Milestones then ns.Milestones:OnPurge(b.id) end
		else
			break
		end
	end

	ns.Directions:Resolve()
	ns.GuidePanel:Refresh()
end

local function OnZoneChanged()
	-- Persist time spent so far into the area total whenever the crusader moves.
	ns.Stats:FlushTime()
	ns.Directions:Resolve()
	ns.GuidePanel:Refresh()
	if ns.Minimap then ns.Minimap:UpdateText() end

	local bracket = ns.GetBracket(ns.db.char.currentBracket)
	local inArea = ns.IsInArea(bracket)

	-- Reveal the guide when the crusader first sets foot on the active holy ground.
	if ns.db.profile.autoShowPanel and inArea then
		ns.GuidePanel:Show()
	end

	-- Arrival cue: announce only on the false->true transition into the ground.
	if inArea and not wasInArea and ns.db.profile.arrivalCues and bracket then
		if SOUNDKIT and SOUNDKIT.IG_QUEST_LIST_OPEN then
			PlaySound(SOUNDKIT.IG_QUEST_LIST_OPEN, "Master")
		end
		ns.Print(ns.Gold("You set foot upon " .. (bracket.subzone or bracket.zone)
			.. ". Cleanse it in the Light's name."))
	end
	wasInArea = inArea
end

local function OnEvent(_, event, arg1)
	if event == "PLAYER_LEVEL_UP" then
		OnLevelUp(tonumber(arg1))
	else
		OnZoneChanged()
	end
end

function Tracker:OnEnable()
	-- All other modules are enabled by now; reconcile then paint everything.
	self:Reconcile()
	ns.Directions:Resolve()
	ns.GuidePanel:Refresh()
	if ns.Minimap then ns.Minimap:UpdateText() end

	-- Seed arrival state so logging in inside the active ground is not announced.
	wasInArea = ns.IsInArea(ns.GetBracket(ns.db.char.currentBracket))

	eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("PLAYER_LEVEL_UP")
	eventFrame:RegisterEvent("ZONE_CHANGED")
	eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	eventFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
	eventFrame:SetScript("OnEvent", OnEvent)
end
