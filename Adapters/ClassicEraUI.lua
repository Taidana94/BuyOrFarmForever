-- Classic Era adapter part: the item on the cursor (drag and drop into the addon window).
-- Loaded before Adapters/ClassicEra.lua, which exposes these functions as adapter methods.
-- GetCursorInfo and ClearCursor are documented in Classic Era 70003; Blizzard's own code only
-- reads the first return ("item"), so the item id is taken from the second return or, if that
-- is not a number, from the item link (third return). Both: unverified in game.
local _, ns = ...

local UI = {}
ns.ClassicEraUI = UI

-- Item id on the cursor, or nil if the cursor holds no item.
function UI.GetCursorItem()
	if not GetCursorInfo then
		return nil
	end
	local kind, id, link = GetCursorInfo()
	if kind ~= "item" then
		return nil
	end
	if type(id) == "number" then
		return id
	end
	return type(link) == "string" and tonumber(link:match("|Hitem:(%d+)")) or nil
end

function UI.ClearCursor()
	if ClearCursor then
		ClearCursor()
	end
end
