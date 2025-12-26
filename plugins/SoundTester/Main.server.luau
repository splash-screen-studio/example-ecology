--[[
    Sound Tester Plugin v1.0.0

    Lists all sounds used in the game from AudioConfig.
    Play any sound to test it. Shows human names and asset IDs.

    Usage: Click "Sound Tester" in the Plugins tab toolbar.
]]

local VERSION = "1.0.0"

local toolbar = plugin:CreateToolbar("Audio Tools")
local button = toolbar:CreateButton(
	"Sound Tester",
	"Test and preview game sounds",
	"rbxassetid://6031302931" -- Speaker icon
)

-- Create widget
local widgetInfo = DockWidgetPluginGuiInfo.new(
	Enum.InitialDockState.Float,
	false, -- Initially disabled
	false, -- Override previous state
	400, -- Default width
	500, -- Default height
	300, -- Min width
	200 -- Min height
)

local widget = plugin:CreateDockWidgetPluginGui("SoundTesterWidget", widgetInfo)
widget.Title = "Sound Tester v" .. VERSION

-- UI Colors
local COLORS = {
	Background = Color3.fromRGB(40, 40, 40),
	Header = Color3.fromRGB(60, 60, 60),
	Row = Color3.fromRGB(50, 50, 50),
	RowAlt = Color3.fromRGB(45, 45, 45),
	RowHover = Color3.fromRGB(70, 70, 70),
	Text = Color3.fromRGB(255, 255, 255),
	TextMuted = Color3.fromRGB(180, 180, 180),
	PlayButton = Color3.fromRGB(80, 160, 80),
	StopButton = Color3.fromRGB(160, 80, 80),
	Placeholder = Color3.fromRGB(180, 100, 100),
}

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(1, 0, 1, 0)
mainFrame.BackgroundColor3 = COLORS.Background
mainFrame.BorderSizePixel = 0
mainFrame.Parent = widget

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = COLORS.Header
header.BorderSizePixel = 0
header.Parent = mainFrame

local headerLabel = Instance.new("TextLabel")
headerLabel.Size = UDim2.new(1, -20, 1, 0)
headerLabel.Position = UDim2.new(0, 10, 0, 0)
headerLabel.BackgroundTransparency = 1
headerLabel.Text = "Game Sounds - Click to Play"
headerLabel.TextColor3 = COLORS.Text
headerLabel.TextSize = 16
headerLabel.Font = Enum.Font.GothamBold
headerLabel.TextXAlignment = Enum.TextXAlignment.Left
headerLabel.Parent = header

-- Refresh button
local refreshBtn = Instance.new("TextButton")
refreshBtn.Size = UDim2.new(0, 70, 0, 26)
refreshBtn.Position = UDim2.new(1, -80, 0.5, -13)
refreshBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
refreshBtn.BorderSizePixel = 0
refreshBtn.Text = "Refresh"
refreshBtn.TextColor3 = COLORS.Text
refreshBtn.TextSize = 12
refreshBtn.Font = Enum.Font.Gotham
refreshBtn.Parent = header

local refreshCorner = Instance.new("UICorner")
refreshCorner.CornerRadius = UDim.new(0, 4)
refreshCorner.Parent = refreshBtn

-- Scroll frame for sound list
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -10, 1, -50)
scrollFrame.Position = UDim2.new(0, 5, 0, 45)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 8
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = mainFrame

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 2)
listLayout.Parent = scrollFrame

-- Track current playing sound
local currentSound: Sound? = nil

-- Sound data structure
local soundData = {}

local function stopCurrentSound()
	if currentSound then
		currentSound:Stop()
		currentSound:Destroy()
		currentSound = nil
	end
end

local function playSound(assetId: string)
	stopCurrentSound()

	if assetId == "rbxassetid://0" then
		warn("[SoundTester] Cannot play placeholder sound (rbxassetid://0)")
		return
	end

	currentSound = Instance.new("Sound")
	currentSound.SoundId = assetId
	currentSound.Volume = 0.8
	currentSound.Parent = game:GetService("SoundService")
	currentSound:Play()

	currentSound.Ended:Connect(function()
		if currentSound then
			currentSound:Destroy()
			currentSound = nil
		end
	end)
end

