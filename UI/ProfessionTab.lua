-- Professions tab of the main window: one view per profession of the character (icons on the left),
-- its learned recipes grouped by what they are good for (category headers, collapsible), filtered by
-- name and by the reagents in the bags, and the selected recipe in the detail panel.
-- Same refresh rules as the other tabs: events only while shown, refreshes coalesced to one per frame.
-- The selected profession and the reagent filter are settings; search, scroll position, collapsed
-- categories and the selected recipe last for the session.
local _, ns = ...

local L = ns.L
local Util = ns.Util
local Widgets = ns.Widgets
local ProfessionView = ns.ProfessionView
local RecipeCategories = ns.RecipeCategories
local Layout = ns.ProfessionTabLayout
local Detail = ns.ProfessionDetail

local ProfessionTab = {}
ns.ProfessionTab = ProfessionTab

local REFRESH_SIGNALS = { "BAGS_CHANGED", "ITEM_LOADED", "PRICES_CHANGED", "DATA_CHANGED", "RECIPES_CHANGED" }
local OTHER_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"
local COLOR_PARTIAL = { 1, 0.82, 0 }

local Tab = {}
Tab.__index = Tab
Widgets.MixRefresh(Tab)

function ProfessionTab.Create(parent)
	local tab = setmetatable({ offset = 0, search = "", collapsed = {} }, Tab)
	Layout.Build(tab, parent)
	Widgets.InitRefresh(tab, REFRESH_SIGNALS)
	return tab
end

-- Display name of a category: effect categories from the locale, item classes from the client.
function ProfessionTab.CategoryLabel(category)
	local classID = RecipeCategories.ClassID(category)
	if classID then
		return ns.Client:GetItemClassName(classID) or L.CATEGORY_CLASS_UNKNOWN
	end
	return L["CATEGORY_" .. category]
end

local function professionName(key)
	return (ns.Client:GetProfessionInfo(key)) or L.PROF_OTHER
end

-- Actions (from the widgets) --------------------------------------------------------------

function Tab:SelectProfession(key)
	if not ns.readOnly then
		ns.db.settings.window.profession = key
	end
	self.offset, self.selectedKey = 0, nil
	self:Refresh()
end

function Tab:SetSearch(text)
	self.search = string.lower(Util.Trim(text))
	self.offset = 0
	self:RequestRefresh()
end

function Tab:SetMats(mode)
	if not ns.readOnly then
		ns.db.settings.window.professionMats = mode
	end
	self.offset = 0
	self:Refresh()
end

function Tab:Scroll(step)
	self.offset = self.offset + step
	self:Refresh()
end

function Tab:ClickRow(entry)
	if not entry then
		return
	end
	if entry.header then
		self.collapsed[entry.category] = not self.collapsed[entry.category] or nil
	else
		self.selectedKey = entry.row.key
	end
	self:Refresh()
end

function Tab:ShowRowTooltip(rowFrame)
	local row = rowFrame.entry and rowFrame.entry.row
	if not row then
		return
	end
	GameTooltip:SetOwner(rowFrame, "ANCHOR_RIGHT")
	if row.recipe.outputItemID ~= 0 then
		GameTooltip:SetHyperlink("item:" .. row.recipe.outputItemID)
	else
		GameTooltip:AddLine(row.name or L.UNKNOWN_SHORT)
	end
	GameTooltip:AddLine(Util.Format(L.PROF_ROW_TIP, row.have, row.total, row.crafts), 1, 1, 1, true)
	GameTooltip:Show()
end

-- Refresh ---------------------------------------------------------------------------------

-- The profession to show: the stored one if the character has it, else the first one.
local function currentProfession(professions)
	local stored = ns.db.settings.window.profession
	for _, profession in ipairs(professions) do
		if profession.key == stored then
			return profession
		end
	end
	return professions[1]
end

function Tab:UpdateIcons(professions, current)
	for index, button in ipairs(self.icons) do
		local profession = professions[index]
		Widgets.SetShown(button, profession ~= nil)
		if profession then
			local name, icon = ns.Client:GetProfessionInfo(profession.key)
			button.professionKey = profession.key
			button.texture:SetTexture(icon or OTHER_ICON)
			Widgets.SetShown(button.selected, profession == current)
			button.tooltipTitle = name or L.PROF_OTHER
			button.tooltipText = Util.Format(L.PROF_ICON_TIP, profession.count)
		end
	end
end

function Tab:UpdateSkill(profession)
	self.professionName:SetText(profession and professionName(profession.key) or "")
	local skill = profession and profession.skill
	self.skillBar:SetMinMaxValues(0, skill and math.max(skill.maxRank, 1) or 1)
	self.skillBar:SetValue(skill and skill.rank or 0)
	self.skillText:SetText(skill and Util.Format(L.PROF_SKILL, skill.rank, skill.maxRank) or L.PROF_SKILL_UNKNOWN)
	Widgets.SetShown(self.skillBar, profession ~= nil)
