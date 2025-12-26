--!strict
--[[
    NotificationToast Component

    Displays notification popups for discoveries, quest updates, and rewards.
    Automatically fades out after a delay.
]]

local NotificationToast = {}

-- Services
local TweenService = game:GetService("TweenService")

-- Types
export type NotificationType = "discovery" | "quest" | "reward" | "info"

export type ToastWidget = {
	frame: Frame,
	show: (self: ToastWidget, notifType: NotificationType, title: string, description: string?, rarity: string?) -> (),
	destroy: (self: ToastWidget) -> (),
}

-- Configuration
local CONFIG = {
	TOAST_WIDTH = 300,
	TOAST_HEIGHT = 80,
	CORNER_RADIUS = 8,
	DISPLAY_TIME = 4, -- seconds before fade
	FADE_TIME = 0.5,
	SLIDE_DISTANCE = 50,
	MAX_TOASTS = 3,
}

local RARITY_COLORS = {
	common = Color3.fromRGB(150, 150, 150),
	uncommon = Color3.fromRGB(50, 200, 100),
	rare = Color3.fromRGB(50, 150, 255),
	legendary = Color3.fromRGB(255, 200, 50),
}

local TYPE_ICONS = {
	discovery = "🔍",
	quest = "📜",
	reward = "🎁",
	info = "ℹ️",
}

local TYPE_COLORS = {
	discovery = Color3.fromRGB(100, 180, 255),
	quest = Color3.fromRGB(255, 200, 100),
	reward = Color3.fromRGB(100, 255, 150),
	info = Color3.fromRGB(200, 200, 200),
}

--------------------------------------------------------------------------------
-- UI CREATION
--------------------------------------------------------------------------------

