local _, class = UnitClass("player")
if class ~= "HUNTER" then return end

local emod = clcInfo.env
local debug = clcInfo.debug
local db

-- status
local s_ctime, s_realtime, s_delta, s_beast = 0, 0, 0, 0

-- focus storage
local focus

-- mode, 0 is Careful Aim, 1 is Standard, 2 is Kill Shot
local mode

-- hunter instant shots incurr a 1s GCD
emod.H_INSTANT = 1.0

emod.spells = {
	["Serpent Sting"] = 87935,
	["Arcane Shot"] = 3044,
	["Steady Shot"] = 56641,
	["Chimera Shot"] = 53209,
	["Dire Beast"] = 120679,
	["Kill Shot"] = 53351,
	["Rapid Fire"] = 3045,
	["Aimed Shot"] = 19434,
	["Arcane Shot"] = 3044,
	["A Murder of Crows"] = 131894,
	["Auto Shot"] = 75,
	["Cobra Shot"] = 77767,
	["Bestial Wrath"] = 19574,
	["Kill Command"] = 34026,
	["Stampede"] = 121818,
	["Glaive Toss"] = 117050,
	["Barrage"] = 120360,
	["Explosive Trap"] = 13813,
	["Focus Fire"] = 82692,
	["Lynx Rush"] = 120697,
	["Black Arrow"] = 3674,
	["Explosive Shot"] = 53301,
	["Multi-Shot"] = 2643,
	["Viper Venom"] = 118976,
	["Serpent Spread"] = 87935,
	["Fervor"] = 82726,
	["Eagle Eye"] = 6197, -- for GCD detction
}

emod.auras = {
	["Serpent Sting"] = GetSpellInfo(87935),
	["Steady Focus"] = GetSpellInfo(177667),
	["Fire!"] = GetSpellInfo(82926),
	["A Murder of Crows"] = GetSpellInfo(131894),
	["Rapid Fire"] = GetSpellInfo(3045),
	["Frenzy"] = GetSpellInfo(19615),
	["Bestial Wrath"] = GetSpellInfo(19574),
	["Lock and Load"] = GetSpellInfo(168980),
	["Black Arrow"] = GetSpellInfo(3674),
	["Cobra Shot"] = GetSpellInfo(77767), -- not really an aura but need the name localised for cast detection
	["Fervor"] = GetSpellInfo(82726),
	["Thrill of the Hunt"] = GetSpellInfo(109306),
}

emod.talents = {}
emod.recent = {
	[120679] = 0, -- dire beast
	[3044] = 0, -- arcane shot
	[2643] = 0, -- multi-shot
}

-- spell tracking
local recent_ss = 0

local spellframe = CreateFrame("Frame", nil, UIParent)
spellframe:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
spellframe:RegisterEvent("PLAYER_TALENT_UPDATE")
spellframe:RegisterEvent("PLAYER_ENTERED_WORLD")
spellframe:RegisterEvent("ZONE_CHANGED")
spellframe:SetScript("OnEvent", function(self, event, unit, name, rank, line, id)
	if event == "UNIT_SPELLCAST_SUCCEEDED" and unit == "player" then
		-- record the last time of desired shots in recent
		if emod.recent[id] ~= nil then
			emod.recent[id] = GetTime()
		end

		-- timing last cast steady shot, dire beast or resetting recent steady shots
		if id == emod.spells["Steady Shot"] then recent_ss = recent_ss + 1
		elseif id ~= emod.spells["Auto Shot"] then recent_ss = 0 end
		if id == emod.spells["Dire Beast"] then beast = GetTime() end
	elseif event == "PLAYER_ENTERED_WORLD" or event == "PLAYER_TALENT_UPDATE" then
		-- we're caching talents in emod.talents, so need to hook them when we log in
		-- or when we change spec
		emod:UpdateTalents()
	end
end)

local CostTip = CreateFrame('GameTooltip')
local CostText = CostTip:CreateFontString()
CostTip:AddFontStrings(CostTip:CreateFontString(), CostTip:CreateFontString())
CostTip:AddFontStrings(CostText, CostTip:CreateFontString())

-- via Bodypull, how to get the cost of spells now the focus cost isn't in GetSpellInfo
function emod:GetFocusCost(spellID)
	local function GetPowerCost(sid) -- returns the value of the second line of the tooltip
		if not sid then return end
		CostTip:SetOwner(WorldFrame, 'ANCHOR_NONE')
		CostTip:SetSpellByID(sid)
		return CostText:GetText()
	end
	
	local PowerPatterns = {
		[0] = '^' .. gsub(MANA_COST, '%%d', '([.,%%d]+)', 1) .. '$',
		[2] = '^' .. gsub(FOCUS_COST, '%%d', '([.,%%d]+)', 1) .. '$',
		[3] = '^' .. gsub(ENERGY_COST, '%%d', '([.,%%d]+)', 1) .. '$',
	}
	
	-- everything below this would be used in a function to look up the cost of a specific spellID
	-- depends on your implementation
	local powerPattern = PowerPatterns[UnitPowerType('player')] -- get the pattern for the player's current power type
	local costText = GetPowerCost(spellID) -- get the line out of the tooltip
	local cost = powerPattern and costText and strmatch(costText, powerPattern) -- check the pattern against the line to see if it matches

	if cost then
		cost = gsub(cost, '%D', '') + 0 -- strip delimiter and convert to number
	else
		cost = 0
	end
	return cost
