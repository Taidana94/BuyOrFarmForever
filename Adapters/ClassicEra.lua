-- Client adapter for WoW Classic Era (1.15.9, interface 11509).
-- APIs used here are listed with their verification status in work/notes/BuyOrFarmForever-plan.md.
local _, ns = ...

local ClassicEra = {
	id = "classic_era",
	caps = {},
	-- WoW event -> client-neutral signal (all documented in Classic Era 70003)
	events = {
		BANKFRAME_OPENED = "BANK_OPENED",
		BANKFRAME_CLOSED = "BANK_CLOSED",
		BAG_UPDATE_DELAYED = "BAGS_CHANGED",
	},
}

-- WOW_PROJECT_CLASSIC (2) and WOW_PROJECT_ID are defined by Blizzard's
-- Blizzard_FrameXMLBase/Vanilla/Constants.lua in Classic Era.
function ClassicEra:IsCurrentClient()
	return WOW_PROJECT_ID ~= nil and WOW_PROJECT_CLASSIC ~= nil and WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
end

function ClassicEra:GetBuildInfo()
	local version, build, date, interface = GetBuildInfo()
	return {
		version = version,
		build = build,
		date = date,
		interface = interface,
	}
end

function ClassicEra:GetLocale()
	return GetLocale()
end

function ClassicEra:GetAddOnVersion(addonName)
	if C_AddOns and C_AddOns.GetAddOnMetadata then
		return C_AddOns.GetAddOnMetadata(addonName, "Version")
	end
	return nil
end

-- Returns the value, or nil if it is missing or a secret value.
local function plain(value)
	if value == nil then
		return nil
	end
	if issecretvalue and issecretvalue(value) then
		return nil
	end
	return value
end

-- Returns nil until name and realm are known. Call it on or after PLAYER_LOGIN.
function ClassicEra:GetCharacterKey()
	local name = plain(UnitName("player"))
	local normalizedRealm = plain(GetNormalizedRealmName())
	if type(name) ~= "string" or name == "" or type(normalizedRealm) ~= "string" or normalizedRealm == "" then
		return nil
	end
	return {
		key = name .. "-" .. normalizedRealm,
		name = name,
		realm = plain(GetRealmName()),
		normalizedRealm = normalizedRealm,
		faction = plain(UnitFactionGroup("player")),
	}
end

function ClassicEra:GetServerTime()
	return GetServerTime()
end

function ClassicEra:GetUptime()
	return GetTime()
end

function ClassicEra:GetBagCount(itemID)
	if C_Item and C_Item.GetItemCount then
		return C_Item.GetItemCount(itemID, false)
	end
	return 0
end

-- includeBank = true. Correct also while the bank is closed (confirmed in game, 70003).
function ClassicEra:GetBagAndBankCount(itemID)
	if C_Item and C_Item.GetItemCount then
		return C_Item.GetItemCount(itemID, true)
	end
	return nil
end

-- C_Spell.GetSpellName is documented in Classic Era 70003 (MayReturnNothing).
function ClassicEra:GetSpellName(spellID)
	if C_Spell and C_Spell.GetSpellName then
		return plain(C_Spell.GetSpellName(spellID))
	end
	return nil
end

-- Profession windows ------------------------------------------------------------------
-- Classic Era has two: the trade skill window (most professions) and the craft window
-- (Enchanting; also Beast Training, which has no reagents). Both can be open at once; the most
-- recently opened one is used. Functions below are called by Blizzard's Vanilla UI code
-- (Blizzard_TradeSkillUI, Blizzard_CraftUI, build 70003); not in the generated docs.

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

local TRADE = {
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

-- The recipe selected in the most recently opened profession window.
-- Returns { key, outputItemID (0 = none), outputMin, outputMax, reagents = { { itemID, count } } },
-- or nil plus "no_window" | "no_selection" | "loading" (links not available yet).
-- The result is raw client data; the core validates it (Recipes.Normalize).
function ClassicEra:ReadSelectedRecipe()
	local api = (lastWindow == "trade" and TRADE) or (lastWindow == "craft" and CRAFT)
	if not api then
		return nil, "no_window"
	end
	local index = api.selection()
	if type(index) ~= "number" or index < 1 or api.info(index) == "header" then
		return nil, "no_selection"
	end
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

-- C_Item.GetItemInfo returns nil until the item is in the client cache.
function ClassicEra:GetItemLink(itemID)
	if not (C_Item and C_Item.GetItemInfo) then
		return nil
	end
	local _, link = C_Item.GetItemInfo(itemID)
	if link then
		return link
	end
	if C_Item.RequestLoadItemDataByID then
		C_Item.RequestLoadItemDataByID(itemID)
	end
	return nil
end

ns.Adapter.Register(ClassicEra)
