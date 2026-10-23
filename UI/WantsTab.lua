-- Wants tab ("Ziele", 0.10.0): add an item you want, and the addon shows the cheapest way to get it
-- (Core/WantPlan.lua): have it, buy, farm or craft, for a craft per reagent. Crafting and farming
-- start from the tree rows. Every input runs the matching chat command (Inputs.Run), so validation
-- and messages are the same as in the chat. Same refresh rules as the other tabs: events only while
-- shown, refreshes coalesced to one per frame.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Money = ns.Money
local Widgets = ns.Widgets
local Inputs = ns.Inputs
local UIShared = ns.UIShared
local WantCommands = ns.WantCommands
local Layout = ns.WantsTabLayout

local WantsTab = {}
ns.WantsTab = WantsTab

local DEFAULT_COUNT = 1
local REFRESH_SIGNALS = {
	"BAGS_CHANGED", "BANK_CLOSED", "ITEM_LOADED", "DATA_CHANGED", "PRICES_CHANGED", "MONEY_CHANGED", "RECIPES_CHANGED",
	"AUCTION_OPENED", "AUCTION_CLOSED", "SETTINGS_CHANGED",
}
local ACTION_LABELS = { CRAFT = "WANT_BTN_CRAFT", FARM = "WANT_BTN_FARM" }

local Tab = {}
Tab.__index = Tab
Widgets.MixRefresh(Tab)

function WantsTab.Create(parent)
	local tab = setmetatable({ selected = 1, offset = 0, wantOffset = 0, lines = {} }, Tab)
	Layout.Build(tab, parent)
	Widgets.InitRefresh(tab, REFRESH_SIGNALS)
	return tab
end

local function currentCharacter()
	return ns.db and not ns.readOnly and ns.charKey and ns.db.characters[ns.charKey]
end

-- Add line -------------------------------------------------------------------------------

function Tab:SetPendingItem(itemID)
	self.pendingItemID = itemID
	Inputs.SetSlotItem(self.slot, itemID)
	self.addCount:SetFocus()
end

function Tab:AddPending()
	if not self.pendingItemID then
		return
	end
	local count = Util.ParseInteger(self.addCount:GetText() or "") or DEFAULT_COUNT
	Inputs.Run("want add " .. self.pendingItemID .. " " .. count)
	local charData = currentCharacter()
	local index = charData and select(2, ns.Wants.Find(charData, self.pendingItemID))
	self.selected = index or self.selected
	if self.selected > self.wantOffset + Layout.WANT_ROWS then
		self.wantOffset = self.selected - Layout.WANT_ROWS
	end
	self.pendingItemID = nil
	Inputs.SetSlotItem(self.slot, nil)
	self.addCount:SetText("")
	self.addCount:ClearFocus()
end

-- Want rows ------------------------------------------------------------------------------

function Tab:SelectWant(index)
	if index then
		self.selected, self.offset = index, 0
		self:Refresh()
	end
end

function Tab:SetCount(row, text)
	if row.itemID and Util.ParseInteger(text) then
		Inputs.Run("want set " .. row.itemID .. " " .. text)
	end
end

function Tab:RemoveWant(row)
	if row.itemID then
		Inputs.Run("want remove " .. row.itemID)
	end
end

-- Tree rows ------------------------------------------------------------------------------

