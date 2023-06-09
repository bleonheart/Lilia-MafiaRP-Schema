if IsValid(TFA.INSPECTIONPANEL) then TFA.INSPECTIONPANEL:Remove() end

local l_CT = CurTime

local CMIX_MULT = 1
local c1t = {}
local c2t = {}

local function ColorMix(c1, c2, fac, t)
	c1 = c1 or color_white
	c2 = c2 or color_white
	c1t.r = c1.r
	c1t.g = c1.g
	c1t.b = c1.b
	c1t.a = c1.a
	c2t.r = c2.r
	c2t.g = c2.g
	c2t.b = c2.b
	c2t.a = c2.a

	for k, v in pairs(c1t) do
		if t == CMIX_MULT then
			c1t[k] = Lerp(fac, v, (c1t[k] / 255 * c2t[k] / 255) * 255)
		else
			c1t[k] = Lerp(fac, v, c2t[k])
		end
	end

	return Color(c1t.r, c1t.g, c1t.b, c1t.a)
end



local cv_red_r, cv_red_g, cv_red_b = GetConVar("cl_tfa_hud_crosshair_color_enemy_r"), GetConVar("cl_tfa_hud_crosshair_color_enemy_g"), GetConVar("cl_tfa_hud_crosshair_color_enemy_b")
local c_red = Color(cv_red_r:GetInt(), cv_red_g:GetInt(), cv_red_b:GetInt(), 255)

local function UpdateEnemyTeamColor()
	c_red.r = cv_red_r:GetInt()
	c_red.g = cv_red_g:GetInt()
	c_red.b = cv_red_b:GetInt()
end
cvars.AddChangeCallback(cv_red_r:GetName(), UpdateEnemyTeamColor, "c_red")
cvars.AddChangeCallback(cv_red_g:GetName(), UpdateEnemyTeamColor, "c_red")
cvars.AddChangeCallback(cv_red_b:GetName(), UpdateEnemyTeamColor, "c_red")



local cv_grn_r, cv_grn_g, cv_grn_b = GetConVar("cl_tfa_hud_crosshair_color_friendly_r"), GetConVar("cl_tfa_hud_crosshair_color_friendly_g"), GetConVar("cl_tfa_hud_crosshair_color_friendly_b")
local c_grn = Color(cv_grn_r:GetInt(), cv_grn_g:GetInt(), cv_grn_b:GetInt(), 255)

local function UpdateFriendlyTeamColor()
	c_grn.r = cv_grn_r:GetInt()
	c_grn.g = cv_grn_g:GetInt()
	c_grn.b = cv_grn_b:GetInt()
end
cvars.AddChangeCallback(cv_grn_r:GetName(), UpdateFriendlyTeamColor, "c_grn")
cvars.AddChangeCallback(cv_grn_g:GetName(), UpdateFriendlyTeamColor, "c_grn")
cvars.AddChangeCallback(cv_grn_b:GetName(), UpdateFriendlyTeamColor, "c_grn")



local cl_xhair_teamcolorcvar, sv_xhair_showplayercvar, sv_xhair_showplayerteamcvar

local GetNPCDisposition = TFA.GetNPCDisposition
local GameModeTeamBased = GAMEMODE.TeamBased

function SWEP:GetTeamColor(ent)
	if not cl_xhair_teamcolorcvar then
		cl_xhair_teamcolorcvar = GetConVar("cl_tfa_hud_crosshair_color_team")
	end

	if not sv_xhair_showplayercvar then
		sv_xhair_showplayercvar = GetConVar("sv_tfa_crosshair_showplayer")
	end

	if not sv_xhair_showplayerteamcvar then
		sv_xhair_showplayerteamcvar = GetConVar("sv_tfa_crosshair_showplayerteam")
	end

	if not cl_xhair_teamcolorcvar:GetBool() then return color_white end

	local ply = LocalPlayer()
	if not IsValid(ply) then return color_white end

	if ent:IsPlayer() then
		if not sv_xhair_showplayercvar:GetBool() then return color_white end

		if GameModeTeamBased and sv_xhair_showplayerteamcvar:GetBool() then
			if ent:Team() == ply:Team() then
				return c_grn
			else
				return c_red
			end
		end

		return c_red
	end

	if ent:IsNPC() then
		local disp = GetNPCDisposition(ent) or ent:GetNW2Int("tfa_disposition", -1)

		if disp > 0 then
			if disp == (D_FR or 2) or disp == (D_HT or 1) then
				return c_red
			else
				return c_grn
			end
		end

		if IsFriendEntityName(ent:GetClass()) then
			return c_grn
		else
			return c_red
		end
	end

	return color_white
end

--[[
local function RoundDecimals(number, decimals)
	local decfactor = math.pow(10, decimals)

	return math.Round(tonumber(number) * decfactor) / decfactor
end
]]
--
--[[
Function Name:  DoInspectionDerma
Syntax: self:DoInspectionDerma().
Returns:  Nothing.
Notes:  Used to manage our Derma.
Purpose:  Used to manage our Derma.
]]
--
local TFA_INSPECTIONPANEL
local spacing = 64

local ScaleH = TFA.ScaleH

local DrawTextShadowed = TFA.DrawTextShadowed
local function TextShadowPaint(myself, w, h)
	if not myself.TextColor then
		myself.TextColor = ColorAlpha(color_white, 0)
	end

	DrawTextShadowed(myself.Text, myself.Font, myself.TextPosX or 0, myself.TextPosY or 0, myself.TextColor, ScaleH(2))
end
SWEP.TextShadowPaintFunc = TextShadowPaint

local cv_bars_exp = GetConVar("cl_tfa_inspect_newbars")
function SWEP:PaintStatPanel(w, h)
	if not IsValid(self) then return end
	if not IsValid(TFA_INSPECTIONPANEL) then return end
	if not IsValid(self.Weapon) then return end
	if not self.StatTable then return end

	if self.StatTable.bar then
		local bar = math.Clamp(self.StatTable.bar(self.Weapon), 0, 1)

		local xx, ww, blockw, padw
		xx = w - ScaleH(120)
		ww = w - xx

		local bgcol = ColorAlpha(TFA_INSPECTIONPANEL.BackgroundColor or color_white, (TFA_INSPECTIONPANEL.Alpha or 0) / 2)

		if cv_bars_exp and cv_bars_exp:GetBool() then
			draw.RoundedBox(4, xx + 1, 1, ww - 2, h - 2, bgcol)

			local w1, h1 = self:LocalToScreen(xx + 2, 2)
			local w2, h2 = self:LocalToScreen(xx - 2 + ww * bar, h - 2)

			render.SetScissorRect(w1, h1, w2, h2, true)
			draw.RoundedBox(4, xx + 2, 2, ww - 4, h - 4, TFA_INSPECTIONPANEL.SecondaryColor or color_white)
			render.SetScissorRect(0, 0, 0, 0, false)

			return
		end

		blockw = math.floor(ww / 15)
		padw = math.floor(ww / 10)

		self.Bars = math.Clamp(math.Round(bar * 10), 0, 10)

		surface.SetDrawColor(bgcol)
		for _ = 0, 9 do
			surface.DrawRect(xx, 2, blockw, h - 5)
			xx = math.floor(xx + padw)
		end

		xx = w - ScaleH(120)
		surface.SetDrawColor(TFA_INSPECTIONPANEL.BackgroundColor or color_white)

		for _ = 0, self.Bars - 1 do
			surface.DrawRect(xx + 1, 3, blockw, h - 5)
			xx = math.floor(xx + padw)
		end

		xx = w - ScaleH(120)
		surface.SetDrawColor(TFA_INSPECTIONPANEL.SecondaryColor or color_white)

		for _ = 0, self.Bars - 1 do
			surface.DrawRect(xx, 2, blockw, h - 5)
			xx = math.floor(xx + padw)
		end
	end

	if self.StatTable.text then
		DrawTextShadowed(self.StatTable.text(self.Weapon), self.Font, 0, 0, TFA_INSPECTIONPANEL.SecondaryColor, ScaleH(2))
	end
end

local function WrapTextLines(textlines, maxwidth, font)
	if type(textlines) == "string" then
		textlines = string.Split(textlines, "\n")
	end

	local lines = {}

	surface.SetFont(font)

	for _, text in ipairs(textlines) do
		local w, _ = surface.GetTextSize(text)

		if w > maxwidth then
			local line = ""

			for _, word in ipairs(string.Explode(" ", text)) do
				local added = line == "" and word or line .. " " .. word
				w, _ = surface.GetTextSize(added)

				if w > maxwidth then
					table.insert(lines, line)
					line = word
				else
					line = added
				end
			end

			if line ~= "" then
				table.insert(lines, line)
			end
		else
			table.insert(lines, text)
		end
	end

	return lines
end

local pad = 4
local infotextpad = "\t"
local INSPECTION_BACKGROUND = TFA.Attachments.Colors["background"]
local INSPECTION_ACTIVECOLOR = TFA.Attachments.Colors["active"]
local INSPECTION_PRIMARYCOLOR = TFA.Attachments.Colors["primary"]
local INSPECTION_SECONDARYCOLOR = TFA.Attachments.Colors["secondary"]


SWEP.AmmoTypeStrings = {
	["pistol"] = "tfa.ammo.pistol",
	["smg1"] = "tfa.ammo.smg1",
	["ar2"] = "tfa.ammo.ar2",
	["buckshot"] = "tfa.ammo.buckshot",
	["357"] = "tfa.ammo.357",
	["SniperPenetratedRound"] = "tfa.ammo.sniperpenetratedround"
}

SWEP.WeaponTypeStrings = {
	["weapon"] = "tfa.weptype.generic",
	["pistol"] = "tfa.weptype.pistol",
	["machine pistol"] = "tfa.weptype.machpistol",
	["revolver"] = "tfa.weptype.revolver",
	["sub-machine gun"] = "tfa.weptype.smg",
	["rifle"] = "tfa.weptype.rifle",
	["carbine"] = "tfa.weptype.carbine",
	["light machine gun"] = "tfa.weptype.lmg",
	["shotgun"] = "tfa.weptype.shotgun",
	["designated marksman rifle"] = "tfa.weptype.dmr",
	["sniper rifle"] = "tfa.weptype.sniper",
	["grenade"] = "tfa.weptype.grenade",
	["launcher"] = "tfa.weptype.launcher",
	["dual pistols"] = "tfa.weptype.pistol.dual",
	["dual revolvers"] = "tfa.weptype.revolver.dual",
	["dual sub-machine guns"] = "tfa.weptype.smg.dual",
	["dual guns"] = "tfa.weptype.generic.dual",
} -- if you have more generalized (and widely used) types that could be localized please let us know so that we can add them here!

