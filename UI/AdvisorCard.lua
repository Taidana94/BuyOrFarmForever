-- One advisor card: a framed box with a coloured stripe (category), the icon and three lines –
-- bold title, the gold value, a grey detail – and an optional button on the right. Cards are created once per list
-- slot and redrawn with Card.Draw; hidden when the slot is empty. Backdrop: BACKDROP_TOAST_12_12
-- (Blizzard_SharedXML/Backdrop.lua, Classic Era 70003).
local _, ns = ...

local Widgets = ns.Widgets

local Card = {}
ns.AdvisorCard = Card

Card.HEIGHT = 58
local PADDING, ICON_SIZE, STRIPE_WIDTH, GAP = 8, 32, 4, 6
local LINE_HEIGHT = 14
Card.BUTTON_WIDTH = 78
-- Left edge of the text lines inside a card.
Card.TEXT_X = PADDING + STRIPE_WIDTH + ICON_SIZE + GAP
local VALUE_COLOR = { 1, 0.86, 0.35 }
local COLORS = {
	HERE = { 0.25, 0.85, 0.35 },
	GOLD = { 1, 0.82, 0 },
	INFO = { 0.4, 0.7, 1 },
	WARN = { 1, 0.5, 0.15 },
	NONE = { 0.45, 0.45, 0.45 },
}

local function showTooltip(card)
	local view = card.view
	if not view then
		return
	end
	GameTooltip:SetOwner(card, "ANCHOR_RIGHT")
	if card.suggestion.itemID then
		GameTooltip:SetHyperlink("item:" .. card.suggestion.itemID)
	else
		GameTooltip:AddLine(view.title)
	end
	for _, line in ipairs(ns.AdvisorText.TooltipLines(card.suggestion) or {}) do
		GameTooltip:AddLine(line, 1, 1, 1)
	end
	if card.clickable and view.button then
		GameTooltip:AddLine(ns.Util.Format(ns.L.ADVISOR_CLICK_HINT, view.button), 0.4, 1, 0.4)
	end
	GameTooltip:Show()
end

local function hideTooltip()
	GameTooltip:Hide()
end

local function text(card, font, justify)
	local fontString = card:CreateFontString(nil, "OVERLAY", font)
	fontString:SetJustifyH(justify)
	fontString:SetWordWrap(false)
	return fontString
end

-- Creates a card of `width`; onAction(suggestion) runs when its button is clicked. opts.clickable:
-- no button, a click on the card runs the action (narrow cards of the advisor window).
function Card.Create(parent, width, onAction, opts)
	local card = CreateFrame("Frame", nil, parent, "BackdropTemplate")
	card:SetSize(width, Card.HEIGHT)
	card:SetBackdrop(BACKDROP_TOAST_12_12)
	card:EnableMouse(true)
	card.stripe = card:CreateTexture(nil, "ARTWORK")
	card.stripe:SetPoint("TOPLEFT", PADDING / 2, -PADDING / 2)
	card.stripe:SetPoint("BOTTOMLEFT", PADDING / 2, PADDING / 2)
	card.stripe:SetWidth(STRIPE_WIDTH)
	card.icon = card:CreateTexture(nil, "ARTWORK")
	card.icon:SetSize(ICON_SIZE, ICON_SIZE)
	card.icon:SetPoint("LEFT", PADDING + STRIPE_WIDTH, 0)
	card.lines = {}
	for i, font in ipairs({ "GameFontNormal", "GameFontHighlightSmall", "GameFontDisableSmall" }) do
		local line = text(card, font, "LEFT")
		line:SetPoint("TOPLEFT", Card.TEXT_X, -PADDING - (i - 1) * LINE_HEIGHT)
		card.lines[i] = line
	end
	card.title, card.value, card.detail = card.lines[1], card.lines[2], card.lines[3]
	card.value:SetTextColor(VALUE_COLOR[1], VALUE_COLOR[2], VALUE_COLOR[3])
	card.button = Widgets.CreateButton(card, "", Card.BUTTON_WIDTH)
	card.button:SetPoint("RIGHT", -PADDING, 0)
	card.button:SetScript("OnClick", function()
		onAction(card.suggestion)
	end)
	card:SetScript("OnEnter", showTooltip)
	card:SetScript("OnLeave", hideTooltip)
	card.clickable = opts and opts.clickable or false
	if card.clickable then
		card:SetScript("OnMouseUp", function()
			if card.suggestion and card.suggestion.action then
				onAction(card.suggestion)
			end
		end)
	end
	return card
end

-- Shows a suggestion in a context (Advisor.Context()); nil hides the card.
function Card.Draw(card, suggestion, context)
	card.suggestion = suggestion
	if not suggestion then
		card.view = nil
		card:Hide()
		return
	end
	local view = ns.AdvisorText.View(suggestion, context)
	card.view = view
	local color = COLORS[view.category] or COLORS.INFO
	card.stripe:SetColorTexture(color[1], color[2], color[3], 1)
	card.icon:SetTexture(view.icon)
	card.title:SetText(view.title)
	card.value:SetText(view.value)
	card.detail:SetText(view.detail)
	local hasButton = view.button ~= nil and not card.clickable
	local right = hasButton and Card.BUTTON_WIDTH + 2 * PADDING or PADDING
	for _, line in ipairs(card.lines) do
		line:SetWidth(card:GetWidth() - Card.TEXT_X - right)
	end
	card.button:SetText(view.button or "")
	Widgets.SetShown(card.button, hasButton)
	card:Show()
end
