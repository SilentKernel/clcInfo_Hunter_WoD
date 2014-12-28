local _, class = UnitClass("player")
if class ~= "HUNTER" then return end

local modName = "__survival"
local mod = clcInfo:RegisterClassModule(modName)
local emod = clcInfo.env
local debug = clcInfo.debug
local db

-- status
local s1, s2

local prio = {
	"ba", -- black arrow
	"moc", -- murder of crows (talent)
	"db", -- dire beast
	"fv", -- fervor
	"gt", -- glaive toss (talent)
	"bar", -- barrage (talent)
	"es", -- explosive shot
	"stm", -- stampede
	"ac", -- arcane shot
	"cs", -- cobra shot
}

local function GetStatus()
	-- also implicitly updates focus
	s_ctime = emod:GetTime()

	-- gcd
	local start, duration = GetSpellCooldown(emod.spells["Arcane Shot"])
	local gcd = start + duration - s_ctime
	if gcd < 0 then gcd = 0 end

	-- we actually want to advance the model past the current GCD
	-- so that we make predictions based on the next available time
	-- that a shot can be used
	if gcd > 0 then
		s_ctime = emod:SetTime(gcd)
		emod:SetFocus(gcd)
	end

	-- update mode
	local hp = UnitHealth("target")
	local hpmax = UnitHealthMax("target")

	-- update info
	emod.s_ss = emod:GetTargetDebuff(emod.auras["Serpent Sting"])
	emod.s_moc = emod:GetTargetDebuff(emod.auras["A Murder of Crows"])
	emod.s_ba = emod:GetTargetDebuff(emod.auras["Black Arrow"])
	emod.s_lnl = emod:GetBuffStacks(emod.auras["Lock and Load"])
	emod.s_esc = 0

	-- fiddle serpent sting for inflight shots
	if emod.s_ss == 0 and emod:GetRecentSerpentSting() then
		emod.s_ss = 15.0
	end
end

local function SurvivalRotation()
	s1 = nil
	GetStatus()
	if debug.enabled then
		debug:Clear()
		debug:AddBoth("s_ss", emod.s_ss)
		debug:AddBoth("s_moc", emod.s_moc)
		debug:AddBoth("s_ba", emod.s_ba)
		debug:AddBoth("s_lnl", emod.s_lnl)
		debug:AddBoth("focus", emod:GetFocus())
		debug:AddBoth("recent_ss", emod.recent_ss)
		debug:AddBoth("s_boss", emod.s_boss)
	end

	emod:SetLastAbility(nil)

	local action
	s1, action = emod:GetNextAbility(prio)
	if debug.enabled then
		debug:AddBoth("s1", action)
		debug:AddBoth("s1f", emod:GetTimeUntilFocus(s1))
	end

	emod:SetLastAbility(action)

	s_otime = s_ctime
	-- each action needs to update s_ctime for the time taken to cast
	emod:GetAbility(action).UpdateStatus()

	s_otime = s_ctime - s_otime
	emod.s_ss = max(0, emod.s_ss - s_otime)

	-- now calculate how much generic regen we have made
	emod:SetFocus(s_otime)

	if debug.enabled then
		debug:AddBoth("s_ss", emod.s_ss)
		debug:AddBoth("s_mm", emod.s_mm)
		debug:AddBoth("focus", emod.focus)
	end

	s2, action = emod:GetNextAbility(prio)
	if debug.enabled then
		debug:AddBoth("s2", action)
	end
end

function emod.IconSurvival1(...)
	SurvivalRotation(...)
	if secondarySkill then secondarySkill:DoUpdate() end
	return emod.IconSpell(s1, true)
end

local function SecondaryExec()
	return emod.IconSpell(s2, true)
end

local function ExecCleanup2()
	secondarySkill = nil
end

function emod.IconSurvival2(...)
	secondarySkill = emod.___e
	secondarySkill:SetScript("OnUpdate", nil)
	secondarySkill.exec = SecondaryExec
	secondarySkill.ExecCleanup = ExecCleanup2
end
