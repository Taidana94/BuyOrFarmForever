-- Widgets of the professions tab, created once: profession icons on the left, the list column
-- (skill bar, search box, reagent filter buttons, a fixed pool of rows for category headers and
-- recipes) and the detail panel (UI/ProfessionDetail.lua). The tab (UI/ProfessionTab.lua) fills them.
-- Frame API and templates that exist in Classic Era 70003 (UIPanelButtonTemplate, InputBoxTemplate).
local _, ns = ...

local L = ns.L
local Widgets = ns.Widgets

local Layout = {}
ns.ProfessionTabLayout = Layout

Layout.MAX_ICONS = 9
Layout.VISIBLE_ROWS = 15
local ICON_SIZE, ICON_GAP = 32, 6
local LIST_X, LIST_WIDTH = 44, 300
local SKILL_Y, BAR_Y, BAR_HEIGHT = 0, -18, 14
local SEARCH_Y, SEARCH_WIDTH, SEARCH_TEXT_X = -40, 200, 6
local MATS_Y, MATS_WIDTH, MATS_GAP = -64, 96, 4
local LIST_Y, ROW_HEIGHT = -92, 18
local ROW_ICON_SIZE, ROW_ICON_X, ROW_NAME_X, ROW_COUNT_WIDTH = 16, 12, 32, 50
local BAR_COLOR = { 0, 0, 1, 0.5 }
local BAR_BACKGROUND = { 0, 0, 0, 0.5 }
local SELECTED_COLOR = { 1, 0.82, 0, 0.25 }
local BAR_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
local ICON_HIGHLIGHT = "Interface\\Buttons\\ButtonHilight-Square"
local ICON_SELECTED = "Interface\\Buttons\\CheckButtonHilight"

local function showIconTooltip(button)
	if button.tooltipTitle then
		GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
		GameTooltip:AddLine(button.tooltipTitle)
		GameTooltip:AddLine(button.tooltipText, 1, 1, 1, true)
		GameTooltip:Show()
	end
end

local function hideTooltip()
	GameTooltip:Hide()
end

local function buildIcons(tab, frame)
	tab.icons = {}
	for index = 1, Layout.MAX_ICONS do
		local button = CreateFrame("Button", nil, frame)
		button:SetSize(ICON_SIZE, ICON_SIZE)
		button:SetPoint("TOPLEFT", 0, -(index - 1) * (ICON_SIZE + ICON_GAP))
		button.texture = button:CreateTexture(nil, "ARTWORK")
		button.texture:SetAllPoints()
		button.selected = button:CreateTexture(nil, "OVERLAY")
		button.selected:SetTexture(ICON_SELECTED)
		button.selected:SetBlendMode("ADD")
		button.selected:SetAllPoints()
		button:SetHighlightTexture(ICON_HIGHLIGHT, "ADD")
		button:SetScript("OnClick", function(self)
			tab:SelectProfession(self.professionKey)
		end)
		button:SetScript("OnEnter", showIconTooltip)
		button:SetScript("OnLeave", hideTooltip)
		tab.icons[index] = button
	end
end

local function buildSkill(tab, frame)
	tab.professionName = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	tab.professionName:SetPoint("TOPLEFT", LIST_X, SKILL_Y)
	tab.skillBar = CreateFrame("StatusBar", nil, frame)
	tab.skillBar:SetPoint("TOPLEFT", LIST_X, BAR_Y)
	tab.skillBar:SetSize(LIST_WIDTH, BAR_HEIGHT)
	tab.skillBar:SetStatusBarTexture(BAR_TEXTURE)
	tab.skillBar:SetStatusBarColor(BAR_COLOR[1], BAR_COLOR[2], BAR_COLOR[3], BAR_COLOR[4])
	local background = tab.skillBar:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints()
	background:SetColorTexture(BAR_BACKGROUND[1], BAR_BACKGROUND[2], BAR_BACKGROUND[3], BAR_BACKGROUND[4])
	tab.skillText = tab.skillBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	tab.skillText:SetPoint("CENTER")
	-- Hover: the cheapest recipes for the next skill point (/bof skillup).
	tab.skillBar:EnableMouse(true)
	tab.skillBar:SetScript("OnEnter", function(bar)
		tab:ShowSkillTooltip(bar)
	end)
	tab.skillBar:SetScript("OnLeave", hideTooltip)
end

