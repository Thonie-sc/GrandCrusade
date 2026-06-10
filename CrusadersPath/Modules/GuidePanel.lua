-- Crusader's Path :: GuidePanel
-- The crusade guide. Shows the current holy ground, its level span, and - when
-- the faithful stand upon that ground - the quests to be fulfilled there, as a
-- checklist. When elsewhere, it bids the crusader consult the Path of Light.

local ADDON, ns = ...

local GuidePanel = {}
ns.GuidePanel = ns.RegisterModule(GuidePanel)

local frame
local rows = {}

local function SavePosition()
	local point, _, _, x, y = frame:GetPoint()
	ns.db.profile.panelPoint = { point, x, y }
end

local function AcquireRow(index)
	if rows[index] then return rows[index] end
	local parent = frame.content
	local row = CreateFrame("CheckButton", "CrusadersPathQuestRow" .. index, parent, "UICheckButtonTemplate")
	row:SetSize(22, 22)
	if index == 1 then
		row:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -4)
	else
		row:SetPoint("TOPLEFT", rows[index - 1], "BOTTOMLEFT", 0, -4)
	end
	local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", row, "RIGHT", 4, 0)
	label:SetPoint("RIGHT", parent, "RIGHT", -6, 0)
	label:SetJustifyH("LEFT")
	label:SetWordWrap(true)
	row.label = label
	rows[index] = row
	return row
end

local function Build()
	if frame then return frame end

	local f = CreateFrame("Frame", "CrusadersPathGuide", UIParent, "BackdropTemplate")
	f:SetSize(300, 260)
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
	title:SetPoint("TOPLEFT", 12, -10)
	title:SetPoint("TOPRIGHT", -28, -10)
	title:SetJustifyH("CENTER")
	f.title = title

	local sub = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
	sub:SetPoint("TOPRIGHT", title, "BOTTOMRIGHT", 0, -2)
	sub:SetJustifyH("CENTER")
	f.sub = sub

	local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", 0, 0)
	close:SetScript("OnClick", function() GuidePanel:Hide() end)

	local content = CreateFrame("Frame", nil, f)
	content:SetPoint("TOPLEFT", 10, -52)
	content:SetPoint("BOTTOMRIGHT", -10, 10)
	f.content = content

	local directive = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	directive:SetPoint("TOPLEFT", 4, -4)
	directive:SetPoint("TOPRIGHT", -4, -4)
	directive:SetJustifyH("LEFT")
	directive:SetJustifyV("TOP")
	directive:SetSpacing(2)
	f.directive = directive

	frame = f
	return f
end

local function HideRows()
	for _, row in ipairs(rows) do row:Hide() end
end

function GuidePanel:Refresh()
	Build()
	local id = ns.db.char.currentBracket or 1
	local bracket = ns.GetBracket(id)
	if not bracket then
		frame.title:SetText(ns.Gold("The Crusade is Won"))
		frame.sub:SetText(ns.Pale("Every holy ground is cleansed."))
		HideRows()
		frame.directive:SetText(ns.Pale("Rest now, champion. The Light shines upon you."))
		return
	end

	frame.title:SetText(ns.Gold("Crusade: " .. (bracket.subzone or bracket.zone)))
	frame.sub:SetText(ns.Pale(("Levels %d - %d  *  %s"):format(bracket.min, bracket.max, bracket.zone)))

	local inArea = ns.IsInArea and ns.IsInArea(bracket)

	if not inArea then
		HideRows()
		frame.directive:Show()
		frame.directive:SetText(ns.Pale("The Light bids you onward - consult the Path of Light to reach this holy ground."))
		return
	end

	frame.directive:Hide()

	if #bracket.quests == 0 then
		HideRows()
		frame.directive:Show()
		frame.directive:SetText(ns.Pale("No quests burden this ground - simply cleanse the undead until you are ready to march on."))
		return
	end

	ns.db.char.questsDone[id] = ns.db.char.questsDone[id] or {}
	local done = ns.db.char.questsDone[id]

	for i, q in ipairs(bracket.quests) do
		local row = AcquireRow(i)
		local locked = q.id and C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted
			and C_QuestLog.IsQuestFlaggedCompleted(q.id)
		local checked = locked or done[i] and true or false
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
		row:Show()
	end
	-- hide any leftover rows from a longer previous bracket
	for i = #bracket.quests + 1, #rows do rows[i]:Hide() end
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
