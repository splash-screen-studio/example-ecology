--!strict
--[[
    DialoguePanel Component

    Displays NPC dialogue with response buttons.
    Mobile-first design with large touch targets (min 48px).

    Network flow:
    1. Server fires InteractComplete with type="dialogue"
    2. Client displays dialogue panel with NPC text + responses
    3. Player taps response
    4. Client fires Interact back with response index
]]

local DialoguePanel = {}

-- Services
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Shared constants
local HUDConstants = require(script.Parent.Parent.HUDConstants)

-- Dependencies (lazy loaded)
local Network

-- Types
export type DialogueResponse = {
	index: number,
	text: string,
}

export type DialogueData = {
	type: string,
	npcName: string,
	speaker: string?,
	text: string,
	responses: { DialogueResponse },
	autoAdvance: number?,
}

export type DialoguePanelWidget = {
	frame: Frame,
	show: (self: DialoguePanelWidget, data: DialogueData) -> (),
	hide: (self: DialoguePanelWidget) -> (),
	isVisible: (self: DialoguePanelWidget) -> boolean,
	onResponse: ((responseIndex: number) -> ())?,
	onClose: (() -> ())?,
	destroy: (self: DialoguePanelWidget) -> (),
}

-- Use shared constants
local Spacing = HUDConstants.Spacing
local Sizes = HUDConstants.Sizes
local Colors = HUDConstants.Colors
local Animation = HUDConstants.Animation
local Fonts = HUDConstants.Fonts
local Transparency = HUDConstants.Transparency

-- Configuration
local CONFIG = {
	-- Panel dimensions
	PANEL_WIDTH = 400,
	PANEL_MIN_HEIGHT = 200,
	PANEL_MAX_HEIGHT = 500,
	CORNER_RADIUS = 12,

	-- Response button dimensions (min 48px for touch targets)
	RESPONSE_BUTTON_HEIGHT = 52,
	RESPONSE_BUTTON_GAP = 8,
	MAX_RESPONSES = 4,

	-- Close button
	CLOSE_BUTTON_SIZE = 48,

	-- Text sizing
	NPC_NAME_SIZE = 20,
	DIALOGUE_TEXT_SIZE = 16,
	RESPONSE_TEXT_SIZE = 14,

	-- Animation
	FADE_TIME = 0.25,
	SLIDE_DISTANCE = 30,

	-- Positioning: space above the inventory hotbar
	-- Hotbar height: SLOT_SIZE(48) + CONTAINER_PADDING(12)*2 = 72
	-- Plus gap between dialogue and hotbar
	HOTBAR_HEIGHT = 72,
	HOTBAR_GAP = 12,
}

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function loadDependencies()
	if not Network then
		local Shared = ReplicatedStorage:WaitForChild("Shared")
		Network = require(Shared.Network)
	end
end

--------------------------------------------------------------------------------
-- UI CREATION
--------------------------------------------------------------------------------

local function createCloseButton(parent: Frame): TextButton
	local button = Instance.new("TextButton")
	button.Name = "CloseButton"
	button.Size = UDim2.new(0, CONFIG.CLOSE_BUTTON_SIZE, 0, CONFIG.CLOSE_BUTTON_SIZE)
	button.Position = UDim2.new(1, -CONFIG.CLOSE_BUTTON_SIZE - 8, 0, 8)
	button.BackgroundColor3 = Colors.BackgroundDark
	button.BackgroundTransparency = 0.5
	button.BorderSizePixel = 0
	button.Text = "X"
	button.TextSize = Fonts.SizeMedium
	button.Font = Fonts.Primary
	button.TextColor3 = Colors.TextSecondary
	button.AutoButtonColor = true
	button.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Sizes.CornerRadiusSmall)
	corner.Parent = button

	return button
end

local function createNPCNameLabel(parent: Frame): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = "NPCName"
	label.Size = UDim2.new(1, -CONFIG.CLOSE_BUTTON_SIZE - 24, 0, 28)
	label.Position = UDim2.new(0, Spacing.ContainerPadding, 0, Spacing.ContainerPadding)
	label.BackgroundTransparency = 1
	label.Text = "NPC Name"
	label.TextSize = CONFIG.NPC_NAME_SIZE
	label.Font = Fonts.Primary
	label.TextColor3 = Colors.Primary
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = parent

	return label
end

local function createDialogueText(parent: Frame): TextLabel
	local label = Instance.new("TextLabel")
	label.Name = "DialogueText"
	label.Size = UDim2.new(1, -Spacing.ContainerPadding * 2, 0, 80)
	label.Position = UDim2.new(0, Spacing.ContainerPadding, 0, 44)
	label.BackgroundTransparency = 1
	label.Text = "Dialogue text goes here..."
	label.TextSize = CONFIG.DIALOGUE_TEXT_SIZE
	label.Font = Fonts.Secondary
	label.TextColor3 = Colors.TextPrimary
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Top
	label.TextWrapped = true
	label.AutomaticSize = Enum.AutomaticSize.Y
	label.Parent = parent

	return label