-- Search box with a grey "Suche" hint while it is empty; every typed character filters the list.
local function buildSearch(tab, frame)
	local box = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
	box:SetSize(SEARCH_WIDTH, Widgets.BUTTON_HEIGHT)
	box:SetPoint("TOPLEFT", LIST_X + SEARCH_TEXT_X, SEARCH_Y)
	box:SetAutoFocus(false)
	box.hint = box:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	box.hint:SetPoint("LEFT", 0, 0)
	box.hint:SetText(L.PROF_SEARCH_HINT)
	box:SetScript("OnTextChanged", function(self)
		local text = self:GetText() or ""
		Widgets.SetShown(self.hint, text == "")
		tab:SetSearch(text)
	end)
	box:SetScript("OnEscapePressed", box.ClearFocus)
	box:SetScript("OnEnterPressed", box.ClearFocus)
	tab.searchBox = box
end

local function showButtonTooltip(button)
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:AddLine(button.tooltipText, 1, 1, 1, true)
	GameTooltip:Show()
end

local function buildMats(tab, frame)
	tab.matsButtons = {}
	for index, mode in ipairs(ns.ProfessionView.MATS) do
		local button = Widgets.CreateButton(frame, L["PROF_MATS_" .. mode], MATS_WIDTH)
		button:SetPoint("TOPLEFT", LIST_X + (index - 1) * (MATS_WIDTH + MATS_GAP), MATS_Y)
		button.tooltipText = L["PROF_MATS_TIP_" .. mode]
		button:SetScript("OnClick", function()
			tab:SetMats(mode)
		end)
		button:SetScript("OnEnter", showButtonTooltip)
		button:SetScript("OnLeave", hideTooltip)
		tab.matsButtons[mode] = button
	end
end

-- One list row: a header (text only) or a recipe (icon, name, count on the right).
local function createRow(tab, list, index)
	local row = CreateFrame("Button", nil, list)
	row:SetSize(LIST_WIDTH, ROW_HEIGHT)
	row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
	row.selected = row:CreateTexture(nil, "BACKGROUND")
	row.selected:SetAllPoints()
	row.selected:SetColorTexture(SELECTED_COLOR[1], SELECTED_COLOR[2], SELECTED_COLOR[3], SELECTED_COLOR[4])
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(ROW_ICON_SIZE, ROW_ICON_SIZE)
	row.icon:SetPoint("LEFT", ROW_ICON_X, 0)
	row.header = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	row.header:SetPoint("LEFT", 0, 0)
	row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.name:SetPoint("LEFT", ROW_NAME_X, 0)
	row.name:SetWidth(LIST_WIDTH - ROW_NAME_X - ROW_COUNT_WIDTH)
	row.name:SetJustifyH("LEFT")
	row.count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.count:SetPoint("RIGHT", 0, 0)
	row.count:SetWidth(ROW_COUNT_WIDTH)
	row.count:SetJustifyH("RIGHT")
	row:SetHighlightTexture(ICON_HIGHLIGHT, "ADD")
	row:SetScript("OnClick", function(self)
		tab:ClickRow(self.entry)
	end)
	row:SetScript("OnEnter", function(self)
		tab:ShowRowTooltip(self)
	end)
	row:SetScript("OnLeave", hideTooltip)
	return row
end

local function buildList(tab, frame)
	local list = CreateFrame("Frame", nil, frame)
	list:SetPoint("TOPLEFT", LIST_X, LIST_Y)
	list:SetSize(LIST_WIDTH, Layout.VISIBLE_ROWS * ROW_HEIGHT)
	list:EnableMouseWheel(true)
	list:SetScript("OnMouseWheel", function(_, delta)
		tab:Scroll(-delta)
	end)
	tab.rows = {}
	for index = 1, Layout.VISIBLE_ROWS do
		tab.rows[index] = createRow(tab, list, index)
	end
	tab.emptyText = list:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	tab.emptyText:SetPoint("TOPLEFT", 0, 0)
	tab.emptyText:SetWidth(LIST_WIDTH)
	tab.emptyText:SetJustifyH("LEFT")
end

-- Creates the widgets of a tab object and connects them to its methods (SelectProfession, SetSearch,
-- SetMats, ClickRow, ShowRowTooltip, Scroll).
function Layout.Build(tab, parent)
	local frame = Widgets.CreateTabFrame(parent)
	tab.frame = frame
	buildIcons(tab, frame)
	buildSkill(tab, frame)
	buildSearch(tab, frame)
	buildMats(tab, frame)
	buildList(tab, frame)
	tab.detail = ns.ProfessionDetail.Build(frame, LIST_X + LIST_WIDTH)
end
