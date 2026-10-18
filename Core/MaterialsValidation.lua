-- Validation of stored material goals (registered with DB.VALIDATORS). Runs on load, after
-- all modules exist. Pure logic on the SavedVariables tables.
local _, ns = ...

local Materials = ns.Materials

local function isPositiveInteger(value, max)
	return type(value) == "number" and value >= 1 and value <= max and value == math.floor(value)
end

-- Drops invalid entries and merges duplicates. Returns the clean list and whether it changed.
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

local function sanitizeGoalItems(goal, p, repairs)
	if type(goal.items) ~= "table" then
		goal.items = {}
		repairs[#repairs + 1] = p .. ".items"
		return
	end
	local clean, changed = sanitizeItems(goal.items)
	goal.items = clean
	if changed then
		repairs[#repairs + 1] = p .. ".items"
	end
end

-- Repairs one stored goal in place; p is its path for the repair list.
local function sanitizeGoal(goal, p, repairs)
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
	-- Optional (goals created from a recipe).
	if goal.recipeKey ~= nil and not ns.Recipes.IsValidKey(goal.recipeKey) then
		goal.recipeKey = nil
		repairs[#repairs + 1] = p .. ".recipeKey"
	end
	sanitizeGoalItems(goal, p, repairs)
end

function Materials.Sanitize(charData, path, repairs)
	local goals = charData.materialGoals
	local maxID = 0
	for id, goal in pairs(goals) do
		local p = path .. ".materialGoals." .. tostring(id)
		if not isPositiveInteger(id, Materials.MAX_GOAL_ID) or type(goal) ~= "table" then
			goals[id] = nil
			repairs[#repairs + 1] = p
		else
			maxID = math.max(maxID, id)
			sanitizeGoal(goal, p, repairs)
		end
	end
	if not isPositiveInteger(charData.nextGoalID, Materials.MAX_GOAL_ID) or charData.nextGoalID <= maxID then
		charData.nextGoalID = maxID + 1
		repairs[#repairs + 1] = path .. ".nextGoalID"
	end
	if charData.activeGoalID ~= 0 and not goals[charData.activeGoalID] then
		charData.activeGoalID = 0
		repairs[#repairs + 1] = path .. ".activeGoalID"
	end
end

ns.DB.VALIDATORS[#ns.DB.VALIDATORS + 1] = Materials.Sanitize
