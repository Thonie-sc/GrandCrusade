-- Crusader's Path :: Directions
-- The persistent "Path of Light" frame, anchored bottom-right by default.
-- It holds the last set of directions given - the race-intro pilgrimage at the
-- start, then each holy ground's travel directions as the crusade advances.

local ADDON, ns = ...

local Directions = {}
ns.Directions = ns.RegisterModule(Directions)

local frame

local function SavePosition()
	local point, _, _, x, y = frame:GetPoint()
	ns.db.profile.directionsPoint = { point, x, y }
end

local function Build()
	if frame then return frame end

	local f = CreateFrame("Frame", "CrusadersPathDirections", UIParent, "BackdropTemplate")
	f:SetSize(320, 150)
	f:SetClampedToScreen(true)
	f:SetMovable(true)
	f:EnableMouse(true)
	f:RegisterForDrag("LeftButton")
	f:SetScript("OnDragStart", function(self)
		if not ns.db.profile.lockFrames then self:StartMoving() end
	end)
	f:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		SavePosition()
	end)

	if f.SetBackdrop then
		f:SetBackdrop({
			bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
			tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		})
		f:SetBackdropColor(0, 0, 0, 0.78)
		f:SetBackdropBorderColor(0.8, 0.7, 0.35, 1)
	end

	local header = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	header:SetPoint("TOPLEFT", 12, -10)
	header:SetPoint("TOPRIGHT", -12, -10)
	header:SetJustifyH("CENTER")
	header:SetText(ns.Gold("The Path of Light"))
	f.header = header

	local body = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	body:SetPoint("TOPLEFT", 14, -36)
	body:SetPoint("TOPRIGHT", -14, -36)
	body:SetJustifyH("LEFT")
	body:SetJustifyV("TOP")
	body:SetSpacing(2)
	f.body = body

	frame = f
	return f
end

local function ApplyPosition()
	local p = ns.db.profile.directionsPoint or { "BOTTOMRIGHT", -20, 220 }
	frame:ClearAllPoints()
	frame:SetPoint(p[1] or "BOTTOMRIGHT", UIParent, p[1] or "BOTTOMRIGHT", p[2] or -20, p[3] or 220)
end

-- Resize the frame to wrap its body text.
local function FitToText()
	local h = frame.body:GetStringHeight() or 60
	frame:SetHeight(math.max(90, h + 56))
end

function Directions:Set(text)
	Build()
	ns.db.char.directionsText = text
	frame.body:SetText(ns.Pale(text or ""))
	FitToText()
	if ns.db.profile.showDirections then
		frame:Show()
	end
end

-- Recompute the correct directions from current crusade state.
function Directions:Resolve()
	Build()
	local c = ns.db.char
	local id = c.currentBracket or 1
	local bracket = ns.GetBracket(id)

	local text
	-- A brand-new crusade (nothing met/purged) and not yet in Tirisfal: show the
	-- race pilgrimage to the first holy ground.
	if id == 1 and not c.progress[1] and (GetZoneText() ~= "Tirisfal Glades") then
		local _, raceToken = UnitRace("player")
		text = ns.RaceIntro[raceToken] or ns.RaceIntroFallback
	elseif bracket then
		text = bracket.travel
	else
		text = "Your crusade is complete. The Light shines upon you, champion."
	end

	self:Set(text)
end

function Directions:SetShown(shown)
	Build()
	ns.db.profile.showDirections = shown and true or false
	if shown then
		frame:Show()
		self:Resolve()
	else
		frame:Hide()
	end
end

function Directions:Toggle()
	Build()
	local nowShown = not ns.db.profile.showDirections
	self:SetShown(nowShown)
	ns.Print(nowShown and "The Path of Light is revealed." or "The Path of Light is veiled.")
end

function Directions:UpdateLock()
	-- nothing persistent needed; drag handlers consult lockFrames live
end

function Directions:OnEnable()
	Build()
	ApplyPosition()
	if not ns.db.profile.showDirections then
		frame:Hide()
	end
	-- Tracker:Reconcile (run in its OnEnable) sets currentBracket before this if
	-- ordering allows; regardless we resolve here for a correct first paint.
	self:Resolve()
end