local att_enabled_cv = GetConVar("sv_tfa_attachments_enabled")

SWEP.VGUIPaddingW = 32
SWEP.VGUIPaddingH = 80

function SWEP:InspectionVGUISideBars(mainpanel)
	local barleft = vgui.Create("DPanel", mainpanel)
	barleft:SetWidth(ScaleH(self.VGUIPaddingW))
	barleft:Dock(LEFT)

	barleft.Paint = function(myself, w, h)
		local mycol = mainpanel.SecondaryColor

		if not mycol then return end

		surface.SetDrawColor(mycol)
		surface.SetTexture(mainpanel.SideBar or 1)
		surface.DrawTexturedRect(0, 0, w, h)
	end

	local barright = vgui.Create("DPanel", mainpanel)
	barright:SetWidth(ScaleH(self.VGUIPaddingW))
	barright:Dock(RIGHT)

	barright.Paint = function(myself, w, h)
		local mycol = mainpanel.SecondaryColor

		if not mycol then return end

		surface.SetDrawColor(mycol)
		surface.SetTexture(mainpanel.SideBar or 1)
		surface.DrawTexturedRectUV(0, 0, w, h, 1, 0, 0, 1)
	end
end

function SWEP:InspectionVGUIMainInfo(contentpanel)
	if hook.Run("TFA_InspectVGUI_InfoStart", self, contentpanel) ~= false then
		local mainpanel = contentpanel:GetParent()

		local infopanel = contentpanel:Add("DSizeToContents")
		infopanel:SetName("Main Weapon Info")

		infopanel:SetSize(0, 0)
		infopanel:Dock(TOP)
		infopanel.Paint = function() end

		local titletext = infopanel:Add("DPanel")
		titletext:SetName("Name")
		titletext.Text = self.PrintName or "TFA Weapon"

		titletext.Think = function(myself)
			myself.TextColor = mainpanel.PrimaryColor
		end

		titletext.Font = "TFA_INSPECTION_TITLE"
		titletext:Dock(TOP)
		titletext:SetSize(ScrW() * .5, TFA.Fonts.InspectionHeightTitle)
		titletext.Paint = TextShadowPaint

		local typetext = infopanel:Add("DPanel")
		typetext:SetName("Type")

		local weptype = self:GetStatL("Type_Displayed") or self:GetType()
		typetext.Text = language.GetPhrase(self.WeaponTypeStrings[weptype:lower()] or weptype)

		typetext.Think = function(myself)
			myself.TextColor = mainpanel.PrimaryColor
		end

		typetext.Font = "TFA_INSPECTION_DESCR"
		typetext:Dock(TOP)
		typetext:SetSize(ScrW() * .5, TFA.Fonts.InspectionHeightDescription)
		typetext.Paint = TextShadowPaint

		--Space things out for block1
		local spacer = infopanel:Add("DPanel")
		spacer:SetName("Spacer")
		spacer:Dock(TOP)
		spacer:SetSize(ScrW() * .5, TFA.Fonts.InspectionHeightDescription)
		spacer.Paint = function() end

		--First stat block
		local categorytext = infopanel:Add("DPanel")
		categorytext:SetName("Category")
		categorytext.Text = self.Category or self.Base

		categorytext.Think = function(myself)
			myself.TextColor = mainpanel.SecondaryColor
		end

		categorytext.Font = "TFA_INSPECTION_SMALL"
		categorytext:Dock(TOP)
		categorytext:SetSize(ScrW() * .5, TFA.Fonts.InspectionHeightSmall)
		categorytext.Paint = TextShadowPaint

		if self.Author and string.Trim(self.Author) ~= "" then
			local authortext = infopanel:Add("DPanel")
			authortext:SetName("Author")
			authortext.Text = infotextpad .. language.GetPhrase("tfa.inspect.creator"):format(self.Author)

			authortext.Think = function(myself)
				myself.TextColor = mainpanel.SecondaryColor
			end

			authortext.Font = "TFA_INSPECTION_SMALL"
			authortext:Dock(TOP)
			authortext:SetSize(ScrW() * .5, TFA.Fonts.InspectionHeightSmall)
			authortext.Paint = TextShadowPaint
		end

		if self.Manufacturer and string.Trim(self.Manufacturer) ~= "" then
			local makertext = infopanel:Add("DPanel")
			makertext:SetName("Manufacturer")
			makertext.Text = infotextpad .. language.GetPhrase("tfa.inspect.manufacturer"):format(self.Manufacturer)

			makertext.Think = function(myself)
				myself.TextColor = mainpanel.SecondaryColor
			end

			makertext.Font = "TFA_INSPECTION_SMALL"
			makertext:Dock(TOP)
			makertext:SetSize(ScrW() * .5, TFA.Fonts.InspectionHeightSmall)
			makertext.Paint = TextShadowPaint
		end

		local clip = self:GetStatL("Primary.ClipSize")

		if clip > 0 then
			local capacitytext = infopanel:Add("DPanel")
			capacitytext:SetName("Capacity")
			capacitytext.Text = infotextpad .. language.GetPhrase("tfa.inspect.capacity"):format(clip .. (self:CanChamber() and (self:GetStatL("IsAkimbo") and " + 2" or " + 1") or ""))

			capacitytext.Think = function(myself)
				myself.TextColor = mainpanel.SecondaryColor
			end

			capacitytext.Font = "TFA_INSPECTION_SMALL"
			capacitytext:Dock(TOP)
			capacitytext:SetSize(ScrW() * .5, TFA.Fonts.InspectionHeightSmall)
			capacitytext.Paint = TextShadowPaint
		end

		local an = game.GetAmmoName(self:GetPrimaryAmmoType())

		if an and an ~= "" and string.len(an) > 1 then
			local ammotypetext = infopanel:Add("DPanel")
			ammotypetext:SetName("Ammo Type")
			ammotypetext.Text = infotextpad .. language.GetPhrase("tfa.inspect.ammotype"):format(language.GetPhrase(self.AmmoTypeStrings[an:lower()] or (an .. "_ammo")))

			ammotypetext.Think = function(myself)
				myself.TextColor = mainpanel.SecondaryColor
			end

			ammotypetext.Font = "TFA_INSPECTION_SMALL"
			ammotypetext:Dock(TOP)
			ammotypetext:SetSize(ScrW() * .5, TFA.Fonts.InspectionHeightSmall)
			ammotypetext.Paint = TextShadowPaint
		end

		local maxlinewidth = ScrW() * .5 - ScaleH(self.VGUIPaddingW) * 4

		if self.Purpose and string.Trim(self.Purpose) ~= "" then
			local lines = WrapTextLines(language.GetPhrase("tfa.inspect.purpose"):format(language.GetPhrase(self.Purpose)), maxlinewidth, "TFA_INSPECTION_SMALL")

			for _, line in pairs(lines) do
				local purposeline = infopanel:Add("DPanel")
				purposeline:SetName("Purpose")
				purposeline.Text = infotextpad .. line

				purposeline.Think = function(myself)
					myself.TextColor = mainpanel.SecondaryColor
				end

				purposeline.Font = "TFA_INSPECTION_SMALL"
				purposeline:Dock(TOP)
				purposeline:SetSize(ScrW() * .5, TFA.Fonts.InspectionHeightSmall)
				purposeline.Paint = TextShadowPaint
			end
		end

		if self.Description and string.Trim(self.Description) ~= "" then
			local lines = WrapTextLines(language.GetPhrase(self.Description), maxlinewidth, "TFA_INSPECTION_SMALL")

			for _, line in ipairs(lines) do
				local descline = infopanel:Add("DPanel")
				descline:SetName("Description")
				descline.Text = infotextpad .. line

				descline.Think = function(myself)
					myself.TextColor = mainpanel.SecondaryColor
				end

				descline.Font = "TFA_INSPECTION_SMALL"
				descline:Dock(TOP)
				descline:SetSize(ScrW() * .5, TFA.Fonts.InspectionHeightSmall)
				descline.Paint = TextShadowPaint
			end
		end

		hook.Run("TFA_InspectVGUI_InfoFinish", self, contentpanel, infopanel)
	end
end

local cv_display_moa = GetConVar("cl_tfa_inspect_spreadinmoa")
local sv_tfa_weapon_weight = GetConVar("sv_tfa_weapon_weight")

local AccuracyToDegrees = 1 / TFA.DegreesToAccuracy
local AccuracyToMOA = 1 / TFA.DegreesToAccuracy * 60

SWEP.InspectionVGUI_BestDamage = 100
SWEP.InspectionVGUI_BestRPM = 1200
SWEP.InspectionVGUI_WorstAccuracy = 0.045
SWEP.InspectionVGUI_WorstMove = 0.8
SWEP.InspectionVGUI_WorstRecoil = 1

