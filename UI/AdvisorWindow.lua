-- Advisor window ("Ratgeber"): a small movable window with fixed summary rows as cards
-- (Core/AdvisorSummary.lua: sell, disenchant, craft, savings goal, best hour). Created on first
-- open, refreshed only while shown (same coalesced refresh as the tabs). Opens by itself after login when something
-- important is waiting (setting advisorAtLogin). Its settings are in the settings tab.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Widgets = ns.Widgets
local Card = ns.AdvisorCard

local AdvisorWindow = {}
ns.AdvisorWindow = AdvisorWindow

-- Compact (user feedback on 0.7.0-alpha.1: the window was far too big): one card per summary row,
-- the height follows the shown cards, drawn at a smaller scale.
AdvisorWindow.MAX_CARDS = 5
AdvisorWindow.SCALE = 0.85
-- After login: wait for the chat summary, then open only for suggestions at least this important.
AdvisorWindow.LOGIN_DELAY_SECONDS = 7
-- 80: full bags, cooldowns, craftable goals; not everyday selling.
AdvisorWindow.LOGIN_MIN_PRIORITY = 80
local WIDTH, PADDING, HEADER_HEIGHT, CARD_GAP, FOOTER_HEIGHT = 300, 14, 44, 4, 14
local CARD_WIDTH = WIDTH - 2 * PADDING
local REFRESH_SIGNALS = {
	"BAGS_CHANGED", "DATA_CHANGED", "PRICES_CHANGED", "MONEY_CHANGED", "ITEM_LOADED", "ADVISOR_CONTEXT",
	"SETTINGS_CHANGED", "MERCHANT_CHANGED",
}
local CONTEXT_NAMES = {
	MERCHANT = "ADVISOR_CONTEXT_MERCHANT", AUCTION = "ADVISOR_CONTEXT_AUCTION", BANK = "ADVISOR_CONTEXT_BANK",
	MAIL = "ADVISOR_CONTEXT_MAIL", PROFESSION = "ADVISOR_CONTEXT_PROFESSION", ANY = "ADVISOR_CONTEXT_ANY",
}

local Window = {}
Window.__index = Window
Widgets.MixRefresh(Window)

local window

local function savePosition(frame)
	frame:StopMovingOrSizing()
	local point, _, _, x, y = frame:GetPoint()
	local position = ns.db.settings.advisorWindow
	position.point, position.x, position.y = point, math.floor(x + 0.5), math.floor(y + 0.5)
end

-- Height for `cards` shown cards (at least one row, for the "nothing to do" text).
local function heightFor(cards)
	return HEADER_HEIGHT + math.max(1, cards) * (Card.HEIGHT + CARD_GAP) + FOOTER_HEIGHT
end

local function buildFrame()
	local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	frame:Hide()
	frame:SetSize(WIDTH, heightFor(AdvisorWindow.MAX_CARDS))
	frame:SetScale(AdvisorWindow.SCALE)
	frame:SetFrameStrata("MEDIUM")
	-- Own frame level band before any child is created, so the small windows never interleave.
	frame:SetFrameLevel(Widgets.WINDOW_LEVELS.ADVISOR)
	frame:SetBackdrop(BACKDROP_DIALOG_32_32)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", savePosition)
	local position = ns.db.settings.advisorWindow
	frame:SetPoint(position.point, UIParent, position.point, position.x, position.y)
	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -6, -6)
	return frame
end

local function buildHeader(win, frame)
	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", PADDING, -PADDING)
	title:SetText(L.ADVISOR_TITLE)
	win.contextText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	win.contextText:SetPoint("LEFT", title, "RIGHT", PADDING / 2, 0)
	win.emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
	win.emptyText:SetPoint("TOPLEFT", PADDING, -HEADER_HEIGHT - PADDING)
	win.emptyText:SetWidth(CARD_WIDTH)
	win.emptyText:SetJustifyH("LEFT")
end

local function create()
	local win = setmetatable({ cards = {} }, Window)
	local frame = buildFrame()
	win.frame = frame
	buildHeader(win, frame)
	for i = 1, AdvisorWindow.MAX_CARDS do
		local card = Card.Create(frame, CARD_WIDTH, ns.AdvisorActions.Run, { clickable = true })
		card:SetPoint("TOPLEFT", PADDING, -HEADER_HEIGHT - (i - 1) * (Card.HEIGHT + CARD_GAP))
		win.cards[i] = card
	end
	Widgets.InitRefresh(win, REFRESH_SIGNALS)
	frame:SetScript("OnShow", function()
		win:Activate()
	end)
	frame:SetScript("OnHide", function()
		win:Deactivate()
	end)
	return win
end

function Window:Refresh()
	local charData = ns.db and not ns.readOnly and ns.charKey and ns.db.characters[ns.charKey]
	local context = ns.Advisor.Context()
	self.contextText:SetText(Util.Format(L.ADVISOR_CONTEXT_LINE, L[CONTEXT_NAMES[context]]))
	local list = charData and ns.AdvisorSummary.Rows(charData, context, ns.Client:GetServerTime()) or {}
	for i, card in ipairs(self.cards) do
		Card.Draw(card, list[i], context)
	end
	self.frame:SetHeight(heightFor(math.min(#list, AdvisorWindow.MAX_CARDS)))
	self.emptyText:SetText(charData and "" or L.NOT_READY)
end

function AdvisorWindow.Toggle()
	if not (ns.db and ns.charKey) or ns.readOnly then
		ns.Log.Print(ns.readOnly and L.READ_ONLY_NO_ACCESS or L.NOT_READY)
		return
	end
	window = window or create()
	Widgets.SetShown(window.frame, not window.frame:IsShown())
end

function AdvisorWindow.Show()
	if not (window and window.frame:IsShown()) then
		AdvisorWindow.Toggle()
	end
end

-- The window object, or nil before the first open (for tests).
function AdvisorWindow.Get()
	return window
end

-- After login: open if something important is waiting.
local function openAtLogin()
	local charData = ns.db and not ns.readOnly and ns.charKey and ns.db.characters[ns.charKey]
	if not (charData and ns.db.settings.advisorAtLogin) then
		return
	end
	local first = ns.Advisor.Collect(charData, ns.Advisor.Context(), ns.Client:GetServerTime())[1]
	if first and first.priority >= AdvisorWindow.LOGIN_MIN_PRIORITY then
		AdvisorWindow.Show()
	end
end

if ns.Client then
	ns.Slash.AddCommand("advisor", AdvisorWindow.Toggle, "HELP_LINE_ADVISOR")
	ns.Events.OnSignal("CHARACTER_READY", function()
		C_Timer.After(AdvisorWindow.LOGIN_DELAY_SECONDS, openAtLogin)
	end)
end
