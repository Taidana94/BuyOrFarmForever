-- Classic Era adapter part: reading the profession windows (trade skill and craft window).
-- Loaded before Adapters/ClassicEra.lua, which exposes these functions as adapter methods; which
-- profession a window shows comes from Adapters/ClassicEraProfessionInfo.lua.
-- Classic Era only; Forever has a different professions API (C_TradeSkillUI).
local _, ns = ...

local Professions = {}
ns.ClassicEraProfessions = Professions

-- Profession windows ------------------------------------------------------------------
-- Classic Era has two: the trade skill window (most professions) and the craft window
-- (Enchanting; also Beast Training, which has no reagents). Both can be open at once; the window
-- in which a recipe was selected last is used (user request), else the one opened last.
-- Functions below are called by Blizzard's Vanilla UI code (Blizzard_TradeSkillUI,
-- Blizzard_CraftUI, build 70003); not in the generated docs.

local openWindows = { trade = false, craft = false }
local lastWindow -- "trade" | "craft" | nil

local WINDOW_EVENTS = {
	TRADE_SKILL_SHOW = { "trade", true },
	TRADE_SKILL_CLOSE = { "trade", false },
	CRAFT_SHOW = { "craft", true },
	CRAFT_CLOSE = { "craft", false },
}

local function onWindowEvent(_, event)
	local kind, isOpen = WINDOW_EVENTS[event][1], WINDOW_EVENTS[event][2]
	openWindows[kind] = isOpen
	if isOpen then
		lastWindow = kind
	elseif lastWindow == kind then
		local other = kind == "trade" and "craft" or "trade"
		lastWindow = openWindows[other] and other or nil
	end
end

-- Rare events (opening/closing a profession window), so they stay registered.
local windowFrame = CreateFrame("Frame")
for event in pairs(WINDOW_EVENTS) do
	windowFrame:RegisterEvent(event)
end
windowFrame:SetScript("OnEvent", onWindowEvent)

-- Selecting a recipe calls SelectTradeSkill(id) / SelectCraft(id) (Blizzard's
-- TradeSkillFrame_SetSelection and CraftFrame_SetSelection, also replacement UIs that use the
-- API). A secure post-hook only records which window that was; it changes nothing and runs
-- only on clicks. Selections in a closed window are ignored.
local function selected(kind)
	if openWindows[kind] then
		lastWindow = kind
	end
end

if hooksecurefunc then
	if SelectTradeSkill then
		hooksecurefunc("SelectTradeSkill", function()
			selected("trade")
		end)
	end
	if SelectCraft then
		hooksecurefunc("SelectCraft", function()
			selected("craft")
		end)
	end
end

local TRADE = {
	count = function()
		return GetNumTradeSkills()
	end,
	-- Localized skill line name, rank, max rank (Vanilla TradeSkillFrame_Update uses it so).
	skillLine = function()
		if GetTradeSkillLine then
			return GetTradeSkillLine()
		end
		return nil
	end,
	-- Seconds until the recipe can be used again, or nil (Vanilla TradeSkillUI shows it the same way).
	cooldown = function(i)
		return GetTradeSkillCooldown(i)
	end,
	selection = function()
		return GetTradeSkillSelectionIndex()
	end,
	info = function(i)
		local _, skillType = GetTradeSkillInfo(i)
		return skillType
	end,
	outputLink = function(i)
		return GetTradeSkillItemLink(i)
	end,
	recipeLink = function(i)
		return GetTradeSkillRecipeLink(i)
	end,
	numMade = function(i)
		return GetTradeSkillNumMade(i)
	end,
	numReagents = function(i)
		return GetTradeSkillNumReagents(i)
	end,
	reagentCount = function(i, r)
		local _, _, count = GetTradeSkillReagentInfo(i, r)
		return count
	end,
	reagentLink = function(i, r)
		return GetTradeSkillReagentItemLink(i, r)
	end,
}