-- Craft (only with this character's recipe) or start a farm run for the item.
local function actionOf(node)
	if node.method == "CRAFT" and node.recipe.charKey == ns.charKey then
		return "CRAFT"
	end
	if node.method == "FARM" then
		return "FARM"
	end
	return nil
end

function Tab:RunAction(row)
	local node = row.node
	local action = node and actionOf(node)
	if action == "CRAFT" then
		ns.MakeCommand.Run(node.recipe.key, node.crafts)
	elseif action == "FARM" then
		Inputs.Run("farm start " .. node.itemID)
	end
end

-- Where the stock lies: own bags and bank, then every other character of the realm.
local function stockLines(lines, itemID)
	local bags, bank, mail = ns.Stock.Count(itemID)
	lines[#lines + 1] = Util.Format(L.WANT_TIP_OWN, bags, bank and tostring(bank) or L.UNKNOWN_SHORT, mail)
	local charData = currentCharacter()
	local _, others = ns.Stock.OthersFor(ns.db, ns.charKey, charData.faction, itemID)
	local now = ns.Client:GetServerTime()
	for _, d in ipairs(others) do
		local template = d.sameFaction and L.STOCK_ALT_DETAIL or L.STOCK_ALT_OTHER_FACTION
		lines[#lines + 1] = Util.Format(template, d.name, d.total, d.bags, d.bank, d.mail, Util.FormatAge(now - d.at))
	end
end

-- Tooltip lines of a tree row: price per unit, travel, why it is open, where the stock lies.
local function nodeTooltip(node)
	local lines = {}
	if node.unitPrice then
		lines[#lines + 1] = Util.Format(L.WANT_TIP_PRICE, Money.Format(node.unitPrice), UIShared.PriceSourceName(node.source))
	end
	if node.travelSeconds and node.travelSeconds > 0 then
		lines[#lines + 1] = Util.Format(L.WANT_TIP_TRAVEL, Util.FormatDuration(node.travelSeconds))
	end
	if node.method == "OPEN" then
		lines[#lines + 1] = L.WANT_TIP_OPEN
	end
	if node.have > 0 then
		stockLines(lines, node.itemID)
	end
	return lines
end

local function drawTreeRow(row, line)
	row.node = line and line.node
	if not line then
		row:Hide()
		return
	end
	local node = line.node
	Layout.Indent(row, line.depth)
	row.itemID = node.itemID
	row.icon:SetTexture(ns.Client:GetItemIcon(node.itemID))
	row.text:SetText(line.text)
	local color = node.method == "OPEN" and Widgets.COLOR_MISSING or (node.method == "HAVE" and Widgets.COLOR_DONE)
		or Widgets.COLOR_NORMAL
	row.text:SetTextColor(color[1], color[2], color[3])
	row.tooltipLines = nodeTooltip(node)
	local action = actionOf(node)
	row.action:SetText(action and L[ACTION_LABELS[action]] or "")
	Widgets.SetShown(row.action, action ~= nil and not ns.readOnly)
	row:Show()
end

function Tab:Scroll(delta)
	local maxOffset = math.max(0, #self.lines - Layout.TREE_ROWS)
	self.offset = math.min(maxOffset, math.max(0, self.offset + delta))
	for i, row in ipairs(self.treeRows) do
		drawTreeRow(row, self.lines[self.offset + i])
	end
end

-- Refresh --------------------------------------------------------------------------------

local function drawWantRow(row, index, want, node, selected)
	row.index, row.itemID = want and index, want and want.itemID
	if not want then
		row:Hide()
		return
	end
	row.icon:SetTexture(ns.Client:GetItemIcon(want.itemID))
	row.name:SetText(UIShared.ItemText(want.itemID))
	Inputs.SetValue(row.countBox, tostring(want.count))
	Widgets.SetShown(row.highlight, selected)
	row.tooltipLines = { node and WantCommands.NodeText(node) or nil }
	row:Show()
end

local function setLines(texts, lines)
	for i, text in ipairs(texts) do
		text:SetText(lines[i] or "")
	end
end

function Tab:ScrollWants(delta)
	local charData = currentCharacter()
	local count = charData and #charData.wants or 0
	self.wantOffset = math.min(math.max(0, count - Layout.WANT_ROWS), math.max(0, self.wantOffset + delta))
	self:Refresh()
end

function Tab:Refresh()
	local charData = currentCharacter()
	Widgets.SetEnabled(self.add, charData ~= nil)
	Widgets.SetEnabled(self.scan, charData ~= nil and ns.PriceCapture.IsAuctionOpen())
	local wants = charData and charData.wants or {}
	local plan = charData and ns.WantPlan.Current()
	if self.selected > #wants then
		self.selected = math.max(1, #wants)
	end
	self.wantOffset = math.min(self.wantOffset, math.max(0, #wants - Layout.WANT_ROWS))
	for i, row in ipairs(self.wantRows) do
		local index = self.wantOffset + i
		drawWantRow(row, index, wants[index], plan and plan.nodes[index], index == self.selected)
	end
	self.emptyText:SetText(#wants == 0 and (charData and L.WANT_EMPTY or L.NOT_READY) or "")
	Widgets.SetShown(self.treeHeader, #wants > 0)
	local root = plan and plan.nodes[self.selected]
	self.lines = root and WantCommands.PlanLines({ nodes = { root } }) or {}
	self:Scroll(0)
	setLines(self.summary, plan and #wants > 0 and WantCommands.SummaryLines(charData, plan) or {})
end
