local _, class = UnitClass("player")
if class ~= "HUNTER" then return end

-- This file defines common abilities for the hunter class, along with a mechanism for the
-- individual specs to register functions that allow them to override specifics about
-- common spells and add new ones.

local emod = clcInfo.env
emod.hunter_abilities = {
	moc = {
		id = emod.spells["A Murder of Crows"],
		GetCD = function()
			-- only show if we have this as a talent
			if not emod.talents[13] then return 100 end
			-- don't show major cooldowns for trash
			if not emod.s_boss then return 100 end
			if emod.last_ability == emod.spells["A Murder of Crows"] then return 100 end
			if emod.s_moc > 0 then return 100 end
			return emod:GetCooldown(emod.spells["A Murder of Crows"])
		end,
		UpdateStatus = function()
			emod:SetTime(1.0)
			emod:UseFocus(60)
			emod.s_moc = 30.0
		end,
		info = "A Murder of Crows",
	},

	lr = {
		id = emod.spells["Lynx Rush"],
		GetCD = function()
			-- only show if we have this as a talent
			if not emod.talents[15] then return 100 end
			if not emod.s_boss then return 100 end
			if emod.last_ability == emod.spells["Lynx Rush"] then return 100 end
			return emod:GetCooldown(emod.spells["Lynx Rush"])
		end,
		UpdateStatus = function() end,
		info = "Lynx Rush",
	},

	cs = {
		id = emod.spells["Cobra Shot"],
		GetCD = function()
			-- the return value of this determines the "wiggle room" between choosing
			-- a shot that requires more regeneration and choosing to cast cobra shot
			-- instead of it.
			return 1.0
		end,
		UpdateStatus = function()
			emod:SetTime(emod:GetCastTime(emod.spells["Cobra Shot"]))
			emod:UseFocus(-14)
		end,
		info = "Cobra Shot",
	},
	
	fv = {
		id = emod.spells["Fervor"],
		GetCD = function()
			-- don't show fervor if we don't have it talented
			if not emod.talents[10] then return 100 end
			if emod.last_ability == emod.spells["Fervor"] then return 100 end
			if emod:GetFocus() > 40 then return 100 end
			return emod:GetCooldown(emod.spells["Fervor"])
		end,
		UpdateStatus = function()
			emod:SetTime(1.0)
		end,
		info = "Fervor",
	},

	db = {
		id = emod.spells["Dire Beast"],
		GetCD = function()
			-- don't show dire beast if we don't have it talented
			if not emod.talents[11] then return 100 end
			if emod.last_ability == emod.spells["Dire Beast"] then return 100 end
			return emod:GetCooldown(emod.spells["Dire Beast"])
		end,
		UpdateStatus = function()
			emod:SetTime(1.0)
		end,
		info = "Dire Beast",
	},

	gt = {
		id = emod.spells["Glaive Toss"],
		GetCD = function()
			if emod.last_ability == emod.spells["Glaive Toss"] then return 100 end
			return emod:GetCooldown(emod.spells["Glaive Toss"])
		end,
		UpdateStatus = function()
			emod:SetTime(1.0)
			emod:UseFocus(15)
		end,
		info = "Glaive Toss",
	},

	bar = {
		id = emod.spells["Barrage"],
		GetCD = function()
			if emod.last_ability == emod.spells["Barrage"] then return 100 end
			-- This is an exotic hotfix because emod:getCooldown does not seem to work well with barrage
			local startBar = GetSpellCooldown(emod.spells["Barrage"])
			local cooldownBar = 20 - (GetTime() - startBar)
			if cooldownBar < 0.5 then cooldownBar = 0 end
			return cooldownBar --emod:GetCooldown()
		end,
		UpdateStatus = function()
			emod:SetTime(3.0 / (1 + UnitSpellHaste("player") / 100))
			emod:UseFocus(60)
		end,
		info = "Barrage",
	},

	ks = {
		id = emod.spells["Kill Shot"],
		GetCD = function()
			if emod.last_ability == emod.spells["Kill Shot"] then return 100 end
			if UnitHealth("target") / UnitHealthMax("target") < 0.2 then
				return emod:GetCooldown(emod.spells["Kill Shot"])
			end
			return 100
		end,
		UpdateStatus = function()
			emod:SetTime(1.0)
		end,
		info = "Kill Shot",
	},

	rf = {
		id = emod.spells["Rapid Fire"],
		GetCD = function()
			-- don't show major cooldowns for trash
			if emod.last_ability == emod.spells["Rapid Fire"] then return 100 end
			if not emod.s_boss then return 100 end
			if emod.s_rf > 0 then return 100 end
			return emod:GetCooldown(emod.spells["Rapid Fire"])
		end,
		UpdateStatus = function()
			emod.s_rf = 15.0
		end,
		info = "Rapid Fire",
	},

	ac = {
		id = emod.spells["Arcane Shot"],
		GetCD = function()
			return 0
		end,
		UpdateStatus = function()
			emod:SetTime(1.0)
			emod:UseFocus(30)
		end,
		info = "Arcane Shot",
	},

	stm = {
		id = emod.spells["Stampede"],
		GetCD = function()
			if emod.last_ability == emod.spells["Stampede"] then return 100 end
			if not emod.s_boss then return 100 end
			return emod:GetCooldown(emod.spells["Stampede"])
		end,
		UpdateStatus = function()
			emod:SetTime(1.0)
		end,
		info = "Stampede",
	},

	et = {
		id = emod.spells["Explosive Trap"],
		GetCD = function()
			if emod.last_ability == emod.spells["Explosive Trap"] then return 100 end
			return emod:GetCooldown(emod.spells["Explosive Trap"])
		end,
		UpdateStatus = function()
			emod:SetTime(1.0)
		end,
		info = "Explosive Trap",
	},

	ms = {
		id = emod.spells["Multi-Shot"],
		GetCD = function()
			-- as per femaledwarf, only apply multi-shot when we want a
			-- new serpent sting
			if emod.s_ss == 0 then return 0 end
			return 100
		end,
		UpdateStatus = function()
			emod:UseFocus(40)
			emod.s_ss = 15
		end,
		info = "Multi-Shot",
	},

	_cs = {
		id = emod.spells["Cobra Shot"],
		GetCD = function() return 100 end,
		UpdateStatus = function()
			local __, __, __, __, __, endTime = UnitCastingInfo("player")
			local delta = (endTime / 1000) - emod.s_ctime
			emod:SetTime(delta)
			emod:UseFocus(-14)
		end,
		info = "Cobra Shot (during existing cast)",
	},
}

