-- Profession leveling: the cheapest learned recipes for the next skill point. A craft costs its
-- reagents (Core/ProfessionView.lua Economics: bags count as their price) minus what its product
-- brings at the vendor (sure money; auction sales are not counted, they may not sell). The skill-up
-- chance per colour is a design estimate of this addon, not game data: orange always, yellow
-- mostly, green rarely, gray never. Expected cost per point = net cost / chance.
local _, ns = ...

local SkillUp = {}
ns.SkillUp = SkillUp

SkillUp.CHANCES = { optimal = 1, medium = 0.75, easy = 0.25 }
SkillUp.MAX_OPTIONS = 3

local function option(key, recipe, chance, now)
	local economics = ns.ProfessionView.Economics(recipe, now)
	local net = math.max(0, economics.cost - (economics.vendor or 0))
	return { key = key, itemID = recipe.outputItemID, chance = chance, cost = economics.cost,
		perPoint = ns.Util.Round(net / chance), complete = economics.costComplete }
end

-- The best options of one profession: { { key, itemID, chance, cost, perPoint, complete } },
-- cheapest per point first; recipes with a missing reagent price come last.
function SkillUp.Options(charData, profession, now)
	local list = {}
	for key, entry in pairs(charData.recipeBook) do
		local chance = entry.profession == profession and SkillUp.CHANCES[entry.difficulty or ""]
		local recipe = chance and ns.Recipes.Get(ns.db, key)
		if recipe then
			list[#list + 1] = option(key, recipe, chance, now)
		end
	end
	table.sort(list, function(a, b)
		if a.complete ~= b.complete then
			return a.complete
		end
		if a.perPoint ~= b.perPoint then
			return a.perPoint < b.perPoint
		end
		return a.key < b.key
	end)
	while #list > SkillUp.MAX_OPTIONS do
		table.remove(list)
	end
	return list
end
