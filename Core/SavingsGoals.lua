-- Gold buffer: savings goals of a character (training, riding, profession, another craft) with a
-- target amount and a reserved amount. The list order is the priority. Distributing assigns the
-- character's gold once, in priority order; reserves stay until the next distribution.
-- Pure logic on characters[charKey].savingsGoals = { { label, copper, reserved, done, createdAt } }.
local _, ns = ...

local SavingsGoals = {}
ns.SavingsGoals = SavingsGoals

SavingsGoals.MAX_GOALS = 30

local function isAmount(copper)
	return type(copper) == "number" and copper > 0 and copper <= ns.Money.MAX_COPPER and copper == math.floor(copper)
end

-- Returns the new goal's number, or nil plus "invalid_money" | "too_many_savings".
function SavingsGoals.Add(charData, label, copper, now)
	local list = charData.savingsGoals
	if not isAmount(copper) then
		return nil, "invalid_money"
	end
	if #list >= SavingsGoals.MAX_GOALS then
		return nil, "too_many_savings"
	end
	list[#list + 1] = { label = ns.Materials.CleanLabel(label), copper = copper, reserved = 0, done = false, createdAt = now or 0 }
	return #list
end

local function goalAt(charData, index)
	return type(index) == "number" and charData.savingsGoals[index] or nil
end

function SavingsGoals.SetAmount(charData, index, copper)
	local goal = goalAt(charData, index)
	if not goal then
		return nil, "no_savings_goal"
	end
	if not isAmount(copper) then
		return nil, "invalid_money"
	end
	goal.copper = copper
	goal.reserved = math.min(goal.reserved, copper)
	return goal
end

function SavingsGoals.Rename(charData, index, label)
	local goal = goalAt(charData, index)
	if not goal then
		return nil, "no_savings_goal"
	end
	goal.label = ns.Materials.CleanLabel(label)
	return goal
end

-- Moves a goal one place up (higher priority). Returns the new index.
function SavingsGoals.MoveUp(charData, index)
	local list = charData.savingsGoals
	if not goalAt(charData, index) then
		return nil, "no_savings_goal"
	end
	if index > 1 then
		list[index - 1], list[index] = list[index], list[index - 1]
		return index - 1
	end
	return index
end

-- Marks a goal as reached (e.g. the training was bought); its reserve is released.
function SavingsGoals.Complete(charData, index)
	local goal = goalAt(charData, index)
	if not goal then
		return nil, "no_savings_goal"
	end
	goal.done = true
	goal.reserved = 0
	return goal
end

function SavingsGoals.Delete(charData, index)
	if not goalAt(charData, index) then
		return nil, "no_savings_goal"
	end
	table.remove(charData.savingsGoals, index)
	return true
end

-- The reserves of all goals in list order (to undo a distribution).
function SavingsGoals.SnapshotReserves(charData)
	local snapshot = {}
	for i, goal in ipairs(charData.savingsGoals) do
		snapshot[i] = goal.reserved
	end
	return snapshot
end

-- Restores reserves from a snapshot; goals added since keep theirs. Reserves stay within targets.
function SavingsGoals.RestoreReserves(charData, snapshot)
	for i, goal in ipairs(charData.savingsGoals) do
		if snapshot[i] then
			goal.reserved = math.min(snapshot[i], goal.copper)
		end
	end
end

-- Assigns `money` once to the open goals in priority order. Returns the amount assigned.
function SavingsGoals.Distribute(charData, money)
	local left = math.max(0, money or 0)
	for _, goal in ipairs(charData.savingsGoals) do
		goal.reserved = 0
		if not goal.done then
			goal.reserved = math.min(goal.copper, left)
			left = left - goal.reserved
		end
	end
	return math.max(0, money or 0) - left
end

-- Budget overview for the current gold: { money, reserved (covered, at most money), free,
-- uncovered (sum of open targets not reserved), openGoals }.
function SavingsGoals.Overview(charData, money)
	local overview = { money = money, reserved = 0, uncovered = 0, openGoals = 0 }
	for _, goal in ipairs(charData.savingsGoals) do
		if not goal.done then
			overview.openGoals = overview.openGoals + 1
			overview.reserved = overview.reserved + goal.reserved
			overview.uncovered = overview.uncovered + (goal.copper - goal.reserved)
		end
	end
	-- Gold spent after the distribution can leave less than reserved: reserves are capped.
	overview.reserved = math.min(overview.reserved, money)
	overview.free = money - overview.reserved
	return overview
end

-- Sum of the reserves of all open goals (not capped by the current gold).
function SavingsGoals.ReservedTotal(charData)
	local total = 0
	for _, goal in ipairs(charData.savingsGoals) do
		if not goal.done then
			total = total + goal.reserved
		end
	end
	return total
end

-- How much of a purchase of `cost` would use reserves: max(0, cost - free).
function SavingsGoals.ReserveUse(overview, cost)
	return math.max(0, cost - overview.free)
end

-- Validation of stored savings goals (registered with DB.VALIDATORS).
local function validGoal(goal)
	return type(goal) == "table" and type(goal.label) == "string" and isAmount(goal.copper)
		and type(goal.reserved) == "number" and goal.reserved >= 0 and type(goal.done) == "boolean"
		and type(goal.createdAt) == "number"
end

function SavingsGoals.Sanitize(charData, path, repairs)
	local clean = {}
	for _, goal in ipairs(charData.savingsGoals) do
		if validGoal(goal) and #clean < SavingsGoals.MAX_GOALS then
			goal.label = ns.Materials.CleanLabel(goal.label)
			goal.reserved = math.min(goal.reserved, goal.copper)
			clean[#clean + 1] = goal
		end
	end
	if #clean ~= #charData.savingsGoals then
		repairs[#repairs + 1] = path .. ".savingsGoals"
	end
	charData.savingsGoals = clean
end

ns.DB.VALIDATORS[#ns.DB.VALIDATORS + 1] = SavingsGoals.Sanitize