SWEP.InspectionVGUIStatsTable = {
	{
		name = "bash",
		cond = function(wep) return wep.BashBase and wep:GetStatL("Secondary.CanBash") ~= false end,
		text = function(wep) return language.GetPhrase("tfa.inspect.stat.bashdamage"):format(math.Round(wep:GetStatL("Secondary.BashDamage", 0))) end,
		bar = function(wep) return wep:GetStatL("Secondary.BashDamage") / wep.InspectionVGUI_BestDamage end
	},
	{
		name = "stability",
		cond = function(wep) return true end,
		text = function(wep) return language.GetPhrase("tfa.inspect.stat.stability"):format(math.Clamp(math.Round((1 - math.abs(wep:GetStatL("Primary.KickUp") + wep:GetStatL("Primary.KickDown")) / 2 / 1) * 100), 0, 100)) end,
		bar = function(wep) return (1 - math.abs(wep:GetStatL("Primary.KickUp") + wep:GetStatL("Primary.KickDown")) / 2 / wep.InspectionVGUI_WorstRecoil) end
	},
	{
		name = "damage",
		cond = function(wep) return true end,
		text = function(wep)
			local dmgstr = language.GetPhrase("tfa.inspect.stat.damage"):format(math.Round(wep:GetStatL("Primary.Damage")))

			if wep:GetStatL("Primary.NumShots") ~= 1 then
				dmgstr = dmgstr .. "x" .. math.Round(wep:GetStatL("Primary.NumShots"))
			end

			return dmgstr
		end,
		bar = function(wep) return (wep:GetStatL("Primary.Damage") * math.Round(wep:GetStatL("Primary.NumShots") * 0.75)) / wep.InspectionVGUI_BestDamage end
	},
	{
		name = "mobility",
		cond = function(wep) return sv_tfa_weapon_weight:GetBool() end,
		text = function(wep) return language.GetPhrase("tfa.inspect.stat.mobility"):format(math.Round(wep:GetStatL("RegularMoveSpeedMultiplier") * 100)) end,
		bar = function(wep) return (wep:GetStatL("RegularMoveSpeedMultiplier") - wep.InspectionVGUI_WorstMove) / (1 - wep.InspectionVGUI_WorstMove) end
	},
	{
		name = "firerate",
		cond = function(wep) return true end,
		text = function(wep) return language.GetPhrase("tfa.inspect.stat.rpm"):format(wep:GetStatL("Primary.RPM_Displayed") or wep:GetStatL("Primary.RPM")) end,
		bar = function(wep) return (wep:GetStatL("Primary.RPM_Displayed") or wep:GetStatL("Primary.RPM")) / wep.InspectionVGUI_BestRPM end
	},
	{
		name = "spread_hip",
		cond = function(wep) return wep:GetStatL("Secondary.DisplaySpread", true) end,
		text = function(wep)
			local spread = wep:GetStatL("Primary.Spread")

			local spreadtext
			if cv_display_moa and cv_display_moa:GetBool() then
				spreadtext = language.GetPhrase("tfa.inspect.val.moa"):format(spread * AccuracyToMOA)
			else
				spreadtext = language.GetPhrase("tfa.inspect.val.degrees"):format(spread * AccuracyToDegrees)
			end

			return language.GetPhrase("tfa.inspect.stat.accuracy.hip"):format(spreadtext)
		end,
		bar = function(wep) return 1 - wep:GetStatL("Primary.Spread") / wep.InspectionVGUI_WorstAccuracy end
	},
	{
		name = "spread_iron",
		cond = function(wep) return wep:GetStatL("Secondary.IronSightsEnabled", false) and wep:GetStatL("Secondary.DisplayIronSpread", true) end,
		text = function(wep)
			local spread = wep:GetStatL("Primary.IronAccuracy")

			local spreadtext
			if cv_display_moa and cv_display_moa:GetBool() then
				spreadtext = language.GetPhrase("tfa.inspect.val.moa"):format(spread * AccuracyToMOA)
			else
				spreadtext = language.GetPhrase("tfa.inspect.val.degrees"):format(spread * AccuracyToDegrees)
			end

			return language.GetPhrase("tfa.inspect.stat.accuracy"):format(spreadtext)
		end,
		bar = function(wep) return 1 - wep:GetStatL("Primary.IronAccuracy") / wep.InspectionVGUI_WorstAccuracy end
	},
	{
		name = "condition",
		cond = function(wep) return wep:CanBeJammed() end,
		text = function(wep) return language.GetPhrase("tfa.inspect.condition"):format(math.Clamp(math.Round((1 - wep:GetJamFactor() * .01) * 100), 0, 100)) end,
		bar = function(wep) return 1 - wep:GetJamFactor() * .01 end
	},
}

function SWEP:InspectionVGUIStats(contentpanel)
	if hook.Run("TFA_InspectVGUI_StatsStart", self, contentpanel) ~= false then
		local mainpanel = contentpanel:GetParent()

		local statspanel = contentpanel:Add("DPanel")
		statspanel:SetName("Weapon Stats Container")

		local preferredWidth = math.min(ScaleH(400), ScrW() * .4)

		statspanel:SetSize(0, 0)
		statspanel:Dock(BOTTOM)
		statspanel:DockMargin(0, 0, ScrW() - preferredWidth - ScaleH(self.VGUIPaddingW) * 4, 0)
		statspanel.Paint = function() end

		statspanel.stats = {}
		for _, tbl in ipairs(self.InspectionVGUIStatsTable) do
			if not tbl.name or not tbl.text or not tbl.bar or statspanel.stats[tbl.name] then continue end
			if tbl.cond and not tbl.cond(self) then continue end

			statspanel:SetTall(statspanel:GetTall() + TFA.Fonts.InspectionHeightSmall)

			local statpanel = statspanel:Add("DPanel")

			statpanel:SetName("Stat Panel - " .. tbl.name)
			statpanel:SetSize(preferredWidth, TFA.Fonts.InspectionHeightSmall)

			statpanel.StatTable = tbl
			statpanel.Weapon = self
			statpanel.Font = "TFA_INSPECTION_SMALL"

			statpanel.Paint = self.PaintStatPanel
			statpanel:Dock(BOTTOM)

			statspanel.stats[tbl.name] = statpanel
		end

		hook.Run("TFA_InspectVGUI_StatsFinish", self, contentpanel, statspanel)
	end
end

