--!strict
--[[
    InteractionPrompt Component

    Displays interaction prompts when player is near interactable objects.
    Shows "Press E to..." or tap-to-interact on mobile.
]]

local InteractionPrompt = {}

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Dependencies
local Network

-- Types
export type PromptWidget = {
	screenGui: ScreenGui,
	frame: Frame,
	currentTarget: Instance?,
	enabled: boolean,
	onInteract: ((targetId: string) -> ())?,
	destroy: (self: PromptWidget) -> (),
}

-- Configuration
local CONFIG = {
	UPDATE_INTERVAL = 0.1, -- seconds
	PROMPT_OFFSET = Vector3.new(0, 3, 0), -- Above object
	MAX_RANGE = 15, -- studs
	TAG_INTERACTABLE = "Interactable",
}

-- State
local player = Players.LocalPlayer
local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function loadDependencies()
	if not Network then
		local Shared = ReplicatedStorage:WaitForChild("Shared")
		Network = require(Shared.Network)
	end
end

local function getPlayerPosition(): Vector3?
	local character = player.Character
	if not character then
		return nil
	end
	local rootPart = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not rootPart then
		return nil
	end
	return rootPart.Position
end

local function getObjectPosition(obj: Instance): Vector3?
	if obj:IsA("BasePart") then
		return obj.Position
	elseif obj:IsA("Model") then
		local primary = obj.PrimaryPart
		if primary then
			return primary.Position
		end
		local part = obj:FindFirstChildWhichIsA("BasePart")
		if part then
			return part.Position
		end
	end
	return nil
end

local function findNearestInteractable(): (Instance?, number?)
	local playerPos = getPlayerPosition()
	if not playerPos then
		return nil, nil
	end

	local nearest: Instance? = nil
	local nearestDist = math.huge

	for _, obj in CollectionService:GetTagged(CONFIG.TAG_INTERACTABLE) do
		local objPos = getObjectPosition(obj)
		if objPos then
			-- Check range attribute
			local maxRange = obj:GetAttribute("InteractableRange") or CONFIG.MAX_RANGE
			local dist = (playerPos - objPos).Magnitude

			if dist <= maxRange and dist < nearestDist then
				-- Check if visible (simple line of sight check could go here)
				nearest = obj
				nearestDist = dist
			end
		end
	end

	return nearest, nearestDist
end

--------------------------------------------------------------------------------
-- UI CREATION
--------------------------------------------------------------------------------

