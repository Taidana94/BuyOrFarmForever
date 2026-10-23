-- Settings tab of the main window: one check box or number box per schema entry
-- (Core/Settings.lua), grouped in two columns, the character's stat weights for the gear rating (with
-- the suggestion for class and talents), plus debug mode, the performance output and a reset with
-- confirmation. Every change runs /bof set (or weights/debug/perf/reset), like the chat.
local _, ns = ...

local L = ns.L
local Widgets = ns.Widgets
local Inputs = ns.Inputs
local Settings = ns.Settings

local SettingsTab = {}
ns.SettingsTab = SettingsTab

-- Groups per column (keys of Settings.GROUPS).
local COLUMNS = { { "FARM", "MATERIAL" }, { "GOLD", "DISPLAY" } }
local COLUMN_WIDTH = 370
local ROW_HEIGHT, HEADER_HEIGHT, GROUP_GAP = 24, 20, 8
local BOX_WIDTH, LABEL_GAP = 44, 6
local BUTTON_WIDTH, BUTTON_GAP = 160, 10
local WEIGHTS_Y, WEIGHT_BOX_WIDTH, WEIGHT_GAP, SUGGEST_WIDTH = 30, 32, 6, 100
local STAT_WORDS = { STR = "str", AGI = "agi", STA = "sta", INT = "int", SPI = "spi", ARMOR = "armor", DPS = "dps" }
local REFRESH_SIGNALS = { "DATA_CHANGED", "SETTINGS_CHANGED" }

local Tab = {}
Tab.__index = Tab
Widgets.MixRefresh(Tab)

local run = Inputs.Run

local function groupLabel(key)
	for _, group in ipairs(Settings.GROUPS) do
		if group.key == key then
			return L[group.label]
		end
	end
	return key
end

-- A number setting: label text, then the box.
local function buildNumber(tab, frame, entry, x, y)
	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("TOPLEFT", x + LABEL_GAP, y - LABEL_GAP)
	label:SetText(L[entry.label])
	local box = Inputs.CreateBox(frame, { width = BOX_WIDTH, numeric = true, onCommit = function(text)
		run("set " .. entry.key .. " " .. text)
	end })
	box:SetPoint("LEFT", label, "RIGHT", LABEL_GAP * 2, 0)
	tab.boxes[entry.key] = box
end

local function buildEntry(tab, frame, entry, x, y)
	if entry.type == "number" then
		buildNumber(tab, frame, entry, x, y)
		return
	end
	local check = Widgets.CreateCheck(frame, L[entry.label], function(checked)
		run("set " .. entry.key .. " " .. (checked and "on" or "off"))
	end)
	check:SetPoint("TOPLEFT", x, y)
	tab.checks[entry.key] = check
end

-- One column of groups, each with a header and its entries.
local function buildColumn(tab, frame, groups, x)
	local y = 0
	for _, group in ipairs(groups) do
		local header = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		header:SetPoint("TOPLEFT", x, y)
		header:SetText(groupLabel(group))
		y = y - HEADER_HEIGHT
		for _, entry in ipairs(Settings.InGroup(group)) do
			buildEntry(tab, frame, entry, x, y)
			y = y - ROW_HEIGHT
		end
		y = y - GROUP_GAP
	end
end

-- "Gewichte: Stä [1] Bew [1] … [Vorschlag]" above the bottom row.
local function buildWeights(tab, frame)
	local label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	label:SetPoint("BOTTOMLEFT", 0, WEIGHTS_Y)
	label:SetText(L.CRAFT_WEIGHTS_LABEL)
	tab.weightBoxes = {}
	local previous = label
	for _, stat in ipairs(ns.CraftEval.STATS) do
		local name = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		name:SetPoint("LEFT", previous, "RIGHT", WEIGHT_GAP * 2, 0)
		name:SetText(L["STAT_SHORT_" .. stat])
		local box = Inputs.CreateBox(frame, { width = WEIGHT_BOX_WIDTH, onCommit = function(text)
			run("weights " .. STAT_WORDS[stat] .. " " .. text)
		end })
		box:SetPoint("LEFT", name, "RIGHT", WEIGHT_GAP, 0)
		tab.weightBoxes[stat] = box
		previous = box
	end
	tab.suggest = Widgets.CreateButton(frame, L.SET_WEIGHTS_SUGGEST, SUGGEST_WIDTH)
	tab.suggest:SetPoint("LEFT", previous, "RIGHT", WEIGHT_GAP * 2, 0)
	tab.suggest:SetScript("OnClick", function()
		run("weights suggest")
	end)
end

local function buildBottom(tab, frame)
	tab.debug = Widgets.CreateCheck(frame, L.SET_DEBUG, function()
		run("debug")
	end)
	tab.debug:SetPoint("BOTTOMLEFT", 0, 0)
	tab.perf = Widgets.CreateButton(frame, L.SET_SHOW_PERF, BUTTON_WIDTH)
	tab.perf:SetPoint("BOTTOMLEFT", COLUMN_WIDTH, 0)
	tab.perf:SetScript("OnClick", function()
		run("perf")
	end)
	tab.reset = Widgets.CreateButton(frame, L.SET_RESET, BUTTON_WIDTH)
	tab.reset:SetPoint("LEFT", tab.perf, "RIGHT", BUTTON_GAP, 0)
	tab.reset:SetScript("OnClick", function()
		Inputs.Confirm(L.SET_RESET_CONFIRM, function()
			run("reset")
			run("reset confirm")
		end)
	end)
end

function SettingsTab.Create(parent)
	local tab = setmetatable({ checks = {}, boxes = {} }, Tab)
	local frame = Widgets.CreateTabFrame(parent)
	tab.frame = frame
	for i, groups in ipairs(COLUMNS) do
		buildColumn(tab, frame, groups, (i - 1) * COLUMN_WIDTH)
	end
	buildWeights(tab, frame)
	buildBottom(tab, frame)
	Widgets.InitRefresh(tab, REFRESH_SIGNALS)
	return tab
end

function Tab:Refresh()
	local settings = ns.db and ns.db.settings
	if not settings then
		return
	end
	local canWrite = not ns.readOnly
	for key, check in pairs(self.checks) do
		check:SetChecked(settings[key])
		Widgets.SetEnabled(check, canWrite)
	end
	for key, box in pairs(self.boxes) do
		Inputs.SetValue(box, tostring(settings[key]))
	end
	local charData = ns.charKey and ns.db.characters[ns.charKey]
	for stat, box in pairs(self.weightBoxes) do
		Inputs.SetValue(box, charData and ns.Util.FormatCompact(charData.craftEval.weights[stat]) or "")
	end
	Widgets.SetEnabled(self.suggest, canWrite and charData ~= nil)
	self.debug:SetChecked(settings.debug)
	Widgets.SetEnabled(self.reset, canWrite)
end
