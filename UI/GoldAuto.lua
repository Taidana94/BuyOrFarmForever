-- Automatic distribution of new gold to the savings goals (setting goldAutoDistribute, off by
-- default): after each gold gain the current gold is distributed again in priority order, quietly
-- (no chat line per coin). Spending does not redistribute, so purchases still show up as a reserve
-- warning. The previous reserves can be restored with "Rückgängig" (/bof gold undo).
local _, ns = ...

local Events = ns.Events

local GoldAuto = {}
ns.GoldAuto = GoldAuto

local lastMoney

local function hasUncovered(charData)
	for _, goal in ipairs(charData.savingsGoals) do
		if not goal.done and goal.reserved < goal.copper then
			return true
		end
	end
	return false
end

local function onMoneyChanged()
	local money = ns.Client:GetMoney()
	local gained = money and lastMoney and money > lastMoney
	lastMoney = money
	if not (gained and ns.db and not ns.readOnly and ns.db.settings.goldAutoDistribute) then
		return
	end
	local charData = ns.db.characters[ns.charKey]
	if charData and hasUncovered(charData) then
		ns.GoldCommands.Distribute(charData)
		ns.Log.Debug("gold distributed automatically")
		Events.Emit("DATA_CHANGED")
	end
end

if ns.Client then
	Events.OnSignal("CHARACTER_READY", function()
		lastMoney = ns.Client:GetMoney()
	end)
	Events.OnSignal("MONEY_CHANGED", onMoneyChanged)
end