end

function Tab:UpdateMats(mats)
	for mode, button in pairs(self.matsButtons) do
		Widgets.SetEnabled(button, mode ~= mats)
	end
end

-- Headers and the rows of open categories, each row with its category label.
local function flatten(groups, collapsed)
	local entries = {}
	for _, group in ipairs(groups) do
		local label = ProfessionTab.CategoryLabel(group.category)
		entries[#entries + 1] = { header = true, category = group.category, label = label, count = #group.rows }
		for _, row in ipairs(collapsed[group.category] and {} or group.rows) do
			row.categoryLabel = label
			entries[#entries + 1] = { row = row }
		end
	end
	return entries
end

-- The selected recipe if it is still listed (also in a collapsed category), else the first one.
local function selectedRow(groups, key)
	local first
	for _, group in ipairs(groups) do
		for _, row in ipairs(group.rows) do
			if row.key == key then
				row.categoryLabel = row.categoryLabel or ProfessionTab.CategoryLabel(group.category)
				return row
			end
			first = first or row
		end
	end
	if first and not first.categoryLabel then
		first.categoryLabel = ProfessionTab.CategoryLabel(groups[1].category)
	end
	return first
end

local function fillHeader(frame, entry, collapsed)
	frame.header:SetText(Util.Format(L.PROF_CATEGORY_LINE, collapsed and "+" or "-", entry.label, entry.count))
end

local function countText(row)
	if row.crafts > 0 then
		return Util.Format(L.PROF_ROW_CRAFTS, row.crafts), Widgets.COLOR_DONE
	end
	if row.have > 0 then
		return Util.Format(L.PROF_ROW_PARTIAL, row.have, row.total), COLOR_PARTIAL
	end
	return "", Widgets.COLOR_NORMAL
end

local function fillRecipe(frame, row, isSelected)
	local itemID = row.recipe.outputItemID
	frame.icon:SetTexture(itemID ~= 0 and ns.Client:GetItemIcon(itemID) or Detail.SPELL_ICON)
	Widgets.SetText(frame.name, row.name or L.PROF_LOADING_NAME, Detail.DIFFICULTY_COLORS[row.difficulty] or Widgets.COLOR_NORMAL)
	local text, color = countText(row)
	Widgets.SetText(frame.count, text, color)
	Widgets.SetShown(frame.selected, isSelected)
end

function Tab:ShowEntries(entries, selectedKey)
	self.offset = math.max(0, math.min(self.offset, #entries - Layout.VISIBLE_ROWS))
	for index, frame in ipairs(self.rows) do
		local entry = entries[self.offset + index]
		frame.entry = entry
		Widgets.SetShown(frame, entry ~= nil)
		local isHeader = entry ~= nil and entry.header == true
		for _, widget in ipairs({ frame.icon, frame.name, frame.count }) do
			Widgets.SetShown(widget, entry ~= nil and not isHeader)
		end
		Widgets.SetShown(frame.header, isHeader)
		Widgets.SetShown(frame.selected, false)
		if isHeader then
			fillHeader(frame, entry, self.collapsed[entry.category])
		elseif entry then
			fillRecipe(frame, entry.row, entry.row.key == selectedKey)
		end
	end
end

function Tab:ShowEmpty(text)
	self.emptyText:SetText(text)
	self.emptyText:Show()
	self:ShowEntries({}, nil)
	Detail.Show(self.detail, nil)
end

function Tab:Refresh()
	local charData = ns.db and ns.charKey and ns.db.characters[ns.charKey]
	local professions = charData and ProfessionView.Professions(charData) or {}
	local current = currentProfession(professions)
	self:UpdateIcons(professions, current)
	self:UpdateSkill(current)
	local mats = ns.db and ns.db.settings.window.professionMats or "ALL"
	self:UpdateMats(mats)
	if not current then
		self:ShowEmpty(charData and L.PROF_EMPTY_BOOK or L.NOT_READY)
		return
	end
	local groups = ProfessionView.Build(charData, current.key, { search = self.search, mats = mats })
	if #groups == 0 then
		self:ShowEmpty(L.PROF_EMPTY_FILTER)
		return
	end
	self.emptyText:Hide()
	local row = selectedRow(groups, self.selectedKey)
	self.selectedKey = row and row.key
	self:ShowEntries(flatten(groups, self.collapsed), self.selectedKey)
	Detail.Show(self.detail, row, ns.Client:GetServerTime())
end
