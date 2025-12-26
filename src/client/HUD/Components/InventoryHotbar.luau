--!strict
--[[
    InventoryHotbar Component

    Quick-access bar for frequently used items.
    Mobile-first design with large touch targets.
]]

local InventoryHotbar = {}

-- Services
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

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
	onSlotClicked: ((slotIndex: number) -> ())?,
	onUseItem: ((item: InventoryItem) -> ())?,
	destroy: (self: HotbarWidget) -> (),
}

-- Configuration
local CONFIG = {
	SLOT_COUNT = 5,
	SLOT_SIZE = 50,
	SLOT_SPACING = 6,
	CORNER_RADIUS = 8,
	ICON_PADDING = 6,
	QUANTITY_SIZE = 16,
}

local SLOT_COLORS = {
	default = Color3.fromRGB(50, 50, 50),
	selected = Color3.fromRGB(80, 120, 180),
	empty = Color3.fromRGB(30, 30, 30),
	hover = Color3.fromRGB(70, 70, 70),
}

-- Simple item icons (text-based for now)
local ITEM_ICONS: { [string]: string } = {
	apple = "🍎",
	berries = "🫐",
	fish = "🐟",
	cooked_fish = "🍣",
	water_bottle = "💧",
	grass_seeds = "🌱",
	watering_can = "🪴",
	fishing_rod = "🎣",
	binoculars = "🔭",
	net = "🪺",
	shovel = "⛏️",
	wood = "🪵",
	stone = "🪨",
	feather = "🪶",
	default = "📦",
}

--------------------------------------------------------------------------------
-- HELPERS
--------------------------------------------------------------------------------

local function getItemIcon(itemId: string): string
	return ITEM_ICONS[itemId] or ITEM_ICONS.default
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

local function createSlot(index: number, onClicked: (number) -> ()): Frame
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

	-- Item icon
	local iconLabel = Instance.new("TextLabel")
	iconLabel.Name = "Icon"
	iconLabel.Size = UDim2.new(1, -CONFIG.ICON_PADDING * 2, 1, -CONFIG.ICON_PADDING * 2)
	iconLabel.Position = UDim2.new(0, CONFIG.ICON_PADDING, 0, CONFIG.ICON_PADDING)
	iconLabel.BackgroundTransparency = 1
	iconLabel.Text = ""
	iconLabel.TextSize = 24
	iconLabel.Font = Enum.Font.GothamBold
	iconLabel.TextColor3 = Color3.new(1, 1, 1)
	iconLabel.Parent = slot

	-- Quantity label
	local quantityLabel = Instance.new("TextLabel")
	quantityLabel.Name = "Quantity"
	quantityLabel.Size = UDim2.new(0, CONFIG.QUANTITY_SIZE, 0, CONFIG.QUANTITY_SIZE)
	quantityLabel.Position = UDim2.new(1, -CONFIG.QUANTITY_SIZE - 2, 1, -CONFIG.QUANTITY_SIZE - 2)
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
	local totalWidth = CONFIG.SLOT_COUNT * CONFIG.SLOT_SIZE + (CONFIG.SLOT_COUNT - 1) * CONFIG.SLOT_SPACING
	local frame = Instance.new("Frame")
	frame.Name = "InventoryHotbar"
	frame.Size = UDim2.new(0, totalWidth + 16, 0, CONFIG.SLOT_SIZE + 16)
	frame.Position = UDim2.new(0.5, -totalWidth / 2 - 8, 1, -CONFIG.SLOT_SIZE - 26)
	frame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	frame.BackgroundTransparency = 0.5
	frame.BorderSizePixel = 0
	frame.Parent = parent

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame

	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingTop = UDim.new(0, 8)
	padding.Parent = frame

	-- Create widget first (for closure)
	local widget: HotbarWidget
	local slots: { Frame } = {}
	local items: { InventoryItem? } = {}

	local function onSlotClicked(slotIndex: number)
		if widget.onSlotClicked then
			widget.onSlotClicked(slotIndex)
		end
		widget:selectSlot(slotIndex)

		-- Use item on double-tap / double-click
		local item = widget.items[slotIndex]
		if item and widget.onUseItem then
			widget.onUseItem(item)
		end
	end

	-- Create slots
	for i = 1, CONFIG.SLOT_COUNT do
		local slot = createSlot(i, onSlotClicked)
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
			local quantityLabel = slot:FindFirstChild("Quantity") :: TextLabel?

			if not iconLabel or not quantityLabel then
				return
			end

			self.items[slotIndex] = item

			if item and item.quantity > 0 then
				iconLabel.Text = getItemIcon(item.itemId)
				slot.BackgroundColor3 = if slotIndex == self.selectedSlot then SLOT_COLORS.selected else SLOT_COLORS.default

				if item.quantity > 1 then
					quantityLabel.Text = tostring(item.quantity)
					quantityLabel.Visible = true
				else
					quantityLabel.Visible = false
				end
			else
				iconLabel.Text = ""
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

	return widget
end

return InventoryHotbar
