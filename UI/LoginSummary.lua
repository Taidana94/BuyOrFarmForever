-- Summary of the previous play session, once after login (setting loginSummary): net gold, online
-- time and farm runs. Shown a few seconds after login, when the chat is ready and quiet; not after
-- a /reload (the session continues then).
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

local function show()
	if not (ns.db and not ns.readOnly and ns.db.settings.loginSummary) then
		return
	end
	local line = LoginSummary.Line(ns.IncomeCapture.PreviousSession(), ns.Client:GetServerTime())
	if line then
		Log.Print(line)
	end
end

if ns.Client then
	ns.Events.OnSignal("CHARACTER_READY", function()
		C_Timer.After(LoginSummary.DELAY_SECONDS, show)
	end)
end
