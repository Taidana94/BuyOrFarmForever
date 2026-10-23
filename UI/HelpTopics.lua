-- Topics of the Help tab: every window, button, mouse action and chat command, grouped by area.
-- A topic is a list of sections (a coloured heading and its lines, Locales/deDE.lua keys H_*); the
-- data and about topics reuse UI/About.lua, the command topic groups the /bof help lines by area.
local _, ns = ...

local L = ns.L

local HelpTopics = {}
ns.HelpTopics = HelpTopics

local HEADING_COLOR = "|cffffd100"
local COLOR_END = "|r"

local function sections(list)
	return function()
		local lines = {}
		for _, section in ipairs(list) do
			if #lines > 0 then
				lines[#lines + 1] = ""
			end
			lines[#lines + 1] = HEADING_COLOR .. L[section[1]] .. COLOR_END
			for _, key in ipairs(section[2]) do
				lines[#lines + 1] = L[key]
			end
		end
		return lines
	end
end

-- { id, label key, lines() } in button order.
HelpTopics.LIST = {
	{ id = "START", label = "H_TOPIC_START", lines = sections({
		{ "H_START_HEAD", { "H_START_1", "H_START_2", "H_START_3", "H_START_4" } },
		{ "H_START_WINDOW_HEAD", { "H_START_WINDOW_1", "H_START_WINDOW_2", "H_START_WINDOW_3", "H_START_WINDOW_4" } },
		{ "H_START_INPUT_HEAD", { "H_START_INPUT_1", "H_START_INPUT_2", "H_START_INPUT_3" } },
	}) },
	{ id = "WANTS", label = "H_TOPIC_WANTS", lines = sections({
		{ "H_WANTS_HEAD", { "H_WANTS_1", "H_WANTS_2" } },
		{ "H_WANTS_ADD_HEAD", { "H_WANTS_ADD_1", "H_WANTS_ADD_2", "H_WANTS_ADD_3" } },
		{ "H_WANTS_LIST_HEAD", { "H_WANTS_LIST_1", "H_WANTS_LIST_2", "H_WANTS_LIST_3", "H_WANTS_LIST_4" } },
		{ "H_WANTS_MODE_HEAD", { "H_WANTS_MODE_1", "H_WANTS_MODE_2", "H_WANTS_MODE_3" } },
		{ "H_WANTS_TREE_HEAD", { "H_WANTS_TREE_1", "H_WANTS_TREE_2", "H_WANTS_TREE_3", "H_WANTS_TREE_4" } },
	}) },
	{ id = "FARM", label = "H_TOPIC_FARM", lines = sections({
		{ "H_FARM_AUTO_HEAD", { "H_FARM_AUTO_1", "H_FARM_AUTO_2", "H_FARM_AUTO_3", "H_FARM_AUTO_4" } },
		{ "H_FARM_WINDOW_HEAD", { "H_FARM_WINDOW_1", "H_FARM_WINDOW_2", "H_FARM_WINDOW_3", "H_FARM_WINDOW_4" } },
		{ "H_FARM_TAB_HEAD", { "H_FARM_TAB_1", "H_FARM_TAB_2", "H_FARM_TAB_4", "H_FARM_TAB_3" } },
	}) },
	{ id = "PROF", label = "H_TOPIC_PROF", lines = sections({
		{ "H_PROF_HEAD", { "H_PROF_1", "H_PROF_2" } },
		{ "H_PROF_LIST_HEAD", { "H_PROF_LIST_1", "H_PROF_LIST_2", "H_PROF_LIST_3", "H_PROF_LIST_4" } },
		{ "H_PROF_DETAIL_HEAD", { "H_PROF_DETAIL_1", "H_PROF_DETAIL_2", "H_PROF_DETAIL_3", "H_PROF_DETAIL_4" } },
	}) },
	{ id = "GOLD", label = "H_TOPIC_GOLD", lines = sections({
		{ "H_GOLD_HEAD", { "H_GOLD_1", "H_GOLD_2" } },
		{ "H_GOLD_GOALS_HEAD", { "H_GOLD_GOALS_1", "H_GOLD_GOALS_2", "H_GOLD_GOALS_3", "H_GOLD_GOALS_4" } },
		{ "H_GOLD_MORE_HEAD", { "H_GOLD_MORE_1", "H_GOLD_MORE_2", "H_GOLD_MORE_3" } },
	}) },
	{ id = "PLANNER", label = "H_TOPIC_PLANNER", lines = sections({
		{ "H_PLAN_HEAD", { "H_PLAN_1", "H_PLAN_2", "H_PLAN_3", "H_PLAN_4" } },
		{ "H_PLAN_TIME_HEAD", { "H_PLAN_TIME_1", "H_PLAN_TIME_2" } },
		{ "H_PLAN_VIEWS_HEAD", { "H_PLAN_VIEWS_1", "H_PLAN_VIEWS_2", "H_PLAN_VIEWS_3" } },
		{ "H_PLAN_NOW_HEAD", { "H_PLAN_NOW_1", "H_PLAN_NOW_2", "H_PLAN_NOW_3", "H_PLAN_NOW_4", "H_PLAN_NOW_5" } },
		{ "H_PLAN_KEEP_HEAD", { "H_PLAN_KEEP_1", "H_PLAN_KEEP_2" } },
	}) },
	{ id = "ADVISOR", label = "H_TOPIC_ADVISOR", lines = sections({
		{ "H_ADV_HEAD", { "H_ADV_1", "H_ADV_2" } },
		{ "H_ADV_WINDOW_HEAD", { "H_ADV_WINDOW_1", "H_ADV_WINDOW_2", "H_ADV_WINDOW_3" } },
		{ "H_ADV_SIDE_HEAD", { "H_ADV_SIDE_1", "H_ADV_SIDE_2" } },
	}) },
	{ id = "EXTRAS", label = "H_TOPIC_EXTRAS", lines = sections({
		{ "H_EXTRA_MINIMAP_HEAD", { "H_EXTRA_MINIMAP_1", "H_EXTRA_MINIMAP_2", "H_EXTRA_MINIMAP_3",
			"H_EXTRA_MINIMAP_4" } },
		{ "H_EXTRA_KEYS_HEAD", { "H_EXTRA_KEYS_1", "H_EXTRA_KEYS_2" } },
		{ "H_EXTRA_HINTS_HEAD", { "H_EXTRA_HINTS_1", "H_EXTRA_HINTS_2", "H_EXTRA_HINTS_3", "H_EXTRA_HINTS_4" } },
	}) },
	{ id = "SETTINGS", label = "H_TOPIC_SETTINGS", lines = sections({
		{ "H_SET_HEAD", { "H_SET_1", "H_SET_2", "H_SET_3" } },
		{ "H_SET_GROUPS_HEAD", { "H_SET_GROUPS_1", "H_SET_GROUPS_2", "H_SET_GROUPS_3", "H_SET_GROUPS_4",
			"H_SET_GROUPS_6", "H_SET_GROUPS_5" } },
	}) },
	{ id = "DATA", label = "H_TOPIC_DATA", lines = function()
		return ns.About.HowToLines()
	end },
	{ id = "COMMANDS", label = "H_TOPIC_COMMANDS", lines = sections({
		{ "H_CMD_GENERAL", { "HELP_LINE_HELP", "HELP_LINE_SHOW", "HELP_LINE_VERSION", "HELP_LINE_ABOUT",
			"HELP_LINE_HOWTO", "HELP_LINE_SET", "HELP_LINE_DEBUG", "HELP_LINE_PERF", "HELP_LINE_RESET" } },
		{ "H_CMD_WANTS", { "HELP_LINE_WANT", "HELP_LINE_RECIPE", "HELP_LINE_PRICE" } },
		{ "H_CMD_FARM", { "HELP_LINE_FARM" } },
		{ "H_CMD_PROF", { "HELP_LINE_MAKE", "HELP_LINE_CRAFT", "HELP_LINE_WEIGHTS" } },
		{ "H_CMD_GOLD", { "HELP_LINE_GOLD", "HELP_LINE_GOLDPLAN", "HELP_LINE_PLAN", "HELP_LINE_SHOP", "HELP_LINE_MAIL", "HELP_LINE_COMPARE",
			"HELP_LINE_GOLDSOURCES",
			"HELP_LINE_GOLDKEEP", "HELP_LINE_ACCOUNT", "HELP_LINE_ADVISOR" } },
	}) },
	{ id = "ABOUT", label = "H_TOPIC_ABOUT", lines = function()
		return ns.About.Lines()
	end },
}
