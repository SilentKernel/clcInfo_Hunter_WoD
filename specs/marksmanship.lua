local _, class = UnitClass("player")
if class ~= "HUNTER" then return end

local modName = "__marksmanship"
local mod = clcInfo:RegisterClassModule(modName)
local emod = clcInfo.env
local debug = clcInfo.debug
local db

-- status
local s1, s2

local prio = {
	"moc", -- murder of crows
	-- "ssp", -- steady shot pair (steady focus)
	"rf", -- rapid fire
	"cs", -- chimera shot
	"db", -- dire beast
	"ks", -- kill shot
	"mm", -- aimed shot (thrill)
	"gt", -- glaive toss
	"am", -- aimed shot
	"ss", -- steady shot
}

local function UseFocus(f)
	focus = max(0, focus - f)
end

local function GetStatus()
	s_ctime = emod:GetTime()

	-- gcd
	local gcd = emod:GetGlobalCooldown()
	
	-- we actually want to advance the model past the current GCD
	-- so that we make predictions based on the next available time
	-- that a shot can be used
	if gcd > 0 then
		s_ctime = emod:SetTime(gcd)
		emod:SetFocus(gcd)
	end

	-- -- update info
	emod.s_moc = emod:GetTargetDebuff(emod.auras["A Murder of Crows"])
	emod.s_sf = emod:GetBuff(emod.auras["Steady Focus"])
	emod.s_rf = emod:GetBuff(emod.auras["Rapid Fire"])
	emod.s_toth = emod:GetBuffStacks(emod.auras["Thrill of the Hunt"])
	emod.focus = UnitPower("player")
	emod.maxf = UnitPowerMax("player")
	emod.s_rcss = emod:GetRecentSteadyShotCount()
end

local function MarksRotation()
	s1 = nil
	GetStatus()
	if debug.enabled then
		debug:Clear()
		debug:AddBoth("mode", mode)
		debug:AddBoth("s_moc", emod.s_moc)
		debug:AddBoth("s_sf", emod.s_sf)
		debug:AddBoth("s_toth", emod.s_toth)
		debug:AddBoth("focus", emod.focus)
		debug:AddBoth("recent_ss", emod:GetRecentSteadyShotCount())
	end
	
	emod:SetLastAbility(nil)

	local action
	s1, action = emod:GetNextAbility(prio)
	if debug.enabled then
		debug:AddBoth("s1", action)
	end
	
	emod:SetLastAbility(action)

	s_otime = s_ctime
	-- each action needs to update s_ctime for the time taken to cast
	emod:GetAbility(action).UpdateStatus()

	s_otime = s_ctime - s_otime
	emod:SetFocus(s_otime)

	if debug.enabled then
		debug:AddBoth("focus", focus)
	end

	s2, action = emod:GetNextAbility(prio)
	if debug.enabled then
		debug:AddBoth("s2", action)
	end
end

function emod.IconMarks1(...)
	MarksRotation(...)
	if secondarySkill then secondarySkill:DoUpdate() end
	return emod.IconSpell(s1, true)
end

local function SecondaryExec()
	return emod.IconSpell(s2, true)
end

local function ExecCleanup2()
	secondarySkill = nil
end

function emod.IconMarks2(...)
	secondarySkill = emod.___e
	secondarySkill:SetScript("OnUpdate", nil)
	secondarySkill.exec = SecondaryExec
	secondarySkill.ExecCleanup = ExecCleanup2
end
