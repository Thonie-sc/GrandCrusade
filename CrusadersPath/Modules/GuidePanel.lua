-- Crusader's Path :: GuidePanel
-- The crusade guide. Shows the current holy ground, its level span, the Light's
-- estimate of how many undead must fall to advance, and - when the faithful
-- stand upon that ground - the quests to fulfil there. The frame's height is
-- fitted to its contents.

local ADDON, ns = ...

local GuidePanel = {}
ns.GuidePanel = ns.RegisterModule(GuidePanel)

local FRAME_W = 300
local CONTENT_INSET = 10
local CONTENT_W = FRAME_W - CONTENT_INSET * 2
local LABEL_W = CONTENT_W - 34          -- room for the checkbox
local PAD, SECTION_GAP, ROW_GAP, BOTTOM_PAD = 12, 6, 4, 12
local MIN_H = 120

local frame
local rows = {}
local displayedId

local function SavePosition()
	local point, _, _, x, y = frame:GetPoint()
	ns.db.profile.panelPoint = { point, x, y }
end

local function AcquireRow(index)
	if rows[index] then return rows[index] end
	local parent = frame.content
	local row = CreateFrame("CheckButton", "CrusadersPathQuestRow" .. index, parent, "UICheckButtonTemplate")
	row:SetSize(22, 22)
	local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("TOPLEFT", row, "TOPRIGHT", 4, -3)
	label:SetWidth(LABEL_W)
	label:SetJustifyH("LEFT")
	label:SetWordWrap(true)
	row.label = label
	rows[index] = row
	return row
end

local function Build()
	if frame then return frame end

	local f = CreateFrame("Frame", "CrusadersPathGuide", UIParent, "BackdropTemplate")
	f:SetSize(FRAME_W, MIN_H)
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
		f:SetBackdropColor(0, 0, 0, 0.82)
		f:SetBackdropBorderColor(0.8, 0.7, 0.35, 1)
	end

	local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetJustifyH("CENTER")
	f.title = title

	local sub = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	sub:SetJustifyH("CENTER")
	f.sub = sub

	local estimate = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	estimate:SetJustifyH("CENTER")
	estimate:SetSpacing(2)
	f.estimate = estimate

	local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 0, 0)
	close:SetScript("OnClick", function() GuidePanel:Hide() end)

	local content = CreateFrame("Frame", nil, f)
	content:SetWidth(CONTENT_W)
	f.content = content

	local directive = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	directive:SetPoint("TOPLEFT", content, "TOPLEFT", 2, -2)
	directive:SetWidth(CONTENT_W - 4)
	directive:SetJustifyH("LEFT")
	directive:SetJustifyV("TOP")
	directive:SetSpacing(2)
	f.directive = directive

	frame = f
	return f
end

-- Position a top-anchored header FontString and return its measured height.
local function PlaceHeader(fs, y)
	fs:ClearAllPoints()
	fs:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, -y)
	fs:SetWidth(FRAME_W - PAD * 2)
	return fs:GetStringHeight()
end

local function HideRows()
	for _, row in ipairs(rows) do row:Hide() end
end

-- The Light's estimate line for the given area.
local function EstimateText(bracket)
	local needed = ns.MobsToPurge(bracket)
	local slain = ns.Stats:GetKills(bracket.id)
	return ns.Gold(("The Light foresees ~%d undead must fall here."):format(needed))
		.. "\n" .. ns.Pale(("Slain upon this ground: %d of ~%d"):format(slain, needed))
end

