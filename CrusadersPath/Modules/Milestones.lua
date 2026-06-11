-- Crusader's Path :: Milestones
-- A "welcome back" recap on login and one-time toasts as the crusade reaches
-- notable tallies (undead slain) and its completion.

local ADDON, ns = ...

local Milestones = {}
ns.Milestones = ns.RegisterModule(Milestones)

local KILL_TIERS = { 100, 250, 500, 1000, 2500, 5000, 10000 }

local function Sound()
	if SOUNDKIT and SOUNDKIT.IG_QUEST_LIST_COMPLETE then
		PlaySound(SOUNDKIT.IG_QUEST_LIST_COMPLETE, "Master")
	end
end

local function FormatTime(sec)
	sec = math.floor(sec or 0)
	local h = math.floor(sec / 3600)
	local m = math.floor((sec % 3600) / 60)
	if h > 0 then return ("%dh %dm"):format(h, m) end
	return ("%dm"):format(m)
end

local function Announce(text)
	if not ns.db.profile.milestonesEnabled then return end
	ns.Print(ns.Gold("* ") .. text)
	Sound()
end

local function Seen(key) return ns.db.char.milestones[key] end
local function Mark(key) ns.db.char.milestones[key] = true end

-- Login recap -----------------------------------------------------------------
local function LoginSummary()
	local id = ns.db.char.currentBracket or 1
	local bracket = ns.GetBracket(id)

	ns.Print(ns.Gold("Welcome back, crusader of the Light."))
	if bracket then
		ns.Print(ns.Pale("Holy ground: ") .. ns.Holy(bracket.subzone or bracket.zone)
			.. ns.Pale((" (Lvl %d-%d)"):format(bracket.min, bracket.max)))
	end
	ns.Print(ns.Pale(("Grounds cleared %s  *  Undead slain %s  *  Time %s"):format(
		ns.Gold(ns.Stats:ClearedCount() .. "/" .. ns.LastBracketId),
		ns.Gold(tostring(ns.Stats:TotalKills())),
		ns.Gold(FormatTime(ns.Stats:TotalTime())))))
	if bracket and UnitLevel("player") < 60 and ns.Pace then
		ns.Print(ns.Pale("The Light foresees ") .. ns.Pace:Summary(bracket)
			.. ns.Pale(" to the next ground."))
	end
end

-- Hooks -----------------------------------------------------------------------
function Milestones:OnKill()
	if not ns.db.profile.milestonesEnabled then return end
	local total = ns.Stats:TotalKills()
	for _, tier in ipairs(KILL_TIERS) do
		local key = "kill_" .. tier
		if total >= tier and not Seen(key) then
			Mark(key)
			Announce(ns.Gold(tostring(tier)) .. ns.Pale(" undead have fallen to your blade. The Light is well served."))
		end
	end
end

-- Called by the Tracker after a live purge advances the crusade.
function Milestones:OnPurge()
	if ns.Stats:ClearedCount() >= ns.LastBracketId and not Seen("complete") then
		Mark("complete")
		Announce(ns.Gold("The crusade is complete. Every holy ground is cleansed. Rise, champion - the Light honors you."))
	end
end

function Milestones:OnEnable()
	-- Defer the recap so Tracker:Reconcile and Pace have settled first.
	if C_Timer and C_Timer.After then
		C_Timer.After(1.5, LoginSummary)
	else
		LoginSummary()
	end
end
