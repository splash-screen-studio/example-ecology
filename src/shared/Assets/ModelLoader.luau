--!strict
--[[
    ModelLoader

    Utility for loading and cloning models from the asset library.
    Provides caching, LOD selection, and validation.

    Usage:
        local ModelLoader = require(path.to.ModelLoader)

        local rabbitModel = ModelLoader:getModel("Animals", "marsh_rabbit")
        local clone = ModelLoader:cloneModel("Animals", "marsh_rabbit")
]]

local ModelLoader = {}

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Configuration
local CONFIG = {
	ASSETS_PATH = "Assets", -- Folder name in ReplicatedStorage
	CACHE_ENABLED = true,
	LOD_LEVELS = { "LOD0", "LOD1", "LOD2" },
}

-- Cache
local modelCache: { [string]: Model } = {}
local assetsFolder: Folder? = nil
local assetsFolderChecked = false
local assetsFolderWarned = false

--------------------------------------------------------------------------------
-- INITIALIZATION
--------------------------------------------------------------------------------

local function getAssetsFolder(): Folder?
	if assetsFolderChecked then
		return assetsFolder
	end

	assetsFolderChecked = true
	assetsFolder = ReplicatedStorage:FindFirstChild(CONFIG.ASSETS_PATH) :: Folder?
	return assetsFolder
end

--------------------------------------------------------------------------------
-- PATH RESOLUTION
--------------------------------------------------------------------------------

local function resolvePath(category: string, modelId: string): Model?
	local assets = getAssetsFolder()
	if not assets then
		if not assetsFolderWarned then
			assetsFolderWarned = true
			warn("[ModelLoader] Assets folder not found:", CONFIG.ASSETS_PATH, "- using placeholder models")
		end
		return nil
	end

	-- Try direct path first: Assets/Category/modelId
	local categoryFolder = assets:FindFirstChild(category)
	if categoryFolder then
		local model = categoryFolder:FindFirstChild(modelId)
		if model and model:IsA("Model") then
			return model
		end

		-- Try subcategories: Assets/Category/Subcategory/modelId
		for _, subfolder in categoryFolder:GetChildren() do
			if subfolder:IsA("Folder") then
				local subModel = subfolder:FindFirstChild(modelId)
				if subModel and subModel:IsA("Model") then
					return subModel
				end
			end
		end
	end

	-- Try searching all categories
	for _, folder in assets:GetChildren() do
		if folder:IsA("Folder") then
			local model = folder:FindFirstChild(modelId)
			if model and model:IsA("Model") then
				return model
			end
		end
	end

	return nil
end

local function getCacheKey(category: string, modelId: string): string
	return category .. "/" .. modelId
end

--------------------------------------------------------------------------------
-- MODEL RETRIEVAL
--------------------------------------------------------------------------------

function ModelLoader:getModel(category: string, modelId: string): Model?
	local cacheKey = getCacheKey(category, modelId)

	-- Check cache first
	if CONFIG.CACHE_ENABLED and modelCache[cacheKey] then
		return modelCache[cacheKey]
	end

	-- Resolve and cache
	local model = resolvePath(category, modelId)
	if model and CONFIG.CACHE_ENABLED then
		modelCache[cacheKey] = model
	end

	return model
end

function ModelLoader:cloneModel(category: string, modelId: string): Model?
	local model = self:getModel(category, modelId)
	if not model then
		return nil
	end

	local clone = model:Clone()
	return clone
end

function ModelLoader:cloneModelWithLOD(category: string, modelId: string, lodLevel: number): Model?
	local model = self:getModel(category, modelId)
	if not model then
		return nil
	end

	-- Check if model has LOD variants
	local lodName = CONFIG.LOD_LEVELS[lodLevel + 1] -- 0-indexed to 1-indexed
	local lodModel = model:FindFirstChild(lodName)

	if lodModel and lodModel:IsA("Model") then
		return lodModel:Clone()
	end

	-- Fallback to full model
	return model:Clone()
