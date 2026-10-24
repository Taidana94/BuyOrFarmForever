-- Craft buttons at the bottom of the professions tab's detail panel: a box for the number of crafts,
-- "Herstellen", "Alle: n" (what the bags allow) and "Stapel: n" (one stack of the product). Every button
-- runs /gc make (UI/MakeCommand.lua). Recipes without reagents in the bags get disabled buttons;
-- enchantments get a hint instead (they need a target item). Widgets are created once with the panel and
-- refilled with Update.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Widgets = ns.Widgets
local Inputs = ns.Inputs

local MakeRow = {}
ns.ProfessionMakeRow = MakeRow

local BOX_WIDTH, MAKE_WIDTH, ALL_WIDTH, STACK_WIDTH, GAP = 40, 96, 80, 90, 6

local function run(row, count)
	if row.key then
		ns.MakeCommand.Run(row.key, count)
	end
end

-- The box's number; empty or invalid counts as 1 (the command reports invalid numbers itself).
local function boxCount(row)
	local text = Util.Trim(row.box:GetText() or "")
	return text == "" and "1" or text
end

-- Row at the bottom left of `panel`, `padding` from its edges.
function MakeRow.Build(panel, padding)
	local row = { buttons = {} }
	row.box = Inputs.CreateBox(panel, { width = BOX_WIDTH, numeric = true, draft = true, onCommit = function()
		run(row, boxCount(row))
	end })
	row.box:SetPoint("BOTTOMLEFT", padding + GAP, padding)
	Inputs.SetValue(row.box, "1")
	row.make = ns.ProfessionDetail.CreateButton(panel, L.PROF_MAKE_BUTTON, MAKE_WIDTH, L.PROF_MAKE_TIP)
	row.make:SetPoint("LEFT", row.box, "RIGHT", GAP, 0)
	row.make:SetScript("OnClick", function()
		run(row, boxCount(row))
	end)
	row.all = ns.ProfessionDetail.CreateButton(panel, "", ALL_WIDTH, L.PROF_MAKE_ALL_TIP)
	row.all:SetPoint("LEFT", row.make, "RIGHT", GAP, 0)
	row.all:SetScript("OnClick", function()
		run(row, row.counts and row.counts.all)
	end)
	row.stack = ns.ProfessionDetail.CreateButton(panel, "", STACK_WIDTH, L.PROF_MAKE_STACK_TIP)
	row.stack:SetPoint("LEFT", row.all, "RIGHT", GAP, 0)
	row.stack:SetScript("OnClick", function()
		run(row, row.counts and row.counts.stack)
	end)
	row.buttons = { row.box, row.make, row.all, row.stack }
	row.hint = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	row.hint:SetPoint("BOTTOMLEFT", padding, padding)
	row.hint:SetPoint("RIGHT", -padding, 0)
	row.hint:SetJustifyH("LEFT")
	row.hint:SetText(L.MAKE_ERR_ENCHANT)
	return row
end

-- Fills the row for a recipe row of ProfessionView.Build (nil hides it).
function MakeRow.Update(row, recipeRow)
	row.key = recipeRow and recipeRow.key
	local itemID = recipeRow and recipeRow.recipe.outputItemID
	for _, widget in ipairs(row.buttons) do
		Widgets.SetShown(widget, itemID ~= nil and itemID ~= 0)
	end
	Widgets.SetShown(row.hint, itemID == 0)
	if not itemID or itemID == 0 then
		return
	end
	local stackSize = ns.Client:GetItemStackSize(itemID)
	row.counts = ns.ProfessionView.CraftCounts(recipeRow.recipe, recipeRow.crafts, stackSize)
	local canMake = recipeRow.crafts > 0
	row.all:SetText(Util.Format(L.PROF_MAKE_ALL, row.counts.all))
	row.stack:SetText(Util.Format(L.PROF_MAKE_STACK, row.counts.stack or 0))
	Widgets.SetShown(row.stack, row.counts.stack ~= nil)
	Widgets.SetEnabled(row.make, canMake)
	Widgets.SetEnabled(row.all, canMake)
	Widgets.SetEnabled(row.stack, canMake)
end
