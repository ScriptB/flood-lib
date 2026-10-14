--!strict
local TweenService = game:GetService("TweenService")

local AnimationsManager = {}
AnimationsManager.__index = AnimationsManager

export type Config = {
	Enabled: boolean?,
}

function AnimationsManager.new(_config: Config?): any
	local self = setmetatable({}, AnimationsManager)
	self._tweens = {} :: { Tween }
	return self
end

function AnimationsManager:Tween(instance: Instance, info: TweenInfo, props: { [string]: any }): Tween
	local tw = TweenService:Create(instance, info, props)
	table.insert(self._tweens, tw)
	tw.Completed:Connect(function()
		for i, t in ipairs(self._tweens) do
			if t == tw then
				table.remove(self._tweens, i)
				break
			end
		end
	end)
	tw:Play()
	return tw
end

function AnimationsManager:CancelAll()
	for _, tw in ipairs(self._tweens) do
		tw:Cancel()
	end
	self._tweens = {}
end

function AnimationsManager:Destroy()
	self:CancelAll()
end

return AnimationsManager
