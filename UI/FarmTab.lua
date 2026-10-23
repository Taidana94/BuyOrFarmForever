-- Farm tab of the main window: the recorded farm routes (one row per zone: runs, farm time, gold per
-- hour sure and on the auction house, the most looted item as icon; the loot per hour in the tooltip)
-- and a button for the farm window, where runs are started and stopped (user request 0.10.0). Same
-- refresh rules as the other tabs: events only while shown, refreshes coalesced to one per frame.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Money = ns.Money
local Widgets = ns.Widgets

local FarmTab = {}
ns.FarmTab = FarmTab

FarmTab.VISIBLE_ROWS = 10
local SECONDS_PER_HOUR = 3600
local OPEN_WIDTH, STATUS_GAP, STATUS_WIDTH = 160, 10, 500
local INTRO_Y, HEADER_Y, LIST_Y, EMPTY_Y, TEXT_WIDTH = -32, -56, -74, -80, 690
local TOOLTIP_ITEMS = 8
local TABLE = Widgets.TableLayout(260, {
	{ key = "runs", header = "COL_RUNS", width = 70 },
	{ key = "time", header = "COL_FARM_TIME", width = 90 },
	{ key = "sure", header = "COL_GOLD_HOUR", width = 110 },
	{ key = "auction", header = "COL_AUCTION_HOUR", width = 110 },
}, "COL_ZONE")
local REFRESH_SIGNALS = { "FARM_CHANGED", "DATA_CHANGED", "ITEM_LOADED", "PRICES_CHANGED" }

local Tab = {}
Tab.__index = Tab
Widgets.MixRefresh(Tab)

-- Items of a route by amount, most first: { { itemID, amount } }.
local function lootByAmount(route)
	local list = {}
	for itemID, amount in pairs(route.items) do
		list[#list + 1] = { itemID = itemID, amount = amount }
	end
	table.sort(list, function(a, b)
		if a.amount ~= b.amount then
			return a.amount > b.amount
		end
		return a.itemID < b.itemID
	end)
	return list
end

local function showTooltip(row)
	local route = row.data
	if not route then
		return
	end
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	GameTooltip:AddLine(ns.FarmCommands.RouteName(route))
	GameTooltip:AddLine(Util.Format(L.FARM_ROUTE_TRAVEL, Util.FormatDuration(route.travelSeconds)), 1, 1, 1)
	local reliability = ns.GoldPlanCommands.ReliabilityText(route)
	GameTooltip:AddLine(reliability ~= "" and reliability:gsub("^ – ", "") or L.ROUTE_RELIABILITY_STABLE, 1, 0.82, 0)
	for i, entry in ipairs(lootByAmount(route)) do
		if i > TOOLTIP_ITEMS then
			break
		end
		local perHour = math.floor(entry.amount * SECONDS_PER_HOUR / route.activeSeconds + 0.5)
		GameTooltip:AddLine(Util.Format(L.FARM_ROUTE_ITEM, ns.UIShared.ItemText(entry.itemID), perHour), 1, 1, 1)
	end
	GameTooltip:Show()
end

local function hideTooltip()
	GameTooltip:Hide()
end

local function createText(frame, font, y)
	local text = frame:CreateFontString(nil, "OVERLAY", font)
	text:SetPoint("TOPLEFT", 0, y)
	text:SetWidth(TEXT_WIDTH)
	text:SetJustifyH("LEFT")
	return text
end

function FarmTab.Create(parent)
	local tab = setmetatable({ offset = 0, routes = {} }, Tab)
	local frame = Widgets.CreateTabFrame(parent)
	tab.frame = frame
	tab.open = Widgets.CreateButton(frame, L.FARM_OPEN_WINDOW, OPEN_WIDTH)
	tab.open:SetPoint("TOPLEFT", 0, 0)
	tab.open:SetScript("OnClick", function()
		ns.FarmWindow.Toggle()
	end)
	tab.statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	tab.statusText:SetPoint("LEFT", tab.open, "RIGHT", STATUS_GAP, 0)
	tab.statusText:SetWidth(STATUS_WIDTH)
	tab.statusText:SetJustifyH("LEFT")
	tab.introText = createText(frame, "GameFontNormalSmall", INTRO_Y)
	tab.rows = Widgets.CreateTable(frame, TABLE, FarmTab.VISIBLE_ROWS, HEADER_Y, LIST_Y)
	for _, row in ipairs(tab.rows) do
		row:SetScript("OnEnter", showTooltip)
		row:SetScript("OnLeave", hideTooltip)
	end
	tab.emptyText = createText(frame, "GameFontDisableSmall", EMPTY_Y)
	frame:EnableMouseWheel(true)
	frame:SetScript("OnMouseWheel", function(_, delta)
		tab:Scroll(-delta)
	end)
	Widgets.InitRefresh(tab, REFRESH_SIGNALS)
	return tab
end

function Tab:DrawRow(row, route)
	row.data = route
	if not route then
		row:Hide()
		return
	end
	local top = lootByAmount(route)[1]
	row.icon:SetTexture(top and ns.Client:GetItemIcon(top.itemID) or nil)
	row.name:SetText(ns.FarmCommands.RouteName(route))
	row.numbers.runs:SetText(tostring(route.runs))
	row.numbers.time:SetText(Util.FormatDuration(route.activeSeconds))
	row.numbers.sure:SetText(Money.Format(math.floor(route.surePerHour)))
	row.numbers.auction:SetText(Money.Format(math.floor(route.auctionPerHour)))
	row:Show()
end

function Tab:Scroll(delta)
	local maxOffset = math.max(0, #self.routes - FarmTab.VISIBLE_ROWS)
	self.offset = math.min(maxOffset, math.max(0, self.offset + delta))
	for i, row in ipairs(self.rows) do
		self:DrawRow(row, self.routes[self.offset + i])
	end
end

function Tab:Refresh()
	local charData = ns.db and ns.charKey and ns.db.characters[ns.charKey]
	local farmRun = charData and ns.FarmRuns.Current(charData)
	self.statusText:SetText(farmRun and ns.FarmCommands.StatusLine(farmRun, ns.Client:GetServerTime()) or "")
	self.routes = charData and ns.GoldRoutes.Current({ minSeconds = 0, minCopper = 0 }) or {}
	self.introText:SetText(#self.routes > 0 and L.FARM_ROUTES_INTRO or "")
	self.emptyText:SetText(#self.routes == 0 and L.FARM_ROUTES_EMPTY or "")
	self:Scroll(0)
end
