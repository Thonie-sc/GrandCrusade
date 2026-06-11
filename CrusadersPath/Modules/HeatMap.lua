-- Crusader's Path :: HeatMap
-- A world-map overlay marking each area's known undead camps with soft blobs,
-- colored by difficulty (con) relative to the player's level. Camp positions are
-- authored (ns.AreaMap) because the API cannot enumerate live mobs in a zone.

local ADDON, ns = ...

local HeatMap = {}
ns.HeatMap = ns.RegisterModule(HeatMap)

local BLOB = "Interface\\COMMON\\Indicator-Gray" -- soft circle, tintable
local BASE_SIZE = 30

local overlay        -- frame on the map canvas that holds the blobs
local pins = {}
local ticker
local hooked = false

local function GetCanvas()
	if WorldMapFrame and WorldMapFrame.GetCanvas then
		return WorldMapFrame:GetCanvas()
	end
	return WorldMapFrame and WorldMapFrame.ScrollContainer and WorldMapFrame.ScrollContainer.Child
end

local function EnsureOverlay()
	local canvas = GetCanvas()
	if not canvas then return nil end
	if not overlay or overlay:GetParent() ~= canvas then
		overlay = CreateFrame("Frame", nil, canvas)
		overlay:SetAllPoints(canvas)
		overlay:SetFrameLevel((canvas:GetFrameLevel() or 0) + 20) -- above the map tiles
		pins = {}
	end
	return overlay, canvas
end

local function AcquirePin(i)
	if pins[i] then return pins[i] end
	local t = overlay:CreateTexture(nil, "OVERLAY")
	t:SetTexture(BLOB)
	pins[i] = t
	return t
end

local function HideFrom(n)
	for i = n, #pins do pins[i]:Hide() end
end

function HeatMap:Update()
	local ov, canvas = EnsureOverlay()
	if not ov or not WorldMapFrame:IsShown() or not ns.db.profile.heatmapEnabled then
		HideFrom(1)
		return
	end

	local w, h = canvas:GetWidth(), canvas:GetHeight()
	if not w or w < 1 then return end          -- canvas not sized yet; ticker retries

	local shownMap = WorldMapFrame:GetMapID()
	local activeId = ns.db.char.currentBracket or 1
	local n = 0

	for id, area in pairs(ns.AreaMap) do
		if area.mapID == shownMap then
			local active = (id == activeId)
			for _, c in ipairs(area.camps) do
				n = n + 1
				local pin = AcquirePin(n)
				local size = BASE_SIZE * (c.density or 1) * (active and 1.0 or 0.85)
				pin:SetSize(size, size)
				pin:ClearAllPoints()
				pin:SetPoint("CENTER", canvas, "TOPLEFT", c.x * w, -c.y * h)
				local r, g, b = ns.Con(c.level)
				pin:SetVertexColor(r, g, b)
				pin:SetAlpha(active and 0.85 or 0.55)
				pin:Show()
			end
		end
	end

	HideFrom(n + 1)
end

local function Start()
	HeatMap:Update()
	if C_Timer and C_Timer.NewTicker and not ticker then
		-- Refresh while the map is open to catch zone navigation and sizing.
		ticker = C_Timer.NewTicker(0.5, function() HeatMap:Update() end)
	end
end

local function Stop()
	if ticker then ticker:Cancel(); ticker = nil end
	HideFrom(1)
end

function HeatMap:OnEnable()
	if not WorldMapFrame then return end

	if not hooked then
		hooked = true
		WorldMapFrame:HookScript("OnShow", Start)
		WorldMapFrame:HookScript("OnHide", Stop)
		if WorldMapFrame.OnMapChanged then
			hooksecurefunc(WorldMapFrame, "OnMapChanged", function() HeatMap:Update() end)
		end
		local f = CreateFrame("Frame")
		f:RegisterEvent("PLAYER_LEVEL_UP")
		f:SetScript("OnEvent", function() HeatMap:Update() end)
	end

	if WorldMapFrame:IsShown() then Start() end
end
