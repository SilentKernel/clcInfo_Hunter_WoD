local _, class = UnitClass("player")
if class ~= "HUNTER" then return end

local modName = "__beastmastery"
local mod = clcInfo:RegisterClassModule(modName)
local emod = clcInfo.env
local debug = clcInfo.debug
local db

-- status
local s1, s2

local prio = {
	"bw", -- bestial wrath
	"kc", -- kill command
	"ks", -- kill shot
	"gt", -- glaive toss (talent)
	"bar", -- barrage (talent)
	"db", -- dire beast
	"stm", -- stampede
	"moc", -- murder of crows (talent)
	"lr", -- lynx rush (talent)
	"ff", -- focus fire
	"ac", -- arcane shot
	"cs", -- cobra shot
}

local function GetStatus()
	-- also updates focus
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

	-- update info
	emod.s_moc = emod:GetTargetDebuff(emod.auras["A Murder of Crows"])
	emod.s_bw = emod:GetBuff(emod.auras["Bestial Wrath"])
	emod.s_frenzy = emod:GetBuffStacks(emod.auras["Frenzy"])

end

local function BeastRotation()
	s1 = nil
	GetStatus()
	if debug.enabled then
		debug:Clear()
		debug:AddBoth("focus", emod:GetFocus())
		debug:AddBoth("s_moc", emod.s_moc)
		debug:AddBoth("s_bw", emod.s_bw)
		debug:AddBoth("s_frenzy", emod.s_frenzy)
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

	-- now calculate how much generic regen we have made
	emod:SetFocus(s_otime)

	if debug.enabled then
		debug:AddBoth("focus", emod.focus)
	end

	s2, action = emod:GetNextAbility(prio)
	if debug.enabled then
		debug:AddBoth("s2", action)
	end
end

function emod.IconBeast1(...)
	BeastRotation(...)
	if secondarySkill then secondarySkill:DoUpdate() end
	return emod.IconSpell(s1, true)
end

local function SecondaryExec()
	return emod.IconSpell(s2, true)
end

local function ExecCleanup2()
	secondarySkill = nil
end

function emod.IconBeast2(...)
	secondarySkill = emod.___e
	secondarySkill:SetScript("OnUpdate", nil)
	secondarySkill.exec = SecondaryExec
	secondarySkill.ExecCleanup = ExecCleanup2
end
