-- Detail panel of the professions tab: the selected recipe's product, category and skill-up chance,
-- its reagents (bags / need, bank on top), how often the bags allow it, what one craft costs and
-- brings, the rating of gear against the equipped items, and a button that adds the product to the
-- wants. Widgets are created once and refilled.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Money = ns.Money
local Widgets = ns.Widgets
local ProfessionView = ns.ProfessionView

local Detail = {}
ns.ProfessionDetail = Detail

local MAX_REAGENTS = 8
local PANEL_GAP, PADDING = 16, 12
local ICON_SIZE, TITLE_X = 36, 56
local REAGENTS_Y, REAGENT_HEIGHT, REAGENT_ICON = -64, 22, 20
local REAGENT_COUNT_WIDTH, REAGENT_NAME_X = 70, 26
local BOTTOM_LINES, LINE_GAP, BOTTOM_Y = 5, 4, 40
local GOAL_BUTTON_WIDTH, GOAL_BUTTON_LIFT = 140, 4
local BACKGROUND = { 0, 0, 0, 0.3 }
-- Icon of enchantments (no product item); also used by the list rows.
Detail.SPELL_ICON = "Interface\\Icons\\Spell_Holy_GreaterHeal"
-- Skill-up colours as the Vanilla profession window shows them (Blizzard_TradeSkillUI TradeSkillTypeColor).
Detail.DIFFICULTY_COLORS = {
	optimal = { 1, 0.5, 0.25 }, medium = { 1, 1, 0 }, easy = { 0.25, 0.75, 0.25 }, trivial = { 0.5, 0.5, 0.5 },
}

local function showLinkTooltip(owner)
	if owner.link then
		GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
		GameTooltip:SetHyperlink(owner.link)
		GameTooltip:Show()
	end
end

local function hideTooltip()
	GameTooltip:Hide()
end

local function showButtonTip(button)
	GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
	GameTooltip:AddLine(button.tip, 1, 1, 1, true)
	GameTooltip:Show()
end

-- Button with a tooltip text (shared with UI/ProfessionMakeRow.lua); the caller sets OnClick.
function Detail.CreateButton(parent, label, width, tip)
	local button = Widgets.CreateButton(parent, label, width)
	button.tip = tip
	button:SetScript("OnEnter", showButtonTip)
	button:SetScript("OnLeave", hideTooltip)
	return button
end

local function createReagent(panel, index)
	local row = CreateFrame("Button", nil, panel)
	row:SetSize(1, REAGENT_HEIGHT)
	row:SetPoint("TOPLEFT", PADDING, REAGENTS_Y - index * REAGENT_HEIGHT)
	row:SetPoint("RIGHT", -PADDING, 0)
	row.icon = row:CreateTexture(nil, "ARTWORK")
	row.icon:SetSize(REAGENT_ICON, REAGENT_ICON)
	row.icon:SetPoint("LEFT", 0, 0)
	row.count = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.count:SetPoint("LEFT", REAGENT_NAME_X, 0)
	row.count:SetWidth(REAGENT_COUNT_WIDTH)
	row.count:SetJustifyH("LEFT")
	row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	row.name:SetPoint("LEFT", REAGENT_NAME_X + REAGENT_COUNT_WIDTH, 0)
	row.name:SetPoint("RIGHT", 0, 0)
	row.name:SetJustifyH("LEFT")
	row:SetScript("OnEnter", showLinkTooltip)
	row:SetScript("OnLeave", hideTooltip)
	return row
end