end

local function createResponseContainer(parent: Frame): Frame
	local container = Instance.new("Frame")
	container.Name = "ResponseContainer"
	container.Size = UDim2.new(1, -Spacing.ContainerPadding * 2, 0, 0)
	container.Position = UDim2.new(0, Spacing.ContainerPadding, 0, 140)
	container.BackgroundTransparency = 1
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.Parent = parent

	local layout = Instance.new("UIListLayout")
	layout.Name = "Layout"
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, CONFIG.RESPONSE_BUTTON_GAP)
	layout.Parent = container

	return container
end

local function createResponseButton(index: number, text: string): TextButton
	local button = Instance.new("TextButton")
	button.Name = "Response" .. index
	button.Size = UDim2.new(1, 0, 0, CONFIG.RESPONSE_BUTTON_HEIGHT)
	button.LayoutOrder = index
	button.BackgroundColor3 = Colors.BackgroundDark
	button.BackgroundTransparency = 0.3
	button.BorderSizePixel = 0
	button.Text = ""
	button.AutoButtonColor = false
	button.Parent = nil -- Will be parented by caller

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Sizes.CornerRadiusSmall)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Name = "Stroke"
	stroke.Color = Colors.Primary
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = button

	-- Response number indicator
	local numberLabel = Instance.new("TextLabel")
	numberLabel.Name = "Number"
	numberLabel.Size = UDim2.new(0, 32, 0, 32)
	numberLabel.Position = UDim2.new(0, 10, 0.5, -16)
	numberLabel.BackgroundColor3 = Colors.Primary
	numberLabel.BackgroundTransparency = 0.7
	numberLabel.Text = tostring(index)
	numberLabel.TextSize = Fonts.SizeMedium
	numberLabel.Font = Fonts.Primary
	numberLabel.TextColor3 = Colors.TextPrimary
	numberLabel.Parent = button

	local numberCorner = Instance.new("UICorner")
	numberCorner.CornerRadius = UDim.new(0, 4)
	numberCorner.Parent = numberLabel

	-- Response text
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = "Text"
	textLabel.Size = UDim2.new(1, -60, 1, -8)
	textLabel.Position = UDim2.new(0, 50, 0, 4)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextSize = CONFIG.RESPONSE_TEXT_SIZE
	textLabel.Font = Fonts.Secondary
	textLabel.TextColor3 = Colors.TextPrimary
	textLabel.TextXAlignment = Enum.TextXAlignment.Left
	textLabel.TextWrapped = true
	textLabel.TextTruncate = Enum.TextTruncate.AtEnd
	textLabel.Parent = button

	return button
end

local function createPanel(): Frame
	-- Calculate Y position: above hotbar
	local bottomOffset = Spacing.ScreenPadding + CONFIG.HOTBAR_HEIGHT + CONFIG.HOTBAR_GAP

	local panel = Instance.new("Frame")
	panel.Name = "DialoguePanel"
	panel.Size = UDim2.new(0, CONFIG.PANEL_WIDTH, 0, CONFIG.PANEL_MIN_HEIGHT)
	panel.AnchorPoint = Vector2.new(0.5, 1)
	panel.Position = UDim2.new(0.5, 0, 1, -bottomOffset - CONFIG.SLIDE_DISTANCE)
	panel.BackgroundColor3 = Colors.Background
	panel.BackgroundTransparency = Transparency.Background
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.AutomaticSize = Enum.AutomaticSize.Y

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, CONFIG.CORNER_RADIUS)
	corner.Parent = panel

	local stroke = Instance.new("UIStroke")
	stroke.Color = Colors.Primary
	stroke.Thickness = 2
	stroke.Transparency = 0.6
	stroke.Parent = panel

	-- Add padding at the bottom for content
	local padding = Instance.new("UIPadding")
	padding.PaddingBottom = UDim.new(0, Spacing.ContainerPadding)
	padding.Parent = panel

	return panel
end

--------------------------------------------------------------------------------
-- ANIMATIONS
--------------------------------------------------------------------------------

local function animateIn(panel: Frame)
	panel.Visible = true
	panel.BackgroundTransparency = 1

	-- Position above hotbar
	local bottomOffset = Spacing.ScreenPadding + CONFIG.HOTBAR_HEIGHT + CONFIG.HOTBAR_GAP
	local targetPos = UDim2.new(0.5, 0, 1, -bottomOffset)
	panel.Position = UDim2.new(0.5, 0, 1, -bottomOffset + CONFIG.SLIDE_DISTANCE)

	local tweenInfo = TweenInfo.new(CONFIG.FADE_TIME, Animation.EasingStyle, Animation.EasingDirection)

	local positionTween = TweenService:Create(panel, tweenInfo, {
		Position = targetPos,
	})

	local transparencyTween = TweenService:Create(panel, tweenInfo, {
		BackgroundTransparency = Transparency.Background,
	})

	positionTween:Play()
	transparencyTween:Play()
