--!strict
--[[
    StatsBar Component

    Displays player vital stats (hunger, thirst) as horizontal bars.
    Mobile-first design with large touch targets.
]]

local StatsBar = {}

-- Services
local TweenService = game:GetService("TweenService")

-- Shared constants
local HUDConstants = require(script.Parent.Parent.HUDConstants)

-- Types
export type StatBarConfig = {
	name: string,
	color: Color3,
	icon: string,
	maxValue: number,
}

export type StatsBarWidget = {
	frame: Frame,
	bars: { [string]: { bar: Frame, label: TextLabel, current: number } },
	update: (self: StatsBarWidget, statName: string, value: number, maxValue: number?) -> (),
	destroy: (self: StatsBarWidget) -> (),
}

-- Use shared constants
local Spacing = HUDConstants.Spacing
local Sizes = HUDConstants.Sizes
local Colors = HUDConstants.Colors
local Animation = HUDConstants.Animation
local Fonts = HUDConstants.Fonts

local STAT_CONFIGS: { StatBarConfig } = {
	{
		name = "hunger",
		color = Colors.Hunger,
		icon = "rbxassetid://0",
		maxValue = 100,
	},
	{
		name = "thirst",
		color = Colors.Thirst,
		icon = "rbxassetid://0",
		maxValue = 100,
	},
}

--------------------------------------------------------------------------------
-- UI CREATION
--------------------------------------------------------------------------------

local function createStatBar(config: StatBarConfig, index: number): (Frame, Frame, TextLabel)
	local iconSize = Sizes.IconMedium
	local barHeight = Sizes.StatBarHeight
	local barWidth = Sizes.StatBarWidth
	local gap = Spacing.ElementGap

	local container = Instance.new("Frame")
	container.Name = config.name .. "Container"
	container.Size = UDim2.new(0, barWidth + iconSize + gap, 0, iconSize)
	container.Position = UDim2.new(0, 0, 0, (index - 1) * (iconSize + gap))
	container.BackgroundTransparency = 1

	-- Icon (emoji-based)
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(0, iconSize, 0, iconSize)
	iconLabel.Position = UDim2.new(0, 0, 0, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = if config.name == "hunger" then "🍎" else "💧"
	iconLabel.TextSize = Fonts.SizeMedium
	iconLabel.Font = Fonts.Primary
	iconLabel.TextColor3 = Colors.TextPrimary
	iconLabel.Parent = container

	-- Bar background
	local barBg = Instance.new("Frame")
	barBg.Name = "BarBackground"
	barBg.Size = UDim2.new(0, barWidth, 0, barHeight)
	barBg.Position = UDim2.new(0, iconSize + gap, 0.5, -barHeight / 2)
	barBg.BackgroundColor3 = Colors.SlotDefault
	barBg.BorderSizePixel = 0
	barBg.Parent = container

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, Sizes.CornerRadiusSmall)
	bgCorner.Parent = barBg

	-- Bar fill
	local barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3 = config.color
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, Sizes.CornerRadiusSmall)
	fillCorner.Parent = barFill

	-- Value label (percentage)
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.Size = UDim2.new(1, 0, 1, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = "100%"
	valueLabel.TextSize = Fonts.SizeOverlay
	valueLabel.Font = Fonts.Primary
	valueLabel.TextColor3 = Colors.TextPrimary
	valueLabel.TextStrokeTransparency = 0.5
	valueLabel.Parent = barBg

	return container, barFill, valueLabel
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function StatsBar.create(parent: GuiObject): StatsBarWidget
	local iconSize = Sizes.IconMedium
	local barWidth = Sizes.StatBarWidth
	local gap = Spacing.ElementGap
	local padding = Spacing.ContainerPadding
	local screenPadding = Spacing.ScreenPadding

	-- Main container (top-right to avoid Roblox default HUD in top-left)
	local frame = Instance.new("Frame")
	frame.Name = "StatsBar"
	frame.Size = UDim2.new(0, barWidth + iconSize + gap + padding * 2, 0, #STAT_CONFIGS * (iconSize + gap) + padding)
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Position = UDim2.new(1, -screenPadding, 0, screenPadding)
	frame.BackgroundColor3 = Colors.ContainerBackground
	frame.BackgroundTransparency = HUDConstants.Transparency.Background
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Sizes.CornerRadius)
	corner.Parent = frame

	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingLeft = UDim.new(0, padding)
	uiPadding.PaddingTop = UDim.new(0, padding)
	uiPadding.PaddingRight = UDim.new(0, padding)
	uiPadding.PaddingBottom = UDim.new(0, padding)
	uiPadding.Parent = frame

	-- Create bars for each stat
	local bars: { [string]: { bar: Frame, label: TextLabel, current: number } } = {}

	for i, config in STAT_CONFIGS do
		local container, barFill, valueLabel = createStatBar(config, i)
		container.Parent = frame

		bars[config.name] = {
			bar = barFill,
			label = valueLabel,
			current = config.maxValue,
		}
	end

	-- Create widget object
	local widget: StatsBarWidget = {
		frame = frame,
		bars = bars,

		update = function(self, statName: string, value: number, maxValue: number?)
			local barData = self.bars[statName]
			if not barData then
				return
			end

			maxValue = maxValue or 100
			local percentage = math.clamp(value / maxValue, 0, 1)

			-- Animate bar fill
			local tween = TweenService:Create(
				barData.bar,
				TweenInfo.new(Animation.TweenTime, Animation.EasingStyle, Animation.EasingDirection),
				{ Size = UDim2.new(percentage, 0, 1, 0) }
			)
			tween:Play()

			-- Update label
			barData.label.Text = string.format("%d%%", math.floor(percentage * 100))
			barData.current = value

			-- Color shift when low
			if percentage < 0.25 then
				barData.bar.BackgroundColor3 = Colors.WarningCritical
			elseif percentage < 0.5 then
				barData.bar.BackgroundColor3 = Colors.WarningLow
			else
				-- Restore original color
				for _, config in STAT_CONFIGS do
					if config.name == statName then
						barData.bar.BackgroundColor3 = config.color
						break
					end
				end
			end
		end,

		destroy = function(self)
			self.frame:Destroy()
		end,
	}

	return widget
end

return StatsBar
