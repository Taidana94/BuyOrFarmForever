-- Help tab of the main window: topic buttons on the left (UI/HelpTopics.lua: quick start, every
-- tab and window with its buttons and mouse actions, data collection, chat commands, about) and the
-- selected topic on the right in one wrapping text block; the mouse wheel scrolls by line. Static
-- text; it needs no events.
local _, ns = ...

local L = ns.L
local Widgets = ns.Widgets

local HelpTab = {}
ns.HelpTab = HelpTab

local BUTTON_WIDTH, BUTTON_HEIGHT, BUTTON_GAP, TEXT_X = 130, 22, 4, 146

local Tab = {}
Tab.__index = Tab
Widgets.MixRefresh(Tab)

local function buildButtons(tab, frame)
	tab.topicButtons = {}
	for i, topic in ipairs(ns.HelpTopics.LIST) do
		local button = Widgets.CreateButton(frame, L[topic.label], BUTTON_WIDTH)
		button:SetHeight(BUTTON_HEIGHT)
		button:SetPoint("TOPLEFT", 0, -(i - 1) * (BUTTON_HEIGHT + BUTTON_GAP))
		button:SetScript("OnClick", function()
			tab:Select(topic)
		end)
		tab.topicButtons[topic.id] = button
	end
end

function HelpTab.Create(parent)
	local tab = setmetatable({ offset = 0, help = {}, topic = ns.HelpTopics.LIST[1] }, Tab)
	local frame = Widgets.CreateTabFrame(parent)
	tab.frame = frame
	buildButtons(tab, frame)
	-- One text block: long lines wrap, text below the frame's bottom is cut off by the client.
	tab.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	tab.text:SetPoint("TOPLEFT", TEXT_X, 0)
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

function Tab:Select(topic)
	self.topic, self.offset = topic, 0
	self:Refresh()
end

function Tab:Refresh()
	self.help = self.topic.lines()
	for id, button in pairs(self.topicButtons) do
		Widgets.SetEnabled(button, id ~= self.topic.id)
	end
	self:Scroll(0)
end

-- Shows the lines from the current offset on (one wheel step = one line).
function Tab:Scroll(delta)
	self.offset = math.min(#self.help - 1, math.max(0, self.offset + delta))
	self.text:SetText(table.concat(self.help, "\n", self.offset + 1))
end
