-- Crusader's Path :: Route data
-- The sacred pilgrimage of the undead-only crusade, 1 -> 60.
-- One entry per area ("bracket"). `max` is the level at which the area is PURGED
-- and the crusade advances to the next holy ground.
--
-- Quest entries: { name = "Display Name", id = <questID or nil> }
--   When `id` is set, completion auto-detects via C_QuestLog.IsQuestFlaggedCompleted.
--   When `id` is nil, the faithful tick the quest by hand. The manual path is always
--   available, so a missing id never blocks the guidance.

local ADDON, ns = ...

ns.Route = {
	{
		id = 1, min = 1, max = 6,
		zone = "Tirisfal Glades", subzone = "Deathknell",
		quests = {},
		travel = "Your crusade begins in Deathknell, where the newly risen wake. The crypt lies just beyond the chapel - descend, and cleanse it.",
		purge = "The crypt of Deathknell lies silent. Its restless dead trouble the living no more. Onward, crusader.",
	},
	{
		id = 2, min = 6, max = 10,
		zone = "Tirisfal Glades", subzone = "Agamand Mills",
		quests = {},
		travel = "March north and west along the road from Brill; the brooding Agamand farmsteads crown the hills. Carry the Light to them.",
		purge = "The Agamand dead are scattered to ash. Their mill grinds no longer. The Light marches north.",
	},
	{
		id = 3, min = 10, max = 13,
		zone = "Silverpine Forest", subzone = "The Dead Field",
		quests = {},
		travel = "Journey south out of Tirisfal into Silverpine Forest. The Dead Field festers near the Sepulcher - let it rot no longer.",
		purge = "The Dead Field is sown with salt and sanctified. Press on to Fenris.",
	},
	{
		id = 4, min = 13, max = 17,
		zone = "Silverpine Forest", subzone = "Fenris Isle",
		quests = {},
		travel = "Travel east to the shore of Lordamere Lake; Fenris Isle waits across the cold water. Cross, and break its cursed lords.",
		purge = "Fenris Isle is cleansed of its cursed lords. Let Ambermill be next.",
	},
	{
		id = 5, min = 17, max = 20,
		zone = "Silverpine Forest", subzone = "Ambermill",
		quests = {},
		travel = "Follow the southern road to Ambermill on the lake's far bank; sanctify the graves you find there.",
		purge = "Ambermill's graves rest quiet beneath the Light. Silverpine is purified - south, to Duskwood.",
	},
	{
		id = 6, min = 20, max = 24,
		zone = "Duskwood", subzone = "Raven Hill Cemetery",
		quests = {
			{ name = "The Night Watch (Part 1)" },
			{ name = "The Night Watch (Part 2)" },
			{ name = "The Night Watch (Part 3)" },
			{ name = "Rotting Horrors" },
			{ name = "Zombie Juice" },
			{ name = "Skeleton Fingers" },
			{ name = "Gather Rot Blossoms" },
		},
		travel = "Make the long pilgrimage south to Duskwood, by way of Stormwind's roads. In the forest's west lies Raven Hill - its cemetery cries for cleansing.",
		purge = "Raven Hill's risen are laid to rest once more. This ground is hallowed.",
	},
	{
		id = 7, min = 24, max = 26,
		zone = "Duskwood", subzone = "Tranquil Gardens Cemetery",
		quests = {},
		travel = "Bear east along the Duskwood road; Tranquil Gardens rests in the heart of the wood. Bring it true peace.",
		purge = "Tranquil Gardens is tranquil in truth at last. The Light holds this place.",
	},
	{
		id = 8, min = 26, max = 30,
		zone = "Duskwood", subzone = "Raven Hill",
		quests = {
			{ name = "Mor'Ladim" },
		},
		travel = "Walk the road between Raven Hill and Tranquil Gardens and hold it well, for Mor'Ladim stalks this ground. Stand fast, and end him.",
		purge = "Mor'Ladim falls, and Duskwood breathes free of his shadow. A great evil is undone.",
	},
	{
		id = 9, min = 30, max = 32,
		zone = "Hillsbrad Foothills", subzone = "Azurelode Mine",
		quests = {
			{ name = "Elixir of Suffering" },
			{ name = "Elixir of Pain" },
		},
		travel = "Return north to Hillsbrad Foothills; the Azurelode bores into the hills below Tarren Mill. Descend, and purge its brew.",
		purge = "The Azurelode is purged of its festering brew. Hillsbrad is the cleaner for it.",
	},
	{
		id = 10, min = 32, max = 36,
		zone = "Alterac Mountains", subzone = "Ruins of Alterac",
		quests = {},
		travel = "Climb north and east into the Alterac Mountains; the old ruins crown the snowy heights. Sweep them clean.",
		purge = "The ruins of Alterac are swept clean. The mountains echo with the Light's hymn.",
	},
	{
		id = 11, min = 36, max = 40,
		zone = "Western Plaguelands", subzone = "The Weeping Cave",
		quests = {},
		travel = "Press east through the mountains into the Western Plaguelands. At its western marches, the true crusade begins.",
		purge = "The borderlands of the Western Plague are broken open. The true crusade begins.",
	},
	{
		id = 12, min = 40, max = 46,
		zone = "Western Plaguelands", subzone = "Sorrow Hill",
		quests = {
			{ name = "A Call to Arms: The Plaguelands!" },
			{ name = "Clear the Way" },
		},
		travel = "Travel east to Sorrow Hill, near the chapel grounds; answer the fallen who lie there.",
		purge = "Sorrow Hill knows sorrow no longer. Its fallen are answered with steel and Light.",
	},
	{
		id = 13, min = 46, max = 50,
		zone = "Western Plaguelands", subzone = "Andorhal",
		quests = {
			{ name = "All Along the Watchtowers" },
			{ name = "Skeletal Fragments" },
		},
		travel = "March west upon the ruined city of Andorhal; reclaim its watchtowers from the Scourge.",
		purge = "Andorhal's watchtowers stand reclaimed. The Scourge is driven from its streets.",
	},
	{
		id = 14, min = 50, max = 56,
		zone = "Western Plaguelands", subzone = "Felstone Field",
		quests = {
			{ name = "Target: Felstone Field" },
			{ name = "Scourge Cauldrons" },
		},
		travel = "Ride the circuit of the plagued fields north of Andorhal - Felstone chief among them. Find the cauldron, and shatter it.",
		purge = "The cauldron of Felstone is shattered. Its poison will choke the land no more.",
	},
	{
		id = 15, min = 56, max = 58,
		zone = "Eastern Plaguelands", subzone = "Corin's Crossing",
		quests = {
			{ name = "Carrion Grubbage" },
			{ name = "Defenders of Darrowshire" },
			{ name = "Hameya's Plea" },
			{ name = "Zaeldarr the Outcast" },
		},
		travel = "Cross east into the Eastern Plaguelands; Corin's Crossing smolders at the central roads. Avenge it.",
		purge = "Corin's Crossing is avenged, and Darrowshire's dead defended. The east trembles before the Light.",
	},
	{
		id = 16, min = 58, max = 60,
		zone = "Eastern Plaguelands", subzone = "Northdale",
		quests = {},
		travel = "Journey north to Northdale in the blighted east; there, finish the great work.",
		purge = "Northdale is cleansed, and the Eastern Plague yields. Your crusade is complete, champion. Rise, and be honored.",
	},
}

