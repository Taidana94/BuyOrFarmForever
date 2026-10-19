-- A small non-modal bar near the top of the screen with a text and up to three buttons, used to
-- offer something to the player (start a farm run, keep a quest reward as alternative). It hides
-- after a click or after a number of seconds; a newer offer replaces an older one.
local _, ns = ...

local Widgets = ns.Widgets

local PromptBar = {}
ns.PromptBar = PromptBar

local BAR_WIDTH, BAR_HEIGHT = 480, 64
local BUTTON_WIDTH, PADDING, MAX_BUTTONS = 140, 12, 3

-- Creates a hidden bar at `y` pixels below the top of the screen.
function PromptBar.Create(y)
	local bar = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
	bar:Hide()
	bar:SetSize(BAR_WIDTH, BAR_HEIGHT)
	bar:SetPoint("TOP", 0, y)
	bar:SetFrameStrata("DIALOG")
	bar:SetBackdrop(BACKDROP_DIALOG_32_32)
	bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	bar.text:SetPoint("TOPLEFT", PADDING, -PADDING)
	bar.text:SetPoint("TOPRIGHT", -PADDING, -PADDING)
	bar.buttons = {}
	for i = 1, MAX_BUTTONS do
		local button = Widgets.CreateButton(bar, "", BUTTON_WIDTH)
		button:SetPoint("BOTTOMLEFT", PADDING + (i - 1) * (BUTTON_WIDTH + PADDING), PADDING)
		button:SetScript("OnClick", function(self)
			bar:Hide()
			if self.onClick then
				self.onClick()
			end
		end)
		bar.buttons[i] = button
	end
	bar.sequence = 0
	return bar
end

-- Shows `text` with buttons = { { label, onClick (optional) } } for `seconds`.
function PromptBar.Show(bar, text, buttons, seconds)
	bar.text:SetText(text)
	for i, button in ipairs(bar.buttons) do
		local spec = buttons[i]
		button.onClick = spec and spec[2]
		button:SetText(spec and spec[1] or "")
		Widgets.SetShown(button, spec ~= nil)
	end
	bar:Show()
	bar.sequence = bar.sequence + 1
	local sequence = bar.sequence
	C_Timer.After(seconds, function()
		if sequence == bar.sequence then
			bar:Hide()
		end
	end)
end
