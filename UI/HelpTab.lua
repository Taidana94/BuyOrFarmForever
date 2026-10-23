-- Help tab of the main window: a short introduction and the command list (the same lines as
-- /bof help) in one wrapping text block; the mouse wheel scrolls by line. A button switches to the
-- about text (/bof about) and back. Static text; it needs no events.
local _, ns = ...

local L = ns.L
local Widgets = ns.Widgets

local HelpTab = {}
ns.HelpTab = HelpTab

local TEXT_Y = -26
local BUTTON_WIDTH = 80

local Tab = {}
Tab.__index = Tab
Widgets.MixRefresh(Tab)

function HelpTab.Create(parent)
	local tab = setmetatable({ offset = 0, help = {} }, Tab)
	local frame = Widgets.CreateTabFrame(parent)
	tab.frame = frame
	tab.intro = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	tab.intro:SetPoint("TOPLEFT", 0, 0)
	tab.intro:SetPoint("TOPRIGHT", -BUTTON_WIDTH, 0)
	tab.aboutButton = Widgets.CreateButton(frame, L.HELP_BTN_ABOUT, BUTTON_WIDTH)
	tab.aboutButton:SetPoint("TOPRIGHT", 0, 0)
	tab.aboutButton:SetScript("OnClick", function()
		tab.showAbout = not tab.showAbout
		tab.offset = 0
		tab:Refresh()
	end)
	tab.intro:SetJustifyH("LEFT")
	tab.intro:SetText(L.HELP_TAB_INTRO)
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
	self.help = self.showAbout and ns.About.Lines() or ns.Slash.HelpLines()
	self.aboutButton:SetText(self.showAbout and L.HELP_BTN_COMMANDS or L.HELP_BTN_ABOUT)
	self:Scroll(0)
end

-- Shows the lines from the current offset on (one wheel step = one line).
function Tab:Scroll(delta)
	self.offset = math.min(#self.help - 1, math.max(0, self.offset + delta))
	self.text:SetText(table.concat(self.help, "\n", self.offset + 1))
end
