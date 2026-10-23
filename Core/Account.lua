-- Account overview: what every known character has, from the stored data only (gold from
-- Core/IncomeCapture.lua, skill bars and recipe book from Core/RecipeBook.lua, bag and bank snapshots
-- from Core/Stock.lua). Characters appear once they logged in with the addon. Pure logic.
local _, ns = ...

local Account = {}
ns.Account = Account

local function professions(charData)
	local list = {}
	for key, skill in pairs(charData.professions) do
		list[#list + 1] = { key = key, rank = skill.rank, maxRank = skill.maxRank, recipes = 0 }
	end
	table.sort(list, function(a, b)
		return a.rank ~= b.rank and a.rank > b.rank or a.key < b.key
	end)
	return list
end

local function countRecipes(charData, list)
	local byKey, total = {}, 0
	for _, profession in ipairs(list) do
		byKey[profession.key] = profession
	end
	for _, entry in pairs(charData.recipeBook) do
		total = total + 1
		local profession = entry.profession and byKey[entry.profession]
		if profession then
			profession.recipes = profession.recipes + 1
		end
	end
	return total
end

-- Distinct items and units in a snapshot ({ [itemID] = count }).
local function countItems(counts)
	local items, units = 0, 0
	for _, count in pairs(counts) do
		items, units = items + 1, units + count
	end
	return items, units
end

local function row(key, charData)
	local name, realm = ns.Stock.SplitKey(key)
	local list = professions(charData)
	local bagItems, bagUnits = countItems(charData.stock.bags)
	local bankItems, bankUnits = countItems(charData.stock.bank)
	return {
		key = key, name = name or key, realm = realm or "", faction = charData.faction,
		money = charData.money, moneyAt = charData.moneyAt, professions = list,
		recipes = countRecipes(charData, list),
		items = bagItems + bankItems, units = bagUnits + bankUnits, bankSeen = charData.stock.bankAt > 0,
	}
end

-- Rows of the characters on `realm` (all realms when nil), most gold first, and the total gold.
-- Row: { key, name, realm, faction, money, moneyAt (0 = never seen), professions ({ key, rank,
-- maxRank, recipes }, highest skill first), recipes, items (stacks of distinct items, bags + bank),
-- units, bankSeen }.
function Account.Rows(db, realm)
	local rows, total = {}, 0
	for key, charData in pairs(db.characters) do
		local data = row(key, charData)
		if not realm or data.realm == realm then
			rows[#rows + 1] = data
			total = total + data.money
		end
	end
	table.sort(rows, function(a, b)
		return a.money ~= b.money and a.money > b.money or a.key < b.key
	end)
	return rows, total
end
