-- Crusader's Path :: Minimap
-- The sigil of the Light upon the minimap - gateway to the guide, the tally,
-- and the rites (settings).

local ADDON, ns = ...

local Minimap = {}
ns.Minimap = ns.RegisterModule(Minimap)

local LDB = LibStub("LibDataBroker-1.1", true)
local DBIcon = LibStub("LibDBIcon-1.0", true)
local dataObject

local function CurrentSummary()
	local id = ns.db.char.currentBracket or 1
	local b = ns.GetBracket(id)
	if not b then return "The crusade is won." end
	return ("%s (Lvl %d-%d)"):format(b.subzone or b.zone, b.min, b.max)
end

function Minimap:UpdateText()
	if dataObject then
		dataObject.text = CurrentSummary()
	end
end

local function OnClick(_, button)
	if button == "RightButton" then
		if ns.Options then ns.Options:Open() end
	elseif IsShiftKeyDown() then
		if ns.StatsPanel then ns.StatsPanel:Toggle() end
	else
		if ns.GuidePanel then ns.GuidePanel:Toggle() end
	end
end

local function OnTooltipShow(tooltip)
	local purged = 0
	for _, b in ipairs(ns.Route) do
		if ns.Stats:GetAreaStatus(b.id) == "purged" then purged = purged + 1 end
	end

	tooltip:AddLine(ns.Gold("Crusader's Path"))
	tooltip:AddLine(ns.Pale("Onward, champion of the Light."), 1, 1, 1)
	tooltip:AddLine(" ")
	tooltip:AddLine(ns.Pale("Holy ground: ") .. ns.Holy(CurrentSummary()))
	tooltip:AddLine(ns.Pale("Grounds purged: ") .. ns.Gold(purged .. " / " .. ns.LastBracketId))
	tooltip:AddLine(" ")
	tooltip:AddLine("|cffffff00Left-click|r  reveal the crusade guide")
	tooltip:AddLine("|cffffff00Shift-click|r  the tally of your crusade")
	tooltip:AddLine("|cffffff00Right-click|r  the rites and settings")
end

function Minimap:OnEnable()
	if not LDB then return end

	dataObject = LDB:NewDataObject("CrusadersPath", {
		type = "data source",
		text = CurrentSummary(),
		icon = "Interface\\Icons\\Spell_Holy_HolyBolt",
		OnClick = OnClick,
		OnTooltipShow = OnTooltipShow,
	})

	if DBIcon then
		DBIcon:Register("CrusadersPath", dataObject, ns.db.profile.minimap)
	end

	self:UpdateText()
end

function Minimap:SetHidden(hidden)
	ns.db.profile.minimap.hide = hidden and true or false
	if DBIcon then
		if hidden then DBIcon:Hide("CrusadersPath") else DBIcon:Show("CrusadersPath") end
	end
end
