local _, class = UnitClass("player")
if class ~= "HUNTER" then return end

-- marksman only shots
local emod = clcInfo.env

emod:RegisterSpecialisation(2, {
	cs = {
		id = emod.spells["Chimera Shot"],
		GetCD = function()
			if emod.last_ability == emod.spells["Chimera Shot"] then return 100 end
			return emod:GetCooldown(emod.spells["Chimera Shot"])
		end,
		UpdateStatus = function()
			emod:SetTime(1.0)
			emod:UseFocus(45)
		end,
		info = "Chimera Shot",
	},

	rf = {
		id = emod.spells["Rapid Fire"],
		GetCD = function()
			-- don't show major cooldowns for trash
			if s1 == emod.spells["Rapid Fire"] then return 100 end
			if not emod.s_boss then return 100 end
			if s_rf > 0 then return 100 end
			return emod:GetCooldown(emod.spells["Rapid Fire"])
		end,
		UpdateStatus = function()
			emod.s_rf = 15.0
		end,
		info = "Rapid Fire",
	},

	mm = {
		id = emod.spells["Aimed Shot"],
		GetCD = function()
			if emod.talents[12] then
				if emod.s_toth > 0 then return emod:GetTimeUntilFocus(emod.spells["Aimed Shot"]) end
			end
			return 100
		end,
		UpdateStatus = function()
			emod:SetTime(1.0)
			emod:UseFocus(30)
			emod.s_toth = emod.s_toth - 1
		end,
		info = "Aimed Shot (TotH)",
	},
	
	am = {
		id = emod.spells["Aimed Shot"],
		GetCD = function() return 0 end,
		UpdateStatus = function()
			emod:SetTime(1.0)
			emod:UseFocus(50)
		end,
		info = "Aimed Shot",
	},

	ss = {
		id = emod.spells["Steady Shot"],
		GetCD = function() return 1.0 end,
		UpdateStatus = function()
			emod:SetTime(emod:GetCastTime(emod.spells["Steady Shot"]))
			emod:UseFocus(-14)
			emod.s_rcss = emod.s_rcss + 1
		end,
		info = "Steady Shot",
	},
})
