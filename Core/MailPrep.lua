-- Mail preparation: what this character should send to whom (same realm and faction). Two reasons:
--   WANT   another character wants an item (not its reagents: the plan exists only for the
--          logged-in character) and this one carries it
--   CRAFT  a step of the running plan crafts on an alt; its reagents in the bags go there
-- Pure logic over the character data; bagCount(itemID) reads the bags.
-- Entry: { name, charKey, itemID, count, reason }.
local _, ns = ...

local MailPrep = {}
ns.MailPrep = MailPrep

-- What a character still misses of its wanted items: { [itemID] = n }.
function MailPrep.MissingOf(other)
	local missing = {}
	for _, want in ipairs(other.wants) do
		local have = ns.Stock.SnapshotCount(other, want.itemID)
		if want.count > have then
			missing[want.itemID] = want.count - have
		end
	end
	return missing
end

-- Reagents of the open alt craft steps: { [charKey] = { [itemID] = n } }.
local function craftNeeds(steps)
	local needs = {}
	for _, step in ipairs(steps) do
		local task = not step.done and step.task
		local recipe = task and task.charKey and task.recipeKey and ns.Recipes.Get(ns.db, task.recipeKey)
		if recipe then
			needs[task.charKey] = needs[task.charKey] or {}
			for _, reagent in ipairs(recipe.reagents) do
				local list = needs[task.charKey]
				list[reagent.itemID] = (list[reagent.itemID] or 0) + reagent.count * task.crafts
			end
		end
	end
	return needs
end

-- Adds what `key` needs of `wanted`, as far as the bags hold it; used = { [itemID] = n } already
-- planned for other entries, so an item is never sent twice.
local function addEntries(list, key, wanted, reason, bagCount, used)
	local name = ns.Stock.SplitKey(key)
	for itemID, count in pairs(wanted) do
		local send = math.min(count, bagCount(itemID) - (used[itemID] or 0))
		if send > 0 then
			used[itemID] = (used[itemID] or 0) + send
			list[#list + 1] = { name = name, charKey = key, itemID = itemID, count = send, reason = reason }
		end
	end
end

-- Everything to send, sorted by recipient and item. steps: the running plan's steps (or {}).
function MailPrep.Collect(charData, steps, bagCount)
	local list, needs, used = {}, craftNeeds(steps), {}
	for _, key in ipairs(ns.Stock.SameRealmAndFaction(charData)) do
		if key ~= ns.charKey then
			addEntries(list, key, needs[key] or {}, "CRAFT", bagCount, used)
			addEntries(list, key, MailPrep.MissingOf(ns.db.characters[key]), "WANT", bagCount, used)
		end
	end
	table.sort(list, function(a, b)
		if a.name ~= b.name then
			return a.name < b.name
		end
		return a.itemID < b.itemID
	end)
	return list
end
