-- Classic Era adapter part: item rewards of the quest shown in the quest frame (offered or ready
-- to turn in), for quest rewards as craft alternatives.
-- Loaded before Adapters/ClassicEra.lua, which exposes these functions as adapter methods.
-- GetNumQuestChoices, GetNumQuestRewards, GetQuestItemLink("choice" | "reward", i) and
-- GetTitleText are legacy globals used by Blizzard's Classic Era quest frame
-- (Blizzard_UIPanels_Game/Classic/QuestFrame.lua, Vanilla/QuestInfo.lua). Unverified in game.
local _, ns = ...

local Quest = {}
ns.ClassicEraQuest = Quest

local function addItems(items, kind, count)
	for i = 1, count or 0 do
		local link = GetQuestItemLink(kind, i)
		local itemID = type(link) == "string" and tonumber(link:match("|Hitem:(%d+)"))
		if itemID then
			items[#items + 1] = itemID
		end
	end
end

-- { title, items = { itemID, ... } } of the open quest frame (choices first), or nil.
function Quest.GetQuestRewards()
	if not (GetQuestItemLink and GetNumQuestChoices and GetNumQuestRewards) then
		return nil
	end
	local items = {}
	addItems(items, "choice", GetNumQuestChoices())
	addItems(items, "reward", GetNumQuestRewards())
	return { title = GetTitleText and GetTitleText() or "", items = items }
end
