-- About text (what the addon does, its version and its developer) and the how-to (how the addon
-- gets its data), both in sections with a colored heading. Shown by /bof about, /bof howto and the
-- views of the Help tab (with an empty line between sections; the chat leaves those out).
local addonName, ns = ...

local L = ns.L
local Util = ns.Util
local Log = ns.Log

local About = {}
ns.About = About

local HEADING_COLOR = "|cffffd100"
local COLOR_END = "|r"

-- { heading key, line keys } per section.
local ABOUT_SECTIONS = {
	{ "ABOUT_HEAD_FEATURES", { "ABOUT_WANTS", "ABOUT_STOCK", "ABOUT_FARM", "ABOUT_PROFESSIONS", "ABOUT_GOLD",
		"ABOUT_ADVISOR", "ABOUT_PRICES" } },
	{ "ABOUT_HEAD_DEVELOPER", { "ABOUT_DEVELOPER", "ABOUT_LICENSE" } },
}
local HOWTO_SECTIONS = {
	{ "HOWTO_HEAD_CHARACTERS", { "HOWTO_ALTS", "HOWTO_BAGS", "HOWTO_BANK", "HOWTO_MAIL", "HOWTO_GOLD" } },
	{ "HOWTO_HEAD_PROFESSIONS", { "HOWTO_RECIPES" } },
	{ "HOWTO_HEAD_PRICES", { "HOWTO_VENDOR", "HOWTO_AUCTION", "HOWTO_AUCTIONATOR", "HOWTO_HISTORY", "HOWTO_MANUAL" } },
	{ "HOWTO_HEAD_FARMING", { "HOWTO_FARM", "HOWTO_FISHING", "HOWTO_WANTS" } },
}

local function heading(text)
	return HEADING_COLOR .. text .. COLOR_END
end

local function addSections(lines, sections)
	for _, section in ipairs(sections) do
		lines[#lines + 1] = ""
		lines[#lines + 1] = heading(L[section[1]])
		for _, key in ipairs(section[2]) do
			lines[#lines + 1] = L[key]
		end
	end
	return lines
end

function About.Lines()
	local title = heading(Util.Format(L.ABOUT_TITLE, ns.Client:GetAddOnVersion(addonName) or L.UNKNOWN_VALUE))
	return addSections({ title, L.ABOUT_SUMMARY }, ABOUT_SECTIONS)
end

function About.HowToLines()
	return addSections({ heading(L.HOWTO_TITLE) }, HOWTO_SECTIONS)
end

local function printLines(lines)
	for _, line in ipairs(lines) do
		if line ~= "" then
			Log.Print(line)
		end
	end
end

ns.Slash.AddCommand("about", function()
	printLines(About.Lines())
end, L.HELP_LINE_ABOUT)
ns.Slash.AddCommand("howto", function()
	printLines(About.HowToLines())
end, L.HELP_LINE_HOWTO)
