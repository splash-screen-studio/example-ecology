--!strict
--[[
    ItemTypes

    Shared type definitions for the inventory system.
]]

local ItemTypes = {}

-- Item categories
export type ItemCategory = "food" | "tool" | "resource" | "seed" | "quest" | "special"

-- Rarity affects drop rates and value
export type ItemRarity = "common" | "uncommon" | "rare" | "legendary"

-- Base item definition (static data)
export type ItemDefinition = {
	id: string,
	name: string,
	description: string,
	category: ItemCategory,
	rarity: ItemRarity,

	-- Stacking
	stackable: boolean,
	maxStack: number,

	-- Value
	baseValue: number, -- In-game currency value

	-- Usage
	usable: boolean,
	consumable: boolean, -- Destroyed on use?
	cooldown: number?, -- Seconds between uses

	-- Effects (for usable items)
	effects: {
		hungerRestore: number?,
		thirstRestore: number?,
		healthRestore: number?,
		ecoAction: string?, -- Triggers ecology action
		targetSpecies: string?, -- For ecology items
		buffType: string?,
		buffDuration: number?,
	}?,

	-- Visual
	icon: string?, -- Asset ID for UI
	model: string?, -- Asset ID for world model
}

-- Inventory slot (runtime state)
export type InventorySlot = {
	itemId: string,
	quantity: number,
	metadata: {
		durability: number?, -- For tools
		quality: number?, -- Affects effectiveness
		customData: { [string]: any }?,
	}?,
}

-- Inventory state
export type Inventory = {
	slots: { [string]: InventorySlot }, -- itemId -> slot
	maxSlots: number,
	currency: number,
}

return ItemTypes
