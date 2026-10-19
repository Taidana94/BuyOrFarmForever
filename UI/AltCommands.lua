-- /bof alt: list, add and remove alternatives to the craft and set their cost, time effort and
-- requirements. Display helpers come from CraftCommands.
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Money = ns.Money
local CraftEval = ns.CraftEval
local Slash = ns.Slash
local UIShared = ns.UIShared
local CraftCommands = ns.CraftCommands

local KIND_WORDS = { planned = "PLANNED", drop = "POSSIBLE" }
local CLEAR_WORD = "clear"

-- /bof alt [add <item> planned|drop [note] | remove <nr> | cost|time|req <nr> <value|clear>] ---

local function printAlternative(index, alt)
	local note = alt.note ~= "" and Util.Format(L.ALT_NOTE, alt.note) or ""
	Log.Print(Util.Format(L.ALT_LIST_LINE, index, CraftCommands.KindName(alt.kind), UIShared.ItemText(alt.itemID), note))
	local details = CraftCommands.DetailLine(alt)
	if details then
		Log.Print(details)
	end
end

local function listAlternatives(charData)
	if #charData.craftEval.alternatives == 0 then
		Log.Print(L.ALT_LIST_EMPTY)
		return
	end
	for index, alt in ipairs(charData.craftEval.alternatives) do
		printAlternative(index, alt)
	end
end

local function addAlternative(charData, argument)
	local itemID, rest = Util.ParseItemArg(argument)
	local kindWord, note = Slash.SplitCommand(rest or "")
	local index, err = CraftEval.AddAlternative(charData, itemID, KIND_WORDS[kindWord], note, ns.Client:GetServerTime())
	if not index then
		Log.Print(err == "too_many_alternatives" and Util.Format(L.ALT_TOO_MANY, CraftEval.MAX_ALTERNATIVES) or L.ALT_USAGE)
		return
	end
	Log.Print(Util.Format(L.ALT_ADDED, index, UIShared.ItemText(itemID)))
end

local function removeAlternative(charData, argument)
	if CraftEval.RemoveAlternative(charData, Util.ParseInteger(Util.Trim(argument))) then
		Log.Print(L.ALT_REMOVED)
	else
		Log.Print(Util.Format(L.ALT_NOT_FOUND, Util.Trim(argument)))
	end
end

local function parseRequires(text)
	local requires = Util.Trim(text)
	if requires == "" then
		return nil, "invalid_requires"
	end
	return requires
end

-- /bof alt cost|time|req <nr> <value|clear>: subcommand -> stored field and parser of the value.
local DETAILS = {
	cost = { field = "copper", parse = Money.Parse },
	time = { field = "seconds", parse = Util.ParseDuration },
	req = { field = "requires", parse = parseRequires },
}

local function setDetail(charData, detail, argument)
	local indexText, valueText = Slash.SplitCommand(argument)
	local value
	if string.lower(Util.Trim(valueText)) ~= CLEAR_WORD then
		local err
		value, err = detail.parse(valueText)
		if value == nil then
			UIShared.PrintError(err)
			return
		end
	end
	local index = Util.ParseInteger(indexText)
	if not CraftEval.SetAlternativeDetail(charData, index, detail.field, value) then
		Log.Print(Util.Format(L.ALT_NOT_FOUND, indexText))
		return
	end
	printAlternative(index, charData.craftEval.alternatives[index])
end

-- /bof alt kind <nr> planned|drop
local function setKind(charData, argument)
	local indexText, kindWord = Slash.SplitCommand(argument)
	local index = Util.ParseInteger(indexText)
	local ok, err = CraftEval.SetAlternativeKind(charData, index, KIND_WORDS[string.lower(Util.Trim(kindWord))])
	if not ok then
		Log.Print(err == "invalid_kind" and L.ALT_USAGE or Util.Format(L.ALT_NOT_FOUND, indexText))
		return
	end
	printAlternative(index, charData.craftEval.alternatives[index])
end

local WRITE_COMMANDS = { add = addAlternative, remove = removeAlternative, kind = setKind }
for word, detail in pairs(DETAILS) do
	WRITE_COMMANDS[word] = function(charData, argument)
		setDetail(charData, detail, argument)
	end
end

local function altCommand(argument)
	local sub, rest = Slash.SplitCommand(argument)
	if sub == "" or sub == "list" then
		local charData = UIShared.Character()
		if charData then
			listAlternatives(charData)
		end
		return
	end
	local command = WRITE_COMMANDS[sub]
	if not command then
		Log.Print(L.ALT_USAGE)
		return
	end
	local charData = UIShared.WritableCharacter()
	if charData then
		command(charData, rest)
	end
end

if ns.Client then
	Slash.AddCommand("alt", altCommand, L.HELP_LINE_ALT)
end
