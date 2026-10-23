-- Input widgets of the window: edit boxes that commit on Enter, an item slot for drag and drop
-- and one shared confirmation dialog. Tabs create them once and reuse them. The tabs turn every
-- input into the matching chat command (Inputs.Run), so the window and the chat share one code
-- path: the same validation, the same messages and the DATA_CHANGED refresh.
-- Frame API and templates only (InputBoxTemplate, UIPanelButtonTemplate, BackdropTemplate exist
-- in Blizzard_SharedXML of Classic Era 70003).
local _, ns = ...

local L = ns.L
local Widgets = ns.Widgets

local Inputs = {}
ns.Inputs = Inputs

local BOX_HEIGHT = 20
Inputs.SLOT_SIZE = 22
local DIALOG_WIDTH, DIALOG_HEIGHT = 340, 120
local DIALOG_BUTTON_WIDTH, DIALOG_PADDING = 100, 20
local SLOT_BACKGROUND = { 0, 0, 0, 0.5 }

-- Runs a /bof command line (without "/bof") like the chat does.
function Inputs.Run(command)
	ns.Slash.Handle(command)
end

-- Edit box. opts = { width, numeric (digits only), draft, onCommit = fn(text) }. Enter commits and
-- drops the focus. Losing the focus (also Escape) restores the shown value; a draft box (fields of
-- a form that a button submits, e.g. "Neu: [Name] [Betrag] [Anlegen]") keeps the typed text
-- instead, so moving to the next field or clicking the button does not lose it. Refreshes set the
-- shown value with Inputs.SetValue, which leaves a box alone while the player is typing in it.
function Inputs.CreateBox(parent, opts)
	local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	box:SetSize(opts.width, BOX_HEIGHT)
	box:SetAutoFocus(false)
	box:SetNumeric(opts.numeric == true)
	box.value = ""
	box:SetScript("OnEnterPressed", function(self)
		local text = self:GetText() or ""
		self:ClearFocus()
		opts.onCommit(text)
	end)
	box:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	box:SetScript("OnEditFocusLost", function(self)
		if opts.draft then
			self.value = self:GetText() or ""
		else
			self:SetText(self.value)
		end
	end)
	return box
end

function Inputs.SetValue(box, text)
	box.value = text or ""
	if not box:HasFocus() then
		box:SetText(box.value)
	end
end

local function showSlotTooltip(slot)
	GameTooltip:SetOwner(slot, "ANCHOR_RIGHT")
	if slot.itemID then
		GameTooltip:SetHyperlink("item:" .. slot.itemID)
	else
		GameTooltip:AddLine(L.INPUT_SLOT_HINT)
	end
	GameTooltip:Show()
end

local function hideTooltip()
	GameTooltip:Hide()
end

local slots = {}

-- Item slot: drop an item from the bags on it (or click while holding one), or shift-click an item
-- while the slot is visible. onItem(itemID) is called with the item; a dragged item goes back to
-- where it came from (the cursor is cleared).
function Inputs.CreateItemSlot(parent, onItem)
	local slot = CreateFrame("Button", nil, parent)
	slot:SetSize(Inputs.SLOT_SIZE, Inputs.SLOT_SIZE)
	local background = slot:CreateTexture(nil, "BACKGROUND")
	background:SetAllPoints()
	background:SetColorTexture(SLOT_BACKGROUND[1], SLOT_BACKGROUND[2], SLOT_BACKGROUND[3], SLOT_BACKGROUND[4])
	slot.icon = slot:CreateTexture(nil, "ARTWORK")
	slot.icon:SetAllPoints()
	local function take()
		local itemID = ns.Client:GetCursorItem()
		if itemID then
			ns.Client:ClearCursor()
			onItem(itemID)
		end
	end
	slot:SetScript("OnReceiveDrag", take)
	slot:SetScript("OnClick", take)
	slot:SetScript("OnEnter", showSlotTooltip)
	slot:SetScript("OnLeave", hideTooltip)
	slot.onItem = onItem
	slots[#slots + 1] = slot
	return slot
end

-- A shift-clicked item goes to the visible item slot (only one tab is shown at a time).
local function onLinkInsert(itemID)
	for _, slot in ipairs(slots) do
		if slot:IsVisible() then
			slot.onItem(itemID)
			return
		end
	end
end

-- Shows an item in the slot (nil empties it).
function Inputs.SetSlotItem(slot, itemID)
	slot.itemID = itemID
	slot.icon:SetTexture(itemID and ns.Client:GetItemIcon(itemID) or nil)
end

-- Confirmation dialog -------------------------------------------------------------------

local dialog

local function createDialog()
	dialog = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	dialog:Hide()
	dialog:SetSize(DIALOG_WIDTH, DIALOG_HEIGHT)
	dialog:SetPoint("CENTER")
	dialog:SetFrameStrata("DIALOG")
	dialog:SetBackdrop(BACKDROP_DIALOG_32_32)
	dialog:EnableMouse(true)
	dialog.text = dialog:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	dialog.text:SetPoint("TOPLEFT", DIALOG_PADDING, -DIALOG_PADDING)
	dialog.text:SetPoint("TOPRIGHT", -DIALOG_PADDING, -DIALOG_PADDING)
	dialog.yes = Widgets.CreateButton(dialog, L.INPUT_YES, DIALOG_BUTTON_WIDTH)
	dialog.yes:SetPoint("BOTTOMRIGHT", dialog, "BOTTOM", -DIALOG_PADDING / 2, DIALOG_PADDING)
	dialog.no = Widgets.CreateButton(dialog, L.INPUT_NO, DIALOG_BUTTON_WIDTH)
	dialog.no:SetPoint("BOTTOMLEFT", dialog, "BOTTOM", DIALOG_PADDING / 2, DIALOG_PADDING)
	dialog.yes:SetScript("OnClick", function()
		dialog:Hide()
		dialog.onYes()
	end)
	dialog.no:SetScript("OnClick", function()
		dialog:Hide()
	end)
end

-- Asks a yes/no question; onYes runs only after "Ja".
function Inputs.Confirm(text, onYes)
	if not dialog then
		createDialog()
	end
	dialog.text:SetText(text)
	dialog.onYes = onYes
	dialog:Show()
end

-- The dialog frame, or nil before the first question (for tests).
function Inputs.GetDialog()
	return dialog
end

if ns.Client then
	ns.Events.OnSignal("CHARACTER_READY", function()
		ns.Client:HookLinkInsert(onLinkInsert)
	end)
end