function SWEP:InspectionVGUIAttachments(contentpanel)
	local mainpanel = contentpanel:GetParent()
	local scrollpanel, vbar

	if att_enabled_cv:GetBool() and hook.Run("TFA_InspectVGUI_AttachmentsStart", self, contentpanel) ~= false then
		if self.Attachments then
			scrollpanel = mainpanel:Add("DScrollPanel")
			scrollpanel:SetName("Attachments Container")

			scrollpanel:SetSize(ScrW() * .5 - ScaleH(self.VGUIPaddingW) * 2, mainpanel:GetTall() - ScaleH(self.VGUIPaddingH) * 2)
			scrollpanel:SetPos(ScrW() * .5, ScaleH(self.VGUIPaddingH))

			vbar = scrollpanel:GetVBar()

			vbar.Paint = function(myself, w, h)
				if not mainpanel or not mainpanel.BackgroundColor then return end
				surface.SetDrawColor(mainpanel.BackgroundColor.r, mainpanel.BackgroundColor.g, mainpanel.BackgroundColor.b, mainpanel.BackgroundColor.a / 2)
				surface.DrawRect(w * .65, 0, w * .35, h)
			end

			vbar.btnUp.Paint = function(myself, w, h)
				if not mainpanel or not mainpanel.PrimaryColor then return end
				surface.SetDrawColor(mainpanel.PrimaryColor.r, mainpanel.PrimaryColor.g, mainpanel.PrimaryColor.b, mainpanel.PrimaryColor.a)
				surface.DrawRect(w * .65, 0, w * .35, h)
			end

			vbar.btnDown.Paint = function(myself, w, h)
				if not mainpanel or not mainpanel.PrimaryColor then return end
				surface.SetDrawColor(mainpanel.PrimaryColor.r, mainpanel.PrimaryColor.g, mainpanel.PrimaryColor.b, mainpanel.PrimaryColor.a)
				surface.DrawRect(w * .65, 0, w * .35, h)
			end

			vbar.btnGrip.Paint = function(myself, w, h)
				if not mainpanel or not mainpanel.PrimaryColor then return end
				surface.SetDrawColor(mainpanel.PrimaryColor.r, mainpanel.PrimaryColor.g, mainpanel.PrimaryColor.b, mainpanel.PrimaryColor.a)
				surface.DrawRect(w * .65, 0, w * .35, h)
			end
		end

		self:GenerateVGUIAttachmentTable()
		local i = 0
		local prevCat
		local lineY = 0
		local scrollWide = scrollpanel:GetWide() - (IsValid(vbar) and vbar:GetTall() or 0)
		local lastTooltipPanel

		local iconsize = math.Round(TFA.ScaleH(TFA.Attachments.IconSize))
		local catspacing = math.Round(TFA.ScaleH(TFA.Attachments.CategorySpacing))
		local padding = math.Round(TFA.ScaleH(TFA.Attachments.UIPadding))

		for k, v in pairs(self.VGUIAttachments) do
			if k ~= "BaseClass" then
				if prevCat then
					local isContinuing = prevCat == (v.cat or k)
					lineY = lineY + (isContinuing and iconsize + padding or catspacing)

					if not isContinuing then
						lastTooltipPanel = nil
					end
				end

				prevCat = v.cat or k
				local testpanel = mainpanel:Add("TFAAttachmentPanel")
				testpanel:SetName("Attachment Category Container")
				testpanel:SetParent(scrollpanel)
				testpanel:SetContentPanel(scrollpanel)
				i = i + 1
				testpanel:SetWeapon(self)
				testpanel:SetAttachment(k)
				testpanel:SetCategory(v.cat or k)
				testpanel:Initialize()
				lastTooltipPanel = lastTooltipPanel or testpanel:InitializeTooltip()
				testpanel:SetupTooltip(lastTooltipPanel)
				testpanel:PopulateIcons()
				testpanel:SetPos(scrollWide - testpanel:GetWide(), lineY)
			end
		end

		hook.Run("TFA_InspectVGUI_AttachmentsFinish", self, contentpanel, scrollpanel)
	end

	if self.Primary.RangeFalloffLUTBuilt and self:GetStatL("Primary.DisplayFalloff") and hook.Run("TFA_InspectVGUI_FalloffStart", self, contentpanel) ~= false then
		local falloffpanel = vgui.Create("EditablePanel", mainpanel)
		falloffpanel:SetSize(ScrW() * .5 - ScaleH(self.VGUIPaddingW) * 2, mainpanel:GetTall() * 0.2)
		falloffpanel:SetPos(ScrW() * .5, mainpanel:GetTall() - falloffpanel:GetTall() - ScaleH(self.VGUIPaddingH))
		falloffpanel:SetName("Damage Falloff Graph")

		if scrollpanel then
			scrollpanel:SetTall(scrollpanel:GetTall() - falloffpanel:GetTall())
			falloffpanel:SetPos(ScrW() * .5, ScaleH(self.VGUIPaddingH) + scrollpanel:GetTall())
		end

		falloffpanel:NoClipping(true)

		local self2 = self
		local shadow_color = Color(0, 0, 0)

		-- it differ from function above
		local function shadowed_text(text, font, x, y, color, ...)
			draw.SimpleText(text, font, x + 2, y + 2, shadow_color, ...)
			draw.SimpleText(text, font, x, y, color, ...)
		end

		local function shadowed_line(x, y, x2, y2, color, color2)
			surface.SetDrawColor(color2)
			surface.DrawLine(x + 1, y + 1, x2 + 1, y2 + 1)
			surface.SetDrawColor(color)
			surface.DrawLine(x, y, x2, y2)
		end

		function falloffpanel.Paint(myself, w, h)
			if not IsValid(self2) or not IsValid(mainpanel) then return end

			local lut = self2.Primary.RangeFalloffLUTBuilt
			if not lut then return end
			local wepdmg = self2.Primary.Damage

			shadow_color.a = mainpanel.SecondaryColor.a

			shadowed_text("#tfa.inspect.damagedrop", "TFASleekSmall", 0, ScaleH(pad), mainpanel.SecondaryColor, TEXT_ALIGN_LEFT)

			local ax, ay = 0, TFA.Fonts.SleekHeightSmall + ScaleH(pad) * 2

			surface.SetDrawColor(mainpanel.SecondaryColor)

			local range = 0
			local div = 1

			for i, data in ipairs(lut) do
				if data[1] > range then
					range = data[1]
				end

				if data[2] > div then
					div = data[2]
				end
			end

			range = range * 1.337

			local rightpadding = 18

			for pos = 1, 4 do
				shadowed_line(ax + pos * (w - rightpadding) / 4, h - 2 - ay, ax + pos * (w - rightpadding) / 4, h - 12 - ay, mainpanel.SecondaryColor, mainpanel.BackgroundColor)
				shadowed_text(string.format("%dm", range * 0.0254 * pos / 4), "TFASleekSmall", ax + pos * (w - rightpadding) / 4, h - ay, mainpanel.SecondaryColor, TEXT_ALIGN_CENTER)
			end

			shadowed_line(ax + 1, ay + 1, 1, h - 2 - ay, mainpanel.SecondaryColor, mainpanel.BackgroundColor)
			shadowed_line(ax + 1, h - 2 - ay, w - rightpadding, h - 2 - ay, mainpanel.SecondaryColor, mainpanel.BackgroundColor)

			local lx, ly = myself:LocalToScreen(ax, 0)
			local mx, my = input.GetCursorPos()
			local rmx, rmy = mx, my
			mx = mx - lx
			my = my - ly

			local px, py

			local cirX, cirY, dmg, drange

			local progression = mx / (w - ax - rightpadding)

			for i, data in ipairs(lut) do
				local x, y = ax + data[1] / range * (w - ax - rightpadding), ay + (div - data[2]) * (h - ay * 2) / div

				if not px then
					px, py = x, y
				end

				shadowed_line(px, py, x, y, mainpanel.PrimaryColor, mainpanel.BackgroundColor)

				if x > mx and px < mx then
					local t = (mx - px) / (x - px)
					cirX, cirY = Lerp(t, px, x), Lerp(t, py, y)
					local ndmg = lut[i + 1] and lut[i + 1][2] or data[2]
					local deltadmg = ndmg - data[2]
					dmg = deltadmg * t + data[2]
				end

				px, py = x, y
			end

			shadowed_line(px, py, w - ax - 18, py, mainpanel.PrimaryColor, mainpanel.BackgroundColor)

			if mx > px and (w - ax - 18) > mx then
				cirX, cirY = mx, py
				dmg = lut[#lut][2]
			end

			if mx > 0 and my > 0 and mx < w and my < h and dmg then
				shadowed_line(mx, ay, mx, h - ay, mainpanel.PrimaryColor, mainpanel.BackgroundColor)

				if cirX then
					local Xsize = ScaleH(8)

					surface.SetDrawColor(mainpanel.BackgroundColor)
					surface.DrawLine(cirX - Xsize + 1, cirY - Xsize + 1, cirX + Xsize + 1, cirY + Xsize + 1)
					surface.DrawLine(cirX + Xsize + 1, cirY - Xsize + 1, cirX - Xsize + 1, cirY + Xsize + 1)

					surface.SetDrawColor(mainpanel.PrimaryColor)
					surface.DrawLine(cirX - Xsize, cirY - Xsize, cirX + Xsize, cirY + Xsize)
					surface.DrawLine(cirX + Xsize, cirY - Xsize, cirX - Xsize, cirY + Xsize)
				end

				shadowed_text(string.format("%dm", math.Round(range * progression * 0.0254)), "TFASleekSmall", mx - ScaleH(pad), my - TFA.Fonts.SleekHeightSmall, mainpanel.SecondaryColor, TEXT_ALIGN_RIGHT)
				shadowed_text(string.format("%ddmg", dmg * wepdmg), "TFASleekSmall", mx + ScaleH(pad), my - TFA.Fonts.SleekHeightSmall, mainpanel.SecondaryColor, TEXT_ALIGN_LEFT)
			end
		end

		hook.Run("TFA_InspectVGUI_FalloffFinish", self, contentpanel, falloffpanel)
	end
end

local cl_tfa_inspect_hide_in_screenshots = GetConVar("cl_tfa_inspect_hide_in_screenshots")
local cl_tfa_inspect_hide_hud = GetConVar("cl_tfa_inspect_hide_hud")
local cl_tfa_inspect_hide = GetConVar("cl_tfa_inspect_hide")
local cl_drawhud = GetConVar("cl_drawhud")

local blacklist = {
	CHudAmmo = false,
	CHudBattery = false,
	CHudHealth = false,
}

local function HUDShouldDraw(_, elem)
	return blacklist[elem]
end

function SWEP:GenerateInspectionDerma()
	if hook.Run("TFA_InspectVGUI_Start", self) == false then return end
	if cl_tfa_inspect_hide:GetBool() then return end

	TFA_INSPECTIONPANEL = vgui.Create("DPanel")
	TFA_INSPECTIONPANEL:SetSize(ScrW(), ScrH())
	TFA_INSPECTIONPANEL:DockPadding(ScaleH(self.VGUIPaddingW), ScaleH(self.VGUIPaddingH), ScaleH(self.VGUIPaddingW), ScaleH(self.VGUIPaddingH))
	TFA_INSPECTIONPANEL:SetRenderInScreenshots(not cl_tfa_inspect_hide_in_screenshots:GetBool())
	TFA_INSPECTIONPANEL:SetName("TFA Base Inspection Panel")

	TFA.INSPECTIONPANEL = TFA_INSPECTIONPANEL

	local function update_visible(status)
		if not cl_tfa_inspect_hide_hud:GetBool() or not DLib then return end

		if status then
			hook.DisableHook("HUDPaint")
			hook.DisableHook("HUDPaintBackground")
			hook.DisableHook("PreDrawHUD")
			hook.DisableHook("PostDrawHUD")
			hook.DisableHook("DrawDeathNotice")

			hook.Add("HUDShouldDraw", TFA_INSPECTIONPANEL, HUDShouldDraw)
		else
			hook.EnableHook("HUDPaint")
			hook.EnableHook("HUDPaintBackground")
			hook.EnableHook("PreDrawHUD")
			hook.EnableHook("PostDrawHUD")
			hook.EnableHook("DrawDeathNotice")

			hook.Remove("HUDShouldDraw", TFA_INSPECTIONPANEL, HUDShouldDraw)
		end
	end

	if not cl_drawhud:GetBool() then
		TFA_INSPECTIONPANEL:SetVisible(false)
	else
		update_visible(true)
	end

	cvars.AddChangeCallback("cl_drawhud", function()
		if not IsValid(TFA_INSPECTIONPANEL) then return end
		TFA_INSPECTIONPANEL:Think()
		if not IsValid(TFA_INSPECTIONPANEL) then return end
		TFA_INSPECTIONPANEL:SetVisible(cl_drawhud:GetBool())
		update_visible(cl_drawhud:GetBool())
	end, "TFA_INSPECTIONPANEL")

	local lastcustomizing = true

	function TFA_INSPECTIONPANEL.Think(myself, w, h)
		local ply = LocalPlayer()

		if not IsValid(ply) then
			myself:Remove()

			return
		end

		local wep = ply:GetActiveWeapon()

		if not IsValid(wep) or not wep.IsTFAWeapon or wep:GetInspectingProgress() <= 0.01 then
			myself:Remove()

			return
		end

		if cl_tfa_inspect_hide_hud:GetBool() and DLib then
			local customizing = wep:GetCustomizing()

			if customizing ~= lastcustomizing then
				lastcustomizing = customizing
				update_visible(customizing)
			end
		end

		myself.Player = ply
		myself.Weapon = wep
	end

	function TFA_INSPECTIONPANEL.OnRemove(myself)
		update_visible(false)
	end

	function TFA_INSPECTIONPANEL.Paint(myself, w, h)
		local wep = self

		if IsValid(wep) then
			myself.Alpha = wep:GetInspectingProgress() * 255
			myself.PrimaryColor = ColorAlpha(INSPECTION_PRIMARYCOLOR, TFA_INSPECTIONPANEL.Alpha)
			myself.SecondaryColor = ColorAlpha(INSPECTION_SECONDARYCOLOR, TFA_INSPECTIONPANEL.Alpha)
			myself.BackgroundColor = ColorAlpha(INSPECTION_BACKGROUND, TFA_INSPECTIONPANEL.Alpha)
			myself.ActiveColor = ColorAlpha(INSPECTION_ACTIVECOLOR, TFA_INSPECTIONPANEL.Alpha)

			if not myself.SideBar then
				myself.SideBar = surface.GetTextureID("vgui/inspectionhud/sidebar")
			end
		end
	end

	self:InspectionVGUISideBars(TFA_INSPECTIONPANEL)

	local contentpanel = vgui.Create("DPanel", TFA_INSPECTIONPANEL)
	contentpanel:Dock(FILL)
	local spad = ScaleH(pad)
	contentpanel:DockPadding(spad, spad, spad, spad)
	contentpanel:SetName("Inspection Content Panel")

	function contentpanel.Paint() end

	-- Top block (gun name and info)
	self:InspectionVGUIMainInfo(contentpanel)

	-- Bottom block (stats)
	self:InspectionVGUIStats(contentpanel)

	-- Attachments
	self:InspectionVGUIAttachments(contentpanel)

	hook.Run("TFA_InspectVGUI_Finish", self, TFA_INSPECTIONPANEL, contentpanel)
end

function SWEP:DoInspectionDerma()
	if not IsValid(TFA_INSPECTIONPANEL) and self:GetInspectingProgress() > 0.01 then
		self:GenerateInspectionDerma()
	end

	if not IsValid(TFA_INSPECTIONPANEL) then return end
	if not self:OwnerIsValid() then return end
end

cvars.AddChangeCallback("gmod_language", function(convar, oldvalue, newvalue)
	if oldvalue == newvalue then return end

	if IsValid(TFA_INSPECTIONPANEL) then
		TFA_INSPECTIONPANEL:Remove()
	end
end, "TFA_INSPECTIONPANEL_LANGCHECK")

local crosscol = Color(255, 255, 255, 255)
local crossa_cvar = GetConVar("cl_tfa_hud_crosshair_color_a")
local outa_cvar = GetConVar("cl_tfa_hud_crosshair_outline_color_a")
local crosscustomenable_cvar = GetConVar("cl_tfa_hud_crosshair_enable_custom")
local crossr_cvar = GetConVar("cl_tfa_hud_crosshair_color_r")
local crossg_cvar = GetConVar("cl_tfa_hud_crosshair_color_g")
local crossb_cvar = GetConVar("cl_tfa_hud_crosshair_color_b")
local crosslen_cvar = GetConVar("cl_tfa_hud_crosshair_length")
local crosshairwidth_cvar = GetConVar("cl_tfa_hud_crosshair_width")
local drawdot_cvar = GetConVar("cl_tfa_hud_crosshair_dot")
local clen_usepixels = GetConVar("cl_tfa_hud_crosshair_length_use_pixels")
local outline_enabled_cvar = GetConVar("cl_tfa_hud_crosshair_outline_enabled")
local outr_cvar = GetConVar("cl_tfa_hud_crosshair_outline_color_r")
local outg_cvar = GetConVar("cl_tfa_hud_crosshair_outline_color_g")
local outb_cvar = GetConVar("cl_tfa_hud_crosshair_outline_color_b")
local outlinewidth_cvar = GetConVar("cl_tfa_hud_crosshair_outline_width")
local hudenabled_cvar = GetConVar("cl_tfa_hud_enabled")
local cgapscale_cvar = GetConVar("cl_tfa_hud_crosshair_gap_scale")
local tricross_cvar = GetConVar("cl_tfa_hud_crosshair_triangular")

--[[
Function Name:  DrawHUD
Syntax: self:DrawHUD().
Returns:  Nothing.
Notes:  Used to draw the HUD.  Can you read?
Purpose:  HUD
]]
--
function SWEP:DrawHUD()
	-- Inspection Derma
	self:DoInspectionDerma()
	-- 3D2D Ammo
	self:DrawHUDAmmo() --so it's swappable easily

	self:DrawKeyBindHints()
end

function SWEP:DrawHUDBackground()
	--Scope Overlay
	if self:GetIronSightsProgress() > self:GetStatL("ScopeOverlayThreshold") and self:GetStatL("Scoped") then
		self:DrawScopeOverlay()
	end
end

function SWEP:DrawHUD3D2D()
end

local draw = draw
local cam = cam
local surface = surface
local render = render
local Vector = Vector
local Matrix = Matrix
local TFA = TFA
local math = math

local function ColorAlpha(color_in, new_alpha)
	if color_in.a == new_alpha then return color_in end
	return Color(color_in.r, color_in.g, color_in.b, new_alpha)
end

local targ, lactive = 0, -1
local targbool = false
local hudhangtime_cvar = GetConVar("cl_tfa_hud_hangtime")
local hudfade_cvar = GetConVar("cl_tfa_hud_ammodata_fadein")
local lfm, fm = 0, 0

SWEP.CLAmmoProgress = 0
SWEP.TextCol = Color(255, 255, 255, 255) --Primary text color
SWEP.TextColContrast = Color(32, 32, 32, 255) --Secondary Text Color (used for shadow)

function SWEP:DrawHUDAmmo()
	local self2 = self:GetTable()
	local stat = self2.GetStatus(self)

	if self2.GetStatL(self, "BoltAction") then
		if stat == TFA.Enum.STATUS_SHOOTING then
			if not self2.LastBoltShoot then
				self2.LastBoltShoot = l_CT()
			end
		elseif self2.LastBoltShoot then
			self2.LastBoltShoot = nil
		end
	end

	if not hudenabled_cvar:GetBool() then return end

	fm = self:GetFireMode()
	targbool = (not TFA.Enum.HUDDisabledStatus[stat]) or fm ~= lfm
	targbool = targbool or (stat == TFA.Enum.STATUS_SHOOTING and self2.LastBoltShoot and l_CT() > self2.LastBoltShoot + self2.BoltTimerOffset)
	targbool = targbool or (self2.GetStatL(self, "PumpAction") and (stat == TFA.Enum.STATUS_PUMP or (stat == TFA.Enum.STATUS_SHOOTING and self:Clip1() == 0)))
	targbool = targbool or (stat == TFA.Enum.STATUS_FIDGET)

	targ = targbool and 1 or 0
	lfm = fm

	if targ == 1 then
		lactive = RealTime()
	elseif RealTime() < lactive + hudhangtime_cvar:GetFloat() then
		targ = 1
	elseif self:GetOwner():KeyDown(IN_RELOAD) then
		targ = 1
	end

	self2.CLAmmoProgress = math.Approach(self2.CLAmmoProgress, targ, (targ - self2.CLAmmoProgress) * RealFrameTime() * 2 / hudfade_cvar:GetFloat())

	local myalpha = 225 * self2.CLAmmoProgress
	if myalpha < 1 then return end
	local amn = self2.GetStatL(self, "Primary.Ammo")
	if not amn then return end
	if amn == "none" or amn == "" then return end
	local mzpos = self:GetMuzzlePos()

	if self2.GetStatL(self, "IsAkimbo") then
		self2.MuzzleAttachmentRaw = self2.MuzzleAttachmentRaw2 or 1
	end

	if self2.GetHidden(self) then return end

	local xx, yy

	if mzpos and mzpos.Pos then
		local pos = mzpos.Pos
		local textsize = self2.textsize and self2.textsize or 1
		local pl = IsValid(self:GetOwner()) and self:GetOwner() or LocalPlayer()
		local ang = pl:EyeAngles() --(angpos.Ang):Up():Angle()
		ang:RotateAroundAxis(ang:Right(), 90)
		ang:RotateAroundAxis(ang:Up(), -90)
		ang:RotateAroundAxis(ang:Forward(), 0)
		pos = pos + ang:Right() * (self2.textupoffset and self2.textupoffset or -2 * (textsize / 1))
		pos = pos + ang:Up() * (self2.textfwdoffset and self2.textfwdoffset or 0 * (textsize / 1))
		pos = pos + ang:Forward() * (self2.textrightoffset and self2.textrightoffset or -1 * (textsize / 1))
		cam.Start3D()
		local postoscreen = pos:ToScreen()
		cam.End3D()
		xx = postoscreen.x
		yy = postoscreen.y
	else -- fallback to pseudo-3d if no muzzle
		xx, yy = ScrW() * .65, ScrH() * .6
	end

	local v, newx, newy, newalpha = hook.Run("TFA_DrawHUDAmmo", self, xx, yy, myalpha)
	if v ~= nil then
		if v then
			xx = newx or xx
			yy = newy or yy
			myalpha = newalpha or myalpha
		else
			return
		end
	end

	if self:GetInspectingProgress() < 0.01 and self2.GetStatL(self, "Primary.Ammo") ~= "" and self2.GetStatL(self, "Primary.Ammo") ~= 0 then
		local str, clipstr

		if self2.GetStatL(self, "Primary.ClipSize") and self2.GetStatL(self, "Primary.ClipSize") ~= -1 then
			clipstr = language.GetPhrase("tfa.hud.ammo.clip1")

			if self2.GetStatL(self, "IsAkimbo") and self2.GetStatL(self, "EnableAkimboHUD") ~= false then
				str = clipstr:format(math.ceil(self:Clip1() / 2))

				if (self:Clip1() > self2.GetStatL(self, "Primary.ClipSize")) then
					str = clipstr:format(math.ceil(self:Clip1() / 2) - 1 .. " + " .. (math.ceil(self:Clip1() / 2) - math.ceil(self2.GetStatL(self, "Primary.ClipSize") / 2)))
				end
			else
				str = clipstr:format(self:Clip1())

				if (self:Clip1() > self2.GetStatL(self, "Primary.ClipSize")) then
					str = clipstr:format(self2.GetStatL(self, "Primary.ClipSize") .. " + " .. (self:Clip1() - self2.GetStatL(self, "Primary.ClipSize")))
				end
			end

			draw.DrawText(str, "TFASleek", xx + 1, yy + 1, ColorAlpha(self2.TextColContrast, myalpha), TEXT_ALIGN_RIGHT)
			draw.DrawText(str, "TFASleek", xx, yy, ColorAlpha(self2.TextCol, myalpha), TEXT_ALIGN_RIGHT)
			str = language.GetPhrase("tfa.hud.ammo.reserve1"):format(self2.Ammo1(self))
			yy = yy + TFA.Fonts.SleekHeight
			xx = xx - TFA.Fonts.SleekHeight / 3
			draw.DrawText(str, "TFASleekMedium", xx + 1, yy + 1, ColorAlpha(self2.TextColContrast, myalpha), TEXT_ALIGN_RIGHT)
			draw.DrawText(str, "TFASleekMedium", xx, yy, ColorAlpha(self2.TextCol, myalpha), TEXT_ALIGN_RIGHT)
			yy = yy + TFA.Fonts.SleekHeightMedium
			xx = xx - TFA.Fonts.SleekHeightMedium / 3
		else
			str = language.GetPhrase("tfa.hud.ammo1"):format(self2.Ammo1(self))
			draw.DrawText(str, "TFASleek", xx + 1, yy + 1, ColorAlpha(self2.TextColContrast, myalpha), TEXT_ALIGN_RIGHT)
			draw.DrawText(str, "TFASleek", xx, yy, ColorAlpha(self2.TextCol, myalpha), TEXT_ALIGN_RIGHT)
			yy = yy + TFA.Fonts.SleekHeightMedium
			xx = xx - TFA.Fonts.SleekHeightMedium / 3
		end

		str = string.upper(self:GetFireModeName() .. (#self2.GetStatL(self, "FireModes") > 2 and " | +" or ""))

		if self:IsJammed() then
			str = str .. "\n" .. language.GetPhrase("tfa.hud.jammed")
		end

		draw.DrawText(str, "TFASleekSmall", xx + 1, yy + 1, ColorAlpha(self2.TextColContrast, myalpha), TEXT_ALIGN_RIGHT)
		draw.DrawText(str, "TFASleekSmall", xx, yy, ColorAlpha(self2.TextCol, myalpha), TEXT_ALIGN_RIGHT)
		yy = yy + TFA.Fonts.SleekHeightSmall
		xx = xx - TFA.Fonts.SleekHeightSmall / 3

		if self2.GetStatL(self, "IsAkimbo") and self2.GetStatL(self, "EnableAkimboHUD") ~= false then
			local angpos2 = self:GetOwner():ShouldDrawLocalPlayer() and self:GetAttachment(2) or self2.OwnerViewModel:GetAttachment(2)

			if angpos2 then
				local pos2 = angpos2.Pos
				local ts2 = pos2:ToScreen()

				xx, yy = ts2.x, ts2.y
			else
				xx, yy = ScrW() * .35, ScrH() * .6
			end

			if self2.GetStatL(self, "Primary.ClipSize") and self2.GetStatL(self, "Primary.ClipSize") ~= -1 then
				clipstr = language.GetPhrase("tfa.hud.ammo.clip1")

				str = clipstr:format(math.floor(self:Clip1() / 2))

				if (math.floor(self:Clip1() / 2) > math.floor(self2.GetStatL(self, "Primary.ClipSize") / 2)) then
					str = clipstr:format(math.floor(self:Clip1() / 2) - 1 .. " + " .. (math.floor(self:Clip1() / 2) - math.floor(self2.GetStatL(self, "Primary.ClipSize") / 2)))
				end

				draw.DrawText(str, "TFASleek", xx + 1, yy + 1, ColorAlpha(self2.TextColContrast, myalpha), TEXT_ALIGN_RIGHT)
				draw.DrawText(str, "TFASleek", xx, yy, ColorAlpha(self2.TextCol, myalpha), TEXT_ALIGN_RIGHT)
				str = language.GetPhrase("tfa.hud.ammo.reserve1"):format(self2.Ammo1(self))
				yy = yy + TFA.Fonts.SleekHeight
				xx = xx - TFA.Fonts.SleekHeight / 3
				draw.DrawText(str, "TFASleekMedium", xx + 1, yy + 1, ColorAlpha(self2.TextColContrast, myalpha), TEXT_ALIGN_RIGHT)
				draw.DrawText(str, "TFASleekMedium", xx, yy, ColorAlpha(self2.TextCol, myalpha), TEXT_ALIGN_RIGHT)
				yy = yy + TFA.Fonts.SleekHeightMedium
				xx = xx - TFA.Fonts.SleekHeightMedium / 3
			else
				str = language.GetPhrase("tfa.hud.ammo1"):format(self2.Ammo1(self))
				draw.DrawText(str, "TFASleek", xx + 1, yy + 1, ColorAlpha(self2.TextColContrast, myalpha), TEXT_ALIGN_RIGHT)
				draw.DrawText(str, "TFASleek", xx, yy, ColorAlpha(self2.TextCol, myalpha), TEXT_ALIGN_RIGHT)
				yy = yy + TFA.Fonts.SleekHeightMedium
				xx = xx - TFA.Fonts.SleekHeightMedium / 3
			end

			str = string.upper(self:GetFireModeName() .. (#self2.FireModes > 2 and " | +" or ""))
			draw.DrawText(str, "TFASleekSmall", xx + 1, yy + 1, ColorAlpha(self2.TextColContrast, myalpha), TEXT_ALIGN_RIGHT)
			draw.DrawText(str, "TFASleekSmall", xx, yy, ColorAlpha(self2.TextCol, myalpha), TEXT_ALIGN_RIGHT)
		end

		if self2.GetStatL(self, "Secondary.Ammo") and self2.GetStatL(self, "Secondary.Ammo") ~= "" and self2.GetStatL(self, "Secondary.Ammo") ~= "none" and self2.GetStatL(self, "Secondary.Ammo") ~= 0 and not self2.GetStatL(self, "IsAkimbo") then
			if self2.GetStatL(self, "Secondary.ClipSize") and self2.GetStatL(self, "Secondary.ClipSize") ~= -1 then
				clipstr = language.GetPhrase("tfa.hud.ammo.clip2")
				str = (self:Clip2() > self2.GetStatL(self, "Secondary.ClipSize")) and clipstr:format(self2.GetStatL(self, "Secondary.ClipSize") .. " + " .. (self:Clip2() - self2.GetStatL(self, "Primary.ClipSize"))) or clipstr:format(self:Clip2())
				draw.DrawText(str, "TFASleekSmall", xx + 1, yy + 1, ColorAlpha(self2.TextColContrast, myalpha), TEXT_ALIGN_RIGHT)
				draw.DrawText(str, "TFASleekSmall", xx, yy, ColorAlpha(self2.TextCol, myalpha), TEXT_ALIGN_RIGHT)
				str = language.GetPhrase("tfa.hud.ammo.reserve2"):format(self2.Ammo2(self))
				yy = yy + TFA.Fonts.SleekHeightSmall
				xx = xx - TFA.Fonts.SleekHeightSmall / 3
				draw.DrawText(str, "TFASleekSmall", xx + 1, yy + 1, ColorAlpha(self2.TextColContrast, myalpha), TEXT_ALIGN_RIGHT)
				draw.DrawText(str, "TFASleekSmall", xx, yy, ColorAlpha(self2.TextCol, myalpha), TEXT_ALIGN_RIGHT)
			else
				str = language.GetPhrase("tfa.hud.ammo2"):format(self2.Ammo2(self))
				draw.DrawText(str, "TFASleekSmall", xx + 1, yy + 1, ColorAlpha(self2.TextColContrast, myalpha), TEXT_ALIGN_RIGHT)
				draw.DrawText(str, "TFASleekSmall", xx, yy, ColorAlpha(self2.TextCol, myalpha), TEXT_ALIGN_RIGHT)
			end
		end
	end
end

local sv_tfa_recoil_legacy = GetConVar("sv_tfa_recoil_legacy")
local cl_tfa_hud_crosshair_pump = GetConVar("cl_tfa_hud_crosshair_pump")
local sv_tfa_fixed_crosshair = GetConVar("sv_tfa_fixed_crosshair")

local crosshairMatrix = Matrix()
local crosshairMatrixLeft = Matrix()
local crosshairMatrixRight = Matrix()
local crosshairRotation = Angle()

local pixelperfectshift = Vector(-0.5)

function SWEP:CalculateCrosshairConeRecoil()
	return self:GetStatL("CrosshairConeRecoilOverride", false) or self:CalculateConeRecoil()
end

function SWEP:DoDrawCrosshair()
	local self2 = self:GetTable()
	local x, y

	if not self2.ratios_calc or not self2.DrawCrosshairDefault then return true end
	if self2.GetHolding(self) then return true end

	local stat = self2.GetStatus(self)

	if not crosscustomenable_cvar:GetBool() then
		return TFA.Enum.ReloadStatus[stat] or math.min(1 - (self2.IronSightsProgressUnpredicted2 or self:GetIronSightsProgress()), 1 - self:GetSprintProgress(), 1 - self:GetInspectingProgress()) <= 0.5
	end

	self2.clrelp = self2.clrelp or 0
	self2.clrelp = math.Approach(
		self2.clrelp,
		TFA.Enum.ReloadStatus[stat] and 0 or 1,
		((TFA.Enum.ReloadStatus[stat] and 0 or 1) - self2.clrelp) * RealFrameTime() * 7)

	local crossa = crossa_cvar:GetFloat() *
		math.pow(math.min(1 - (((self2.IronSightsProgressUnpredicted2 or self:GetIronSightsProgress()) and
			not self2.GetStatL(self, "DrawCrosshairIronSights")) and (self2.IronSightsProgressUnpredicted2 or self:GetIronSightsProgress()) or 0),
			1 - self:GetSprintProgress(),
			1 - self:GetInspectingProgress(),
			self2.clrelp),
		2)

	local outa = outa_cvar:GetFloat() *
		math.pow(math.min(1 - (((self2.IronSightsProgressUnpredicted2 or self:GetIronSightsProgress()) and
			not self2.GetStatL(self, "DrawCrosshairIronSights")) and (self2.IronSightsProgressUnpredicted2 or self:GetIronSightsProgress()) or 0),
			1 - self:GetSprintProgress(),
			1 - self:GetInspectingProgress(),
			self2.clrelp),
		2)

	local ply = LocalPlayer()
	if not ply:IsValid() or self:GetOwner() ~= ply then return false end

	if not ply.interpposx then
		ply.interpposx = ScrW() / 2
	end

	if not ply.interpposy then
		ply.interpposy = ScrH() / 2
	end

	local tr = {}
	tr.start = ply:GetShootPos()
	tr.endpos = tr.start + ply:GetAimVector() * 0x7FFF
	tr.filter = ply
	tr.mask = MASK_SHOT
	local traceres = util.TraceLine(tr)
	local targent = traceres.Entity

	-- If we're drawing the local player, draw the crosshair where they're aiming
	-- instead of in the center of the screen.
	if self:GetOwner():ShouldDrawLocalPlayer() and not ply:GetNW2Bool("ThirtOTS", false) then
		local coords = traceres.HitPos:ToScreen()
		coords.x = math.Clamp(coords.x, 0, ScrW())
		coords.y = math.Clamp(coords.y, 0, ScrH())
		ply.interpposx = math.Approach(ply.interpposx, coords.x, (ply.interpposx - coords.x) * RealFrameTime() * 7.5)
		ply.interpposy = math.Approach(ply.interpposy, coords.y, (ply.interpposy - coords.y) * RealFrameTime() * 7.5)
		x, y = ply.interpposx, ply.interpposy
		-- Center of screen
	elseif sv_tfa_fixed_crosshair:GetBool() then
		x, y = ScrW() / 2, ScrH() / 2
	else
		tr.endpos = tr.start + self:GetAimAngle():Forward() * 0x7FFF
		local pos = util.TraceLine(tr).HitPos:ToScreen()
		x, y = pos.x, pos.y
	end

	TFA.LastCrosshairPosX, TFA.LastCrosshairPosY = x, y

	local v = hook.Run("TFA_DrawCrosshair", self, x, y)

	if v ~= nil then
		return v
	end

	local s_cone = self:CalculateCrosshairConeRecoil()

	if not self2.selftbl then
		self2.selftbl = {ply, self}
	end

	local crossr, crossg, crossb, crosslen, crosshairwidth, drawdot, teamcol
	teamcol = self2.GetTeamColor(self, targent)
	crossr = crossr_cvar:GetFloat()
	crossg = crossg_cvar:GetFloat()
	crossb = crossb_cvar:GetFloat()
	crosslen = crosslen_cvar:GetFloat() * 0.01
	crosscol.r = crossr
	crosscol.g = crossg
	crosscol.b = crossb
	crosscol.a = crossa
	crosscol = ColorMix(crosscol, teamcol, 1, CMIX_MULT)
	crossr = crosscol.r
	crossg = crosscol.g
	crossb = crosscol.b
	crossa = crosscol.a
	crosshairwidth = crosshairwidth_cvar:GetFloat()
	drawdot = drawdot_cvar:GetBool()
	local scale = (s_cone * 90) / self:GetOwner():GetFOV() * ScrH() / 1.44 * cgapscale_cvar:GetFloat()

	if self:GetSprintProgress() >= 0.1 and not self:GetStatL("AllowSprintAttack", false) then
		scale = scale * (1 + TFA.Cubic(self:GetSprintProgress() - 0.1) * 6)
	end

	if self2.clrelp < 0.9 then
		scale = scale * Lerp(TFA.Cubic(0.9 - self2.clrelp) * 1.111, 1, 8)
	end

	local gap = math.Round(scale / 2) * 2
	local length

	if not clen_usepixels:GetBool() then
		length = gap + ScrH() * 1.777 * crosslen
	else
		length = gap + crosslen * 100
	end

	local extraRotation = 0
	local cPos = Vector(x, y)

	if stat == TFA.Enum.STATUS_PUMP and cl_tfa_hud_crosshair_pump:GetBool() then
		if tricross_cvar:GetBool() then
			extraRotation =  TFA.Quintic(self:GetStatusProgress(true))
			local mul = 360
			extraRotation = extraRotation * mul
		else
			extraRotation = TFA.Quintic(TFA.Cosine(self:GetStatusProgress(true)))
			local mul = -180

			if extraRotation < 0.5 then
				extraRotation = extraRotation * mul
			else
				extraRotation = (1 - extraRotation) * mul
			end
		end
	end

	extraRotation = extraRotation - EyeAngles().r

	crosshairMatrix:Identity()
	crosshairMatrix:Translate(cPos)
	crosshairRotation.y = extraRotation
	crosshairMatrix:Rotate(crosshairRotation)

	if tricross_cvar:GetBool() then
		crosshairMatrixLeft:Identity()
		crosshairMatrixRight:Identity()

		crosshairMatrixLeft:Translate(cPos)
		crosshairMatrixRight:Translate(cPos)

		crosshairRotation.y = extraRotation + 135
		crosshairMatrixRight:SetAngles(crosshairRotation)
		crosshairRotation.y = extraRotation - 135
		crosshairMatrixLeft:SetAngles(crosshairRotation)

		if crosshairwidth % 2 ~= 0 then
			crosshairMatrixLeft:Translate(pixelperfectshift)
			crosshairMatrixRight:Translate(pixelperfectshift)
		end
	end

	DisableClipping(true)

	render.PushFilterMag(TEXFILTER.ANISOTROPIC)
	render.PushFilterMin(TEXFILTER.ANISOTROPIC)

	--Outline
	if outline_enabled_cvar:GetBool() then
		local outr, outg, outb, outlinewidth
		outr = outr_cvar:GetFloat()
		outg = outg_cvar:GetFloat()
		outb = outb_cvar:GetFloat()
		outlinewidth = outlinewidth_cvar:GetFloat()

		cam.PushModelMatrix(crosshairMatrix)
		surface.SetDrawColor(outr, outg, outb, outa)

		local tHeight = math.Round(length - gap + outlinewidth * 2) + crosshairwidth

		local tX, tY, tWidth =
			math.Round(-outlinewidth) - crosshairwidth / 2,
			-gap * self:GetStatL("Primary.SpreadBiasPitch") - tHeight + outlinewidth,
			math.Round(outlinewidth * 2) + crosshairwidth

		-- Top
		surface.DrawRect(tX, tY, tWidth, tHeight)
		cam.PopModelMatrix()

		if tricross_cvar:GetBool() then
			tY = -gap - tHeight

			cam.PushModelMatrix(crosshairMatrixLeft)
			surface.DrawRect(tX, tY + outlinewidth, tWidth, tHeight)
			cam.PopModelMatrix()

			cam.PushModelMatrix(crosshairMatrixRight)
			surface.DrawRect(tX, tY + outlinewidth, tWidth, tHeight)
			cam.PopModelMatrix()
		else
			cam.PushModelMatrix(crosshairMatrix)

			local width = math.Round(length - gap + outlinewidth * 2) + crosshairwidth
			local realgap = math.Round(gap * self:GetStatL("Primary.SpreadBiasYaw") - outlinewidth) - crosshairwidth / 2

			-- Left
			surface.DrawRect(
				-realgap - width,
				math.Round(-outlinewidth) - crosshairwidth / 2,
				width,
				math.Round(outlinewidth * 2) + crosshairwidth)

			-- Right
			surface.DrawRect(
				realgap,
				math.Round(-outlinewidth) - crosshairwidth / 2,
				width,
				math.Round(outlinewidth * 2) + crosshairwidth)

			-- Bottom
			surface.DrawRect(
				math.Round(-outlinewidth) - crosshairwidth / 2,
				math.Round(gap * self:GetStatL("Primary.SpreadBiasPitch") - outlinewidth) - crosshairwidth / 2,
				math.Round(outlinewidth * 2) + crosshairwidth,
				math.Round(length - gap + outlinewidth * 2) + crosshairwidth)

			cam.PopModelMatrix()
		end

		if drawdot then
			cam.PushModelMatrix(crosshairMatrix)
			surface.DrawRect(-math.Round((crosshairwidth - 1) / 2) - math.Round(outlinewidth), -math.Round((crosshairwidth - 1) / 2) - math.Round(outlinewidth), math.Round(outlinewidth * 2) + crosshairwidth, math.Round(outlinewidth * 2) + crosshairwidth) --dot
			cam.PopModelMatrix()
		end
	end

	--Main Crosshair
	cam.PushModelMatrix(crosshairMatrix)
	surface.SetDrawColor(crossr, crossg, crossb, crossa)

	local tHeight = math.Round(length - gap) + crosshairwidth

	local tX, tY, tWidth =
		-crosshairwidth / 2,
		math.Round(-gap * self:GetStatL("Primary.SpreadBiasPitch") - tHeight),
		crosshairwidth

	-- Top
	surface.DrawRect(tX, tY, tWidth, tHeight)
	cam.PopModelMatrix()

	if tricross_cvar:GetBool() then
		local xhl = math.Round(length - gap) + crosshairwidth

		tY = math.Round(-gap - tHeight)

		cam.PushModelMatrix(crosshairMatrixLeft)
		surface.DrawRect(tX, tY, tWidth, tHeight)
		cam.PopModelMatrix()

		cam.PushModelMatrix(crosshairMatrixRight)
		surface.DrawRect(tX, tY, tWidth, tHeight)
		cam.PopModelMatrix()
	else
		cam.PushModelMatrix(crosshairMatrix)

		local width = math.Round(length - gap) + crosshairwidth
		local realgap = math.Round(gap * self:GetStatL("Primary.SpreadBiasYaw")) - crosshairwidth / 2

		-- Left
		surface.DrawRect(
			-realgap - width,
			-crosshairwidth / 2,
			width,
			crosshairwidth)

		-- Right
		surface.DrawRect(
			realgap,
			-crosshairwidth / 2,
			width,
			crosshairwidth)

		-- Bottom
		surface.DrawRect(
			-crosshairwidth / 2,
			math.Round(gap * self:GetStatL("Primary.SpreadBiasPitch")) - crosshairwidth / 2,
			crosshairwidth,
			math.Round(length - gap) + crosshairwidth)

		cam.PopModelMatrix()
	end

	render.PopFilterMag()
	render.PopFilterMin()

	if drawdot then
		cam.PushModelMatrix(crosshairMatrix)
		surface.DrawRect(-math.Round((crosshairwidth - 1) / 2), -math.Round((crosshairwidth - 1) / 2), crosshairwidth, crosshairwidth) --dot
		cam.PopModelMatrix()
	end

	DisableClipping(false)

	return true
end

function SWEP:DrawScopeOverlay()
	if hook.Run("TFA_DrawScopeOverlay", self) == true then return end
	local self2 = self:GetTable()

	local tbl

	if self2.GetStatL(self, "Secondary.UseACOG") then
		tbl = TFA_SCOPE_ACOG
	end

	if self2.GetStatL(self, "Secondary.UseMilDot") then
		tbl = TFA_SCOPE_MILDOT
	end

	if self2.GetStatL(self, "Secondary.UseSVD") then
		tbl = TFA_SCOPE_SVD
	end

	if self2.GetStatL(self, "Secondary.UseParabolic") then
		tbl = TFA_SCOPE_PARABOLIC
	end

	if self2.GetStatL(self, "Secondary.UseElcan") then
		tbl = TFA_SCOPE_ELCAN
	end

	if self2.GetStatL(self, "Secondary.UseGreenDuplex") then
		tbl = TFA_SCOPE_GREENDUPLEX
	end

	if self2.GetStatL(self, "Secondary.UseAimpoint") then
		tbl = TFA_SCOPE_AIMPOINT
	end

	if self2.GetStatL(self, "Secondary.UseMatador") then
		tbl = TFA_SCOPE_MATADOR
	end

	if self2.GetStatL(self, "Secondary.ScopeTable") then
		tbl = self2.GetStatL(self, "Secondary.ScopeTable")
	end

	if not tbl then
		tbl = TFA_SCOPE_MILDOT
	end

	local w, h = ScrW(), ScrH()

	for k, v in pairs(tbl) do
		local dimension = h

		if k == "ScopeBorder" then
			if istable(v) then
				surface.SetDrawColor(v)
			else
				surface.SetDrawColor(color_black)
			end

			surface.DrawRect(0, 0, w / 2 - dimension / 2, dimension)
			surface.DrawRect(w / 2 + dimension / 2, 0, w / 2 - dimension / 2, dimension)
		elseif k == "ScopeMaterial" then
			surface.SetMaterial(v)
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawTexturedRect(w / 2 - dimension / 2, (h - dimension) / 2, dimension, dimension)
		elseif k == "ScopeOverlay" then
			surface.SetMaterial(v)
			surface.SetDrawColor(255, 255, 255, 255)
			surface.DrawTexturedRect(0, 0, w, h)
		elseif k == "ScopeCrosshair" then
			local t = type(v)

			if t == "IMaterial" then
				surface.SetMaterial(v)
				surface.SetDrawColor(255, 255, 255, 255)
				surface.DrawTexturedRect(w / 2 - dimension / 4, h / 2 - dimension / 4, dimension / 2, dimension / 2)
			elseif t == "table" then
				if not v.cached then
					v.cached = true
					v.r = v.r or v.x or v[1] or 0
					v.g = v.g or v.y or v[2] or v[1] or 0
					v.b = v.b or v.z or v[3] or v[1] or 0
					v.a = v.a or v[4] or 255
					v.s = v.Scale or v.scale or v.s or 0.25
				end

				surface.SetDrawColor(v.r, v.g, v.b, v.a)

				if v.Material then
					surface.SetMaterial(v.Material)
					surface.DrawTexturedRect(w / 2 - dimension * v.s / 2, h / 2 - dimension * v.s / 2, dimension * v.s, dimension * v.s)
				elseif v.Texture then
					surface.SetTexture(v.Texture)
					surface.DrawTexturedRect(w / 2 - dimension * v.s / 2, h / 2 - dimension * v.s / 2, dimension * v.s, dimension * v.s)
				else
					surface.DrawRect(w / 2 - dimension * v.s / 2, h / 2, dimension * v.s, 1)
					surface.DrawRect(w / 2, h / 2 - dimension * v.s / 2, 1, dimension * v.s)
				end
			end
		else
			if k == "scopetex" then
				dimension = dimension * self:GetStatL("ScopeScale") ^ 2 * TFA_SCOPE_SCOPESCALE
			elseif k == "reticletex" then
				dimension = dimension * (self:GetStatL("ReticleScale") and self:GetStatL("ReticleScale") or 1) ^ 2 * (TFA_SCOPE_RETICLESCALE and TFA_SCOPE_RETICLESCALE or 1)
			else
				dimension = dimension * self:GetStatL("ReticleScale") ^ 2 * TFA_SCOPE_DOTSCALE
			end

			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetTexture(v)
			surface.DrawTexturedRect(w / 2 - dimension / 2, (h - dimension) / 2, dimension, dimension)
		end
	end
end

SWEP.KeyNameOverrides = {
	["MOUSE1"] = "tfa.keys.lmb",
	["MOUSE2"] = "tfa.keys.rmb",
	["MOUSE3"] = "tfa.keys.mmb",
}

function SWEP:GetKeyBind(binds, altbind)
	if type(binds) == "string" then
		binds = {binds}
	end

	if altbind then
		local cvar = GetConVar("cl_tfa_keys_" .. altbind)

		if cvar and cvar:GetInt() > 0 then
			local key = input.GetKeyName(cvar:GetInt())

			return language.GetPhrase(self.KeyNameOverrides[key] or key:upper())
		end
	end

	local result = {}
	for _,bind in ipairs(binds) do
		local binding = input.LookupBinding(bind, true) or input.LookupBinding(bind)

		table.insert(result, binding and language.GetPhrase(self.KeyNameOverrides[binding] or binding:upper()) or bind)
	end

	return result
end

local cv_cm = GetConVar("sv_tfa_cmenu")
local cv_cm_key = GetConVar("sv_tfa_cmenu_key")
local cv_ironsights = GetConVar("sv_tfa_ironsights_enabled")

function SWEP:PrePopulateKeyBindHints(keys)
	return keys
end

function SWEP:PostPopulateKeyBindHints(keys)
	return keys
end

function SWEP:PopulateKeyBindHints(keys)
	keys = keys or {}

	keys = self:PrePopulateKeyBindHints(keys) or keys

	local CanAim = cv_ironsights:GetInt() and self:GetStatL("Secondary.IronSightsEnabled")
	if CanAim then
		table.insert(keys, {
			label = language.GetPhrase("tfa.hint.keys.ironsights"),
			keys = {self:GetKeyBind({"+attack2"})}
		})
	end

	if self.BashBase then
		if self:GetStatL("Secondary.CanBash") ~= false then
			table.insert(keys, {
				label = language.GetPhrase("tfa.hint.keys.meleebash"),
				keys = {CanAim and self:GetKeyBind({"+zoom"}, "bash") or self:GetKeyBind("+attack2")}
			})
		end
	elseif self.AltAttack then
		table.insert(keys, {
			label = language.GetPhrase("tfa.hint.keys.altattack"),
			keys = {CanAim and self:GetKeyBind({"+zoom"}, "bash") or self:GetKeyBind("+attack2")}
		})
	end

	if cv_cm:GetBool() and cv_cm_key:GetInt() ~= 0 then
		local kcode = cv_cm_key:GetInt()
		table.insert(keys, {
			label = language.GetPhrase("tfa.hint.keys.customize"),
			keys = {kcode > 0 and language.GetPhrase(input.GetKeyName(kcode)):upper() or self:GetKeyBind({"+menu_context"}, "customize")}
		})
	end

	if self:GetActivityEnabled(ACT_VM_FIDGET) or self.InspectionActions then
		table.insert(keys, {
			label = language.GetPhrase("tfa.hint.keys.inspect"),
			keys = {self:GetKeyBind({"+reload"}, "inspect")}
		})
	end

	if self:GetStatL("SelectiveFire") then
		table.insert(keys, {
			label = language.GetPhrase("tfa.hint.keys.firemode"),
			keys = {self:GetKeyBind({"+use", "+reload"}, "firemode")}
		})
	end

	if not self.IsMelee and not self.IsBow and not self.IsKnife then
		table.insert(keys, {
			label = language.GetPhrase("tfa.hint.keys.safety"),
			keys = {self:GetKeyBind({"+speed"}), self:GetKeyBind({"+use", "+reload"}, "firemode")}
		})
	end

	if self:GetStatL("FlashlightAttachmentName") ~= nil or self:GetStatL("FlashlightAttachment", 0) > 0 then
		table.insert(keys, {
			label = language.GetPhrase("tfa.hint.keys.flashlight"),
			keys = {self:GetKeyBind({"impulse 100"})}
		})
	end

	if self:GetStatRawL("CanBeSilenced") then
		table.insert(keys, {
			label = language.GetPhrase("tfa.hint.keys.silencer"),
			keys = {self:GetKeyBind({"+use", "+attack"}, "silencer")}
		})
	end

	keys = self:PostPopulateKeyBindHints(keys) or keys
	keys = hook.Run("TFA_PopulateKeyBindHints", self, keys) or keys

	if #keys > 0 then
		table.insert(keys, {
			label = language.GetPhrase("tfa.hint.keys.showkeys"),
			keys = {self:GetKeyBind({"+showscores"})}
		})
	end

	return keys
end

local GradientMaterial = Material("gui/gradient")
-- SWEP.KeyBindHintAlphaLastUpdate = -1

local lastwep_kb
function SWEP:ResetKeyBindHintAlpha(force)
	if (not force or force == "") and lastwep_kb == self then return end
	lastwep_kb = self

	self.KeyBindHintAlphaLastUpdate = CurTime()
end

local cv_hint_enabled = GetConVar("cl_tfa_hud_keybindhints_enabled")
local cv_hint_solidtime = GetConVar("cl_tfa_hud_keybindhints_solidtime")
local cv_hint_fadeintime = GetConVar("cl_tfa_hud_keybindhints_fadeintime")
local cv_hint_fadeouttime = GetConVar("cl_tfa_hud_keybindhints_fadeouttime")

local HintAlpha = 0
function SWEP:DrawKeyBindHints()
	if self:GetOwner():KeyDown(IN_SCORE) or not self.KeyBindHintAlphaLastUpdate then
		self:ResetKeyBindHintAlpha(true)
	end

	local fadeout =  CurTime() >= self.KeyBindHintAlphaLastUpdate + cv_hint_solidtime:GetFloat()
	HintAlpha = math.Clamp(HintAlpha + (fadeout and FrameTime() * -1000 / cv_hint_fadeouttime:GetFloat() or FrameTime() * 1000 / cv_hint_fadeintime:GetFloat()), 0, 255)

	if not cv_hint_enabled:GetBool() or cv_hint_solidtime:GetFloat() <= 0 then return end

	local a = HintAlpha
	if self:GetInspectingProgress() > 0 then
		a = a * (1 - self:GetInspectingProgress())
	end

	if a <= 0 then return end

	local maincol, bgcol = ColorAlpha(INSPECTION_PRIMARYCOLOR, a), INSPECTION_BACKGROUND
	local textfont = "TFA_INSPECTION_SMALL"
	local textheight = TFA.Fonts.InspectionHeightSmall

	local x, y = ScrW() - ScaleH(80), ScrH() * .5
	local bgpad = ScaleH(8)

	local keystbl = self:PopulateKeyBindHints({})
	if #keystbl <= 0 then return end

	local keystr = {}
	local TargetWidth = 0
	surface.SetFont(textfont)
	for _, tbl in ipairs(keystbl) do
		local key = ""
		for k, v in ipairs(tbl.keys) do
			tbl.keys[k] = type(v) == "table" and table.concat(v, " + ") or v
		end

		local keytext = string.format("[%s] - %s", table.concat(tbl.keys, " + "), tbl.label)

		local tw, _ = surface.GetTextSize(keytext)
		TargetWidth = math.max(tw, TargetWidth)

		table.insert(keystr, keytext)
	end
	x = x - TargetWidth
	y = y - textheight * #keystr * .5

	if hook.Run("TFA_PreDrawKeyBindHint", self, x, y, a, keystbl, keystr) == true then return end

	surface.SetDrawColor(bgcol.r, bgcol.g, bgcol.b, a)
	surface.SetMaterial(GradientMaterial)
	surface.DrawTexturedRectUV(x - bgpad, y - bgpad, TargetWidth + bgpad * 2, textheight * #keystr + bgpad * 2, 1, 0, 0, 1)

	for i, key in ipairs(keystr) do
		TextShadowPaint({Text = key, Font = textfont, TextColor = maincol, TextPosX = x, TextPosY = y + (i - 1) * textheight})
	end

	hook.Run("TFA_PostDrawKeyBindHint", self, x, y, a, keystbl, keystr)
end


local fsin, icon
local matcache = {}

function SWEP:DrawWeaponSelection(x, y, wide, tall, alpha)
	local self2 = self:GetTable()

	surface.SetDrawColor(255, 255, 255, alpha)

	icon = self2.GetStatL(self, "WepSelectIcon_Override", self2.WepSelectIcon)

	if not icon then
		self2.IconFix(self)

		return
	end

	local ticon = type(icon)

	if ticon == "IMaterial" then
		surface.SetMaterial(icon)
	elseif ticon == "string" then
		if not matcache[icon] then
			matcache[icon] = Material(icon, "smooth noclamp")
		end

		surface.SetMaterial(matcache[icon])
	else
		surface.SetTexture(icon)
	end

	fsin = self2.BounceWeaponIcon and math.sin( RealTime() * 10 ) * 5 or 0

	-- Borders
	y = y + 10
	x = x + 10
	wide = wide - 20

	surface.DrawTexturedRect(x + fsin, y - fsin, wide - fsin * 2, wide / 2 + fsin)

	self2.PrintWeaponInfo(self, x + wide + 20, y + tall * 0.95, alpha)
end
