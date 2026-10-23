-- AH shopping list: what the gold plan (reagents to buy before crafting, resale purchases) and the
-- plan of the wants (materials to buy) need from the auction house. Pure logic; the list is
-- { { itemID, units } }, sorted by itemID. Done steps are skipped.
local _, ns = ...

local ShoppingList = {}
ns.ShoppingList = ShoppingList

local function add(units, itemID, count)
	if count > 0 then
		units[itemID] = (units[itemID] or 0) + count
	end
end

local function addTask(units, task)
	for _, entry in ipairs(task.toBuy or {}) do
		add(units, entry.itemID, entry.units)
	end
	if task.kind == "FLIP" then
		add(units, task.itemID, task.units)
	end
end

-- steps: plan steps ({ task?, done? }); wantsToGet: WantPlan.ToGet (or {}).
function ShoppingList.Collect(steps, wantsToGet)
	local units = {}
	for _, step in ipairs(steps) do
		if step.task and not step.done then
			addTask(units, step.task)
		end
	end
	for itemID, entry in pairs(wantsToGet) do
		add(units, itemID, entry.buy)
	end
	local list = {}
	for itemID, count in pairs(units) do
		list[#list + 1] = { itemID = itemID, units = count }
	end
	table.sort(list, function(a, b)
		return a.itemID < b.itemID
	end)
	return list
end
