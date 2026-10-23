-- Help tab of the main window: a short introduction and, in one wrapping text block, the command
-- list (the same lines as /bof help), the how-to (/bof howto) or the about text (/bof about),
-- switched by three buttons; the mouse wheel scrolls by line. Static text; it needs no events.
local _, ns = ...

local L = ns.L
local Widgets = ns.Widgets

local HelpTab = {}
ns.HelpTab = HelpTab

local TEXT_Y = -26
local BUTTON_WIDTH, BUTTON_GAP = 80, 4
-- Views in button order (right to left from the last): label key and line source.
local VIEWS = {
	{ id = "COMMANDS", label = "HELP_BTN_COMMANDS", lines = function()
		return ns.Slash.HelpLines()
	end },
	{ id = "HOWTO", label = "HELP_BTN_HOWTO", lines = function()
		return ns.About.HowToLines()
	end },
	{ id = "ABOUT", label = "HELP_BTN_ABOUT", lines = function()
		return ns.About.Lines()
	end },
}

local Tab = {}
Tab.__index = Tab
Widgets.MixRefresh(Tab)

local function buildButtons(tab, frame)
	tab.viewButtons = {}
	for i, view in ipairs(VIEWS) do
		local button = Widgets.CreateButton(frame, L[view.label], BUTTON_WIDTH)
		button:SetPoint("TOPRIGHT", -(#VIEWS - i) * (BUTTON_WIDTH + BUTTON_GAP), 0)
		button:SetScript("OnClick", function()
			tab.view, tab.offset = view, 0
			tab:Refresh()
		end)
		tab.viewButtons[view.id] = button
	end
end

function HelpTab.Create(parent)
	local tab = setmetatable({ offset = 0, help = {}, view = VIEWS[1] }, Tab)
	local frame = Widgets.CreateTabFrame(parent)
	tab.frame = frame
	tab.intro = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	tab.intro:SetPoint("TOPLEFT", 0, 0)
	tab.intro:SetPoint("TOPRIGHT", -#VIEWS * (BUTTON_WIDTH + BUTTON_GAP), 0)
	tab.intro:SetJustifyH("LEFT")
	tab.intro:SetText(L.HELP_TAB_INTRO)
	buildButtons(tab, frame)
	-- One text block: long lines wrap, text below the frame's bottom is cut off by the client.
	tab.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	tab.text:SetPoint("TOPLEFT", 0, TEXT_Y)
	tab.text:SetPoint("BOTTOMRIGHT", 0, 0)
	tab.text:SetJustifyH("LEFT")
	tab.text:SetJustifyV("TOP")
	frame:EnableMouseWheel(true)
	frame:SetScript("OnMouseWheel", function(_, delta)
		tab:Scroll(-delta)
	end)
	Widgets.InitRefresh(tab, {})
	return tab
end

function Tab:Refresh()
	self.help = self.view.lines()
	for id, button in pairs(self.viewButtons) do
		Widgets.SetEnabled(button, id ~= self.view.id)
	end
	self:Scroll(0)
end

-- Shows the lines from the current offset on (one wheel step = one line).
function Tab:Scroll(delta)
	self.offset = math.min(#self.help - 1, math.max(0, self.offset + delta))
	self.text:SetText(table.concat(self.help, "\n", self.offset + 1))
end
