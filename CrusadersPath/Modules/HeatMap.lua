-- Crusader's Path :: HeatMap
-- A world-map overlay marking each area's known undead camps with soft blobs,
-- colored by difficulty (con) relative to the player's level. Camp positions are
-- authored (ns.AreaMap) because the API cannot enumerate live mobs in a zone.

local ADDON, ns = ...

local HeatMap = {}
ns.HeatMap = ns.RegisterModule(HeatMap)

local BLOB = "Interface\\COMMON\\Indicator-Gray" -- soft circle, tintable
local BASE_SIZE = 34

local pins = {}
local hooked = false

local function GetCanvas()
	if WorldMapFrame and WorldMapFrame.GetCanvas then
		return WorldMapFrame:GetCanvas()
	end
	return WorldMapFrame and WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child
end

local function AcquirePin(i, canvas)
	if pins[i] then return pins[i] end
	local t = canvas:CreateTexture(nil, "OVERLAY")
	t:SetTexture(BLOB)
	t:SetBlendMode("ADD")
	pins[i] = t
	return t
end

local function HideFrom(n)
	for i = n, #pins do pins[i]:Hide() end
end

function HeatMap:Update()
	local canvas = GetCanvas()
	if not canvas or not WorldMapFrame:IsShown() or not ns.db.profile.heatmapEnabled then
		HideFrom(1)
		return
	end

	local shownMap = WorldMapFrame:GetMapID()
	local activeId = ns.db.char.currentBracket or 1
	local w, h = canvas:GetWidth(), canvas:GetHeight()
	local n = 0

	for id, area in pairs(ns.AreaMap) do
		if area.mapID == shownMap then
			local active = (id == activeId)
			for _, c in ipairs(area.camps) do
				n = n + 1
				local pin = AcquirePin(n, canvas)
				local size = BASE_SIZE * (c.density or 1) * (active and 1.0 or 0.8)
				pin:SetSize(size, size)
				pin:ClearAllPoints()
				pin:SetPoint("CENTER", canvas, "TOPLEFT", c.x * w, -c.y * h)
				local r, g, b = ns.Con(c.level)
				pin:SetVertexColor(r, g, b)
				pin:SetAlpha(active and 0.55 or 0.35)
				pin:Show()
			end
		end
	end

	HideFrom(n + 1)
end

function HeatMap:OnEnable()
	if not WorldMapFrame then return end

	local function refresh() HeatMap:Update() end

	if not hooked then
		hooked = true
		WorldMapFrame:HookScript("OnShow", refresh)
		if WorldMapFrame.OnMapChanged then
			hooksecurefunc(WorldMapFrame, "OnMapChanged", refresh)
		end
		if WorldMapFrame.ScrollContainer then
			WorldMapFrame.ScrollContainer:HookScript("OnSizeChanged", refresh)
		end
		local f = CreateFrame("Frame")
		f:RegisterEvent("PLAYER_LEVEL_UP")
		f:SetScript("OnEvent", refresh)
	end

	self:Update()
end
