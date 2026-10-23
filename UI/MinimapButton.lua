-- Minimap button (setting minimapButton): left click opens or closes the window, right click
-- pauses or resumes the farm run (without a run it opens the Farm tab). The position is an angle
-- around the minimap (setting minimapAngle): dragging with the left button moves the button along
-- the edge and stores the angle. Round look like other minimap buttons: a small icon on the round
-- minimap background under the tracking border, cut round by a mask where the client has one.
-- Also the key binding actions (Bindings.xml).
local _, ns = ...

local L = ns.L
local Events = ns.Events
local FarmRuns = ns.FarmRuns

local MinimapButton = {}
ns.MinimapButton = MinimapButton

local SIZE, RADIUS, BORDER_SIZE, ICON_SIZE, BACKGROUND_SIZE = 31, 80, 53, 20, 24
local ICON_X, ICON_Y = 0, 1
local FRAME_LEVEL_ABOVE_MINIMAP = 8
-- Cuts the square icon's edges off.
local ICON_CROP = { 0.08, 0.92, 0.08, 0.92 }
local FULL_CIRCLE = 360
-- Standard icon, minimap border, background and round mask textures of the client (the mask is used
-- by Blizzard_ArenaUI in the Classic Era UI source; paths unverified in game).
local ICON = "Interface\\Icons\\INV_Misc_Coin_01"
local BORDER = "Interface\\Minimap\\MiniMap-TrackingBorder"
local BACKGROUND = "Interface\\Minimap\\UI-Minimap-Background"
local MASK = "Interface\\CharacterFrame\\TempPortraitAlphaMask"

local button, minimap

local function currentRun()
	if not (ns.db and not ns.readOnly and ns.charKey) then
		return nil
	end
	return ns.db.characters[ns.charKey].currentRun
end

-- Right click / key binding: pause or resume the run; without a run open the farm window.
function MinimapButton.ToggleFarmRun()
	local run = currentRun()
	if FarmRuns.IsRunning(run) then
		ns.Slash.Handle("farm pause")
	elseif run and run.state == "PAUSED" then
		ns.Slash.Handle("farm resume")
	else
		ns.FarmWindow.Show()
	end
end

local function showTooltip(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:AddLine(L.ADDON_TITLE)
	GameTooltip:AddLine(L.MINIMAP_TIP_CLICKS, 1, 1, 1)
	local run = currentRun()
	if run then
		GameTooltip:AddLine(ns.FarmCommands.StatusLine(run, ns.Client:GetServerTime()))
	end
	GameTooltip:AddLine(L.MINIMAP_HINT)
	GameTooltip:Show()
end

local function place()
	local angle = math.rad(ns.db.settings.minimapAngle)
	button:ClearAllPoints()
	button:SetPoint("CENTER", minimap, "CENTER", math.cos(angle) * RADIUS, math.sin(angle) * RADIUS)
end

-- Angle in whole degrees (0..359) from the minimap's center to the cursor.
local function cursorAngle()
	local x, y = ns.Client:GetCursorIn(minimap)
	local centerX, centerY = minimap:GetCenter()
	return math.floor(math.deg(math.atan2(y - centerY, x - centerX)) + 0.5) % FULL_CIRCLE
end

-- PERF-OK: OnUpdate only while the button is dragged (set on drag start, removed on drag stop).
local function onDragUpdate()
	ns.db.settings.minimapAngle = cursorAngle()
	place()
end

local function addTextures()
	local background = button:CreateTexture(nil, "BACKGROUND")
	background:SetTexture(BACKGROUND)
	background:SetSize(BACKGROUND_SIZE, BACKGROUND_SIZE)
	background:SetPoint("CENTER", ICON_X, ICON_Y)
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetTexture(ICON)
	icon:SetSize(ICON_SIZE, ICON_SIZE)
	icon:SetPoint("CENTER", ICON_X, ICON_Y)
	icon:SetTexCoord(ICON_CROP[1], ICON_CROP[2], ICON_CROP[3], ICON_CROP[4])
	if button.CreateMaskTexture and icon.AddMaskTexture then
		local mask = button:CreateMaskTexture()
		mask:SetTexture(MASK)
		mask:SetAllPoints(icon)
		icon:AddMaskTexture(mask)
	end
	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetTexture(BORDER)
	border:SetSize(BORDER_SIZE, BORDER_SIZE)
	border:SetPoint("TOPLEFT")
end

local function enableDrag()
	button:RegisterForDrag("LeftButton")
	button:SetScript("OnDragStart", function(self)
		GameTooltip:Hide()
		self:SetScript("OnUpdate", onDragUpdate) -- PERF-OK: only while dragged
	end)
	button:SetScript("OnDragStop", function(self)
		self:SetScript("OnUpdate", nil) -- PERF-OK: drag ended, OnUpdate removed
		Events.Emit("SETTINGS_CHANGED")
	end)
end

local function createButton()
	button = CreateFrame("Button", nil, minimap)
	button:SetSize(SIZE, SIZE)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(minimap:GetFrameLevel() + FRAME_LEVEL_ABOVE_MINIMAP)
	addTextures()
	enableDrag()
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:SetScript("OnClick", function(_, mouseButton)
		if mouseButton == "RightButton" then
			MinimapButton.ToggleFarmRun()
		elseif IsShiftKeyDown() then
			ns.AdvisorWindow.Toggle()
		else
			ns.MainWindow.Toggle()
		end
	end)
	button:SetScript("OnEnter", showTooltip)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
end

-- Shows, hides and places the button after the settings.
local function update()
	minimap = minimap or ns.Client:GetMinimap()
	if not (ns.db and minimap) then
		return
	end
	local wanted = ns.db.settings.minimapButton and not ns.readOnly
	if wanted and not button then
		createButton()
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
BINDING_NAME_BUYORFARMFOREVER_ADVISOR = L.BINDING_ADVISOR

-- The button, or nil while it was never shown (for tests).
function MinimapButton.GetButton()
	return button
end

if ns.Client then
	Events.OnSignal("CHARACTER_READY", update)
	Events.OnSignal("SETTINGS_CHANGED", update)
end
