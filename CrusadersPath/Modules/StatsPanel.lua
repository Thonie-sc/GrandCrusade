-- Crusader's Path :: StatsPanel
-- The tally screen, summoned from the minimap sigil or /crusade stats.

local ADDON, ns = ...

local StatsPanel = {}
ns.StatsPanel = ns.RegisterModule(StatsPanel)

local AceGUI = LibStub("AceGUI-3.0")
local frame, scroll

local function FormatTime(sec)
	sec = math.floor(sec or 0)
	if sec <= 0 then return "-" end
	local h = math.floor(sec / 3600)
	local m = math.floor((sec % 3600) / 60)
	if h > 0 then return ("%dh %dm"):format(h, m) end
	local s = sec % 60
	if m > 0 then return ("%dm %ds"):format(m, s) end
	return ("%ds"):format(s)
end

local function StatusText(id)
	local current = ns.db.char.currentBracket or 1
	local status = ns.Stats:GetAreaStatus(id)
	if status == "purged" then
		return ns.Gold("PURGED")
	elseif status == "met" then
		return ns.Pale("met by prior valor")
	elseif id == current then
		return ns.Holy("the crusade is here")
	else
		return "|cff808080yet to come|r"
	end
end

local function AddLine(text)
	local label = AceGUI:Create("Label")
	label:SetFullWidth(true)
	label:SetText(text)
	label:SetFontObject(GameFontHighlightSmall)
	scroll:AddChild(label)
end

local function Populate()
	scroll:ReleaseChildren()

	local purged = 0
	for _, b in ipairs(ns.Route) do
		if ns.Stats:GetAreaStatus(b.id) == "purged" then purged = purged + 1 end
	end
	local qDone, qTotal = ns.Stats:CountQuests()

	local heading = AceGUI:Create("Label")
	heading:SetFullWidth(true)
	heading:SetFontObject(GameFontNormalLarge)
	heading:SetText(ns.Gold("The tally of your crusade"))
	scroll:AddChild(heading)

	AddLine(ns.Pale(("Holy grounds purged: %s of %d"):format(ns.Gold(tostring(purged)), ns.LastBracketId)))
	AddLine(ns.Pale(("Quests fulfilled: %s of %d"):format(ns.Gold(tostring(qDone)), qTotal)))
	AddLine(ns.Pale(("Undead slain: %s   *   Times fallen: %s"):format(
		ns.Gold(tostring((function() local k = 0 for _, b in ipairs(ns.Route) do k = k + ns.Stats:GetKills(b.id) end return k end)())),
		ns.Gold(tostring((function() local d = 0 for _, b in ipairs(ns.Route) do d = d + ns.Stats:GetDeaths(b.id) end return d end)()))
	)))
	AddLine(ns.Pale("Time upon the crusade: " .. ns.Gold(FormatTime(ns.Stats:TotalTime()))))

	local spacer = AceGUI:Create("Label")
	spacer:SetFullWidth(true); spacer:SetText(" ")
	scroll:AddChild(spacer)

	for _, b in ipairs(ns.Route) do
		local name = ns.Gold(b.subzone or b.zone)
		local meta = ("Lvl %d-%d  *  %s"):format(b.min, b.max, b.zone)
		AddLine(("%s\n%s   %s"):format(name, ns.Pale(meta), StatusText(b.id)))
		AddLine(ns.Pale(("   time %s   *   slain %d   *   fallen %d"):format(
			FormatTime(ns.Stats:GetTime(b.id)), ns.Stats:GetKills(b.id), ns.Stats:GetDeaths(b.id))))
		local gap = AceGUI:Create("Label"); gap:SetFullWidth(true); gap:SetText(" ")
		scroll:AddChild(gap)
	end
end

function StatsPanel:Toggle()
	if frame then
		frame:Release()
		frame, scroll = nil, nil
		return
	end
	frame = AceGUI:Create("Frame")
	frame:SetTitle("Crusader's Path - The Tally")
	frame:SetStatusText("For the Light, and for Lordaeron.")
	frame:SetLayout("Fill")
	frame:SetWidth(460)
	frame:SetHeight(520)
	frame:SetCallback("OnClose", function(widget)
		widget:Release()
		frame, scroll = nil, nil
	end)

	scroll = AceGUI:Create("ScrollFrame")
	scroll:SetLayout("List")
	frame:AddChild(scroll)

	Populate()
end

function StatsPanel:RefreshIfShown()
	if frame and scroll then Populate() end
end
