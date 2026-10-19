-- Classic Era adapter part: the item on the cursor (drag and drop into the addon window), item
-- tooltips and the merchant frame.
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

-- Calls callback(tooltip, itemID) each time GameTooltip or ItemRefTooltip shows an item. Classic
-- Era tooltips use the OnTooltipSetItem script (Blizzard_GameTooltip/Classic/GameTooltip.xml);
-- Blizzard's PTR feedback addon hooks it the same way and reads the link with tooltip:GetItem().
-- Post-hooks only (HookScript); install once.
function UI.HookItemTooltips(callback)
	local function onSetItem(tooltip)
		local _, link = tooltip:GetItem()
		local itemID = type(link) == "string" and tonumber(link:match("|Hitem:(%d+)"))
		if itemID then
			callback(tooltip, itemID)
		end
	end
	for _, tooltip in pairs({ game = GameTooltip, ref = ItemRefTooltip }) do
		if tooltip.HookScript then
			tooltip:HookScript("OnTooltipSetItem", onSetItem)
		end
	end
end

-- Blizzard's merchant frame (Blizzard_UIPanels_Game/Vanilla/MerchantFrame.xml), or nil.
function UI.GetMerchantFrame()
	return MerchantFrame
end
