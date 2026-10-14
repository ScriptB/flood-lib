--!strict
local SoundService = game:GetService("SoundService")

local SoundFXManager = {}
SoundFXManager.__index = SoundFXManager

export type SoundConfig = {
	Volume: number?,
}

function SoundFXManager.new(config: SoundConfig?): any
	local self = setmetatable({}, SoundFXManager)
	self._volume  = (config and config.Volume) or 0.5
	self._enabled = true
	self._pool    = {} :: { Sound }
	return self
end

function SoundFXManager:Play(assetId: string)
	if not self._enabled then return end
	local sound       = Instance.new("Sound")
	sound.SoundId     = assetId
	sound.Volume      = self._volume
	sound.RollOffMaxDistance = 0
	sound.Parent      = SoundService
	table.insert(self._pool, sound)
	sound:Play()
	sound.Ended:Connect(function()
		for i, s in ipairs(self._pool) do
			if s == sound then
				table.remove(self._pool, i)
				break
			end
		end
		sound:Destroy()
	end)
end

function SoundFXManager:SetEnabled(enabled: boolean)
	self._enabled = enabled
end

function SoundFXManager:SetVolume(volume: number)
	self._volume = math.clamp(volume, 0, 1)
end

function SoundFXManager:Destroy()
	for _, s in ipairs(self._pool) do
		s:Stop()
		s:Destroy()
	end
	self._pool = {}
end

return SoundFXManager
