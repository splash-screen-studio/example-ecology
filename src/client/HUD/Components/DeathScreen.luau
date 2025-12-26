--!strict
--[[
    DeathScreen Component

    Displays death overlay with message and respawn countdown.
    Auto-respawns player after delay.
]]

local DeathScreen = {}

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Types
export type DeathScreenWidget = {
	frame: Frame,
	show: (self: DeathScreenWidget, message: string?) -> (),
	hide: (self: DeathScreenWidget) -> (),
	destroy: (self: DeathScreenWidget) -> (),
}

-- Configuration
local CONFIG = {
	RESPAWN_DELAY = 5, -- seconds
	FADE_TIME = 0.5,
}

--------------------------------------------------------------------------------
-- UI CREATION
--------------------------------------------------------------------------------

local function createDeathScreen(parent: GuiObject): Frame
	-- Full-screen overlay
	local frame = Instance.new("Frame")
	frame.Name = "DeathScreen"
	frame.Size = UDim2.new(1, 0, 1, 0)
	frame.Position = UDim2.new(0, 0, 0, 0)
	frame.BackgroundColor3 = Color3.fromRGB(20, 0, 0)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.ZIndex = 100
	frame.Parent = parent

	-- Vignette effect
	local vignette = Instance.new("ImageLabel")
	vignette.Name = "Vignette"
	vignette.Size = UDim2.new(1, 0, 1, 0)
	vignette.BackgroundTransparency = 1
	vignette.Image = "rbxassetid://0" -- Placeholder, could use actual vignette
	vignette.ImageColor3 = Color3.new(0, 0, 0)
	vignette.ImageTransparency = 0.3
	vignette.ZIndex = 101
	vignette.Parent = frame

	-- Center container
	local centerContainer = Instance.new("Frame")
	centerContainer.Name = "CenterContainer"
	centerContainer.Size = UDim2.new(0, 400, 0, 200)
	centerContainer.Position = UDim2.new(0.5, -200, 0.5, -100)
	centerContainer.BackgroundTransparency = 1
	centerContainer.ZIndex = 102
	centerContainer.Parent = frame

	-- "You Died" text
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0, 60)
	titleLabel.Position = UDim2.new(0, 0, 0, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "You Died"
	titleLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
	titleLabel.TextSize = 48
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.TextStrokeTransparency = 0.5
	titleLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
	titleLabel.ZIndex = 103
	titleLabel.Parent = centerContainer

	-- Death message
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "Message"
	messageLabel.Size = UDim2.new(1, 0, 0, 30)
	messageLabel.Position = UDim2.new(0, 0, 0, 70)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Text = ""
	messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	messageLabel.TextSize = 20
	messageLabel.Font = Enum.Font.Gotham
	messageLabel.TextStrokeTransparency = 0.7
	messageLabel.ZIndex = 103
	messageLabel.Parent = centerContainer

	-- Respawn countdown
	local countdownLabel = Instance.new("TextLabel")
	countdownLabel.Name = "Countdown"
	countdownLabel.Size = UDim2.new(1, 0, 0, 30)
	countdownLabel.Position = UDim2.new(0, 0, 0, 130)
	countdownLabel.BackgroundTransparency = 1
	countdownLabel.Text = "Respawning in 5..."
	countdownLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	countdownLabel.TextSize = 18
	countdownLabel.Font = Enum.Font.Gotham
	countdownLabel.TextStrokeTransparency = 0.7
	countdownLabel.ZIndex = 103
	countdownLabel.Parent = centerContainer

	return frame
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function DeathScreen.create(parent: GuiObject): DeathScreenWidget
	local frame = createDeathScreen(parent)
	local countdownThread: thread? = nil

	local widget: DeathScreenWidget = {
		frame = frame,

		show = function(self, message: string?)
			-- Cancel any existing countdown
			if countdownThread then
				task.cancel(countdownThread)
				countdownThread = nil
			end

			-- Set message
			local messageLabel = frame.CenterContainer.Message :: TextLabel
			messageLabel.Text = message or ""

			-- Show with fade
			frame.Visible = true
			frame.BackgroundTransparency = 1

			local fadeIn = TweenService:Create(
				frame,
				TweenInfo.new(CONFIG.FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{ BackgroundTransparency = 0.3 }
			)
			fadeIn:Play()

			-- Start countdown
			local countdownLabel = frame.CenterContainer.Countdown :: TextLabel

			countdownThread = task.spawn(function()
				for i = CONFIG.RESPAWN_DELAY, 1, -1 do
					countdownLabel.Text = string.format("Respawning in %d...", i)
					task.wait(1)
				end

				countdownLabel.Text = "Respawning..."

				-- Hide after respawn triggers
				task.wait(0.5)
				self:hide()
			end)
		end,

		hide = function(self)
			if countdownThread then
				task.cancel(countdownThread)
				countdownThread = nil
			end

			local fadeOut = TweenService:Create(
				frame,
				TweenInfo.new(CONFIG.FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{ BackgroundTransparency = 1 }
			)
			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				frame.Visible = false
			end)
		end,

		destroy = function(self)
			if countdownThread then
				task.cancel(countdownThread)
			end
			frame:Destroy()
		end,
	}

	return widget
end

return DeathScreen