-- Lay quests/directive into the content frame; returns the content height.
local function LayoutContent(bracket, inArea)
	if not bracket then
		HideRows()
		frame.directive:Show()
		frame.directive:SetText(ns.Pale("Rest now, champion. The Light shines upon you."))
		return frame.directive:GetStringHeight() + 4
	end

	if not inArea then
		HideRows()
		frame.directive:Show()
		frame.directive:SetText(ns.Pale("The Light bids you onward - consult the Path of Light to reach this holy ground."))
		return frame.directive:GetStringHeight() + 4
	end

	if #bracket.quests == 0 then
		HideRows()
		frame.directive:Show()
		frame.directive:SetText(ns.Pale("No quests burden this ground - simply cleanse the undead until you are ready to march on."))
		return frame.directive:GetStringHeight() + 4
	end

	frame.directive:Hide()
	ns.db.char.questsDone[bracket.id] = ns.db.char.questsDone[bracket.id] or {}
	local done = ns.db.char.questsDone[bracket.id]

	local y = 0
	for i, q in ipairs(bracket.quests) do
		local row = AcquireRow(i)
		local locked = q.id and C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
			and C_QuestLog.IsQuestFlaggedCompleted(q.id)
		local checked = locked or (done[i] and true) or false
		row:SetChecked(checked)
		if locked then
			row:SetEnabled(false)
			row:SetScript("OnClick", nil)
		else
			row:SetEnabled(true)
			row:SetScript("OnClick", function(self)
				done[i] = self:GetChecked() and true or nil
				GuidePanel:Refresh()
				if ns.StatsPanel then ns.StatsPanel:RefreshIfShown() end
			end)
		end
		row.label:SetText(checked and ns.Gold(q.name) or ns.Pale(q.name))

		row:ClearAllPoints()
		row:SetPoint("TOPLEFT", frame.content, "TOPLEFT", 2, -y)
		row:Show()

		local rowH = math.max(22, row.label:GetStringHeight() + 4)
		y = y + rowH + ROW_GAP
	end
	for i = #bracket.quests + 1, #rows do rows[i]:Hide() end

	return y
end

function GuidePanel:Refresh()
	Build()
	local id = ns.db.char.currentBracket or 1
	local bracket = ns.GetBracket(id)
	displayedId = bracket and id or nil

	-- Header texts
	if bracket then
		frame.title:SetText(ns.Gold("Crusade: " .. (bracket.subzone or bracket.zone)))
		frame.sub:SetText(ns.Pale(("Levels %d - %d  *  %s"):format(bracket.min, bracket.max, bracket.zone)))
		frame.estimate:SetText(EstimateText(bracket))
		frame.estimate:Show()
	else
		frame.title:SetText(ns.Gold("The Crusade is Won"))
		frame.sub:SetText(ns.Pale("Every holy ground is cleansed."))
		frame.estimate:SetText("")
		frame.estimate:Hide()
	end

	-- Lay out top-down, measuring as we go.
	local y = PAD
	y = y + PlaceHeader(frame.title, y) + SECTION_GAP
	y = y + PlaceHeader(frame.sub, y)
	if bracket then
		y = y + SECTION_GAP
		y = y + PlaceHeader(frame.estimate, y)
	end
	y = y + SECTION_GAP

	frame.content:ClearAllPoints()
	frame.content:SetPoint("TOPLEFT", frame, "TOPLEFT", CONTENT_INSET, -y)

	local inArea = ns.IsInArea and ns.IsInArea(bracket)
	local contentH = LayoutContent(bracket, inArea)
	frame.content:SetHeight(math.max(1, contentH))

	frame:SetHeight(math.max(MIN_H, y + contentH + BOTTOM_PAD))
end

-- Cheap live refresh of just the estimate line as undead fall.
function GuidePanel:OnKill(id)
	if not frame or not frame:IsShown() then return end
	if id ~= displayedId then return end
	local bracket = ns.GetBracket(id)
	if bracket then
		frame.estimate:SetText(EstimateText(bracket))
	end
end

function GuidePanel:ApplyPosition()
	Build()
	local p = ns.db.profile.panelPoint
	frame:ClearAllPoints()
	if p then
		frame:SetPoint(p[1] or "CENTER", UIParent, p[1] or "CENTER", p[2] or 0, p[3] or 0)
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 260, 60)
	end
end

function GuidePanel:Show()
	Build()
	ns.db.char.panelShown = true
	frame:Show()
	self:Refresh()
end

function GuidePanel:Hide()
	Build()
	ns.db.char.panelShown = false
	frame:Hide()
end

function GuidePanel:Toggle()
	Build()
	if frame:IsShown() then self:Hide() else self:Show() end
end

function GuidePanel:OnEnable()
	Build()
	self:ApplyPosition()
	self:Refresh()
	if ns.db.char.panelShown == false then
		frame:Hide()
	else
		frame:Show()
	end
end
