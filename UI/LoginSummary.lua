-- Summary of the previous play session, once after login (setting loginSummary): net gold, online
-- time and farm runs, and profession cooldowns that are ready again (recipe book). Shown a few
-- seconds after login, when the chat is ready and quiet; not after a /reload (the session
-- continues then).
local _, ns = ...

local L = ns.L
local Log = ns.Log
local Util = ns.Util
local Money = ns.Money

local LoginSummary = {}
ns.LoginSummary = LoginSummary

LoginSummary.DELAY_SECONDS = 5

-- The summary line of a session, or nil if it had no online time.
function LoginSummary.Line(session, now)
	if not session or session.seconds <= 0 then
		return nil
	end
	local net = session.gained - session.spent
	local netText = (net < 0 and "-" or "+") .. Money.Format(math.abs(net))
	return Util.Format(L.LOGIN_SUMMARY, Util.FormatAge(now - session.endedAt), netText,
		Util.FormatDuration(session.seconds), session.runs or 0)
end

-- "Abklingzeit bereit: [Arkanitbarren]" or nil without ready cooldowns.
function LoginSummary.CooldownLine(charData, now)
	local names = {}
	for _, key in ipairs(ns.RecipeBook.ReadyCooldowns(charData, now)) do
		local recipe = ns.Recipes.Get(ns.db, key)
		if recipe then
			names[#names + 1] = ns.UIShared.ItemText(recipe.outputItemID)
		end
	end
	return #names > 0 and Util.Format(L.LOGIN_COOLDOWNS, table.concat(names, L.PLAN_SEPARATOR)) or nil
end

local function show()
	if not (ns.db and not ns.readOnly and ns.db.settings.loginSummary) then
		return
	end
	local now, session = ns.Client:GetServerTime(), ns.IncomeCapture.PreviousSession()
	local line = LoginSummary.Line(session, now)
	if line then
		Log.Print(line)
	end
	-- Only after a real login (a /reload has no previous session), so reloads stay quiet.
	local cooldowns = session and LoginSummary.CooldownLine(ns.db.characters[ns.charKey], now)
	if cooldowns then
		Log.Print(cooldowns)
	end
end

if ns.Client then
	ns.Events.OnSignal("CHARACTER_READY", function()
		C_Timer.After(LoginSummary.DELAY_SECONDS, show)
	end)
end
