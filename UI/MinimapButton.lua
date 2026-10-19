-- Minimap button (setting minimapButton): left click opens or closes the window, right click
-- pauses or resumes the farm run (without a run it opens the Farm tab). The position is an angle
-- around the minimap (setting minimapAngle, in the settings tab), so no dragging code is needed.
-- Also the key binding actions (Bindings.xml).
local _, ns = ...

local L = ns.L
local Events = ns.Events
local FarmRuns = ns.FarmRuns

local MinimapButton = {}
ns.MinimapButton = MinimapButton

local SIZE, RADIUS, BORDER_SIZE = 31, 80, 54
-- Standard icon and minimap border textures of the client (paths unverified in game).
local ICON = "Interface\\Icons\\INV_Misc_Coin_01"
local BORDER = "Interface\\Minimap\\MiniMap-TrackingBorder"

local button

local function currentRun()
	if not (ns.db and not ns.readOnly and ns.charKey) then
		return nil
	end
	return ns.db.characters[ns.charKey].currentRun
end

-- Right click / key binding: pause or resume the run; without a run (or in review) open the Farm tab.
function MinimapButton.ToggleFarmRun()
	local run = currentRun()
	if FarmRuns.IsRunning(run) then
		ns.Slash.Handle("farm pause")
	elseif run and run.state == "PAUSED" then
		ns.Slash.Handle("farm resume")
	else
		ns.MainWindow.Show()
		ns.MainWindow.SelectTab("FARM")
	end
end

local function showTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:AddLine(L.ADDON_TITLE)
	local run = currentRun()
	if run then
		GameTooltip:AddLine(ns.FarmCommands.StatusLine(run, ns.Client:GetServerTime()))
	end
	GameTooltip:AddLine(L.MINIMAP_HINT)
	GameTooltip:Show()
end

local function createButton(minimap)
	button = CreateFrame("Button", nil, minimap)
	button:SetSize(SIZE, SIZE)
	button:SetFrameStrata("MEDIUM")
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetTexture(ICON)
	icon:SetAllPoints()
	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetTexture(BORDER)
	border:SetSize(BORDER_SIZE, BORDER_SIZE)
	border:SetPoint("TOPLEFT")
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:SetScript("OnClick", function(_, mouseButton)
		if mouseButton == "RightButton" then
			MinimapButton.ToggleFarmRun()
		else
			ns.MainWindow.Toggle()
		end
	end)
	button:SetScript("OnEnter", showTooltip)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

local function place()
	local angle = math.rad(ns.db.settings.minimapAngle)
	button:ClearAllPoints()
	button:SetPoint("CENTER", button:GetParent(), "CENTER", math.cos(angle) * RADIUS, math.sin(angle) * RADIUS)
end

-- Shows, hides and places the button after the settings.
local function update()
	local minimap = ns.Client:GetMinimap()
	if not (ns.db and minimap) then
		return
	end
	local wanted = ns.db.settings.minimapButton and not ns.readOnly
	if wanted and not button then
		createButton(minimap)
	end
	if button then
		place()
		ns.Widgets.SetShown(button, wanted)
	end
end

-- Names in the client's key binding list (Bindings.xml). Global by the client's convention.
BINDING_HEADER_BUYORFARMFOREVER = L.ADDON_TITLE
BINDING_NAME_BUYORFARMFOREVER_TOGGLE = L.BINDING_TOGGLE
BINDING_NAME_BUYORFARMFOREVER_FARM = L.BINDING_FARM

-- The button, or nil while it was never shown (for tests).
function MinimapButton.GetButton()
	return button
end

if ns.Client then
	Events.OnSignal("CHARACTER_READY", update)
	Events.OnSignal("SETTINGS_CHANGED", update)
end