local function createPromptUI(): (ScreenGui, Frame, TextLabel, TextButton)
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "InteractionPrompt"
	screenGui.ResetOnSpawn = false
	screenGui.IgnoreGuiInset = true

	local frame = Instance.new("Frame")
	frame.Name = "PromptFrame"
	frame.Size = UDim2.new(0, 200, 0, 60)
	frame.Position = UDim2.new(0.5, -100, 0.5, 0)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.3
	frame.BorderSizePixel = 0
	frame.Visible = false
	frame.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local promptLabel = Instance.new("TextLabel")
	promptLabel.Name = "PromptLabel"
	promptLabel.Size = UDim2.new(1, -20, 0, 25)
	promptLabel.Position = UDim2.new(0, 10, 0, 8)
	promptLabel.BackgroundTransparency = 1
	promptLabel.Text = "Object Name"
	promptLabel.TextSize = 16
	promptLabel.Font = Enum.Font.GothamBold
	promptLabel.TextColor3 = Color3.new(1, 1, 1)
	promptLabel.TextXAlignment = Enum.TextXAlignment.Center
	promptLabel.Parent = frame

	local keyHint = Instance.new("TextLabel")
	keyHint.Name = "KeyHint"
	keyHint.Size = UDim2.new(1, -20, 0, 20)
	keyHint.Position = UDim2.new(0, 10, 0, 35)
	keyHint.BackgroundTransparency = 1
	keyHint.Text = if isMobile then "Tap to interact" else "[E] Interact"
	keyHint.TextSize = 14
	keyHint.Font = Enum.Font.Gotham
	keyHint.TextColor3 = Color3.fromRGB(200, 200, 200)
	keyHint.TextXAlignment = Enum.TextXAlignment.Center
	keyHint.Parent = frame

	-- Invisible button for mobile tap
	local tapButton = Instance.new("TextButton")
	tapButton.Name = "TapButton"
	tapButton.Size = UDim2.new(1, 0, 1, 0)
	tapButton.BackgroundTransparency = 1
	tapButton.Text = ""
	tapButton.Parent = frame

	return screenGui, frame, promptLabel, tapButton
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function InteractionPrompt.create(parent: Instance): PromptWidget
	loadDependencies()

	local screenGui, frame, promptLabel, tapButton = createPromptUI()
	screenGui.Parent = parent

	local widget: PromptWidget
	local connections: { RBXScriptConnection } = {}
	local currentTarget: Instance? = nil

	-- Update loop
	local lastUpdate = 0
	local updateConn = RunService.Heartbeat:Connect(function(dt)
		lastUpdate = lastUpdate + dt
		if lastUpdate < CONFIG.UPDATE_INTERVAL then
			return
		end
		lastUpdate = 0

		if not widget.enabled then
			frame.Visible = false
			return
		end

		local nearest, distance = findNearestInteractable()

		if nearest and nearest ~= currentTarget then
			currentTarget = nearest
			widget.currentTarget = nearest

			-- Update prompt text
			local displayName = nearest:GetAttribute("InteractableName") or nearest.Name
			local promptText = nearest:GetAttribute("InteractablePrompt") or ("Interact with " .. displayName)

			promptLabel.Text = displayName
			local keyHint = frame:FindFirstChild("KeyHint") :: TextLabel?
			if keyHint then
				local actionText = if isMobile then "Tap" else "[E]"
				keyHint.Text = string.format("%s %s", actionText, promptText)
			end

			-- Position near object (screen space)
			local objPos = getObjectPosition(nearest)
			if objPos then
				local camera = workspace.CurrentCamera
				if camera then
					local screenPos, onScreen = camera:WorldToScreenPoint(objPos + CONFIG.PROMPT_OFFSET)
					if onScreen then
						frame.Position = UDim2.new(0, screenPos.X - frame.Size.X.Offset / 2, 0, screenPos.Y - frame.Size.Y.Offset)
					end
				end
			end

			-- Fade in
			frame.Visible = true
			TweenService:Create(frame, TweenInfo.new(0.15), { BackgroundTransparency = 0.3 }):Play()

		elseif not nearest and currentTarget then
			-- Fade out
			currentTarget = nil
			widget.currentTarget = nil
			TweenService:Create(frame, TweenInfo.new(0.15), { BackgroundTransparency = 1 }):Play()
			task.delay(0.15, function()
				if not widget.currentTarget then
					frame.Visible = false
				end
			end)
		elseif nearest then
			-- Update position for current target
			local objPos = getObjectPosition(nearest)
			if objPos then
				local camera = workspace.CurrentCamera
				if camera then
					local screenPos, onScreen = camera:WorldToScreenPoint(objPos + CONFIG.PROMPT_OFFSET)
					if onScreen then
						frame.Position = UDim2.new(0, screenPos.X - frame.Size.X.Offset / 2, 0, screenPos.Y - frame.Size.Y.Offset)
					else
						frame.Visible = false
					end
				end
			end
		end
	end)
	table.insert(connections, updateConn)

	-- Keyboard interaction (E key)
	local inputConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		if input.KeyCode == Enum.KeyCode.E and widget.currentTarget then
			local targetId = widget.currentTarget:GetAttribute("InteractableId")
			if targetId and widget.onInteract then
				widget.onInteract(targetId)
			end
		end
	end)
	table.insert(connections, inputConn)

	-- Mobile tap
	tapButton.MouseButton1Click:Connect(function()
		if widget.currentTarget then
			local targetId = widget.currentTarget:GetAttribute("InteractableId")
			if targetId and widget.onInteract then
				widget.onInteract(targetId)
			end
		end
	end)

	-- Create widget
	widget = {
		screenGui = screenGui,
		frame = frame,
		currentTarget = nil,
		enabled = true,

		onInteract = function(targetId: string)
			-- Default: call server
			local result = Network.Functions.Interact:InvokeServer({
				targetId = targetId,
				interactionType = "use",
			})

			if result and result.data and result.data.message then
				-- Could show feedback toast here
				print("[Interaction]", result.data.message)
			end
		end,

		destroy = function(self)
			for _, conn in connections do
				conn:Disconnect()
			end
			screenGui:Destroy()
		end,
	}

	return widget
end

return InteractionPrompt
