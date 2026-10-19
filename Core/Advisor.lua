-- Advisor ("Ratgeber"): collects the suggestions of Core/AdvisorSources.lua for the current
-- context (the window that is open: merchant, auction house, bank, mailbox, profession window, or
-- none) and sorts them, most important first. Tracks the context from window signals and raises
-- ADVISOR_CONTEXT when it changes (rare events, always registered).
local _, ns = ...

local Events = ns.Events

local Advisor = {}
ns.Advisor = Advisor

local CONTEXT_SIGNALS = {
	MERCHANT_OPENED = { "MERCHANT", true }, MERCHANT_CLOSED = { "MERCHANT", false },
	AUCTION_OPENED = { "AUCTION", true }, AUCTION_CLOSED = { "AUCTION", false },
	BANK_OPENED = { "BANK", true }, BANK_CLOSED = { "BANK", false },
	MAIL_OPENED = { "MAIL", true }, MAIL_CLOSED = { "MAIL", false },
	PROFESSION_OPENED = { "PROFESSION", true }, PROFESSION_CLOSED = { "PROFESSION", false },
}

-- Open windows in the order they were opened (the last one is the context).
local open = {}

local function setOpen(context, isOpen)
	for i = #open, 1, -1 do
		if open[i] == context then
			table.remove(open, i)
		end
	end
	if isOpen then
		open[#open + 1] = context
	end
end

-- The current context: "MERCHANT" | "AUCTION" | "BANK" | "MAIL" | "PROFESSION" | "ANY".
function Advisor.Context()
	return open[#open] or "ANY"
end

local function rating(entry, discount)
	return ns.GoldRoutes.Rating(entry.sure, entry.auction, discount)
end

-- Suggestions for the character in a context, sorted by priority, then by gold.
function Advisor.Collect(charData, context, now)
	local discount = ns.db.settings.ahDiscountPercent
	local env = { charData = charData, context = context, now = now, discount = discount }
	local list = {}
	for _, source in ipairs(ns.AdvisorSources.BY_CONTEXT.ANY) do
		source(env, list)
	end
	for _, source in ipairs(ns.AdvisorSources.BY_CONTEXT[context] or {}) do
		source(env, list)
	end
	table.sort(list, function(a, b)
		if a.priority ~= b.priority then
			return a.priority > b.priority
		end
		return rating(a, discount) > rating(b, discount)
	end)
	return list
end

if ns.Client then
	for signal, change in pairs(CONTEXT_SIGNALS) do
		Events.OnSignal(signal, function()
			local before = Advisor.Context()
			setOpen(change[1], change[2])
			if Advisor.Context() ~= before then
				Events.Emit("ADVISOR_CONTEXT", Advisor.Context())
			end
		end)
	end
end