local function createSoundRow(name: string, category: string, assetId: string, index: number)
	local isPlaceholder = assetId == "rbxassetid://0"

	local row = Instance.new("Frame")
	row.Name = name
	row.Size = UDim2.new(1, -10, 0, 50)
	row.BackgroundColor3 = if index % 2 == 0 then COLORS.Row else COLORS.RowAlt
	row.BorderSizePixel = 0
	row.LayoutOrder = index

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 4)
	corner.Parent = row

	-- Category label (small, top)
	local categoryLabel = Instance.new("TextLabel")
	categoryLabel.Size = UDim2.new(0, 100, 0, 14)
	categoryLabel.Position = UDim2.new(0, 8, 0, 4)
	categoryLabel.BackgroundTransparency = 1
	categoryLabel.Text = category
	categoryLabel.TextColor3 = COLORS.TextMuted
	categoryLabel.TextSize = 10
	categoryLabel.Font = Enum.Font.Gotham
	categoryLabel.TextXAlignment = Enum.TextXAlignment.Left
	categoryLabel.Parent = row

	-- Name label
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0.5, -60, 0, 18)
	nameLabel.Position = UDim2.new(0, 8, 0, 16)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name
	nameLabel.TextColor3 = if isPlaceholder then COLORS.Placeholder else COLORS.Text
	nameLabel.TextSize = 13
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = row

	-- Asset ID label
	local assetLabel = Instance.new("TextLabel")
	assetLabel.Size = UDim2.new(1, -70, 0, 14)
	assetLabel.Position = UDim2.new(0, 8, 0, 34)
	assetLabel.BackgroundTransparency = 1
	assetLabel.Text = assetId
	assetLabel.TextColor3 = if isPlaceholder then COLORS.Placeholder else COLORS.TextMuted
	assetLabel.TextSize = 10
	assetLabel.Font = Enum.Font.Code
	assetLabel.TextXAlignment = Enum.TextXAlignment.Left
	assetLabel.Parent = row

	-- Play button
	local playBtn = Instance.new("TextButton")
	playBtn.Size = UDim2.new(0, 50, 0, 30)
	playBtn.Position = UDim2.new(1, -58, 0.5, -15)
	playBtn.BackgroundColor3 = if isPlaceholder then COLORS.RowHover else COLORS.PlayButton
	playBtn.BorderSizePixel = 0
	playBtn.Text = "Play"
	playBtn.TextColor3 = COLORS.Text
	playBtn.TextSize = 12
	playBtn.Font = Enum.Font.GothamBold
	playBtn.Parent = row

	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 4)
	btnCorner.Parent = playBtn

	playBtn.MouseButton1Click:Connect(function()
		playSound(assetId)
	end)

	-- Hover effect
	row.MouseEnter:Connect(function()
		row.BackgroundColor3 = COLORS.RowHover
	end)

	row.MouseLeave:Connect(function()
		row.BackgroundColor3 = if index % 2 == 0 then COLORS.Row else COLORS.RowAlt
	end)

	return row
end

local function extractSoundsFromAudioConfig()
	local sounds = {}

	-- Try to find AudioConfig in ReplicatedStorage
	local shared = game:GetService("ReplicatedStorage"):FindFirstChild("Shared")
	if not shared then
		return sounds
	end

	local audio = shared:FindFirstChild("Audio")
	if not audio then
		return sounds
	end

	local audioConfigModule = audio:FindFirstChild("AudioConfig")
	if not audioConfigModule then
		return sounds
	end

	local success, AudioConfig = pcall(function()
		return require(audioConfigModule)
	end)

	if not success or not AudioConfig then
		warn("[SoundTester] Failed to load AudioConfig")
		return sounds
	end

	-- Extract footstep sounds
	if AudioConfig.FootstepMaterials then
		for _, material in AudioConfig.FootstepMaterials do
			local matName = tostring(material.material):gsub("Enum.Material.", "")
			for i, soundId in material.sounds do
				table.insert(sounds, {
					name = matName .. " Footstep " .. i,
					category = "Footsteps",
					assetId = soundId,
				})
			end
		end
	end

	-- Extract sound effects
	if AudioConfig.SoundEffects then
		for id, sfx in AudioConfig.SoundEffects do
			table.insert(sounds, {
				name = id,
				category = "SFX: " .. (sfx.category or "general"),
				assetId = sfx.soundId,
			})
		end
	end

	-- Extract ambient sounds
	if AudioConfig.AmbientZones then
		for zoneName, zone in AudioConfig.AmbientZones do
			if zone.sounds then
				for _, sound in zone.sounds do
					table.insert(sounds, {
						name = sound.id or "unknown",
						category = "Ambient: " .. zoneName,
						assetId = sound.soundId,
					})
				end
			end
		end
	end

	-- Extract music tracks
	if AudioConfig.MusicTracks then
		for id, track in AudioConfig.MusicTracks do
			table.insert(sounds, {
				name = track.name or id,
				category = "Music",
				assetId = track.soundId,
			})
		end
	end

	-- Extract NPC sounds
	if AudioConfig.NPCSounds then
		for npcId, npcSounds in AudioConfig.NPCSounds do
			for soundType, soundIds in npcSounds do
				for i, soundId in soundIds do
					table.insert(sounds, {
						name = npcId .. " " .. soundType .. " " .. i,
						category = "NPC",
						assetId = soundId,
					})
				end
			end
		end
	end

	return sounds
end

local function refreshSoundList()
	-- Clear existing rows
	for _, child in scrollFrame:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Extract sounds from AudioConfig
	soundData = extractSoundsFromAudioConfig()

	-- Sort: placeholders at bottom
	table.sort(soundData, function(a, b)
		local aPlaceholder = a.assetId == "rbxassetid://0"
		local bPlaceholder = b.assetId == "rbxassetid://0"
		if aPlaceholder ~= bPlaceholder then
			return not aPlaceholder -- Non-placeholders first
		end
		return a.category < b.category or (a.category == b.category and a.name < b.name)
	end)

	-- Create rows
	local placeholderCount = 0
	local validCount = 0

	for i, sound in soundData do
		local row = createSoundRow(sound.name, sound.category, sound.assetId, i)
		row.Parent = scrollFrame

		if sound.assetId == "rbxassetid://0" then
			placeholderCount = placeholderCount + 1
		else
			validCount = validCount + 1
		end
	end

	-- Update canvas size
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #soundData * 52)

	-- Update header
	headerLabel.Text = string.format(
		"Sounds: %d valid, %d placeholders",
		validCount,
		placeholderCount
	)
end

-- Button events
button.Click:Connect(function()
	widget.Enabled = not widget.Enabled
	if widget.Enabled then
		refreshSoundList()
	else
		stopCurrentSound()
	end
end)

refreshBtn.MouseButton1Click:Connect(function()
	refreshSoundList()
end)

-- Stop sound when widget closes
widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	if not widget.Enabled then
		stopCurrentSound()
	end
end)

print("[SoundTester v" .. VERSION .. "] Plugin loaded! Click 'Sound Tester' in toolbar.")
