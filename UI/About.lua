-- About text: what the addon does, its version and its developer. Shown by /bof about and the
-- "Über" view of the Help tab.
local addonName, ns = ...

local L = ns.L
local Util = ns.Util
local Log = ns.Log

local About = {}
ns.About = About

local ABOUT_KEYS = {
	"ABOUT_WANTS", "ABOUT_STOCK", "ABOUT_FARM", "ABOUT_PROFESSIONS", "ABOUT_GOLD", "ABOUT_ADVISOR", "ABOUT_PRICES",
}

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
	for _, line in ipairs(About.Lines()) do
		Log.Print(line)
	end
end, L.HELP_LINE_ABOUT)