end

local function animateOut(panel: Frame, callback: (() -> ())?)
	-- Position above hotbar
	local bottomOffset = Spacing.ScreenPadding + CONFIG.HOTBAR_HEIGHT + CONFIG.HOTBAR_GAP
	local targetPos = UDim2.new(0.5, 0, 1, -bottomOffset + CONFIG.SLIDE_DISTANCE)
	local tweenInfo = TweenInfo.new(CONFIG.FADE_TIME, Animation.EasingStyle, Enum.EasingDirection.In)

	local positionTween = TweenService:Create(panel, tweenInfo, {
		Position = targetPos,
	})

	local transparencyTween = TweenService:Create(panel, tweenInfo, {
		BackgroundTransparency = 1,
	})

	positionTween:Play()
	transparencyTween:Play()

	positionTween.Completed:Connect(function()
		panel.Visible = false
		if callback then
			callback()
		end
	end)
end

local function animateButtonHover(button: TextButton, hovering: boolean)
	local stroke = button:FindFirstChild("Stroke") :: UIStroke?
	if stroke then
		local targetTransparency = if hovering then 0 else 0.5
		TweenService:Create(stroke, TweenInfo.new(Animation.TweenTimeFast), {
			Transparency = targetTransparency,
		}):Play()
	end

	local targetColor = if hovering then Colors.Hover else Colors.BackgroundDark
	TweenService:Create(button, TweenInfo.new(Animation.TweenTimeFast), {
		BackgroundColor3 = targetColor,
	}):Play()
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function DialoguePanel.create(parent: GuiObject): DialoguePanelWidget
	loadDependencies()

	-- Create main panel
	local panel = createPanel()
	panel.Parent = parent

	-- Create UI elements
	local closeButton = createCloseButton(panel)
	local npcNameLabel = createNPCNameLabel(panel)
	local dialogueText = createDialogueText(panel)
	local responseContainer = createResponseContainer(panel)

	-- State
	local responseButtons: { TextButton } = {}
	local buttonConnections: { RBXScriptConnection } = {}
	local currentData: DialogueData? = nil

	-- Widget object
	local widget: DialoguePanelWidget

	-- Clear existing response buttons
	local function clearResponses()
		for _, conn in buttonConnections do
			conn:Disconnect()
		end
		buttonConnections = {}

		for _, button in responseButtons do
			button:Destroy()
		end
		responseButtons = {}
	end

	-- Populate response buttons
	local function populateResponses(responses: { DialogueResponse })
		clearResponses()

		for i, response in responses do
			if i > CONFIG.MAX_RESPONSES then
				break
			end

			local button = createResponseButton(response.index, response.text)
			button.Parent = responseContainer
			table.insert(responseButtons, button)

			-- Hover effects
			local enterConn = button.MouseEnter:Connect(function()
				animateButtonHover(button, true)
			end)
			table.insert(buttonConnections, enterConn)

			local leaveConn = button.MouseLeave:Connect(function()
				animateButtonHover(button, false)
			end)
			table.insert(buttonConnections, leaveConn)

			-- Click handler
			local clickConn = button.MouseButton1Click:Connect(function()
				if widget.onResponse then
					widget.onResponse(response.index)
				end
			end)
			table.insert(buttonConnections, clickConn)
		end

		-- Update response container position based on dialogue text height
		task.defer(function()
			local textHeight = dialogueText.AbsoluteSize.Y
			responseContainer.Position = UDim2.new(0, Spacing.ContainerPadding, 0, 44 + textHeight + Spacing.ElementGap)
		end)
	end

	-- Close button handler
	closeButton.MouseButton1Click:Connect(function()
		if widget.onClose then
			widget.onClose()
		end
		widget:hide()
	end)

	-- Close button hover
	closeButton.MouseEnter:Connect(function()
		closeButton.TextColor3 = Colors.TextPrimary
		closeButton.BackgroundTransparency = 0.3
	end)

	closeButton.MouseLeave:Connect(function()
		closeButton.TextColor3 = Colors.TextSecondary
		closeButton.BackgroundTransparency = 0.5
	end)

	-- Create widget
	widget = {
		frame = panel,
		onResponse = nil,
		onClose = nil,

		show = function(self, data: DialogueData)
			currentData = data

			-- Update NPC name (use speaker if provided, otherwise npcName)
			local displayName = data.speaker or data.npcName
			npcNameLabel.Text = displayName

			-- Update dialogue text
			dialogueText.Text = data.text

			-- Populate responses
			populateResponses(data.responses)

			-- Show with animation
			animateIn(panel)
		end,

		hide = function(self)
			currentData = nil
			animateOut(panel, function()
				clearResponses()
			end)
		end,

		isVisible = function(self): boolean
			return panel.Visible
		end,

		destroy = function(self)
			clearResponses()
			panel:Destroy()
		end,
	}

	return widget
end

return DialoguePanel
