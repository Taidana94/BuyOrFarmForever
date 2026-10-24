-- /bof skillup: per profession that can still rise, the cheapest recipes for the next skill point
-- (Core/SkillUp.lua). The colours are read when the profession window was last open.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Log = ns.Log
local Money = ns.Money
local UIShared = ns.UIShared

local SkillUpCommand = {}
ns.SkillUpCommand = SkillUpCommand

local PERCENT = 100

local function optionLine(option)
	local cost = option.complete and Money.Format(option.perPoint) or L.SKILLUP_PRICE_MISSING
	return Util.Format(L.SKILLUP_LINE, UIShared.ItemText(option.itemID), math.floor(option.chance * PERCENT + 0.5), cost)
end

-- The option lines of one profession ({ L.SKILLUP_NONE } without any).
function SkillUpCommand.OptionLines(charData, professionKey, now)
	local lines = {}
	for i, option in ipairs(ns.SkillUp.Options(charData, professionKey, now)) do
		lines[i] = optionLine(option)
	end
	return #lines > 0 and lines or { L.SKILLUP_NONE }
end

local function printProfession(charData, profession, now)
	local skill = profession.skill
	if skill and skill.rank >= skill.maxRank then
		return false
	end
	local name = ns.Client:GetProfessionInfo(profession.key) or L.PROF_OTHER
	Log.Print(Util.Format(L.SKILLUP_HEADER, name, skill and skill.rank or 0, skill and skill.maxRank or 0))
	for _, line in ipairs(SkillUpCommand.OptionLines(charData, profession.key, now)) do
		Log.Print(line)
	end
	return true
end

local function skillUpCommand()
	local charData = UIShared.Character()
	if not charData then
		return
	end
	local now, shown = ns.Client:GetServerTime(), false
	for _, profession in ipairs(ns.ProfessionView.Professions(charData)) do
		if profession.key ~= "OTHER" then
			shown = printProfession(charData, profession, now) or shown
		end
	end
	if not shown then
		Log.Print(L.SKILLUP_NOTHING)
	end
end

if ns.Client then
	ns.Slash.AddCommand("skillup", skillUpCommand, L.HELP_LINE_SKILLUP)
end
