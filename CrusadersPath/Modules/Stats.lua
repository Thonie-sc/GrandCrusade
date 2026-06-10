-- Crusader's Path :: Stats
-- The tally of the crusade: areas purged, time spent on each holy ground,
-- undead slain, and the times the crusader has fallen.

local ADDON, ns = ...

local Stats = {}
ns.Stats = ns.RegisterModule(Stats)

local activeId, activeStart
local eventFrame

local function S() return ns.db.profile.stats end

-- Fold any elapsed active time into the store, then restart the clock.
function Stats:FlushTime()
	if activeId and activeStart then
		local s = S()
		s.time[activeId] = (s.time[activeId] or 0) + (GetTime() - activeStart)
		activeStart = GetTime()
	end
end

-- Mark which holy ground the crusader currently stands upon (for time tracking).
function Stats:SetActive(id)
	self:FlushTime()
	activeId = id
	activeStart = GetTime()
end

function Stats:RecordArea(id, status)
	S().areas[id] = { status = status, time = time() }
end

-- Getters for the tally screen ------------------------------------------------
function Stats:GetTime(id)
	local t = S().time[id] or 0
	if id == activeId and activeStart then
		t = t + (GetTime() - activeStart)
	end
	return t
end

function Stats:GetKills(id) return S().kills[id] or 0 end
function Stats:GetDeaths(id) return S().deaths[id] or 0 end
function Stats:GetAreaStatus(id)
	local a = S().areas[id]
	return a and a.status or nil
end

-- Count fulfilled quests across the whole route.
function Stats:CountQuests()
	local done, total = 0, 0
	for _, bracket in ipairs(ns.Route) do
		local saved = ns.db.char.questsDone[bracket.id]
		for i, q in ipairs(bracket.quests) do
			total = total + 1
			local complete = false
			if q.id and C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
				and C_QuestLog.IsQuestFlaggedCompleted(q.id) then
				complete = true
			elseif saved and saved[i] then
				complete = true
			end
			if complete then done = done + 1 end
		end
	end
	return done, total
end

function Stats:TotalTime()
	local total = 0
	for _, bracket in ipairs(ns.Route) do
		total = total + self:GetTime(bracket.id)
	end
	return total
end

-- Events ----------------------------------------------------------------------
local function OnEvent(_, event)
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		local _, sub, _, sourceGUID = CombatLogGetCurrentEventInfo()
		if sub == "PARTY_KILL" and sourceGUID == UnitGUID("player") then
			if activeId then
				local s = S()
				s.kills[activeId] = (s.kills[activeId] or 0) + 1
				if ns.GuidePanel then ns.GuidePanel:OnKill(activeId) end
			end
		end
	elseif event == "PLAYER_DEAD" then
		if activeId then
			local s = S()
			s.deaths[activeId] = (s.deaths[activeId] or 0) + 1
		end
	elseif event == "PLAYER_LOGOUT" then
		Stats:FlushTime()
	end
end

function Stats:OnEnable()
	eventFrame = CreateFrame("Frame")
	eventFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	eventFrame:RegisterEvent("PLAYER_DEAD")
	eventFrame:RegisterEvent("PLAYER_LOGOUT")
	eventFrame:SetScript("OnEvent", OnEvent)
	-- Tracker:SetActive will be called from Tracker once it determines the bracket.
end
