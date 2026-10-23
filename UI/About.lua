-- About text (what the addon does, its version and its developer) and the how-to (how the addon
-- gets its data). Shown by /bof about, /bof howto and the views of the Help tab.
local addonName, ns = ...

local L = ns.L
local Util = ns.Util
local Log = ns.Log

local About = {}
ns.About = About

local ABOUT_KEYS = {
	"ABOUT_WANTS", "ABOUT_STOCK", "ABOUT_FARM", "ABOUT_PROFESSIONS", "ABOUT_GOLD", "ABOUT_ADVISOR", "ABOUT_PRICES",
}

local HOWTO_KEYS = {
	"HOWTO_TITLE", "HOWTO_ALTS", "HOWTO_BAGS", "HOWTO_BANK", "HOWTO_MAIL", "HOWTO_GOLD", "HOWTO_RECIPES",
	"HOWTO_VENDOR", "HOWTO_AUCTION", "HOWTO_AUCTIONATOR", "HOWTO_HISTORY", "HOWTO_MANUAL", "HOWTO_FARM",
	"HOWTO_FISHING", "HOWTO_WANTS",
}

function About.HowToLines()
	local lines = {}
	for i, key in ipairs(HOWTO_KEYS) do
		lines[i] = L[key]
	end
	return lines
end

local function printLines(lines)
	for _, line in ipairs(lines) do
		Log.Print(line)
	end
end

function About.Lines()
	local lines = { Util.Format(L.ABOUT_TITLE, ns.Client:GetAddOnVersion(addonName) or L.UNKNOWN_VALUE), L.ABOUT_SUMMARY }
	for _, key in ipairs(ABOUT_KEYS) do
		lines[#lines + 1] = L[key]
	end
	lines[#lines + 1] = L.ABOUT_DEVELOPER
	lines[#lines + 1] = L.ABOUT_LICENSE
	return lines
end

ns.Slash.AddCommand("about", function()
	printLines(About.Lines())
end, L.HELP_LINE_ABOUT)
ns.Slash.AddCommand("howto", function()
	printLines(About.HowToLines())
end, L.HELP_LINE_HOWTO)
