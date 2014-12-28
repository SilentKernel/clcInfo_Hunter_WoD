local _, class = UnitClass("player")
if class ~= "HUNTER" then return end

-- survival only shots
local emod = clcInfo.env

emod:RegisterSpecialisation(1, {
	bw = {
		id = emod.spells["Bestial Wrath"],
		GetCD = function()
			if emod.last_ability == emod.spells["Bestial Wrath"] then return 100 end
			if emod.s_bw > 0 then return 100 end
			return emod:GetCooldown(emod.spells["Bestial Wrath"])
		end,
		UpdateStatus = function()
			emod.s_bw = 10.0
		end,
		info = "Bestial Wrath",
	},

	kc = {
		id = emod.spells["Kill Command"],
		GetCD = function()
			if emod.last_ability == emod.spells["Kill Command"] then return 100 end
			local cd = emod:GetCooldown(emod.spells["Kill Command"])
			-- KC costs half focus under bestial wrath
			local cost = 40
			if emod.s_bw > 0 then cost = cost * 0.5 end
			-- femaledwarf suggests that KC should be waited on if there's
			-- 0.3s or less before we'd have the appropriate amount of focus
			if cd <= 0.3 and emod:UpdateFocus(emod:GetFocus(), 0.3) >= cost then return 0 end
			return cd
		end,
		UpdateStatus = function()
			emod:SetTime(1.0)
			emod:UseFocus(40)
		end,
		info = "Kill Command",
	},

	ff = {
		id = emod.spells["Focus Fire"],
		GetCD = function()
			-- don't suggest wasting GCDs in BW with Focus Fire
			if emod.s_bw > 0 then return 100 end
			if emod.last_ability == emod.spells["Focus Fire"] then return 100 end
			if emod.s_frenzy == 5 then return 0 end
			return 100
		end,
		UpdateStatus = function()
			emod:SetTime(1.0)
			emod.s_frenzy = 0
		end,
		info = "Focus Fire",
	},

	ac = {
		id = emod:GetBaseAbility("ac").id,
		GetCD = function()
			-- femaledwarf.com recommends not arcane shotting < 63 focus
			-- for beast mastery
			if emod:GetFocus() < 63 then return 100 end
			return 0
		end,
		UpdateStatus = emod:GetBaseAbility("ac").UpdateStatus,
		info = emod:GetBaseAbility("ac").info,
	},

	lr = {
		id = emod:GetBaseAbility("lr").id,
		GetCD = function()
			-- beastmastery would like to align lynx rush with BW
			if emod:GetCooldown(emod.spells["Bestial Wrath"]) < 10.0 then return 100 end
			-- otherwise, return default logic
			return emod:GetBaseAbility("lr").GetCD()
		end,
		UpdateStatus = emod:GetBaseAbility("lr").UpdateStatus,
		info = emod:GetBaseAbility("lr").info,
	},

	db = {
		id = emod:GetBaseAbility("db").id,
		GetCD = function()
			-- don't suggest wasting GCDs in BW with Dire Beast
			if emod.s_bw > 0 then return 100 end
			return emod:GetBaseAbility("db").GetCD()
		end,
		UpdateStatus = emod:GetBaseAbility("db").UpdateStatus,
		info = emod:GetBaseAbility("db").info,
	},
})
