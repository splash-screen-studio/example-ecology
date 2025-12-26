--!strict
--[[
    StatsBar Component

    Displays player vital stats (hunger, thirst) as horizontal bars.
    Mobile-first design with large touch targets.
]]

local StatsBar = {}

-- Services
local TweenService = game:GetService("TweenService")

-- Types
export type StatBarConfig = {
	name: string,
	color: Color3,
	icon: string, -- emoji or icon ID
	maxValue: number,
}

export type StatsBarWidget = {
	frame: Frame,
	bars: { [string]: { bar: Frame, label: TextLabel, current: number } },
	update: (self: StatsBarWidget, statName: string, value: number, maxValue: number?) -> (),
	destroy: (self: StatsBarWidget) -> (),
}

-- Configuration
local CONFIG = {
	BAR_HEIGHT = 8,
	BAR_WIDTH = 150,
	BAR_SPACING = 6,
	CORNER_RADIUS = 4,
	ICON_SIZE = 20,
	PADDING = 8,
	TWEEN_TIME = 0.3,
}

local STAT_CONFIGS: { StatBarConfig } = {
	{
		name = "hunger",
		color = Color3.fromRGB(255, 170, 50), -- Orange
		icon = "rbxassetid://0", -- Placeholder
		maxValue = 100,
	},
	{
		name = "thirst",
		color = Color3.fromRGB(50, 150, 255), -- Blue
		icon = "rbxassetid://0",
		maxValue = 100,
	},
}

--------------------------------------------------------------------------------
-- UI CREATION
--------------------------------------------------------------------------------

local function createStatBar(config: StatBarConfig, index: number): (Frame, Frame, TextLabel)
	local container = Instance.new("Frame")
	container.Name = config.name .. "Container"
	container.Size = UDim2.new(0, CONFIG.BAR_WIDTH + CONFIG.ICON_SIZE + CONFIG.PADDING, 0, CONFIG.ICON_SIZE)
	container.Position = UDim2.new(0, 0, 0, (index - 1) * (CONFIG.ICON_SIZE + CONFIG.BAR_SPACING))
	container.BackgroundTransparency = 1

	-- Icon (text-based for now)
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(0, CONFIG.ICON_SIZE, 0, CONFIG.ICON_SIZE)
	iconLabel.Position = UDim2.new(0, 0, 0, 0)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = if config.name == "hunger" then "🍎" else "💧"
	iconLabel.TextSize = 14
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextColor3 = Color3.new(1, 1, 1)
	iconLabel.Parent = container

	-- Bar background
	local barBg = Instance.new("Frame")
	barBg.Name = "BarBackground"
	barBg.Size = UDim2.new(0, CONFIG.BAR_WIDTH, 0, CONFIG.BAR_HEIGHT)
	barBg.Position = UDim2.new(0, CONFIG.ICON_SIZE + CONFIG.PADDING, 0.5, -CONFIG.BAR_HEIGHT / 2)
	barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	barBg.BorderSizePixel = 0
	barBg.Parent = container

	local bgCorner = Instance.new("UICorner")
	bgCorner.CornerRadius = UDim.new(0, CONFIG.CORNER_RADIUS)
	bgCorner.Parent = barBg

	-- Bar fill
	local barFill = Instance.new("Frame")
	barFill.Name = "Fill"
	barFill.Size = UDim2.new(1, 0, 1, 0)
	barFill.BackgroundColor3 = config.color
	barFill.BorderSizePixel = 0
	barFill.Parent = barBg

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, CONFIG.CORNER_RADIUS)
	fillCorner.Parent = barFill

	-- Value label (percentage)
	local valueLabel = Instance.new("TextLabel")
	valueLabel.Name = "Value"
	valueLabel.Size = UDim2.new(1, 0, 1, 0)
	valueLabel.BackgroundTransparency = 1
	valueLabel.Text = "100%"
	valueLabel.TextSize = 10
	valueLabel.Font = Enum.Font.GothamBold
	valueLabel.TextColor3 = Color3.new(1, 1, 1)
	valueLabel.TextStrokeTransparency = 0.5
	valueLabel.Parent = barBg

	return container, barFill, valueLabel
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function StatsBar.create(parent: GuiObject): StatsBarWidget
	-- Main container (top-right to avoid Roblox default HUD in top-left)
	local frame = Instance.new("Frame")
	frame.Name = "StatsBar"
	frame.Size = UDim2.new(0, CONFIG.BAR_WIDTH + CONFIG.ICON_SIZE + CONFIG.PADDING * 2, 0, #STAT_CONFIGS * (CONFIG.ICON_SIZE + CONFIG.BAR_SPACING))
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Position = UDim2.new(1, -10, 0, 10)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.5
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, CONFIG.PADDING)
	padding.PaddingTop = UDim.new(0, CONFIG.PADDING)
	padding.Parent = frame

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
				TweenInfo.new(CONFIG.TWEEN_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ Size = UDim2.new(percentage, 0, 1, 0) }
			)
			tween:Play()

			-- Update label
			barData.label.Text = string.format("%d%%", math.floor(percentage * 100))
			barData.current = value

			-- Color shift when low
			if percentage < 0.25 then
				barData.bar.BackgroundColor3 = Color3.fromRGB(255, 80, 80) -- Red warning
			elseif percentage < 0.5 then
				barData.bar.BackgroundColor3 = Color3.fromRGB(255, 200, 50) -- Yellow warning
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
