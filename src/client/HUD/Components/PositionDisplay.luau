--!strict
--[[
    PositionDisplay Component

    Shows player X, Y, Z coordinates under the stats bar.
    Updates in real-time as player moves.
]]

local PositionDisplay = {}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Shared constants
local HUDConstants = require(script.Parent.Parent.HUDConstants)

-- Types
export type PositionWidget = {
	frame: Frame,
	update: (self: PositionWidget) -> (),
	destroy: (self: PositionWidget) -> (),
}

-- Use shared constants
local Spacing = HUDConstants.Spacing
local Sizes = HUDConstants.Sizes
local Colors = HUDConstants.Colors
local Fonts = HUDConstants.Fonts

-- Configuration
local CONFIG = {
	UPDATE_INTERVAL = 0.1, -- Update position every 100ms
}

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function PositionDisplay.create(parent: GuiObject, yOffset: number): PositionWidget
	local player = Players.LocalPlayer
	local padding = Spacing.ContainerPadding
	local screenPadding = Spacing.ScreenPadding

	-- Main container (positioned under stats bar)
	local frame = Instance.new("Frame")
	frame.Name = "PositionDisplay"
	frame.Size = UDim2.new(0, 140, 0, 24)
	frame.AnchorPoint = Vector2.new(1, 0)
	frame.Position = UDim2.new(1, -screenPadding, 0, yOffset)
	frame.BackgroundColor3 = Colors.ContainerBackground
	frame.BackgroundTransparency = HUDConstants.Transparency.Background
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, Sizes.CornerRadiusSmall)
	corner.Parent = frame

	-- Coordinate label
	local coordLabel = Instance.new("TextLabel")
	coordLabel.Name = "Coordinates"
	coordLabel.Size = UDim2.new(1, -padding * 2, 1, 0)
	coordLabel.Position = UDim2.new(0, padding, 0, 0)
	coordLabel.BackgroundTransparency = 1
	coordLabel.Text = "X: 0  Y: 0  Z: 0"
	coordLabel.TextSize = Fonts.SizeSmall
	coordLabel.Font = Fonts.Secondary
	coordLabel.TextColor3 = Colors.TextSecondary
	coordLabel.TextXAlignment = Enum.TextXAlignment.Left
	coordLabel.Parent = frame

	-- Update connection
	local connections: { RBXScriptConnection } = {}
	local lastUpdate = 0

	local function updatePosition()
		local character = player.Character
		if not character then
			return
		end

		local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not rootPart then
			return
		end

		local pos = rootPart.Position
		coordLabel.Text = string.format(
			"X: %d  Y: %d  Z: %d",
			math.floor(pos.X),
			math.floor(pos.Y),
			math.floor(pos.Z)
		)
	end

	-- Throttled update loop
	local updateConn = RunService.Heartbeat:Connect(function(dt)
		lastUpdate = lastUpdate + dt
		if lastUpdate >= CONFIG.UPDATE_INTERVAL then
			lastUpdate = 0
			updatePosition()
		end
	end)
	table.insert(connections, updateConn)

	-- Create widget
	local widget: PositionWidget = {
		frame = frame,

		update = function(self)
			updatePosition()
		end,

		destroy = function(self)
			for _, conn in connections do
				conn:Disconnect()
			end
			self.frame:Destroy()
		end,
	}

	-- Initial update
	updatePosition()

	return widget
end

return PositionDisplay
