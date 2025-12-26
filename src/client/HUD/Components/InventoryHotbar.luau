--!strict
--[[
    InventoryHotbar Component

    Quick-access bar for frequently used items.
    Mobile-first design with large touch targets.
]]

local InventoryHotbar = {}

local VERSION = "1.2.0" -- Fixed emoji compatibility (older Unicode)

-- Services
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Dependencies
local HUDConstants = require(script.Parent.Parent.HUDConstants)

-- Dependencies (lazy loaded)
local ItemDefinitions

-- Types
export type InventoryItem = {
	itemId: string,
	quantity: number,
}

export type HotbarWidget = {
	frame: Frame,
	slots: { Frame },
	selectedSlot: number,
	items: { InventoryItem? },
	update: (self: HotbarWidget, slotIndex: number, item: InventoryItem?) -> (),
	setItems: (self: HotbarWidget, items: { InventoryItem? }) -> (),
	selectSlot: (self: HotbarWidget, slotIndex: number) -> (),
	getSelectedItem: (self: HotbarWidget) -> InventoryItem?,
	showMessage: (self: HotbarWidget, message: string, duration: number?) -> (),
	hideMessage: (self: HotbarWidget) -> (),
	onSlotClicked: ((slotIndex: number) -> ())?,
	onUseItem: ((item: InventoryItem) -> ())?,
	onDiscardItem: ((item: InventoryItem) -> ())?,
	destroy: (self: HotbarWidget) -> (),
}

-- Configuration (using shared HUDConstants for consistency)
local CONFIG = {
	SLOT_COUNT = 5,
	SLOT_SIZE = HUDConstants.Sizes.TouchTarget, -- 48px touch target
	SLOT_SPACING = HUDConstants.Spacing.ElementGap,
	CORNER_RADIUS = HUDConstants.Sizes.CornerRadius,
	ICON_PADDING = HUDConstants.Spacing.SmallGap + 2,
	QUANTITY_SIZE = 16,
	SCREEN_PADDING = HUDConstants.Spacing.ScreenPadding,
	CONTAINER_PADDING = HUDConstants.Spacing.ContainerPadding,
}

local SLOT_COLORS = {
	default = HUDConstants.Colors.BackgroundDark,
	selected = HUDConstants.Colors.Primary,
	empty = HUDConstants.Colors.BackgroundDarker,
	hover = HUDConstants.Colors.Hover,
}

-- Item icons (using older Unicode emojis for compatibility)
-- Avoid Emoji 13.0+ (2020+) as they show as white rectangles on some platforms
local ITEM_ICONS: { [string]: string } = {
	-- Food
	apple = "🍎",
	berries = "🍇", -- Grapes (older than blueberries 🫐)
	fish = "🐟",
	cooked_fish = "🍣",
	water_bottle = "💧",
	herbal_tea = "🍵",

	-- Seeds
	grass_seeds = "🌱",
	lily_seeds = "🌸",
	prairie_seeds = "🌾",

	-- Tools
	watering_can = "🌿", -- Herb (older than potted plant 🪴)
	fishing_rod = "🎣",
	binoculars = "🔭",
	net = "🕸", -- Spider web (older than nest 🪹)
	shovel = "⛏️",
	ecosystem_scanner = "📡",

	-- Resources
	wood = "🌲", -- Tree (older than wood log 🪵)
	stone = "⛰️", -- Mountain emoji
	fiber = "🌀", -- Cyclone/spiral (bright, visible)
	feather = "🕊", -- Dove (older than feather 🪶)
	shell = "🐚",
	rare_flower = "🌺",

	-- Misc
	animal_feed = "🌽",
	cleaning_supplies = "✨", -- Sparkles (older than broom 🧹)
	research_sample = "⚗", -- Alembic (older than test tube 🧪)

	-- Fallback
	default = "❓",
}

