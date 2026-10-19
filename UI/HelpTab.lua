-- Help tab of the main window: a short introduction and the command list (the same lines as
-- /bof help) in one wrapping text block; the mouse wheel scrolls by command. Static text; it
-- needs no events.
local _, ns = ...

local L = ns.L
local Widgets = ns.Widgets

local HelpTab = {}
ns.HelpTab = HelpTab

local TEXT_Y = -26

local Tab = {}
Tab.__index = Tab
Widgets.MixRefresh(Tab)

function HelpTab.Create(parent)
	local tab = setmetatable({ offset = 0, help = {} }, Tab)
	local frame = Widgets.CreateTabFrame(parent)
	tab.frame = frame
	tab.intro = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	tab.intro:SetPoint("TOPLEFT", 0, 0)
	tab.intro:SetPoint("TOPRIGHT", 0, 0)
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
	self.help = ns.Slash.HelpLines()
	self:Scroll(0)
end

-- Shows the commands from the current offset on (one wheel step = one command).
function Tab:Scroll(delta)
	self.offset = math.min(#self.help - 1, math.max(0, self.offset + delta))
	self.text:SetText(table.concat(self.help, "\n", self.offset + 1))
end
