-- Where a gold change comes from: the window or loot that is open when the gold changes (loot,
-- merchant, quest, trainer, mailbox, auction house, trade, otherwise "OTHER"). Used to split the
-- net income by source. Language-independent: no chat messages are parsed. The open/close signals
-- are cheap flag updates and stay registered.
local _, ns = ...

local Events = ns.Events

local MoneyContext = {}
ns.MoneyContext = MoneyContext

-- Sources in display order.
MoneyContext.SOURCES = { "LOOT", "QUEST", "VENDOR", "TRAINER", "MAIL", "AUCTION", "TRADE", "OTHER" }
local LOOT_GRACE_SECONDS = 2

local open = {} -- source -> true while its window is open
local lootClosedAt

-- Signal -> { source, isOpen }.
local SIGNALS = {
	LOOT_OPENED = { "LOOT", true }, LOOT_CLOSED = { "LOOT", false },
	QUEST_REWARDS = { "QUEST", true }, QUEST_CLOSED = { "QUEST", false },
	MERCHANT_OPENED = { "VENDOR", true }, MERCHANT_CLOSED = { "VENDOR", false },
	TRAINER_OPENED = { "TRAINER", true }, TRAINER_CLOSED = { "TRAINER", false },
	MAIL_OPENED = { "MAIL", true }, MAIL_CLOSED = { "MAIL", false },
	AUCTION_OPENED = { "AUCTION", true }, AUCTION_CLOSED = { "AUCTION", false },
	TRADE_OPENED = { "TRADE", true }, TRADE_CLOSED = { "TRADE", false },
}

-- The source of a gold change now: an open window first (in SOURCES order), then a loot window
-- closed moments ago (coins can arrive right after it closes), otherwise "OTHER".
function MoneyContext.Source()
	for _, source in ipairs(MoneyContext.SOURCES) do
		if open[source] then
			return source
		end
	end
	if lootClosedAt and ns.Client:GetUptime() - lootClosedAt <= LOOT_GRACE_SECONDS then
		return "LOOT"
	end
	return "OTHER"
end

if ns.Client then
	for signal, change in pairs(SIGNALS) do
		Events.OnSignal(signal, function()
			open[change[1]] = change[2] or nil
			if signal == "LOOT_CLOSED" then
				lootClosedAt = ns.Client:GetUptime()
			end
		end)
	end
end
