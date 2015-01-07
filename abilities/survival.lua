local _, class = UnitClass("player")
if class ~= "HUNTER" then return end

-- survival only shots
local emod = clcInfo.env

emod:RegisterSpecialisation(3, {
	ba = {
		id = emod.spells["Black Arrow"],
		GetCD = function()
			if emod.last_ability == emod.spells["Black Arrow"] then return 100 end
			if emod.s_ba > 0 then return 100 end
			return emod:GetCooldown(emod.spells["Black Arrow"])
		end,
		UpdateStatus = function()
			emod:SetTime(1.0)
			emod:UseFocus(35)
		end,
		info = "Black Arrow",
	},
	
	es = {
		id = emod.spells["Explosive Shot"],
		GetCD = function()
			-- LnL gives two procs but also resets the CD of the third "real"
			-- Explosive Shot. So we need to record that LnL was used so that
			-- we can suggest three in a row.
			if emod.s_lnl > 0 or emod.s_esc == 1 then return 0 end
			if emod.numOfTargets > 5 then return 100 end
			if emod.last_ability == emod.spells["Explosive Shot"] then return 100 end
			-- femaledwarf suggests that KC should be waited on if there's
			-- 0.3s or less before we'd have the appropriate amount of focus
			--print(emod:GetCooldown(emod.spells["Explosive Shot"]))
			local cd = emod:GetCooldown(emod.spells["Explosive Shot"])
			if cd <= 0.3 and emod:UpdateFocus(emod:GetFocus(), 0.3) >= 25 then return 0 end
			return cd
		end,
		UpdateStatus = function()
			emod:SetTime(1.0)
			if emod.s_lnl > 0 then
				emod.s_lnl = max(0, emod.s_lnl - 1)
				emod.s_esc = 1
			else
				emod:UseFocus(15)
				emod.s_esc = 0
			end
		end,
		info = "Explosive Shot",
	},
	
	ac = {
		id = emod:GetBaseAbility("ac").id,
		GetCD = function()
			-- simulationcraft
			if emod.numOfTargets > 2 then return 100 end
			if emod:GetFocustAfterCurrentCast() > 44 and emod:GetCooldown(emod.spells["Focusing Shot"]) == 0 then return 0 end
			if emod:GetFocustAfterCurrentCast() > 29 and emod.s_ss < 3 then return 0 end
			if emod:GetFocustAfterCurrentCast() < 79 then return 100 end
			return 0
		end,
		UpdateStatus = emod:GetBaseAbility("ac").UpdateStatus,
		info = emod:GetBaseAbility("ac").info,
	},

	tac = {
	id = emod:GetBaseAbility("ac").id,
	GetCD = function()
			if emod.numOfTargets > 2 then return 100 end
			if emod:GetFocustAfterCurrentCast() > 34 and emod.s_toth > 0 then return 0 end
			return 100
		end,
		UpdateStatus = function()
			emod:SetTime(1.0)
			emod:UseFocus(10)
		end,
		info = emod:GetBaseAbility("ac").info,
	},

	ms = {
		id = emod:GetBaseAbility("ms").id,
		GetCD = function()
			if emod.s_ss <= 5 and emod.numOfTargets > 2 then return 0 end
			if emod:GetFocustAfterCurrentCast() < 79 and emod.numOfTargets < 4 then return 100 end
			return 100
		end,
		UpdateStatus = function()
			emod:UseFocus(40)
			--emod.s_ss = 15
		end,
		info = emod:GetBaseAbility("ms").info,
	},

	tms = {
		id = emod:GetBaseAbility("ms").id,
		GetCD = function()
			if emod:GetFocustAfterCurrentCast() > 49 and emod.numOfTargets > 2 and emod.s_toth > 0 then return 0 end
			return 100
		end,
		UpdateStatus = function()
			emod:UseFocus(20)
			--emod.s_ss = 15
		end,
		info = emod:GetBaseAbility("ms").info,
	},
})