local function createToastElement(parent: Frame, index: number): Frame
	local toast = Instance.new("Frame")
	toast.Name = "Toast" .. index
	toast.Size = UDim2.new(0, CONFIG.TOAST_WIDTH, 0, CONFIG.TOAST_HEIGHT)
	toast.Position = UDim2.new(1, CONFIG.SLIDE_DISTANCE, 0, (index - 1) * (CONFIG.TOAST_HEIGHT + 10))
	toast.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	toast.BackgroundTransparency = 0.1
	toast.BorderSizePixel = 0
	toast.Visible = false
	toast.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, CONFIG.CORNER_RADIUS)
	corner.Parent = toast

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 100, 100)
	stroke.Thickness = 1
	stroke.Transparency = 0.5
	stroke.Parent = toast

	-- Icon
	local icon = Instance.new("TextLabel")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 40, 0, 40)
	icon.Position = UDim2.new(0, 10, 0.5, -20)
	icon.BackgroundTransparency = 1
	icon.Text = "🔍"
	icon.TextSize = 24
	icon.Font = Enum.Font.GothamBold
	icon.TextColor3 = Color3.new(1, 1, 1)
	icon.Parent = toast

	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, -70, 0, 24)
	title.Position = UDim2.new(0, 55, 0, 12)
	title.BackgroundTransparency = 1
	title.Text = "Discovery!"
	title.TextSize = 16
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.new(1, 1, 1)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextTruncate = Enum.TextTruncate.AtEnd
	title.Parent = toast

	-- Description
	local description = Instance.new("TextLabel")
	description.Name = "Description"
	description.Size = UDim2.new(1, -70, 0, 36)
	description.Position = UDim2.new(0, 55, 0, 36)
	description.BackgroundTransparency = 1
	description.Text = "You found something new!"
	description.TextSize = 12
	description.Font = Enum.Font.Gotham
	description.TextColor3 = Color3.fromRGB(200, 200, 200)
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.TextWrapped = true
	description.TextTruncate = Enum.TextTruncate.AtEnd
	description.Parent = toast

	-- Rarity indicator bar
	local rarityBar = Instance.new("Frame")
	rarityBar.Name = "RarityBar"
	rarityBar.Size = UDim2.new(0, 4, 1, -16)
	rarityBar.Position = UDim2.new(0, 3, 0, 8)
	rarityBar.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	rarityBar.BorderSizePixel = 0
	rarityBar.Parent = toast

	local rarityCorner = Instance.new("UICorner")
	rarityCorner.CornerRadius = UDim.new(0, 2)
	rarityCorner.Parent = rarityBar

	return toast
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function NotificationToast.create(parent: GuiObject): ToastWidget
	-- Main container (positioned top-right)
	local frame = Instance.new("Frame")
	frame.Name = "NotificationToasts"
	frame.Size = UDim2.new(0, CONFIG.TOAST_WIDTH + 20, 0, CONFIG.MAX_TOASTS * (CONFIG.TOAST_HEIGHT + 10))
	frame.Position = UDim2.new(1, -CONFIG.TOAST_WIDTH - 30, 0, 80)
	frame.BackgroundTransparency = 1
	frame.Parent = parent

	-- Create toast elements
	local toasts: { Frame } = {}
	for i = 1, CONFIG.MAX_TOASTS do
		local toast = createToastElement(frame, i)
		table.insert(toasts, toast)
	end

	-- Queue for pending notifications
	local queue: { { notifType: NotificationType, title: string, description: string?, rarity: string? } } = {}
	local activeToasts: { number } = {}

	local function getAvailableToast(): (Frame?, number?)
		for i, toast in toasts do
			if not toast.Visible then
				return toast, i
			end
		end
		return nil, nil
	end

	local function showToast(toast: Frame, notifType: NotificationType, title: string, description: string?, rarity: string?)
		local icon = toast:FindFirstChild("Icon") :: TextLabel
		local titleLabel = toast:FindFirstChild("Title") :: TextLabel
		local descLabel = toast:FindFirstChild("Description") :: TextLabel
		local rarityBar = toast:FindFirstChild("RarityBar") :: Frame
		local stroke = toast:FindFirstChildWhichIsA("UIStroke")

		-- Set content
		icon.Text = TYPE_ICONS[notifType] or "ℹ️"
		titleLabel.Text = title
		descLabel.Text = description or ""

		-- Set colors
		local typeColor = TYPE_COLORS[notifType] or TYPE_COLORS.info
		titleLabel.TextColor3 = typeColor

		if stroke then
			stroke.Color = typeColor
		end

		local rarityColor = if rarity then RARITY_COLORS[rarity] else RARITY_COLORS.common
		rarityBar.BackgroundColor3 = rarityColor

		-- Show with slide-in animation
		toast.Visible = true
		toast.Position = UDim2.new(1, CONFIG.SLIDE_DISTANCE, toast.Position.Y.Scale, toast.Position.Y.Offset)
		toast.BackgroundTransparency = 0.1

		local slideIn = TweenService:Create(
			toast,
			TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ Position = UDim2.new(1, -CONFIG.TOAST_WIDTH - 10, toast.Position.Y.Scale, toast.Position.Y.Offset) }
		)
		slideIn:Play()

		-- Schedule fade out
		task.delay(CONFIG.DISPLAY_TIME, function()
			if not toast.Visible then
				return
			end

			local fadeOut = TweenService:Create(
				toast,
				TweenInfo.new(CONFIG.FADE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
				{
					Position = UDim2.new(1, CONFIG.SLIDE_DISTANCE, toast.Position.Y.Scale, toast.Position.Y.Offset),
					BackgroundTransparency = 1,
				}
			)
			fadeOut:Play()
			fadeOut.Completed:Connect(function()
				toast.Visible = false
			end)
		end)
	end

	local function processQueue()
		if #queue == 0 then
			return
		end

		local toast, index = getAvailableToast()
		if toast and index then
			local item = table.remove(queue, 1)
			showToast(toast, item.notifType, item.title, item.description, item.rarity)
		end
	end

	-- Create widget object
	local widget: ToastWidget = {
		frame = frame,

		show = function(self, notifType: NotificationType, title: string, description: string?, rarity: string?)
			-- Try to show immediately
			local toast, index = getAvailableToast()
			if toast then
				showToast(toast, notifType, title, description, rarity)
			else
				-- Queue for later
				table.insert(queue, {
					notifType = notifType,
					title = title,
					description = description,
					rarity = rarity,
				})

				-- Schedule queue processing
				task.delay(CONFIG.DISPLAY_TIME + CONFIG.FADE_TIME + 0.1, function()
					processQueue()
				end)
			end
		end,

		destroy = function(self)
			self.frame:Destroy()
		end,
	}

	return widget
end

return NotificationToast
