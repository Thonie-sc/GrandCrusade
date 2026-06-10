-- Crusader's Path :: Notify
-- The "area purged" banner and its holy clamor (bell toll + a custom fanfare).

local ADDON, ns = ...

local Notify = {}
ns.Notify = ns.RegisterModule(Notify)

local BELL = "Sound\\Doodad\\BellTollAlliance.ogg"
-- Custom bundled fanfare. Drop an .ogg (or .mp3) at this path; see Sounds\README.txt.
-- PlaySoundFile fails silently if the file is absent, leaving the bell toll intact.
local PURGE_SOUND = "Interface\\AddOns\\CrusadersPath\\Sounds\\PurgeFanfare.mp3"

local banner

local function BuildBanner()
	if banner then return banner end

	local f = CreateFrame("Frame", "CrusadersPathBanner", UIParent)
	f:SetSize(640, 150)
	f:SetPoint("TOP", UIParent, "TOP", 0, -180)
	f:SetFrameStrata("DIALOG")
	f:Hide()

	-- a soft gilded backdrop glow behind the words
	local glow = f:CreateTexture(nil, "BACKGROUND")
	glow:SetPoint("CENTER")
	glow:SetSize(700, 200)
	glow:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
	glow:SetVertexColor(0.05, 0.04, 0.0, 0.55)
	f.glow = glow

	local header = f:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
	header:SetPoint("TOP", f, "TOP", 0, -6)
	header:SetText(ns.Gold("=== AREA PURGED ==="))
	f.header = header

	local area = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	area:SetPoint("TOP", header, "BOTTOM", 0, -6)
	f.area = area

	local body = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	body:SetPoint("TOP", area, "BOTTOM", 0, -10)
	body:SetWidth(600)
	body:SetJustifyH("CENTER")
	f.body = body

	local ag = f:CreateAnimationGroup()
	local fadeIn = ag:CreateAnimation("Alpha")
	fadeIn:SetFromAlpha(0); fadeIn:SetToAlpha(1); fadeIn:SetDuration(0.6); fadeIn:SetOrder(1)
	local fadeOut = ag:CreateAnimation("Alpha")
	fadeOut:SetFromAlpha(1); fadeOut:SetToAlpha(0); fadeOut:SetDuration(1.4)
	fadeOut:SetStartDelay(5.0); fadeOut:SetOrder(2)
	ag:SetScript("OnFinished", function() f:Hide() end)
	f.anim = ag

	banner = f
	return f
end

-- Play the holy clamor. Bell toll first, the custom fanfare a beat later.
local function PlayClamor()
	if not ns.db.profile.soundEnabled then return end
	PlaySoundFile(BELL, "Master")
	C_Timer.After(0.35, function()
		PlaySoundFile(PURGE_SOUND, "Master")
	end)
end

-- Show the purge banner for bracket `id`.
-- `preview` = true means a debug/vision preview (does not require real progress).
function Notify:Purge(id, preview)
	local bracket = ns.GetBracket(id)
	if not bracket then return end

	if ns.db.profile.bannerEnabled then
		local f = BuildBanner()
		local where = bracket.subzone or bracket.zone or ""
		f.area:SetText(ns.Pale(where) .. ns.Pale("  (" .. bracket.zone .. ")"))

		local onward
		local nextBracket = ns.GetBracket(id + 1)
		if nextBracket then
			onward = ns.Gold("Now ride to " .. (nextBracket.subzone or nextBracket.zone) .. ":\n")
				.. ns.Pale(nextBracket.travel)
		else
			onward = ns.Gold("The crusade is complete. Rest now, champion of the Light.")
		end
		f.body:SetText(ns.Pale(bracket.purge) .. "\n\n" .. onward)

		f.anim:Stop()
		f:SetAlpha(1)
		f:Show()
		f.anim:Play()
	end

	PlayClamor()

	if preview then
		ns.Print("(A vision of cleansing is granted unto you.)")
	end
end
