-- /gc account: the account overview (Core/Account.lua) of the characters on the current realm:
-- gold, professions with skill and learned recipes, items in bags and bank. The lines are shared
-- with the planner view of the Gold tab.
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Money = ns.Money
local Slash = ns.Slash
local UIShared = ns.UIShared

local AccountCommands = {}
ns.AccountCommands = AccountCommands

local function professionPart(profession)
	return Util.Format(L.ACCOUNT_PROFESSION, (ns.Client:GetProfessionInfo(profession.key)) or L.PROF_OTHER,
		profession.rank, profession.maxRank, profession.recipes)
end

local function characterLine(row)
	local parts = {}
	for i, profession in ipairs(row.professions) do
		parts[i] = professionPart(profession)
	end
	local professions = #parts > 0 and table.concat(parts, L.PLAN_SEPARATOR) or L.ACCOUNT_NO_PROFESSIONS
	local line = Util.Format(L.ACCOUNT_LINE, row.name, Money.Format(row.money), professions, row.items)
	if row.mailMoney > 0 then
		line = line .. Util.Format(L.ACCOUNT_MAIL_MONEY, Money.Format(row.mailMoney))
	end
	return row.bankSeen and line or line .. L.ACCOUNT_NO_BANK
end

-- Header line and one line per character of the current realm (most gold first).
function AccountCommands.Lines()
	local _, realm = ns.Stock.SplitKey(ns.charKey)
	local rows, total = ns.Account.Rows(ns.db, realm)
	local lines = { Util.Format(L.ACCOUNT_HEADER, Money.Format(total), #rows) }
	for _, row in ipairs(rows) do
		lines[#lines + 1] = characterLine(row)
	end
	return lines
end

local function accountCommand()
	if not UIShared.Character() then
		return
	end
	for _, line in ipairs(AccountCommands.Lines()) do
		Log.Print(line)
	end
end

if ns.Client then
	Slash.AddCommand("account", accountCommand, "HELP_LINE_ACCOUNT")
end