-- Short text fallback names (for when emojis don't render)
local ITEM_SHORT_NAMES: { [string]: string } = {
	apple = "APL",
	berries = "BRY",
	fish = "FSH",
	cooked_fish = "CFH",
	water_bottle = "WTR",
	herbal_tea = "TEA",
	grass_seeds = "GRS",
	lily_seeds = "LLY",
	prairie_seeds = "PRR",
	watering_can = "CAN",
	fishing_rod = "ROD",
	binoculars = "BIN",
	net = "NET",
	shovel = "SHV",
	ecosystem_scanner = "SCN",
	wood = "WOD",
	stone = "STN",
	fiber = "FBR",
	feather = "FTH",
	shell = "SHL",
	rare_flower = "FLR",
	animal_feed = "FED",
	cleaning_supplies = "CLN",
	research_sample = "SMP",
	default = "???",
}

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function getItemIcon(itemId: string): string
	return ITEM_ICONS[itemId] or ITEM_ICONS.default
end

local function getItemShortName(itemId: string): string
	return ITEM_SHORT_NAMES[itemId] or ITEM_SHORT_NAMES.default
end

local function loadDependencies()
	if not ItemDefinitions then
		local Items = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Items")
		ItemDefinitions = require(Items.ItemDefinitions)
	end
end

--------------------------------------------------------------------------------
-- UI CREATION
--------------------------------------------------------------------------------

local function createSlot(index: number, onClicked: (number) -> (), onRightClicked: (number) -> ()): Frame
	local slot = Instance.new("Frame")
	slot.Name = "Slot" .. index
	slot.Size = UDim2.new(0, CONFIG.SLOT_SIZE, 0, CONFIG.SLOT_SIZE)
	slot.Position = UDim2.new(0, (index - 1) * (CONFIG.SLOT_SIZE + CONFIG.SLOT_SPACING), 0, 0)
	slot.BackgroundColor3 = SLOT_COLORS.empty
	slot.BorderSizePixel = 0

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, CONFIG.CORNER_RADIUS)
	corner.Parent = slot

	-- Slot number
	local numLabel = Instance.new("TextLabel")
	numLabel.Name = "SlotNumber"
	numLabel.Size = UDim2.new(0, 14, 0, 14)
	numLabel.Position = UDim2.new(0, 2, 0, 2)
	numLabel.BackgroundTransparency = 1
	numLabel.Text = tostring(index)
	numLabel.TextSize = 10
	numLabel.Font = Enum.Font.GothamBold
	numLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	numLabel.Parent = slot

	-- Item icon (emoji)
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(1, -CONFIG.ICON_PADDING * 2, 0, 24)
	iconLabel.Position = UDim2.new(0, CONFIG.ICON_PADDING, 0, CONFIG.ICON_PADDING)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = ""
	iconLabel.TextSize = 24
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextColor3 = Color3.new(1, 1, 1)
	iconLabel.Parent = slot

	-- Item short name (text fallback below icon)
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "ItemName"
	nameLabel.Size = UDim2.new(1, -4, 0, 12)
	nameLabel.Position = UDim2.new(0, 2, 1, -14)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = ""
	nameLabel.TextSize = 9
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	nameLabel.TextXAlignment = Enum.TextXAlignment.Center
	nameLabel.Visible = false
	nameLabel.Parent = slot

	-- Quantity label
	local quantityLabel = Instance.new("TextLabel")
	quantityLabel.Name = "Quantity"
	quantityLabel.Size = UDim2.new(0, CONFIG.QUANTITY_SIZE, 0, CONFIG.QUANTITY_SIZE)
	quantityLabel.Position = UDim2.new(1, -CONFIG.QUANTITY_SIZE - 2, 0, 2)
	quantityLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	quantityLabel.BackgroundTransparency = 0.3
	quantityLabel.Text = ""
	quantityLabel.TextSize = 10
	quantityLabel.Font = Enum.Font.GothamBold
	quantityLabel.TextColor3 = Color3.new(1, 1, 1)
	quantityLabel.Visible = false
	quantityLabel.Parent = slot

	local qtyCorner = Instance.new("UICorner")
	qtyCorner.CornerRadius = UDim.new(0, 4)
	qtyCorner.Parent = quantityLabel

	-- Click detection
	local button = Instance.new("TextButton")
	button.Name = "ClickArea"
	button.Size = UDim2.new(1, 0, 1, 0)
	button.BackgroundTransparency = 1
	button.Text = ""
	button.Parent = slot

	button.MouseButton1Click:Connect(function()
		onClicked(index)
	end)

	-- Right-click to discard
	button.MouseButton2Click:Connect(function()
		onRightClicked(index)
	end)

	button.MouseEnter:Connect(function()
		if slot.BackgroundColor3 ~= SLOT_COLORS.selected then
			slot.BackgroundColor3 = SLOT_COLORS.hover
		end
	end)

	button.MouseLeave:Connect(function()
		if slot.BackgroundColor3 ~= SLOT_COLORS.selected then
			slot.BackgroundColor3 = SLOT_COLORS.default
		end
	end)

	return slot