-- Directions from each Alliance starting area to the FIRST holy ground (Deathknell, Tirisfal).
-- Keyed by the locale-independent race token: select(2, UnitRace("player")).
ns.RaceIntro = {
	Human = "Rise in Northshire and make for Stormwind. Take the Deeprun Tram to Ironforge, then march east through Loch Modan and the Wetlands; press north through Arathi and Hillsbrad, into Silverpine, and at last unto Tirisfal Glades and the village of Deathknell.",
	Dwarf = "From Coldridge Valley descend through Kharanos to Ironforge. March east through Loch Modan and the Wetlands, then north through Arathi, Hillsbrad, and Silverpine, until you reach Tirisfal Glades and Deathknell.",
	Gnome = "From Coldridge Valley descend through Kharanos to Ironforge. March east through Loch Modan and the Wetlands, then north through Arathi, Hillsbrad, and Silverpine, until you reach Tirisfal Glades and Deathknell.",
	NightElf = "From Shadowglen, sail from Rut'theran to Auberdine, and take ship to Stormwind Harbor. Ride the Tram to Ironforge, march east through Loch Modan and the Wetlands, then north through Arathi, Hillsbrad, and Silverpine, into Tirisfal Glades and Deathknell.",
}

ns.RaceIntroFallback = "Make your way to Tirisfal Glades, in the north of Lordaeron, and to the village of Deathknell where your crusade begins."

-- Convenience: find the route entry for a given id.
function ns.GetBracket(id)
	return ns.Route[id]
end

ns.LastBracketId = #ns.Route

-- ---------------------------------------------------------------------------
-- Experience reckoning
-- ---------------------------------------------------------------------------
-- XP required to advance FROM level L to L+1 (Classic 1.12 values), L = 1..59.
ns.XP_TO_NEXT = {
	[1] = 400, [2] = 900, [3] = 1400, [4] = 2100, [5] = 2800,
	[6] = 3600, [7] = 4500, [8] = 5400, [9] = 6500, [10] = 7600,
	[11] = 8800, [12] = 10100, [13] = 11400, [14] = 12900, [15] = 14400,
	[16] = 16000, [17] = 17700, [18] = 19400, [19] = 21300, [20] = 23200,
	[21] = 25200, [22] = 27300, [23] = 29400, [24] = 31700, [25] = 34000,
	[26] = 36400, [27] = 38900, [28] = 41400, [29] = 44300, [30] = 47400,
	[31] = 50800, [32] = 54500, [33] = 58600, [34] = 62800, [35] = 67100,
	[36] = 71600, [37] = 76100, [38] = 80800, [39] = 85700, [40] = 90700,
	[41] = 95800, [42] = 101000, [43] = 106300, [44] = 111800, [45] = 117500,
	[46] = 123200, [47] = 129100, [48] = 135100, [49] = 141200, [50] = 147500,
	[51] = 153900, [52] = 160400, [53] = 167100, [54] = 173900, [55] = 180800,
	[56] = 187900, [57] = 195000, [58] = 202300, [59] = 209800,
}

local function RoundUpToTen(n)
	return math.ceil(n / 10) * 10
end

-- Estimate how many undead must fall to advance through an area, from the total
-- XP across its level span and the average XP of a same-level mob in that span.
-- Returns: mobsNeeded (rounded up to the nearest ten), totalXP, avgMobXP.
function ns.MobsToPurge(bracket)
	if not bracket then return 0, 0, 0 end
	local totalXP = 0
	for L = bracket.min, bracket.max - 1 do
		totalXP = totalXP + (ns.XP_TO_NEXT[L] or 0)
	end
	-- Average mob: a same-level kill yields (level * 5 + 45) base XP in Classic.
	local avgLevel = math.floor((bracket.min + bracket.max) / 2)
	local avgMobXP = avgLevel * 5 + 45
	if avgMobXP <= 0 then return 0, totalXP, avgMobXP end
	return RoundUpToTen(totalXP / avgMobXP), totalXP, avgMobXP
end