end

--------------------------------------------------------------------------------
-- VALIDATION
--------------------------------------------------------------------------------

function ModelLoader:validateModel(model: Model): { valid: boolean, issues: { string } }
	local issues = {}

	-- Check for PrimaryPart
	if not model.PrimaryPart then
		table.insert(issues, "Missing PrimaryPart")
	end

	-- Check for at least one mesh
	local hasMesh = false
	for _, child in model:GetDescendants() do
		if child:IsA("MeshPart") or child:IsA("SpecialMesh") then
			hasMesh = true
			break
		end
	end
	if not hasMesh then
		table.insert(issues, "No mesh found")
	end

	-- Check naming convention
	if not string.match(model.Name, "^[a-z_]+$") then
		table.insert(issues, "Name should be lowercase with underscores")
	end

	return {
		valid = #issues == 0,
		issues = issues,
	}
end

function ModelLoader:validateAllModels(): { [string]: { valid: boolean, issues: { string } } }
	local results = {}
	local assets = getAssetsFolder()

	if not assets then
		return results
	end

	local function scanFolder(folder: Folder, path: string)
		for _, child in folder:GetChildren() do
			if child:IsA("Model") then
				local fullPath = path .. "/" .. child.Name
				results[fullPath] = self:validateModel(child)
			elseif child:IsA("Folder") then
				scanFolder(child, path .. "/" .. child.Name)
			end
		end
	end

	scanFolder(assets, CONFIG.ASSETS_PATH)
	return results
end

--------------------------------------------------------------------------------
-- PRELOADING
--------------------------------------------------------------------------------

function ModelLoader:preloadCategory(category: string)
	local assets = getAssetsFolder()
	if not assets then
		return
	end

	local categoryFolder = assets:FindFirstChild(category)
	if not categoryFolder then
		return
	end

	local function cacheFolder(folder: Folder, parentPath: string)
		for _, child in folder:GetChildren() do
			if child:IsA("Model") then
				local cacheKey = getCacheKey(parentPath, child.Name)
				modelCache[cacheKey] = child
			elseif child:IsA("Folder") then
				cacheFolder(child, parentPath)
			end
		end
	end

	cacheFolder(categoryFolder, category)
	print(string.format("[ModelLoader] Preloaded category: %s", category))
end

function ModelLoader:preloadAll()
	local assets = getAssetsFolder()
	if not assets then
		return
	end

	for _, child in assets:GetChildren() do
		if child:IsA("Folder") then
			self:preloadCategory(child.Name)
		end
	end
end

--------------------------------------------------------------------------------
-- CACHE MANAGEMENT
--------------------------------------------------------------------------------

function ModelLoader:clearCache()
	modelCache = {}
end

function ModelLoader:getCacheSize(): number
	local count = 0
	for _ in modelCache do
		count = count + 1
	end
	return count
end

--------------------------------------------------------------------------------
-- QUERIES
--------------------------------------------------------------------------------

function ModelLoader:listCategory(category: string): { string }
	local result = {}
	local assets = getAssetsFolder()

	if not assets then
		return result
	end

	local categoryFolder = assets:FindFirstChild(category)
	if not categoryFolder then
		return result
	end

	local function scanFolder(folder: Folder)
		for _, child in folder:GetChildren() do
			if child:IsA("Model") then
				table.insert(result, child.Name)
			elseif child:IsA("Folder") then
				scanFolder(child)
			end
		end
	end

	scanFolder(categoryFolder)
	return result
end

function ModelLoader:listAllCategories(): { string }
	local result = {}
	local assets = getAssetsFolder()

	if not assets then
		return result
	end

	for _, child in assets:GetChildren() do
		if child:IsA("Folder") then
			table.insert(result, child.Name)
		end
	end

	return result
end

function ModelLoader:modelExists(category: string, modelId: string): boolean
	return self:getModel(category, modelId) ~= nil
end

return ModelLoader