end

--------------------------------------------------------------------------------
-- PUBLIC API
--------------------------------------------------------------------------------

function InventoryHotbar.create(parent: GuiObject): HotbarWidget
	loadDependencies()

	-- Main container
	local containerPad = CONFIG.CONTAINER_PADDING
	local totalWidth = CONFIG.SLOT_COUNT * CONFIG.SLOT_SIZE + (CONFIG.SLOT_COUNT - 1) * CONFIG.SLOT_SPACING
	local frame = Instance.new("Frame")
	frame.Name = "InventoryHotbar"
	frame.Size = UDim2.new(0, totalWidth + containerPad * 2, 0, CONFIG.SLOT_SIZE + containerPad * 2)
	frame.Position = UDim2.new(0.5, -totalWidth / 2 - containerPad, 1, -CONFIG.SLOT_SIZE - CONFIG.SCREEN_PADDING - containerPad)
	frame.BackgroundColor3 = HUDConstants.Colors.Background
	frame.BackgroundTransparency = HUDConstants.Transparency.Background
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, CONFIG.CORNER_RADIUS)
	corner.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, containerPad)
	padding.PaddingTop = UDim.new(0, containerPad)
	padding.Parent = frame

	-- Message label (above hotbar) - parented to screenGui, not frame, to avoid padding issues
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Name = "MessageLabel"
	messageLabel.Size = UDim2.new(0, totalWidth + containerPad * 2, 0, 28)
	-- Position centered above the hotbar frame
	local hotbarY = -CONFIG.SLOT_SIZE - CONFIG.SCREEN_PADDING - containerPad
	local messageY = hotbarY - 28 - 8 -- message height + gap
	messageLabel.Position = UDim2.new(0.5, 0, 1, messageY)
	messageLabel.AnchorPoint = Vector2.new(0.5, 0)
	messageLabel.BackgroundColor3 = Color3.fromRGB(180, 60, 60) -- Red/warning color
	messageLabel.BackgroundTransparency = 0.2
	messageLabel.BorderSizePixel = 0
	messageLabel.Text = "Inventory full"
	messageLabel.TextSize = HUDConstants.Fonts.SizeMedium
	messageLabel.Font = HUDConstants.Fonts.Primary
	messageLabel.TextColor3 = Color3.new(1, 1, 1)
	messageLabel.Visible = false
	messageLabel.Parent = parent -- Parent to screenGui, not frame

	local msgCorner = Instance.new("UICorner")
	msgCorner.CornerRadius = UDim.new(0, CONFIG.CORNER_RADIUS)
	msgCorner.Parent = messageLabel

	-- Create widget first (for closure)
	local widget: HotbarWidget
	local slots: { Frame } = {}
	local items: { InventoryItem? } = {}

	local function onSlotClicked(slotIndex: number)
		if widget.onSlotClicked then
			widget.onSlotClicked(slotIndex)
		end
		widget:selectSlot(slotIndex)

		-- Use item on click
		local item = widget.items[slotIndex]
		if item and widget.onUseItem then
			widget.onUseItem(item)
		end
	end

	local function onSlotRightClicked(slotIndex: number)
		-- Discard item on right-click
		local item = widget.items[slotIndex]
		if item and widget.onDiscardItem then
			widget.onDiscardItem(item)
		end
	end

	-- Create slots
	for i = 1, CONFIG.SLOT_COUNT do
		local slot = createSlot(i, onSlotClicked, onSlotRightClicked)
		slot.Parent = frame
		table.insert(slots, slot)
		items[i] = nil
	end

	-- Initialize widget
	widget = {
		frame = frame,
		slots = slots,
		selectedSlot = 1,
		items = items,

		update = function(self, slotIndex: number, item: InventoryItem?)
			if slotIndex < 1 or slotIndex > CONFIG.SLOT_COUNT then
				return
			end

			local slot = self.slots[slotIndex]
			local iconLabel = slot:FindFirstChild("Icon") :: TextLabel?
			local nameLabel = slot:FindFirstChild("ItemName") :: TextLabel?
			local quantityLabel = slot:FindFirstChild("Quantity") :: TextLabel?

			if not iconLabel or not quantityLabel then
				return
			end

			self.items[slotIndex] = item

			if item and item.quantity > 0 then
				iconLabel.Text = getItemIcon(item.itemId)
				slot.BackgroundColor3 = if slotIndex == self.selectedSlot then SLOT_COLORS.selected else SLOT_COLORS.default

				-- Show short name as fallback (always visible for clarity)
				if nameLabel then
					nameLabel.Text = getItemShortName(item.itemId)
					nameLabel.Visible = true
				end

				if item.quantity > 1 then
					quantityLabel.Text = tostring(item.quantity)
					quantityLabel.Visible = true
				else
					quantityLabel.Visible = false
				end
			else
				iconLabel.Text = ""
				if nameLabel then
					nameLabel.Text = ""
					nameLabel.Visible = false
				end
				quantityLabel.Visible = false
				slot.BackgroundColor3 = if slotIndex == self.selectedSlot then SLOT_COLORS.selected else SLOT_COLORS.empty
			end
		end,

		setItems = function(self, newItems: { InventoryItem? })
			for i = 1, CONFIG.SLOT_COUNT do
				self:update(i, newItems[i])
			end
		end,

		selectSlot = function(self, slotIndex: number)
			if slotIndex < 1 or slotIndex > CONFIG.SLOT_COUNT then
				return
			end

			-- Deselect previous
			local prevSlot = self.slots[self.selectedSlot]
			if prevSlot then
				if self.items[self.selectedSlot] then
					prevSlot.BackgroundColor3 = SLOT_COLORS.default
				else
					prevSlot.BackgroundColor3 = SLOT_COLORS.empty
				end
			end

			-- Select new
			self.selectedSlot = slotIndex
			local newSlot = self.slots[slotIndex]
			newSlot.BackgroundColor3 = SLOT_COLORS.selected
		end,

		getSelectedItem = function(self): InventoryItem?
			return self.items[self.selectedSlot]
		end,

		showMessage = function(self, message: string, duration: number?)
			messageLabel.Text = message
			messageLabel.Visible = true

			-- Auto-hide after duration (default 3 seconds)
			if duration ~= 0 then
				local hideDelay = duration or 3
				task.delay(hideDelay, function()
					if messageLabel.Visible and messageLabel.Text == message then
						messageLabel.Visible = false
					end
				end)
			end
		end,

		hideMessage = function(self)
			messageLabel.Visible = false
		end,

		destroy = function(self)
			self.frame:Destroy()
		end,
	}

	-- Select first slot by default
	widget:selectSlot(1)

	-- Keyboard shortcuts (1-5)
	local inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then
			return
		end

		local keyNum = tonumber(input.KeyCode.Name)
		if keyNum and keyNum >= 1 and keyNum <= CONFIG.SLOT_COUNT then
			widget:selectSlot(keyNum)
		end
	end)

	-- Store connection for cleanup
	local originalDestroy = widget.destroy
	widget.destroy = function(self)
		inputConnection:Disconnect()
		originalDestroy(self)
	end

	print("[InventoryHotbar] v" .. VERSION .. " - Right-click to discard items")

	return widget
end

return InventoryHotbar
