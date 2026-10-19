-- Advisor window ("Ratgeber"): a small movable window with the most important suggestions as
-- cards ("Mach das"), for the window that is open right now. Created on first open, refreshed only
-- while shown (same coalesced refresh as the tabs). Opens by itself after login when something
-- important is waiting (setting advisorAtLogin). Its two settings sit at the bottom, because the
-- settings tab has no room left; /bof set works for them too.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Widgets = ns.Widgets
local Card = ns.AdvisorCard

local AdvisorWindow = {}
ns.AdvisorWindow = AdvisorWindow

AdvisorWindow.MAX_CARDS = 6
-- After login: wait for the chat summary, then open only for suggestions at least this important.
AdvisorWindow.LOGIN_DELAY_SECONDS = 7
-- 80: full bags, cooldowns, craftable goals; not everyday selling.
AdvisorWindow.LOGIN_MIN_PRIORITY = 80
local WIDTH, PADDING, HEADER_HEIGHT, CARD_GAP, FOOTER_HEIGHT = 420, 16, 46, 4, 60
local CARD_WIDTH = WIDTH - 2 * PADDING
local CHECK_GAP = 24
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

local function buildFrame()
	local height = HEADER_HEIGHT + AdvisorWindow.MAX_CARDS * (Card.HEIGHT + CARD_GAP) + FOOTER_HEIGHT
	local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	frame:Hide()
	frame:SetSize(WIDTH, height)
	frame:SetFrameStrata("MEDIUM")
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

local function buildFooter(win, frame)
	win.checks = {}
	for i, key in ipairs({ "advisorCards", "advisorAtLogin" }) do
		local check = Widgets.CreateCheck(frame, L[ns.Settings.Find(key).label], function(checked)
			ns.Inputs.Run("set " .. key .. " " .. (checked and "on" or "off"))
		end)
		check:SetPoint("BOTTOMLEFT", PADDING, PADDING / 2 + (2 - i) * CHECK_GAP)
		win.checks[key] = check
	end
end

local function create()
	local win = setmetatable({ cards = {} }, Window)
	local frame = buildFrame()
	win.frame = frame
	buildHeader(win, frame)
	for i = 1, AdvisorWindow.MAX_CARDS do
		local card = Card.Create(frame, CARD_WIDTH, ns.AdvisorActions.Run)
		card:SetPoint("TOPLEFT", PADDING, -HEADER_HEIGHT - (i - 1) * (Card.HEIGHT + CARD_GAP))
		win.cards[i] = card
	end
	buildFooter(win, frame)
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
	for key, check in pairs(self.checks) do
		check:SetChecked(ns.db.settings[key] == true)
	end
	local context = ns.Advisor.Context()
	self.contextText:SetText(Util.Format(L.ADVISOR_CONTEXT_LINE, L[CONTEXT_NAMES[context]]))
	local list = charData and ns.Advisor.Collect(charData, context, ns.Client:GetServerTime()) or {}
	for i, card in ipairs(self.cards) do
		Card.Draw(card, list[i], context)
	end
	self.emptyText:SetText(#list == 0 and (charData and L.ADVISOR_EMPTY or L.NOT_READY) or "")
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
	ns.Slash.AddCommand("advisor", AdvisorWindow.Toggle, L.HELP_LINE_ADVISOR)
	ns.Events.OnSignal("CHARACTER_READY", function()
		C_Timer.After(AdvisorWindow.LOGIN_DELAY_SECONDS, openAtLogin)
	end)
end
