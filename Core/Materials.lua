-- Shared checks of item ids, counts, craft counts and user-entered labels (wants, recipes, prices,
-- savings goals). Pure logic, no WoW API calls.
local _, ns = ...

local Materials = {}
ns.Materials = Materials

Materials.MAX_LABEL_CHARS = 50
Materials.MAX_COUNT = 100000
Materials.MAX_CRAFTS = 1000
local MAX_ITEM_ID = 10000000

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