local CRAFT = {
	count = function()
		return GetNumCrafts()
	end,
	-- Name is nil for Beast Training (Vanilla CraftFrame_Update).
	skillLine = function()
		if GetCraftDisplaySkillLine then
			return GetCraftDisplaySkillLine()
		end
		return nil
	end,
	cooldown = function()
		return nil
	end,
	selection = function()
		return GetCraftSelectionIndex()
	end,
	info = function(i)
		local _, _, craftType = GetCraftInfo(i)
		return craftType
	end,
	-- An item link for crafts that create items, otherwise an enchant link (plan Q-T4).
	outputLink = function(i)
		return GetCraftItemLink(i)
	end,
	recipeLink = function()
		return nil
	end,
	numMade = function()
		return 1, 1
	end,
	numReagents = function(i)
		return GetCraftNumReagents(i)
	end,
	reagentCount = function(i, r)
		local _, _, count = GetCraftReagentInfo(i, r)
		return count
	end,
	reagentLink = function(i, r)
		return GetCraftReagentItemLink(i, r)
	end,
}

local APIS = { trade = TRADE, craft = CRAFT }

-- Key and output item from the recipe link (spell/enchant id) and the output link.
local function recipeIdentity(api, index)
	local outputType, outputID = ns.Util.ParseLink(api.outputLink(index))
	local outputItemID = outputType == "item" and outputID or 0
	local recipeType, recipeID = ns.Util.ParseLink(api.recipeLink(index))
	if recipeType ~= "enchant" and recipeType ~= "spell" then
		recipeType, recipeID = outputType, outputID
	end
	if recipeType == "enchant" or recipeType == "spell" then
		return "spell:" .. recipeID, outputItemID
	end
	if outputItemID ~= 0 then
		return "item:" .. outputItemID, outputItemID
	end
	return nil, outputItemID
end

local function readReagents(api, index)
	local reagents = {}
	for r = 1, api.numReagents(index) or 0 do
		local _, itemID = ns.Util.ParseLink(api.reagentLink(index, r))
		local count = api.reagentCount(index, r)
		if not (itemID and type(count) == "number") then
			return nil
		end
		reagents[#reagents + 1] = { itemID = itemID, count = count }
	end
	return reagents
end

-- One recipe entry, or nil plus "loading" while its links are not available.
local function readEntry(api, index)
	local key, outputItemID = recipeIdentity(api, index)
	local reagents = readReagents(api, index)
	if not (key and reagents) then
		return nil, "loading"
	end
	local outputMin, outputMax = api.numMade(index)
	return {
		key = key,
		outputItemID = outputItemID,
		outputMin = outputMin,
		outputMax = outputMax,
		reagents = reagents,
	}
end

-- The recipe selected in the most recently opened profession window.
-- Returns { key, outputItemID (0 = none), outputMin, outputMax, reagents = { { itemID, count } } },
-- or nil plus "no_window" | "no_selection" | "loading" (links not available yet).
-- The result is raw client data; the core validates it (Recipes.Normalize).
function Professions.ReadSelectedRecipe()
	local api = (lastWindow == "trade" and TRADE) or (lastWindow == "craft" and CRAFT)
	if not api then
		return nil, "no_window"
	end
	local index = api.selection()
	if type(index) ~= "number" or index < 1 or api.info(index) == "header" then
		return nil, "no_selection"
	end
	return readEntry(api, index)
end

-- Every recipe of the open profession windows (headers skipped), each like ReadSelectedRecipe plus
-- cooldownSeconds (nil without cooldown), profession (key, "OTHER" if unknown) and difficulty (the
-- window's skill type, e.g. "optimal"; raw, validated by the core). Returns the list and true if some
-- entries were skipped because their links are still loading. Empty without an open window.
function Professions.ReadAllRecipes()
	local list, incomplete = {}, false
	for kind, api in pairs(APIS) do
		local profession = openWindows[kind] and ns.ClassicEraProfessionOf((api.skillLine()))
		for index = 1, openWindows[kind] and (api.count() or 0) or 0 do
			local difficulty = api.info(index)
			local recipe = difficulty ~= "header" and readEntry(api, index)
			if recipe then
				recipe.cooldownSeconds = api.cooldown(index)
				recipe.profession, recipe.difficulty = profession, difficulty
				list[#list + 1] = recipe
			end
			incomplete = incomplete or (difficulty ~= "header" and not recipe)
		end
	end
	return list, incomplete
end

-- Skill bars of the open profession windows: { { profession, rank, maxRank } } (raw numbers).
function Professions.ReadProfessionSkills()
	local list = {}
	for kind, api in pairs(APIS) do
		local name, rank, maxRank
		if openWindows[kind] then
			name, rank, maxRank = api.skillLine()
		end
		if name then
			list[#list + 1] = { profession = ns.ClassicEraProfessionOf(name), rank = rank, maxRank = maxRank }
		end
	end
	return list
end
