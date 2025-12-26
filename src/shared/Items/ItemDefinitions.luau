--!strict
--[[
    ItemDefinitions

    All item definitions for the game.
    Shared between client and server.
]]

local ItemTypes = require(script.Parent.ItemTypes)

local Items: { [string]: ItemTypes.ItemDefinition } = {}

--------------------------------------------------------------------------------
-- FOOD ITEMS
--------------------------------------------------------------------------------

Items.apple = {
	id = "apple",
	name = "Wild Apple",
	description = "A crisp apple from the wetlands. Restores hunger.",
	category = "food",
	rarity = "common",
	stackable = true,
	maxStack = 20,
	baseValue = 5,
	usable = true,
	consumable = true,
	effects = {
		hungerRestore = 15,
		thirstRestore = 5,
	},
}

Items.berries = {
	id = "berries",
	name = "Marsh Berries",
	description = "Sweet berries that grow near water. Light snack.",
	category = "food",
	rarity = "common",
	stackable = true,
	maxStack = 30,
	baseValue = 3,
	usable = true,
	consumable = true,
	effects = {
		hungerRestore = 8,
		thirstRestore = 3,
	},
}

Items.fish = {
	id = "fish",
	name = "Basin Minnow",
	description = "A small fish from the ponds. Very nutritious when cooked.",
	category = "food",
	rarity = "common",
	stackable = true,
	maxStack = 10,
	baseValue = 8,
	usable = true,
	consumable = true,
	effects = {
		hungerRestore = 25,
	},
}

Items.cooked_fish = {
	id = "cooked_fish",
	name = "Cooked Minnow",
	description = "Perfectly grilled fish. Delicious and filling.",
	category = "food",
	rarity = "uncommon",
	stackable = true,
	maxStack = 10,
	baseValue = 15,
	usable = true,
	consumable = true,
	effects = {
		hungerRestore = 40,
		thirstRestore = -5,
	},
}

Items.water_bottle = {
	id = "water_bottle",
	name = "Fresh Water",
	description = "Clean water from the marsh. Quenches thirst.",
	category = "food",
	rarity = "common",
	stackable = true,
	maxStack = 5,
	baseValue = 2,
	usable = true,
	consumable = true,
	effects = {
		thirstRestore = 30,
	},
}

Items.herbal_tea = {
	id = "herbal_tea",
	name = "Herbal Tea",
	description = "Brewed from marsh herbs. Restores health over time.",
	category = "food",
	rarity = "uncommon",
	stackable = true,
	maxStack = 5,
	baseValue = 20,
	usable = true,
	consumable = true,
	effects = {
		thirstRestore = 20,
		healthRestore = 15,
		buffType = "regen",
		buffDuration = 30,
	},
}

--------------------------------------------------------------------------------
-- SEEDS (For planting)
--------------------------------------------------------------------------------

Items.grass_seeds = {
	id = "grass_seeds",
	name = "Marsh Grass Seeds",
	description = "Plant these to grow marsh grass. Helps the ecosystem.",
	category = "seed",
	rarity = "common",
	stackable = true,
	maxStack = 50,
	baseValue = 2,
	usable = true,
	consumable = true,
	effects = {
		ecoAction = "plant",
		targetSpecies = "wetland_grass",
	},
}

Items.lily_seeds = {
	id = "lily_seeds",
	name = "Water Lily Bulbs",
	description = "Plant in water to grow beautiful lilies.",
	category = "seed",
	rarity = "uncommon",
	stackable = true,
	maxStack = 20,
	baseValue = 10,
	usable = true,
	consumable = true,
	effects = {
		ecoAction = "plant",
		targetSpecies = "water_lily",
	},
}

Items.prairie_seeds = {
	id = "prairie_seeds",
	name = "Prairie Grass Seeds",
	description = "Hardy seeds that grow in dry conditions.",
	category = "seed",
	rarity = "common",
	stackable = true,
	maxStack = 50,
	baseValue = 2,
	usable = true,
	consumable = true,
	effects = {
		ecoAction = "plant",
		targetSpecies = "plains_grass",
	},
}

--------------------------------------------------------------------------------
-- TOOLS
--------------------------------------------------------------------------------

Items.watering_can = {
	id = "watering_can",
	name = "Watering Can",
	description = "Used to water plants and hydrate areas.",
	category = "tool",
	rarity = "common",
	stackable = false,
	maxStack = 1,
	baseValue = 25,
	usable = true,
	consumable = false,
	cooldown = 3,
	effects = {
		ecoAction = "water",
	},
}

Items.fishing_rod = {
	id = "fishing_rod",
	name = "Fishing Rod",
	description = "Catch fish from ponds and streams.",
	category = "tool",
	rarity = "uncommon",
	stackable = false,
	maxStack = 1,
	baseValue = 50,
	usable = true,
	consumable = false,
	cooldown = 5,
}

Items.binoculars = {
	id = "binoculars",
	name = "Binoculars",
	description = "Observe wildlife from a distance without disturbing them.",
	category = "tool",
	rarity = "uncommon",
	stackable = false,
	maxStack = 1,
	baseValue = 75,
	usable = true,
	consumable = false,
	cooldown = 1,
}

