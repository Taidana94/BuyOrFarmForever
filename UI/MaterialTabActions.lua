-- Actions of the Material tab (buttons, boxes, item slot). Each input runs the matching chat
-- command (Inputs.Run), so validation and messages are the same as in the chat.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Materials = ns.Materials
local UIShared = ns.UIShared
local Money = ns.Money
local Inputs = ns.Inputs
local Widgets = ns.Widgets
local Layout = ns.MaterialTabLayout

local Tab = ns.MaterialTab.Tab
local run = Inputs.Run
local DEFAULT_COUNT = ns.MaterialTab.DEFAULT_COUNT

local function currentCharacter()
	return ns.db and ns.charKey and ns.db.characters[ns.charKey]
end

local function canWrite()
	return ns.db ~= nil and not ns.readOnly
end

-- Selects the previous (-1) or next (1) goal, wrapping around.
function Tab:StepGoal(step)
	if UIShared.StepGoal(step) then
		self.offset = 0
		self:Refresh()
	end
end

function Tab:SetAllGoals(all)
	if not canWrite() then
		self:Refresh()
		return
	end
	ns.db.settings.window.allGoals = all
	self.offset = 0
	self:Refresh()
end

function Tab:ToggleOthers()
	run("stock others")
end

function Tab:Rename(text)
	if Inputs.Changed(self.nameBox, text) then
		run("goal name " .. text)
	end
end

function Tab:SetCrafts(text)
	run("goal crafts " .. text)
end

function Tab:NewGoal()
	ns.db.settings.window.allGoals = false
	run("goal new")
	self.nameBox:SetFocus()
end

function Tab:DeleteGoal()
	local charData = currentCharacter()
	local goal = self.goalID and charData and Materials.GetGoal(charData, self.goalID)
	if not goal then
		return
	end
	local id = self.goalID
	Inputs.Confirm(Util.Format(L.MATERIAL_DELETE_CONFIRM, UIShared.GoalName(goal)), function()
		run("goal delete " .. id .. " confirm")
	end)
end

function Tab:SetCount(row, text)
	if row.data and Util.ParseInteger(text) then
		run("goal set " .. row.data.itemID .. " " .. text)
	end
end

function Tab:RemoveItem(row)
	if row.data then
		run("goal remove " .. row.data.itemID)
	end
end

-- Opens the price box over the row's price cell with the own price (if any).
function Tab:EditPrice(row)
	if not (row.data and canWrite()) then
		return
	end
	self.priceItemID = row.data.itemID
	Layout.PlacePriceBox(self, row)
	Inputs.SetValue(self.priceBox, row.data.manualPrice and Money.Format(row.data.manualPrice) or "")
	self.priceBox:Show()
	self.priceBox:SetFocus()
end

-- An empty box removes the own price.
function Tab:CommitPrice(text)
	self.priceBox:Hide()
	if not self.priceItemID then
		return
	end
	local value = Util.Trim(text) == "" and "clear" or text
	run("price " .. self.priceItemID .. " " .. value)
	self.priceItemID = nil
end

function Tab:SetPendingItem(itemID)
	self.pendingItemID = itemID
	Inputs.SetSlotItem(self.slot, itemID)
	Widgets.SetEnabled(self.add, canWrite())
	self.addCount:SetFocus()
end

-- Adds the item in the slot to the selected goal; without a goal, a new goal is created first.
function Tab:AddPendingItem()
	local charData = currentCharacter()
	if not (charData and self.pendingItemID) then
		return
	end
	if not Materials.GetActiveGoal(charData) then
		run("goal new")
	end
	ns.db.settings.window.allGoals = false
	local count = Util.ParseInteger(Util.Trim(self.addCount:GetText() or "")) or 1
	run("goal add " .. self.pendingItemID .. " " .. count)
	self.pendingItemID = nil
	Inputs.SetSlotItem(self.slot, nil)
	Inputs.SetValue(self.addCount, DEFAULT_COUNT)
end

function Tab:ImportRecipe()
	ns.db.settings.window.allGoals = false
	local count = Util.Trim(self.importCount:GetText() or "")
	run("recipe " .. (count ~= "" and count or DEFAULT_COUNT))
	self.offset = 0
end

function Tab:ScanAuction()
	ns.PriceCommands.Scan()
end