local function buildHead(detail, panel)
	detail.product = CreateFrame("Button", nil, panel)
	detail.product:SetSize(ICON_SIZE, ICON_SIZE)
	detail.product:SetPoint("TOPLEFT", PADDING, -PADDING)
	detail.product.icon = detail.product:CreateTexture(nil, "ARTWORK")
	detail.product.icon:SetAllPoints()
	detail.product:SetScript("OnEnter", showLinkTooltip)
	detail.product:SetScript("OnLeave", hideTooltip)
	detail.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	detail.title:SetPoint("TOPLEFT", TITLE_X, -PADDING)
	detail.title:SetPoint("RIGHT", -PADDING, 0)
	detail.title:SetJustifyH("LEFT")
	detail.subtitle = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	detail.subtitle:SetPoint("TOPLEFT", detail.title, "BOTTOMLEFT", 0, -LINE_GAP)
	detail.subtitle:SetPoint("RIGHT", -PADDING, 0)
	detail.subtitle:SetJustifyH("LEFT")
	detail.reagentLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	detail.reagentLabel:SetPoint("TOPLEFT", PADDING, REAGENTS_Y)
	detail.reagentLabel:SetText(L.PROF_REAGENTS)
end

local function buildBottom(detail, panel)
	detail.lines = {}
	for index = BOTTOM_LINES, 1, -1 do
		local text = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		if index == BOTTOM_LINES then
			text:SetPoint("BOTTOMLEFT", PADDING, BOTTOM_Y)
		else
			text:SetPoint("BOTTOMLEFT", detail.lines[index + 1], "TOPLEFT", 0, LINE_GAP)
		end
		text:SetPoint("RIGHT", -PADDING, 0)
		text:SetJustifyH("LEFT")
		detail.lines[index] = text
	end
	-- Right of the "Zutaten" label; the bottom row belongs to the craft buttons (UI/ProfessionMakeRow.lua).
	detail.goalButton = Detail.CreateButton(panel, L.PROF_GOAL_BUTTON, GOAL_BUTTON_WIDTH, L.PROF_GOAL_TIP)
	detail.goalButton:SetPoint("TOPRIGHT", -PADDING, REAGENTS_Y + GOAL_BUTTON_LIFT)
	detail.goalButton:SetScript("OnClick", function()
		if detail.key then
			ns.Inputs.Run("recipe key " .. detail.key)
		end
	end)
	detail.make = ns.ProfessionMakeRow.Build(panel, PADDING)
end

-- Panel right of the list, from x = left + PANEL_GAP to the tab's right edge.
function Detail.Build(parent, left)
	local panel = CreateFrame("Frame", nil, parent)
	panel:SetPoint("TOPLEFT", left + PANEL_GAP, 0)
	panel:SetPoint("BOTTOMRIGHT", 0, 0)
	local background = panel:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints()
	background:SetColorTexture(BACKGROUND[1], BACKGROUND[2], BACKGROUND[3], BACKGROUND[4])
	local detail = { frame = panel, reagents = {} }
	buildHead(detail, panel)
	for index = 1, MAX_REAGENTS do
		detail.reagents[index] = createReagent(panel, index)
	end
	buildBottom(detail, panel)
	detail.emptyText = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
	detail.emptyText:SetPoint("CENTER")
	detail.emptyText:SetText(L.PROF_DETAIL_EMPTY)
	return detail
end

-- Filling ---------------------------------------------------------------------------------

local function setFilled(detail, filled)
	for _, widget in ipairs({ detail.product, detail.title, detail.subtitle, detail.reagentLabel, detail.goalButton }) do
		Widgets.SetShown(widget, filled)
	end
	for _, line in ipairs(detail.lines) do
		Widgets.SetShown(line, filled)
	end
	Widgets.SetShown(detail.emptyText, not filled)
end

local function productLink(key, recipe)
	if recipe.outputItemID ~= 0 then
		return "item:" .. recipe.outputItemID
	end
	local keyType, spellID = ns.Recipes.SplitKey(key)
	return keyType == "spell" and ("spell:" .. spellID) or nil
end

