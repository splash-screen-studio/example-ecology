--!strict
--[[
    SoundPool

    Object pooling for Sound instances to improve performance.
    Prevents creating/destroying sounds frequently.
]]

local SoundPool = {}
SoundPool.__index = SoundPool

export type SoundPool = typeof(setmetatable({} :: {
	_pool: { Sound },
	_active: { [Sound]: boolean },
	_maxSize: number,
	_parent: Instance,
}, SoundPool))

function SoundPool.new(parent: Instance, maxSize: number?): SoundPool
	local self = setmetatable({
		_pool = {},
		_active = {},
		_maxSize = maxSize or 20,
		_parent = parent,
	}, SoundPool)

	-- Pre-warm the pool
	for _ = 1, math.min(5, self._maxSize) do
		local sound = Instance.new("Sound")
		sound.Parent = parent
		table.insert(self._pool, sound)
	end

	return self
end

function SoundPool.get(self: SoundPool): Sound?
	-- Try to get from pool
	local sound = table.remove(self._pool)

	if not sound then
		-- Pool empty, create new if under limit
		local activeCount = 0
		for _ in self._active do
			activeCount = activeCount + 1
		end

		if activeCount >= self._maxSize then
			return nil -- At capacity
		end

		sound = Instance.new("Sound")
		sound.Parent = self._parent
	end

	-- Reset sound properties
	sound.SoundId = ""
	sound.Volume = 1
	sound.Pitch = 1
	sound.PlaybackSpeed = 1
	sound.Looped = false
	sound.Playing = false
	sound.TimePosition = 0

	self._active[sound] = true
	return sound
end

function SoundPool.release(self: SoundPool, sound: Sound)
	if not self._active[sound] then
		return -- Not from this pool or already released
	end

	sound:Stop()
	self._active[sound] = nil

	if #self._pool < self._maxSize then
		table.insert(self._pool, sound)
	else
		sound:Destroy()
	end
end

function SoundPool.releaseAll(self: SoundPool)
	for sound in self._active do
		self:release(sound)
	end
end

function SoundPool.getActiveCount(self: SoundPool): number
	local count = 0
	for _ in self._active do
		count = count + 1
	end
	return count
end

function SoundPool.destroy(self: SoundPool)
	self:releaseAll()

	for _, sound in self._pool do
		sound:Destroy()
	end

	self._pool = {}
	self._active = {}
end

return SoundPool
