-- /gc mail: what this character should mail to whom (Core/MailPrep.lua), grouped by recipient.
-- At the mailbox the advisor card shows the same entries.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Log = ns.Log
local UIShared = ns.UIShared

local REASONS = { WANT = "MAIL_REASON_WANT", CRAFT = "MAIL_REASON_CRAFT" }

local function bagCount(itemID)
	return ns.Client:GetBagCount(itemID) or 0
end

local function mailCommand()
	local charData = UIShared.Character()
	if not charData then
		return
	end
	local steps = charData.activePlan and charData.activePlan.steps or {}
	local list = ns.MailPrep.Collect(charData, steps, bagCount)
	if #list == 0 then
		Log.Print(L.MAIL_NOTHING)
		return
	end
	Log.Print(L.MAIL_HEADER)
	local name
	for _, entry in ipairs(list) do
		if entry.name ~= name then
			name = entry.name
			Log.Print(Util.Format(L.MAIL_TO, name))
		end
		Log.Print(Util.Format(L.MAIL_LINE, entry.count, UIShared.ItemText(entry.itemID), L[REASONS[entry.reason]]))
	end
end

if ns.Client then
	ns.Slash.AddCommand("mail", mailCommand, "HELP_LINE_MAIL")
end