Items.net = {
	id = "net",
	name = "Butterfly Net",
	description = "Catch insects and small creatures for study.",
	category = "tool",
	rarity = "common",
	stackable = false,
	maxStack = 1,
	baseValue = 30,
	usable = true,
	consumable = false,
	cooldown = 2,
}

Items.shovel = {
	id = "shovel",
	name = "Shovel",
	description = "Dig and plant. Essential for restoration work.",
	category = "tool",
	rarity = "common",
	stackable = false,
	maxStack = 1,
	baseValue = 35,
	usable = true,
	consumable = false,
	cooldown = 2,
	effects = {
		ecoAction = "plant",
	},
}

--------------------------------------------------------------------------------
-- RESOURCES
--------------------------------------------------------------------------------

Items.wood = {
	id = "wood",
	name = "Driftwood",
	description = "Wood found near the water. Useful for crafting.",
	category = "resource",
	rarity = "common",
	stackable = true,
	maxStack = 50,
	baseValue = 3,
	usable = false,
	consumable = false,
}

Items.stone = {
	id = "stone",
	name = "River Stone",
	description = "Smooth stone from the riverbed.",
	category = "resource",
	rarity = "common",
	stackable = true,
	maxStack = 50,
	baseValue = 2,
	usable = false,
	consumable = false,
}

Items.fiber = {
	id = "fiber",
	name = "Plant Fiber",
	description = "Woven fibers from marsh plants.",
	category = "resource",
	rarity = "common",
	stackable = true,
	maxStack = 100,
	baseValue = 1,
	usable = false,
	consumable = false,
}

Items.feather = {
	id = "feather",
	name = "Heron Feather",
	description = "A beautiful feather dropped by a heron.",
	category = "resource",
	rarity = "uncommon",
	stackable = true,
	maxStack = 20,
	baseValue = 15,
	usable = false,
	consumable = false,
}

Items.shell = {
	id = "shell",
	name = "Turtle Shell Fragment",
	description = "A piece of shed turtle shell. Surprisingly durable.",
	category = "resource",
	rarity = "rare",
	stackable = true,
	maxStack = 10,
	baseValue = 30,
	usable = false,
	consumable = false,
}

--------------------------------------------------------------------------------
-- SPECIAL / ECOLOGY ITEMS
--------------------------------------------------------------------------------

Items.animal_feed = {
	id = "animal_feed",
	name = "Animal Feed",
	description = "Nutritious feed that attracts and helps wildlife.",
	category = "special",
	rarity = "uncommon",
	stackable = true,
	maxStack = 20,
	baseValue = 15,
	usable = true,
	consumable = true,
	effects = {
		ecoAction = "feed",
	},
}

Items.cleaning_supplies = {
	id = "cleaning_supplies",
	name = "Eco Cleaning Kit",
	description = "Remove pollution and debris from the environment.",
	category = "special",
	rarity = "uncommon",
	stackable = true,
	maxStack = 10,
	baseValue = 20,
	usable = true,
	consumable = true,
	effects = {
		ecoAction = "clean",
	},
}

Items.ecosystem_scanner = {
	id = "ecosystem_scanner",
	name = "Ecosystem Scanner",
	description = "Analyze the health of the local ecosystem.",
	category = "special",
	rarity = "rare",
	stackable = false,
	maxStack = 1,
	baseValue = 150,
	usable = true,
	consumable = false,
	cooldown = 10,
}

--------------------------------------------------------------------------------
-- QUEST ITEMS
--------------------------------------------------------------------------------

Items.research_sample = {
	id = "research_sample",
	name = "Research Sample",
	description = "A sample collected for scientific study.",
	category = "quest",
	rarity = "common",
	stackable = true,
	maxStack = 10,
	baseValue = 0, -- Can't sell quest items
	usable = false,
	consumable = false,
}

Items.rare_flower = {
	id = "rare_flower",
	name = "Basin Orchid",
	description = "A rare flower found only in Verdant Basin.",
	category = "quest",
	rarity = "legendary",
	stackable = true,
	maxStack = 5,
	baseValue = 0,
	usable = false,
	consumable = false,
}

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS
--------------------------------------------------------------------------------

local ItemDefinitions = {}

function ItemDefinitions.get(itemId: string): ItemTypes.ItemDefinition?
	return Items[itemId]
end

function ItemDefinitions.getAll(): { [string]: ItemTypes.ItemDefinition }
	return Items
end

function ItemDefinitions.getByCategory(category: ItemTypes.ItemCategory): { ItemTypes.ItemDefinition }
	local result = {}
	for _, item in Items do
		if item.category == category then
			table.insert(result, item)
		end
	end
	return result
end

function ItemDefinitions.getByRarity(rarity: ItemTypes.ItemRarity): { ItemTypes.ItemDefinition }
	local result = {}
	for _, item in Items do
		if item.rarity == rarity then
			table.insert(result, item)
		end
	end
	return result
end

function ItemDefinitions.exists(itemId: string): boolean
	return Items[itemId] ~= nil
end

return ItemDefinitions
