-- Material goals: items per craft, number of crafts, merged requirements and shortfall.
-- Pure logic on plain tables (a character's data from the SavedVariables), no WoW API calls.
-- Functions that can fail return nil plus an error code; the chat/UI layer turns codes into text.
local _, ns = ...

local Materials = {}
ns.Materials = Materials

Materials.MAX_LABEL_CHARS = 50
Materials.MAX_COUNT = 100000
Materials.MAX_CRAFTS = 1000
local MAX_ITEM_ID = 10000000
local MAX_GOAL_ID = 1000000000

local function isPositiveInteger(value, max)
	return type(value) == "number" and value >= 1 and value <= max and value == math.floor(value)
end

function Materials.IsValidItemID(itemID)
	return isPositiveInteger(itemID, MAX_ITEM_ID)
end

function Materials.IsValidCount(count)
	return isPositiveInteger(count, Materials.MAX_COUNT)
end

function Materials.IsValidCrafts(crafts)
	return isPositiveInteger(crafts, Materials.MAX_CRAFTS)
end

-- User-entered goal name: no control characters, no "|" (chat escape sequences), trimmed,
-- at most MAX_LABEL_CHARS characters (UTF-8 aware, never cuts a character in half).
function Materials.CleanLabel(label)
	if type(label) ~= "string" then
		return ""
	end
	label = label:gsub("%c", ""):gsub("|", "")
	label = ns.Util.Trim(label)
	local chars, out = 0, {}
	for char in label:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
		chars = chars + 1
		if chars > Materials.MAX_LABEL_CHARS then
			break
		end
		out[#out + 1] = char
	end
	return ns.Util.Trim(table.concat(out))
end

local function findItem(goal, itemID)
	for index, entry in ipairs(goal.items) do
		if entry.itemID == itemID then
			return entry, index
		end
	end
	return nil
end

-- Goals -------------------------------------------------------------------------------

-- Creates a goal, selects it and returns its id.
function Materials.CreateGoal(charData, label, now)
	local id = charData.nextGoalID
	charData.nextGoalID = id + 1
	charData.materialGoals[id] = {
		label = Materials.CleanLabel(label),
		crafts = 1,
		items = {},
		createdAt = now or 0,
	}
	charData.activeGoalID = id
	return id
end

-- Creates and selects a goal from a normalized recipe (Recipes.Normalize): its reagents per
-- craft, the given number of crafts and the recipe key (for the display name). The label stays
-- empty because recipe names are localized. Returns the id, or nil, error code.
function Materials.CreateRecipeGoal(charData, recipe, crafts, now)
	if not Materials.IsValidCrafts(crafts) then
		return nil, "invalid_crafts"
	end
	local id = Materials.CreateGoal(charData, "", now)
	local goal = charData.materialGoals[id]
	goal.crafts = crafts
	goal.recipeKey = recipe.key
	for _, reagent in ipairs(recipe.reagents) do
		goal.items[#goal.items + 1] = { itemID = reagent.itemID, count = reagent.count }
	end
	return id
end

function Materials.GetGoal(charData, id)
	return charData.materialGoals[id]
end

-- Returns the selected goal and its id, or nil.
function Materials.GetActiveGoal(charData)
	local id = charData.activeGoalID
	local goal = charData.materialGoals[id]
	if goal then
		return goal, id
	end
	return nil
end

function Materials.SelectGoal(charData, id)
	if charData.materialGoals[id] then
		charData.activeGoalID = id
		return true
	end
	return false
end

function Materials.DeleteGoal(charData, id)
	if not charData.materialGoals[id] then
		return false
	end
	charData.materialGoals[id] = nil
	if charData.activeGoalID == id then
		charData.activeGoalID = 0
	end
	return true
end

-- Goal ids in ascending order.
function Materials.ListGoalIDs(charData)
	local ids = {}
	for id in pairs(charData.materialGoals) do
		ids[#ids + 1] = id
	end
	table.sort(ids)
	return ids
end

-- Items of a goal ----------------------------------------------------------------------

-- Adds count to the item (merging with an existing entry). Returns the new count per craft.
function Materials.AddItem(goal, itemID, count)
	if not Materials.IsValidItemID(itemID) then
		return nil, "invalid_item"
	end
	if not Materials.IsValidCount(count) then
		return nil, "invalid_count"
	end
	local entry = findItem(goal, itemID)
	local newCount = (entry and entry.count or 0) + count
	if newCount > Materials.MAX_COUNT then
		return nil, "too_many"
	end
	if entry then
		entry.count = newCount
	else
		goal.items[#goal.items + 1] = { itemID = itemID, count = newCount }
	end
	return newCount
end

-- Sets the count per craft. 0 removes the item. Returns the new count.
function Materials.SetItemCount(goal, itemID, count)
	if not Materials.IsValidItemID(itemID) then
		return nil, "invalid_item"
	end
	if count == 0 then
		Materials.RemoveItem(goal, itemID)
		return 0
	end
	if not Materials.IsValidCount(count) then
		return nil, "invalid_count"
	end
	local entry = findItem(goal, itemID)
	if entry then
		entry.count = count
	else
		goal.items[#goal.items + 1] = { itemID = itemID, count = count }
	end
	return count
end

function Materials.RemoveItem(goal, itemID)
	local _, index = findItem(goal, itemID)
	if not index then
		return false
	end
	table.remove(goal.items, index)
	return true
end

function Materials.SetCrafts(goal, crafts)
	if not Materials.IsValidCrafts(crafts) then
		return nil, "invalid_crafts"
	end
	goal.crafts = crafts
	return crafts
end

-- Requirements and shortfall ----------------------------------------------------------

-- Total need per item over the given goals (count per craft x crafts), duplicates merged.
-- Returns a list { { itemID, need }, ... } in order of first appearance.
function Materials.Requirements(goals)
	local list, byID = {}, {}
	for _, goal in ipairs(goals) do
		for _, entry in ipairs(goal.items) do
			local need = entry.count * goal.crafts
			local row = byID[entry.itemID]
			if row then
				row.need = row.need + need
			else
				row = { itemID = entry.itemID, need = need }
				byID[entry.itemID] = row
				list[#list + 1] = row
			end
		end
	end
	return list
end

-- Adds have and missing to each requirement row. haveFn(itemID) returns the available count.
function Materials.Shortfall(requirements, haveFn)
	local result = {}
	for i, row in ipairs(requirements) do
		local have = haveFn(row.itemID) or 0
		result[i] = {
			itemID = row.itemID,
			need = row.need,
			have = have,
			missing = math.max(0, row.need - have),
		}
	end
	return result
end

-- All item ids used in a character's goals (for stock snapshots).
function Materials.TrackedItemIDs(charData)
	local ids, seen = {}, {}
	for _, id in ipairs(Materials.ListGoalIDs(charData)) do
		for _, entry in ipairs(charData.materialGoals[id].items) do
			if not seen[entry.itemID] then
				seen[entry.itemID] = true
				ids[#ids + 1] = entry.itemID
			end
		end
	end
	return ids
end

-- All item ids used in the goals of any character (for stock snapshots of every character).
function Materials.TrackedItemIDsAll(db)
	local ids, seen = {}, {}
	for _, charData in pairs(db.characters) do
		for _, itemID in ipairs(Materials.TrackedItemIDs(charData)) do
			if not seen[itemID] then
				seen[itemID] = true
				ids[#ids + 1] = itemID
			end
		end
	end
	table.sort(ids)
	return ids
end

-- Validation of stored data (registered with DB.VALIDATORS) ----------------------------

local function sanitizeItems(items)
	local clean, byID, changed = {}, {}, false
	for _, entry in ipairs(items) do
		local ok = type(entry) == "table" and Materials.IsValidItemID(entry.itemID) and Materials.IsValidCount(entry.count)
		if not ok then
			changed = true
		elseif byID[entry.itemID] then
			local merged = byID[entry.itemID]
			merged.count = math.min(Materials.MAX_COUNT, merged.count + entry.count)
			changed = true
		else
			local row = { itemID = entry.itemID, count = entry.count }
			byID[entry.itemID] = row
			clean[#clean + 1] = row
		end
	end
	return clean, changed
end

function Materials.Sanitize(charData, path, repairs)
	local goals = charData.materialGoals
	local maxID = 0
	for id, goal in pairs(goals) do
		local p = path .. ".materialGoals." .. tostring(id)
		if not isPositiveInteger(id, MAX_GOAL_ID) or type(goal) ~= "table" then
			goals[id] = nil
			repairs[#repairs + 1] = p
		else
			maxID = math.max(maxID, id)
			local label = Materials.CleanLabel(goal.label)
			if label ~= goal.label then
				goal.label = label
				repairs[#repairs + 1] = p .. ".label"
			end
			if not Materials.IsValidCrafts(goal.crafts) then
				goal.crafts = 1
				repairs[#repairs + 1] = p .. ".crafts"
			end
			if type(goal.createdAt) ~= "number" then
				goal.createdAt = 0
			end
			-- Optional (goals created from a recipe). Validators run on load, after all modules exist.
			if goal.recipeKey ~= nil and not ns.Recipes.IsValidKey(goal.recipeKey) then
				goal.recipeKey = nil
				repairs[#repairs + 1] = p .. ".recipeKey"
			end
			if type(goal.items) ~= "table" then
				goal.items = {}
				repairs[#repairs + 1] = p .. ".items"
			else
				local clean, changed = sanitizeItems(goal.items)
				goal.items = clean
				if changed then
					repairs[#repairs + 1] = p .. ".items"
				end
			end
		end
	end
	if not isPositiveInteger(charData.nextGoalID, MAX_GOAL_ID) or charData.nextGoalID <= maxID then
		charData.nextGoalID = maxID + 1
		repairs[#repairs + 1] = path .. ".nextGoalID"
	end
	if charData.activeGoalID ~= 0 and not goals[charData.activeGoalID] then
		charData.activeGoalID = 0
		repairs[#repairs + 1] = path .. ".activeGoalID"
	end
end

ns.DB.VALIDATORS[#ns.DB.VALIDATORS + 1] = Materials.Sanitize
