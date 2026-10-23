-- Craft tasks on other characters of the realm and faction: recipes an alt has learned and the
-- logged-in character has not. Valued like the own crafts (Core/CraftTasks.lua, reagents from the
-- current bags or bought), plus SWITCH_SECONDS for mailing the reagents and logging over. Only for
-- the gold planner and the strategy comparison; the advisor's craft row stays with own recipes.
local _, ns = ...

local AltCraftTasks = {}
ns.AltCraftTasks = AltCraftTasks

-- Design assumption (not game data): mail the reagents, log over, mail the products back.
AltCraftTasks.SWITCH_SECONDS = 180
AltCraftTasks.MAX_TASKS = 3

local function addTasks(tasks, key, own, now, discount)
	for recipeKey, entry in pairs(ns.db.characters[key].recipeBook) do
		local task = not own[recipeKey] and ns.CraftTasks.TaskFor(recipeKey, entry, now)
		if task then
			task.seconds = task.seconds + AltCraftTasks.SWITCH_SECONDS
			task.charKey = key
			local rating = ns.GoldRoutes.Rating(task.sure, task.auction, discount)
			if rating > 0 then
				task.perSecond = rating / task.seconds
				tasks[#tasks + 1] = task
			end
		end
	end
end

-- The most profitable craft tasks of the alts (best rating per second first), at most MAX_TASKS;
-- each task as in CraftTasks.Collect plus charKey. One task per product (the first alt by name).
function AltCraftTasks.Collect(charData, now)
	local discount = ns.db.settings.ahDiscountPercent
	local tasks = {}
	for _, key in ipairs(ns.Stock.SameRealmAndFaction(charData)) do
		if key ~= ns.charKey then
			addTasks(tasks, key, charData.recipeBook, now, discount)
		end
	end
	table.sort(tasks, function(a, b)
		if a.perSecond ~= b.perSecond then
			return a.perSecond > b.perSecond
		end
		return a.charKey < b.charKey
	end)
	local list, seen = {}, {}
	for _, task in ipairs(tasks) do
		if #list < AltCraftTasks.MAX_TASKS and not seen[task.itemID] then
			seen[task.itemID] = true
			list[#list + 1] = task
		end
	end
	return list
end

-- All one-off tasks of the character now: bags (vendor, auction, disenchant), own crafts and crafts
-- on alts. Lives here because this file loads after BagTasks, GoldPlan and CraftTasks.
function ns.GoldPlan.Tasks(charData, now)
	local tasks = ns.BagTasks.Collect(charData, now, ns.db.settings.ahDiscountPercent)
	for _, task in ipairs(ns.CraftTasks.Collect(charData, now)) do
		tasks[#tasks + 1] = task
	end
	for _, task in ipairs(AltCraftTasks.Collect(charData, now)) do
		tasks[#tasks + 1] = task
	end
	return tasks
end
