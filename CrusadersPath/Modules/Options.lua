-- Crusader's Path :: Options
-- The rites and settings, in the voice of the Light.

local ADDON, ns = ...

local Options = {}
ns.Options = ns.RegisterModule(Options)

local function get(info) return ns.db.profile[info[#info]] end
local function set(info, value) ns.db.profile[info[#info]] = value end

local optionsTable = {
	type = "group",
	name = "Crusader's Path",
	args = {
		intro = {
			type = "description", order = 1, fontSize = "medium",
			name = "Bear the Light across the undead lands. Set the rites of your crusade below.\n",
		},
		heraldry = {
			type = "group", inline = true, order = 10, name = "Heralds of the Purge",
			args = {
				bannerEnabled = {
					type = "toggle", order = 1, width = "full",
					name = "Proclaim each cleansing",
					desc = "Show the holy banner across the heavens when a ground is purged.",
					get = get, set = set,
				},
				soundEnabled = {
					type = "toggle", order = 2, width = "full",
					name = "Sound the bell and holy nova",
					desc = "Let the cathedral bell toll and the Light ring out when a ground is purged.",
					get = get, set = set,
				},
			},
		},
		frames = {
			type = "group", inline = true, order = 20, name = "The Crusader's Sight",
			args = {
				autoShowPanel = {
					type = "toggle", order = 1, width = "full",
					name = "Reveal the guide upon arrival",
					desc = "Unveil the crusade guide whenever you set foot on the active holy ground.",
					get = get, set = set,
				},
				showDirections = {
					type = "toggle", order = 2, width = "full",
					name = "Show the Path of Light",
					desc = "Keep the bottom-right Path frame, which bears your travel directions, in view.",
					get = get,
					set = function(info, value)
						set(info, value)
						if ns.Directions then ns.Directions:SetShown(value) end
					end,
				},
				lockFrames = {
					type = "toggle", order = 3, width = "full",
					name = "Anchor the holy frames",
					desc = "Lock the guide and the Path of Light in place, that they not be moved by mortal hands.",
					get = get, set = set,
				},
				hideMinimap = {
					type = "toggle", order = 4, width = "full",
					name = "Hide the minimap sigil",
					desc = "Remove the sigil of the Light from the minimap.",
					get = function() return ns.db.profile.minimap.hide end,
					set = function(_, value) if ns.Minimap then ns.Minimap:SetHidden(value) end end,
				},
			},
		},
		auguries = {
			type = "group", inline = true, order = 25, name = "Auguries of the Light",
			args = {
				heatmapEnabled = {
					type = "toggle", order = 1, width = "full",
					name = "Reveal the undead upon the map",
					desc = "Mark the known undead camps of your holy ground on the world map, colored by their menace.",
					get = get,
					set = function(info, value)
						set(info, value)
						if ns.HeatMap then ns.HeatMap:Update() end
					end,
				},
				milestonesEnabled = {
					type = "toggle", order = 2, width = "full",
					name = "Herald the crusade's milestones",
					desc = "Announce a recap on login and the great tallies of undead slain as they are reached.",
					get = get, set = set,
				},
				arrivalCues = {
					type = "toggle", order = 3, width = "full",
					name = "Hail each holy ground",
					desc = "Sound a chime and a word of the Light when you first set foot upon the active ground.",
					get = get, set = set,
				},
			},
		},
		deeds = {
			type = "group", inline = true, order = 30, name = "Deeds",
			args = {
				stats = {
					type = "execute", order = 1,
					name = "Behold the tally",
					desc = "Open the tally of your crusade.",
					func = function() if ns.StatsPanel then ns.StatsPanel:Toggle() end end,
				},
				resetPos = {
					type = "execute", order = 2,
					name = "Restore the frames",
					desc = "Return the guide and Path of Light to their appointed places.",
					func = function()
						ns.db.profile.panelPoint = nil
						ns.db.profile.directionsPoint = { "BOTTOMRIGHT", -20, 220 }
						if ns.GuidePanel then ns.GuidePanel:ApplyPosition() end
						if ns.Directions then ns.Directions:OnEnable() end
						ns.Print("The holy frames are restored to their places.")
					end,
				},
				reset = {
					type = "execute", order = 3,
					name = "Begin the crusade anew",
					desc = "Forsake all progress and start again from the first holy ground.",
					func = function() StaticPopup_Show("CRUSADERSPATH_RESET") end,
				},
			},
		},
	},
}

function Options:OnEnable()
	local AceConfig = LibStub("AceConfig-3.0")
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")
	AceConfig:RegisterOptionsTable("CrusadersPath", optionsTable)
	self.dialog = AceConfigDialog
	self.blizz = AceConfigDialog:AddToBlizOptions("CrusadersPath", "Crusader's Path")
end

function Options:Open()
	if self.dialog then
		self.dialog:Open("CrusadersPath")
	end
end
