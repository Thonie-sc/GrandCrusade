-- Crusader's Path :: Core
-- Initialises the addon, the saved-variable database, shared flavor helpers,
-- and the /crusade command. Modules (Tracker, Notify, Directions, ...) live as
-- sub-tables on `ns` and are enabled here.

local ADDON, ns = ...

local CP = LibStub("AceAddon-3.0"):NewAddon("CrusadersPath", "AceConsole-3.0", "AceEvent-3.0")
ns.addon = CP
ns.modules = {} -- registered module list, enabled in order

-- ---------------------------------------------------------------------------
-- Shared flavor helpers (the voice of the Light)
-- ---------------------------------------------------------------------------
ns.GOLD = "fff0d27a"
ns.PALE = "ffe8e0c8"
ns.HOLY = "ff66ccff"

function ns.Gold(text) return "|c" .. ns.GOLD .. (text or "") .. "|r" end
function ns.Pale(text) return "|c" .. ns.PALE .. (text or "") .. "|r" end
function ns.Holy(text) return "|c" .. ns.HOLY .. (text or "") .. "|r" end

ns.TITLE = "Crusader's Path"
ns.CHAT_PREFIX = ns.Gold("[Crusader's Path] ")

function ns.Print(text)
	DEFAULT_CHAT_FRAME:AddMessage(ns.CHAT_PREFIX .. (text or ""))
end

-- ---------------------------------------------------------------------------
-- Difficulty (con) reckoning
-- ---------------------------------------------------------------------------
-- The level at/below which a mob is trivial (grey) for the given player level.
local function GreyLevel(playerLevel)
	if playerLevel <= 5 then
		return 0
	elseif playerLevel <= 39 then
		return playerLevel - math.floor(playerLevel / 10) - 5
	elseif playerLevel <= 59 then
		return playerLevel - math.floor(playerLevel / 5) - 1
	else
		return playerLevel - 9
	end
end

-- Con of a mob level relative to the player. Returns r, g, b (0-1) and a name.
-- Mirrors the classic creature difficulty scale.
function ns.Con(mobLevel, playerLevel)
	playerLevel = playerLevel or UnitLevel("player")
	local diff = mobLevel - playerLevel
	if diff >= 5 then
		return 1.0, 0.10, 0.10, "deadly"          -- red
	elseif diff >= 3 then
		return 1.0, 0.50, 0.00, "tough"            -- orange
	elseif diff >= -2 then
		return 1.0, 0.82, 0.00, "even"             -- yellow
	elseif mobLevel > GreyLevel(playerLevel) then
		return 0.25, 0.75, 0.25, "easy"            -- green
	else
		return 0.55, 0.55, 0.55, "trivial"         -- grey
	end
end

-- ---------------------------------------------------------------------------
-- Database defaults
-- ---------------------------------------------------------------------------
local defaults = {
	char = {
		currentBracket = 1,
		-- progress[id] = "purged" (cleansed live) | "met" (already above level at install)
		progress = {},
		questsDone = {},        -- questsDone[bracketId][questIndex] = true
		directionsText = nil,   -- last set of directions shown in the Path frame
		milestones = {},        -- announced milestone keys, to avoid repeats
	},
	profile = {
		bannerEnabled = true,
		soundEnabled = true,
		autoShowPanel = true,
		showDirections = true,
		heatmapEnabled = true,
		arrivalCues = true,
		milestonesEnabled = true,
		lockFrames = false,
		minimap = { hide = false },             -- consumed by LibDBIcon
		panelPoint = nil,                       -- { point, x, y }
		directionsPoint = { "BOTTOMRIGHT", -20, 220 },
		stats = {
			-- per bracket id:
			areas = {},   -- areas[id] = { status = "purged"|"met", time = <epoch> }
			time = {},    -- time[id] = seconds spent while this bracket was active
			kills = {},   -- kills[id] = count
			deaths = {},  -- deaths[id] = count
		},
	},
}

-- ---------------------------------------------------------------------------
-- Module registration
-- ---------------------------------------------------------------------------
function ns.RegisterModule(module)
	ns.modules[#ns.modules + 1] = module
	return module
end

-- ---------------------------------------------------------------------------
-- Lifecycle
-- ---------------------------------------------------------------------------
function CP:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("CrusadersPathDB", defaults, true)
	ns.db = self.db

	for _, module in ipairs(ns.modules) do
		if module.OnInit then module:OnInit() end
	end

	self:RegisterChatCommand("crusade", "OnSlash")
	self:RegisterChatCommand("cp", "OnSlash")
end

function CP:OnEnable()
	for _, module in ipairs(ns.modules) do
		if module.OnEnable then module:OnEnable() end
	end
end

-- ---------------------------------------------------------------------------
-- Slash command :: /crusade
-- ---------------------------------------------------------------------------
function CP:OnSlash(input)
	input = (input or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	local cmd, rest = input:match("^(%S*)%s*(.*)$")

	if cmd == "" or cmd == "guide" or cmd == "panel" then
		if ns.GuidePanel then ns.GuidePanel:Toggle() end
	elseif cmd == "path" or cmd == "directions" then
		if ns.Directions then ns.Directions:Toggle() end
	elseif cmd == "stats" then
		if ns.StatsPanel then ns.StatsPanel:Toggle() end
	elseif cmd == "config" or cmd == "options" or cmd == "settings" then
		if ns.Options then ns.Options:Open() end
	elseif cmd == "purge" then
		-- debug: preview a purge banner. /crusade purge [bracketId]
		local id = tonumber(rest) or (ns.db.char.currentBracket)
		id = math.max(1, math.min(id, ns.LastBracketId))
		if ns.Notify then ns.Notify:Purge(id, true) end
	elseif cmd == "reset" then
		StaticPopup_Show("CRUSADERSPATH_RESET")
	else
		ns.Print("Heed these commands, faithful one:")
		ns.Print(ns.Gold("/crusade") .. " - reveal or hide the crusade guide")
		ns.Print(ns.Gold("/crusade path") .. " - reveal or hide the Path of Light")
		ns.Print(ns.Gold("/crusade stats") .. " - the tally of your crusade")
		ns.Print(ns.Gold("/crusade config") .. " - the rites and settings")
		ns.Print(ns.Gold("/crusade purge [n]") .. " - witness an area's cleansing (a vision)")
		ns.Print(ns.Gold("/crusade reset") .. " - begin the crusade anew")
	end
end

-- Reset confirmation
StaticPopupDialogs["CRUSADERSPATH_RESET"] = {
	text = "Forsake all progress and begin the crusade anew, from the first holy ground?",
	button1 = YES,
	button2 = NO,
	OnAccept = function()
		local c = ns.db.char
		c.currentBracket = 1
		wipe(c.progress)
		wipe(c.questsDone)
		c.directionsText = nil
		local s = ns.db.profile.stats
		wipe(s.areas); wipe(s.time); wipe(s.kills); wipe(s.deaths)
		if ns.Tracker then ns.Tracker:Reconcile() end
		if ns.Directions then ns.Directions:Resolve() end
		if ns.GuidePanel then ns.GuidePanel:Refresh() end
		ns.Print("The crusade is renewed. Go forth, and let the Light guide your blade.")
	end,
	timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}