local function fillHead(detail, row)
	local itemID = row.recipe.outputItemID
	detail.product.icon:SetTexture(itemID ~= 0 and ns.Client:GetItemIcon(itemID) or Detail.SPELL_ICON)
	detail.product.link = productLink(row.key, row.recipe)
	Widgets.SetText(detail.title, row.name or L.UNKNOWN_SHORT, Detail.DIFFICULTY_COLORS[row.difficulty] or Widgets.COLOR_NORMAL)
	local difficulty = row.difficulty and L["PROF_DIFFICULTY_" .. string.upper(row.difficulty)] or L.PROF_DIFFICULTY_UNKNOWN
	detail.subtitle:SetText(Util.Format(L.PROF_SUBTITLE, row.categoryLabel, difficulty))
end

local function reagentName(itemID, bank)
	local name = ns.Client:GetItemName(itemID) or Util.Format(L.ITEM_UNKNOWN, itemID)
	return bank > 0 and Util.Format(L.PROF_REAGENT_BANK, name, bank) or name
end

local function fillReagents(detail, recipe)
	for index, line in ipairs(detail.reagents) do
		local reagent = recipe.reagents[index]
		Widgets.SetShown(line, reagent ~= nil)
		if reagent then
			local bags = ns.Client:GetBagCount(reagent.itemID)
			local bank = math.max(0, (ns.Client:GetBagAndBankCount(reagent.itemID) or bags) - bags)
			line.icon:SetTexture(ns.Client:GetItemIcon(reagent.itemID))
			Widgets.SetText(line.count, Util.Format(L.PROF_REAGENT_COUNT, bags, reagent.count),
				bags >= reagent.count and Widgets.COLOR_DONE or Widgets.COLOR_MISSING)
			line.name:SetText(reagentName(reagent.itemID, bank))
			line.link = "item:" .. reagent.itemID
		end
	end
end

local function money(copper)
	return copper and Money.Format(copper) or L.UNKNOWN_SHORT
end

local function costLine(economics)
	if economics.costComplete then
		return Util.Format(economics.owned > 0 and L.PROF_COST_OWNED or L.PROF_COST, money(economics.cost))
	end
	return economics.cost > 0 and Util.Format(L.PROF_COST_PARTIAL, money(economics.cost)) or L.PROF_COST_UNKNOWN
end

local function profitLine(economics)
	local profit = economics.profit
	if not profit then
		return L.PROF_PROFIT_UNKNOWN, Widgets.COLOR_GRAY
	end
	if profit < 0 then
		return Util.Format(L.PROF_LOSS, money(-profit)), Widgets.COLOR_MISSING
	end
	return Util.Format(L.PROF_PROFIT, money(profit)), Widgets.COLOR_DONE
end

local function fillEconomics(detail, row, now)
	local economics = ProfessionView.Economics(row.recipe, now)
	detail.lines[1]:SetText(Util.Format(L.PROF_CRAFTS_POSSIBLE, row.crafts))
	detail.lines[2]:SetText(costLine(economics))
	local hasItem = row.recipe.outputItemID ~= 0
	detail.lines[3]:SetText(hasItem and Util.Format(L.PROF_VALUE, money(economics.vendor), money(economics.auction)) or "")
	local text, color = profitLine(economics)
	Widgets.SetText(detail.lines[4], hasItem and text or "", color)
	local charData = ns.db.characters[ns.charKey]
	detail.lines[5]:SetText(hasItem and ns.CraftCommands.GearLine(charData, row.recipe.outputItemID) or "")
end

-- Shows a row of ProfessionView.Build (plus categoryLabel), or the empty hint for nil.
function Detail.Show(detail, row, now)
	detail.key = row and row.key
	setFilled(detail, row ~= nil)
	ns.ProfessionMakeRow.Update(detail.make, row)
	if not row then
		for _, line in ipairs(detail.reagents) do
			line:Hide()
		end
		return
	end
	fillHead(detail, row)
	fillReagents(detail, row.recipe)
	fillEconomics(detail, row, now)
	Widgets.SetEnabled(detail.goalButton, not ns.readOnly)
end
