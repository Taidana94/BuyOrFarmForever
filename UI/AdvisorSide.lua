-- Advisor cards next to Blizzard's merchant, auction house, bank and mailbox window ("Mach hier:"):
-- the suggestions that can be done in that window, with their buttons (sell, buy, scan). Shown
-- while such a window is open and the setting advisorCards is on; one panel, re-anchored to the
-- open window. Refresh handlers are added only while the panel is shown.
local _, ns = ...

local L = ns.L
local Widgets = ns.Widgets
local Card = ns.AdvisorCard

local AdvisorSide = {}
ns.AdvisorSide = AdvisorSide

AdvisorSide.MAX_CARDS = 4
local WIDTH, PADDING, HEADER_HEIGHT, CARD_GAP = 400, 12, 30, 4
local REFRESH_SIGNALS = { "BAGS_CHANGED", "MONEY_CHANGED", "MERCHANT_CHANGED", "DATA_CHANGED", "PRICES_CHANGED" }
-- Kinds shown per window.
local KINDS = {
	-- DISENCHANT at the merchant: a warning not to sell those items.
	MERCHANT = { BUY_MERCHANT = true, SELL_VENDOR = true, BAGS_FULL = true, DISENCHANT = true },
	AUCTION = { BUY_AUCTION = true, SELL_AUCTION = true, PRICES_SCAN = true, DISENCHANT = true },
	BANK = { BANK_TAKE = true },
	MAIL = { MAIL_SEND = true, MAIL_ASK = true },
}

local Panel = {}
Panel.__index = Panel
Widgets.MixRefresh(Panel)

local panel

local function create()
	local p = setmetatable({ cards = {} }, Panel)
	local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	frame:Hide()
	frame:SetBackdrop(BACKDROP_DIALOG_32_32)
	frame:SetWidth(WIDTH)
	frame:EnableMouse(true)
	p.frame = frame
	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOPLEFT", PADDING + 4, -PADDING - 2)
	title:SetText(L.ADVISOR_SIDE_TITLE)
	for i = 1, AdvisorSide.MAX_CARDS do
		local card = Card.Create(frame, WIDTH - 2 * PADDING, ns.AdvisorActions.Run)
		card:SetPoint("TOPLEFT", PADDING, -HEADER_HEIGHT - (i - 1) * (Card.HEIGHT + CARD_GAP))
		p.cards[i] = card
	end
	Widgets.InitRefresh(p, REFRESH_SIGNALS)
	frame:SetScript("OnShow", function()
		p:Activate()
	end)
	frame:SetScript("OnHide", function()
		p:Deactivate()
	end)
	return p
end

-- Suggestions of the context that belong in its window.
local function contextSuggestions(context)
	local charData = ns.db and not ns.readOnly and ns.charKey and ns.db.characters[ns.charKey]
	local kinds = KINDS[context]
	if not (charData and kinds) then
		return {}
	end
	local list = {}
	for _, suggestion in ipairs(ns.Advisor.Collect(charData, context, ns.Client:GetServerTime())) do
		if kinds[suggestion.kind] and #list < AdvisorSide.MAX_CARDS then
			list[#list + 1] = suggestion
		end
	end
	return list
end

function Panel:Refresh()
	local context = ns.Advisor.Context()
	local list = contextSuggestions(context)
	if #list == 0 then
		self.frame:Hide()
		return
	end
	for i, card in ipairs(self.cards) do
		Card.Draw(card, list[i], context)
	end
	self.frame:SetHeight(HEADER_HEIGHT + #list * (Card.HEIGHT + CARD_GAP) + PADDING)
end

-- Shows the panel next to the window of the current context, or hides it. The auction house
-- window is loaded by Blizzard on the first visit, possibly after our handler: one retry a frame
-- later.
function AdvisorSide.Update(retried)
	local context = ns.Advisor.Context()
	local anchor = ns.Client:GetContextFrame(context)
	if not anchor and KINDS[context] and retried ~= true then
		C_Timer.After(0, function()
			AdvisorSide.Update(true)
		end)
		return
	end
	local wanted = anchor and KINDS[context] and ns.db and ns.db.settings.advisorCards
	if not wanted then
		if panel then
			panel.frame:Hide()
		end
		return
	end
	panel = panel or create()
	panel.frame:ClearAllPoints()
	panel.frame:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 0, 0)
	panel.frame:Show()
	panel:Refresh()
end

-- The panel object, or nil before the first window (for tests).
function AdvisorSide.Get()
	return panel
end

if ns.Client then
	local function update()
		AdvisorSide.Update(false)
	end
	ns.Events.OnSignal("ADVISOR_CONTEXT", update)
	ns.Events.OnSignal("SETTINGS_CHANGED", update)
end
