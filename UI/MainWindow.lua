-- Main window: a movable frame with a title line and tabs (Material, Sourcing, Farm, Craft, Gold
-- buffer, Settings, Help). Created lazily on first open;
-- only the shown tab has its events registered, closing the window unregisters them.
-- Uses only widely stable frame APIs and templates that exist in Classic Era 70003
-- (BackdropTemplate, UIPanelCloseButton; see docs/ARCHITECTURE.md).
local _, ns = ...

local L = ns.L
local Slash = ns.Slash

local MainWindow = {}
ns.MainWindow = MainWindow

-- A global frame name is needed so Escape closes the window (UISpecialFrames holds names).
local FRAME_NAME = "BuyOrFarmForeverMainFrame"
local WIDTH, HEIGHT = 780, 466
local VALID_POINTS = {
	CENTER = true, TOP = true, BOTTOM = true, LEFT = true, RIGHT = true,
	TOPLEFT = true, TOPRIGHT = true, BOTTOMLEFT = true, BOTTOMRIGHT = true,
}

-- Tabs in button order; settings.window.tab stores the key of the selected one.
local TABS = {
	{ key = "MATERIAL", label = "TAB_MATERIAL", field = "material", module = "MaterialTab" },
	{ key = "SOURCING", label = "TAB_SOURCING", field = "sourcing", module = "SourcingTab" },
	{ key = "FARM", label = "TAB_FARM", field = "farm", module = "FarmTab" },
	{ key = "CRAFT", label = "TAB_CRAFT", field = "craft", module = "CraftTab" },
	{ key = "GOLD_BUFFER", label = "TAB_GOLD", field = "gold", module = "GoldTab" },
	{ key = "SETTINGS", label = "TAB_SETTINGS", field = "settings", module = "SettingsTab" },
	{ key = "HELP", label = "TAB_HELP", field = "help", module = "HelpTab" },
}
local TAB_BUTTON_WIDTH, TAB_BUTTON_GAP = 88, 3
local TAB_BUTTON_X, TAB_BUTTON_Y = 18, -40
local TITLE_X, TITLE_Y = 22, -18

local frame
local currentKey

local function tabByKey(key)
	for _, tab in ipairs(TABS) do
		if tab.key == key then
			return tab
		end
	end
	return TABS[1]
end

-- Shows one tab and hides the others; the old tab stops listening, the new one refreshes.
local function selectTab(key)
	local selected = tabByKey(key)
	for _, tab in ipairs(TABS) do
		local object = frame[tab.field]
		if tab == selected then
			object.frame:Show()
		else
			if currentKey == tab.key and frame:IsShown() then
				object:Deactivate()
			end
			object.frame:Hide()
		end
		ns.Widgets.SetEnabled(frame.tabButtons[tab.key], tab ~= selected)
	end
	currentKey = selected.key
	if ns.db and not ns.readOnly then
		ns.db.settings.window.tab = selected.key
	end
	if frame:IsShown() then
		frame[selected.field]:Activate()
	end
end

local function buildTabs()
	frame.tabButtons = {}
	local previous
	for _, tab in ipairs(TABS) do
		frame[tab.field] = ns[tab.module].Create(frame)
		local button = ns.Widgets.CreateButton(frame, L[tab.label], TAB_BUTTON_WIDTH)
		if previous then
			button:SetPoint("LEFT", previous, "RIGHT", TAB_BUTTON_GAP, 0)
		else
			button:SetPoint("TOPLEFT", TAB_BUTTON_X, TAB_BUTTON_Y)
		end
		button:SetScript("OnClick", function()
			selectTab(tab.key)
		end)
		frame.tabButtons[tab.key] = button
		previous = button
	end
end

local function currentTab()
	return frame[tabByKey(currentKey).field]
end

local function savePosition(self)
	self:StopMovingOrSizing()
	local point, _, _, x, y = self:GetPoint(1)
	if not (ns.db and not ns.readOnly and VALID_POINTS[point]) then
		return
	end
	local window = ns.db.settings.window
	window.point = point
	window.x = math.floor(x + 0.5)
	window.y = math.floor(y + 0.5)
end

local function restorePosition(self)
	local window = ns.db and ns.db.settings.window
	local point = window and VALID_POINTS[window.point] and window.point or "CENTER"
	self:ClearAllPoints()
	self:SetPoint(point, UIParent, point, window and window.x or 0, window and window.y or 0)
end

local function create()
	frame = CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate")
	frame:Hide()
	frame:SetSize(WIDTH, HEIGHT)
	frame:SetFrameStrata("HIGH")
	frame:SetToplevel(true)
	frame:SetBackdrop(BACKDROP_DIALOG_32_32)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", savePosition)

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	-- Own line above the tab buttons, so eight tabs fit without covering it.
	title:SetPoint("TOPLEFT", TITLE_X, TITLE_Y)
	title:SetText(L.ADDON_TITLE)

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -6, -6)

	buildTabs()
	frame:SetScript("OnShow", function()
		currentTab():Activate()
	end)
	frame:SetScript("OnHide", function()
		currentTab():Deactivate()
	end)
	selectTab(ns.db.settings.window.tab)
	table.insert(UISpecialFrames, FRAME_NAME)
	restorePosition(frame)
end

function MainWindow.Toggle()
	if not (ns.db and ns.charKey) then
		ns.Log.Print(L.NOT_READY)
		return
	end
	-- Data of a newer schema may have a different layout; the window does not read it.
	if ns.readOnly then
		ns.Log.Print(L.READ_ONLY_NO_ACCESS)
		return
	end
	if not frame then
		create()
	end
	if frame:IsShown() then
		frame:Hide()
	else
		frame:Show()
	end
end

-- Switches to a tab ("MATERIAL" | "SOURCING" | "FARM" | "CRAFT" | "GOLD_BUFFER" | "SETTINGS" | "HELP");
-- used by the tab buttons and tests.
function MainWindow.SelectTab(key)
	if frame then
		selectTab(key)
	end
end

-- The frame, or nil before the first open (for tests and debugging).
function MainWindow.GetFrame()
	return frame
end

if ns.Client then
	Slash.AddCommand("show", MainWindow.Toggle, L.HELP_LINE_SHOW)
end
