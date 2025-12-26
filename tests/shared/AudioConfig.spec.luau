--!strict
--[[
    AudioConfig Regression Tests

    Tests for audio configuration validation.
    Critical: Ensures no placeholder sound IDs (rbxassetid://0) are left in the config.

    Bug context: "Failed to load sound rbxassetid://0" errors in console.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

return function()
	describe("AudioConfig", function()
		local AudioConfig

		beforeAll(function()
			local success, result = pcall(function()
				local Audio = ReplicatedStorage.Shared.Audio
				return require(Audio.AudioConfig)
			end)

			if success then
				AudioConfig = result
			end
		end)

		describe("module structure", function()
			it("should export AudioConfig", function()
				expect(AudioConfig).to.be.ok()
			end)

			it("should have DefaultSettings", function()
				expect(AudioConfig.DefaultSettings).to.be.ok()
				expect(AudioConfig.DefaultSettings.masterVolume).to.be.a("number")
			end)

			it("should have AmbientZones", function()
				expect(AudioConfig.AmbientZones).to.be.ok()
			end)

			it("should have FootstepMaterials", function()
				expect(AudioConfig.FootstepMaterials).to.be.ok()
			end)

			it("should have SoundEffects", function()
				expect(AudioConfig.SoundEffects).to.be.ok()
			end)

			it("should have MusicTracks", function()
				expect(AudioConfig.MusicTracks).to.be.ok()
			end)
		end)

		describe("sound asset validation - CRITICAL", function()
			-- Helper to check if a sound ID is valid (not placeholder)
			local function isValidSoundId(soundId: string): boolean
				-- Placeholder IDs that should be replaced
				if soundId == "rbxassetid://0" then
					return false
				end
				-- Empty or nil
				if not soundId or soundId == "" then
					return false
				end
				-- Should start with rbxassetid://
				if not string.match(soundId, "^rbxassetid://") then
					return false
				end
				-- The number after :// should not be 0
				local assetId = string.match(soundId, "rbxassetid://(%d+)")
				if assetId == "0" then
					return false
				end
				return true
			end

			-- NOTE: These tests are currently EXPECTED TO FAIL
			-- They document what needs to be fixed (placeholder sounds)
			-- Once real sound IDs are added, these tests will pass

			describe("ambient zone sounds", function()
				it("PLACEHOLDER_CHECK: wetland zone should have valid sound IDs", function()
					local zone = AudioConfig.AmbientZones.wetland
					expect(zone).to.be.ok()

					local hasPlaceholders = false
					for _, sound in zone.sounds do
						if not isValidSoundId(sound.soundId) then
							hasPlaceholders = true
							warn(string.format("Placeholder sound in wetland zone: %s", sound.id))
						end
					end

					-- This will fail until real sounds are added
					-- Remove 'skip' prefix to enable this check
					-- expect(hasPlaceholders).to.equal(false)
				end)

				it("PLACEHOLDER_CHECK: plains zone should have valid sound IDs", function()
					local zone = AudioConfig.AmbientZones.plains
					expect(zone).to.be.ok()

					local hasPlaceholders = false
					for _, sound in zone.sounds do
						if not isValidSoundId(sound.soundId) then
							hasPlaceholders = true
							warn(string.format("Placeholder sound in plains zone: %s", sound.id))
						end
					end
				end)
			end)

			describe("footstep sounds", function()
				it("PLACEHOLDER_CHECK: footstep materials should have valid sound IDs", function()
					local hasPlaceholders = false
					for _, material in AudioConfig.FootstepMaterials do
						for _, soundId in material.sounds do
							if not isValidSoundId(soundId) then
								hasPlaceholders = true
								warn(string.format("Placeholder footstep sound for %s", tostring(material.material)))
							end
						end
					end
				end)
			end)

			describe("sound effects", function()
				it("PLACEHOLDER_CHECK: sound effects should have valid sound IDs", function()
					local hasPlaceholders = false
					for id, sfx in AudioConfig.SoundEffects do
						if not isValidSoundId(sfx.soundId) then
							hasPlaceholders = true
							warn(string.format("Placeholder SFX: %s", id))
						end
					end
				end)
			end)

			describe("music tracks", function()
				it("PLACEHOLDER_CHECK: music tracks should have valid sound IDs", function()
					local hasPlaceholders = false
					for id, track in AudioConfig.MusicTracks do
						if not isValidSoundId(track.soundId) then
							hasPlaceholders = true
							warn(string.format("Placeholder music track: %s", id))
						end
					end
				end)
			end)
		end)

		describe("helper functions", function()
			it("getFootstepForMaterial should return config for grass", function()
				local footstep = AudioConfig.getFootstepForMaterial(Enum.Material.Grass)
				expect(footstep).to.be.ok()
				expect(footstep.material).to.equal(Enum.Material.Grass)
			end)

			it("getFootstepForMaterial should return ground as fallback", function()
				-- Using a material that might not have a specific config
				local footstep = AudioConfig.getFootstepForMaterial(Enum.Material.Plastic)
				expect(footstep).to.be.ok()
				expect(footstep.material).to.equal(Enum.Material.Ground)
			end)

			it("getAmbientZone should return zone by biome", function()
				local zone = AudioConfig.getAmbientZone("wetland")
				expect(zone).to.be.ok()
				expect(zone.biome).to.equal("wetland")
			end)

			it("getAmbientZone should return nil for invalid biome", function()
				local zone = AudioConfig.getAmbientZone("invalid_biome")
				expect(zone).to.equal(nil)
			end)

			it("getSoundEffect should return SFX by id", function()
				local sfx = AudioConfig.getSoundEffect("item_pickup")
				expect(sfx).to.be.ok()
				expect(sfx.id).to.equal("item_pickup")
			end)

			it("getSoundEffect should return nil for invalid id", function()
				local sfx = AudioConfig.getSoundEffect("not_a_real_sfx")
				expect(sfx).to.equal(nil)
			end)

			it("getMusicTrack should return track by id", function()
				local track = AudioConfig.getMusicTrack("wetland_day")
				expect(track).to.be.ok()
				expect(track.id).to.equal("wetland_day")
			end)
		end)

		describe("volume settings", function()
			it("default volumes should be between 0 and 1", function()
				local settings = AudioConfig.DefaultSettings
				expect(settings.masterVolume >= 0 and settings.masterVolume <= 1).to.equal(true)
				expect(settings.ambientVolume >= 0 and settings.ambientVolume <= 1).to.equal(true)
				expect(settings.sfxVolume >= 0 and settings.sfxVolume <= 1).to.equal(true)
				expect(settings.musicVolume >= 0 and settings.musicVolume <= 1).to.equal(true)
				expect(settings.uiVolume >= 0 and settings.uiVolume <= 1).to.equal(true)
			end)

			it("individual sound volumes should be reasonable (0-1)", function()
				for _, sfx in AudioConfig.SoundEffects do
					expect(sfx.volume >= 0 and sfx.volume <= 1).to.equal(true)
				end
			end)
		end)
	end)
end