emod.hunter_specs = {}
emod.last_ability = nil

function emod:RegisterSpecialisation(spec, table)
	-- just link the table in now
	emod.hunter_specs[spec] = table
end

function emod:GetBaseAbility(a)
	-- this fetches an ability with a specific shortcode. it always fetches the
	-- base ability regardless of spec and can be used by specs (loaded after this
	-- file) to copy sections of an ability to their setup
	return emod.hunter_abilities[a]
end

function emod:SetLastAbility(a)
	if not a then
		emod.last_ability = a
		return
	end
	emod.last_ability = emod:GetAbility(a).id
end

function emod:GetAbility(a)
	-- this fetches an ability with a specific shortcode. if it exists in the
	-- player's current spec then that will be preferred over the base ability
	local spec = GetSpecialization()

	if emod.hunter_specs[spec] and emod.hunter_specs[spec][a] then
		return emod.hunter_specs[spec][a]
	end

	return emod.hunter_abilities[a] or nil
end

function emod:GetNextAbility(prio)
	local q = prio
	local n = #q

	for i=1, n do
		local action = emod:GetAbility(q[i])
		-- pass in the action as "self" and the list itself incase
		-- any of the actions wish to reference other actions
		local cd = action.GetCD(action, prio)
		-- check to see how long until we have enough focus
		-- to do this action.
		local tuf = emod:GetTimeUntilFocus(action.id)
		if tuf > cd then cd = tuf end
		if cd == 0 then
			return action.id, q[i]
		end
		action.cd = cd
	end

	local minQ = 1
	local minCD = emod:GetAbility(q[1]).cd
	for i=2, n do
		local action = emod:GetAbility(q[i])
		if minCD > action.cd then
			minCD = action.cd
			minQ = i
		end
	end
	return emod:GetAbility(q[minQ]).id, q[minQ]
end