end

-- gets the time from WoW and reset the value of s_realtime
function emod:GetTime()
	s_ctime = GetTime()

	s_realtime = 1
	s_delta = 0

	-- pulling us to realtime should also update the current
	-- focus
	focus = UnitPower("player")

	return s_ctime
end

-- advances the time to a given point and returns that value
-- sets s_realtime so we know to use cached values until
-- we're asked to return to normal time
function emod:SetTime(delta)
	s_delta = s_delta + delta
	s_ctime = s_ctime + delta
	s_realtime = 0
	return s_ctime
end

-- updates focus with a estimate of how much would have been regenerated
-- during the advanced period, along with how many attacks dire beast
-- should have had
function emod:UpdateFocus(ofocus, delta)
	local focus = ofocus
	local max = UnitPowerMax("player")

	-- now calculate how much generic regen we have made
	local __, active = GetPowerRegen()
	focus = min(max, focus + (active * delta))

	-- if dire beast is active we have to guess at it's possible regen
	if beast and beast > 0 and (GetTime() - beast) < 15.0 then
		local s_haste = 1 + GetMeleeHaste("player") / 100
		-- DB has base 2s attack speed, adjusted by haste
		local regen = (15 / (2.0 * s_haste * 5))
		focus = min(max, focus + (regen * delta))
	end

	return focus
end

function emod:GetFocus()
	return focus
end

function emod:SetFocus(delta)
	focus = emod:UpdateFocus(focus, delta)
end

function emod:UseFocus(f)
	-- if we have a time for beast within then we'll halve the
	-- cost of the focus. unfortunate that this needs to be hardcoded
	-- her really.
	if emod.s_beast and emod.s_beast > 0 then
		focus = focus * 0.5
	end

	focus = min(UnitPowerMax("player"), max(0, focus - f))
end

function emod:UpdateTalents()
	for i=1,GetMaxTalentTier() do
		for j=1,3 do
			local __, __, __, __, selected, __ = GetTalentInfo(i, j, GetActiveSpecGroup())
			emod.talents[((i-1)*3)+j] = selected
		end
	end
end

function emod:GetGlobalCooldown()
	-- gcd
	local s_gcd
	local start, duration = GetSpellCooldown(emod.spells["Eagle Eye"])
	s_gcd = start + duration - GetTime()
	if s_gcd < 0 then s_gcd = 0 end
	return s_gcd
end

local function IsSpellKnownWorkaround(id)
	-- wtf glaive toss
	if id == 117050 and emod.talents[16] == true then return true end
	return IsSpellKnown(id)
end

function emod:GetCooldown(id)
	-- returns 100 if we don't actually know the spell
	if not IsSpellKnownWorkaround(id) then return 100 end

	local start, duration = GetSpellCooldown(id)
	local cd = start + duration - s_ctime - self:GetGlobalCooldown()
	if cd < 0 then return 0 end
	return cd
end

function emod:GetTimeUntilFocus(id)
	-- return the number of seconds we estimate we need to regen enough
	-- focus to use this particular spell
	local __, combatregen = GetPowerRegen()
	local cost = emod:GetFocusCost(id)
	if cost == 0 then return 0 end

	local current = UnitPower("player")
	if current >= cost then return 0 end

	if beast and beast > 0 and (GetTime() - beast) < 15.0 then
		local s_haste = 1 + GetMeleeHaste("player") / 100
		combatregen = combatregen + (15 / (2.0 * s_haste * 5))
	end

	return (cost - current) / combatregen
end

function emod:GetCastTime(id)
	local __, __, __, __, __, __, time = GetSpellInfo(id)
	return time / 1000
end

function emod:GetRecentSteadyShotCount()
	return recent_ss
end

function emod:GetRecentSerpentSting()
	local sting = emod.recent[emod.spells["Arcane Shot"]]
	local multi = emod.recent[emod.spells["Multi-Shot"]]

	if sting == 0 and multi == 0 then return false end

	-- had recent serpent sting fired, give 2s to allow for travel time
	if GetTime() - sting < 2.0 then
		return true
	end

	-- also include multishot
	if GetTime() - multi < 2.0 then
		return true
	end
	
	return false
end

function emod:GetTargetDebuff(debuff)
	local left = 0
	local name, __, __, __, __, __, expires, __, __, __, __ = UnitAura("target", debuff, nil, "PLAYER|HARMFUL")
	if expires and expires > 0 then
		left = max(0, expires - s_ctime)
	elseif name then
		-- debuffs without times (murder??!)
		left = 100
	end
	return left
end
