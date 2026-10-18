-- Main window: a movable frame with the Material tab (more tabs follow in later stages).
-- Created lazily on first open; closing hides it and unregisters the tab's events.
-- Uses only widely stable frame APIs and templates that exist in Classic Era 70003
-- (BackdropTemplate, UIPanelCloseButton; see docs/ARCHITECTURE.md).
local _, ns = ...

local L = ns.L
local Slash = ns.Slash

local MainWindow = {}
ns.MainWindow = MainWindow

-- A global frame name is needed so Escape closes the window (UISpecialFrames holds names).
local FRAME_NAME = "BuyOrFarmForeverMainFrame"
local WIDTH, HEIGHT = 560, 420
local VALID_POINTS = {
	CENTER = true, TOP = true, BOTTOM = true, LEFT = true, RIGHT = true,
	TOPLEFT = true, TOPRIGHT = true, BOTTOMLEFT = true, BOTTOMRIGHT = true,
}

local frame

local function savePosition(self)
	self:StopMovingOrSizing()
	local point, _, _, x, y = self:GetPoint(1)
	if not (ns.db and not ns.readOnly and VALID_POINTS[point]) then
		return
	end
	local window = ns.db.settings.window
	window.point = point
	window.x = math.floor(x + 0.5)
	window.y = math.floor(y + 0.5)
end

local function restorePosition(self)
	local window = ns.db and ns.db.settings.window
	local point = window and VALID_POINTS[window.point] and window.point or "CENTER"
	self:ClearAllPoints()
	self:SetPoint(point, UIParent, point, window and window.x or 0, window and window.y or 0)
end

local function create()
	frame = CreateFrame("Frame", FRAME_NAME, UIParent, "BackdropTemplate")
	frame:Hide()
	frame:SetSize(WIDTH, HEIGHT)
	frame:SetFrameStrata("HIGH")
	frame:SetToplevel(true)
	frame:SetBackdrop(BACKDROP_DIALOG_32_32)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", savePosition)

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -18)
	title:SetText(L.ADDON_TITLE)

	local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", -6, -6)

	frame.material = ns.MaterialTab.Create(frame)
	frame:SetScript("OnShow", function()
		frame.material:Activate()
	end)
	frame:SetScript("OnHide", function()
		frame.material:Deactivate()
	end)
	table.insert(UISpecialFrames, FRAME_NAME)
	restorePosition(frame)
end

function MainWindow.Toggle()
	if not (ns.db and ns.charKey) then
		ns.Log.Print(L.NOT_READY)
		return
	end
	-- Data of a newer schema may have a different layout; the window does not read it.
	if ns.readOnly then
		ns.Log.Print(L.READ_ONLY_NO_ACCESS)
		return
	end
	if not frame then
		create()
	end
	if frame:IsShown() then
		frame:Hide()
	else
		frame:Show()
	end
end

-- The frame, or nil before the first open (for tests and debugging).
function MainWindow.GetFrame()
	return frame
end

if ns.Client then
	Slash.AddCommand("show", MainWindow.Toggle, L.HELP_LINE_SHOW)
end
