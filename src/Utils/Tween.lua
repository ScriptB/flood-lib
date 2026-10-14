--!strict
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Spring       = require(script.Parent.Spring)

local Tween = {}

Tween.Fast   = TweenInfo.new(0.15, Enum.EasingStyle.Quad,        Enum.EasingDirection.Out)
Tween.Normal = TweenInfo.new(0.25, Enum.EasingStyle.Quad,        Enum.EasingDirection.Out)
Tween.Smooth = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
Tween.Bounce = TweenInfo.new(0.3,  Enum.EasingStyle.Back,        Enum.EasingDirection.Out)
Tween.Pop    = TweenInfo.new(0.12, Enum.EasingStyle.Back,        Enum.EasingDirection.Out)
Tween.Settle = TweenInfo.new(0.28, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
Tween.Slug   = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

export type SpringPreset = { Speed: number, Damper: number }
export type SpringHandle = { Cancel: () -> () }

Tween.SpringPop    = { Speed = 32, Damper = 0.82 } :: SpringPreset
Tween.SpringSettle = { Speed = 20, Damper = 0.78 } :: SpringPreset
Tween.SpringSlug   = { Speed = 14, Damper = 0.72 } :: SpringPreset

type Channel = {
	tick:     (dt: number) -> (),
	settled:  () -> boolean,
	finalize: () -> (),
}

function Tween.Play(instance: Instance, tweenInfo: TweenInfo, properties: { [string]: any }): Tween
	local tween = TweenService:Create(instance, tweenInfo, properties)
	tween:Play()
	return tween
end

function Tween.SpringAnimate(instance: Instance, props: { [string]: any }, preset: SpringPreset?): SpringHandle
	local speed  = if preset then preset.Speed  else 20
	local damper = if preset then preset.Damper else 0.78
	local inst   = instance :: any

	local channels: { Channel } = {}

	for key, target in props do
		local current = inst[key]
		local vtype   = typeof(current)

		if vtype == "number" then
			local s = Spring.new(current :: number, speed, damper)
			s:SetTarget(target :: number)
			table.insert(channels, {
				tick     = function(dt) s:Step(dt); inst[key] = s.Position end,
				settled  = function() return s:IsSettled() end,
				finalize = function() inst[key] = target end,
			})
		elseif vtype == "Color3" then
			local c  = current :: Color3
			local tg = target  :: Color3
			local sr = Spring.new(c.R, speed, damper)
			local sg = Spring.new(c.G, speed, damper)
			local sb = Spring.new(c.B, speed, damper)
			sr:SetTarget(tg.R); sg:SetTarget(tg.G); sb:SetTarget(tg.B)
			table.insert(channels, {
				tick = function(dt)
					sr:Step(dt); sg:Step(dt); sb:Step(dt)
					inst[key] = Color3.new(
						math.clamp(sr.Position, 0, 1),
						math.clamp(sg.Position, 0, 1),
						math.clamp(sb.Position, 0, 1)
					)
				end,
				settled  = function() return sr:IsSettled() and sg:IsSettled() and sb:IsSettled() end,
				finalize = function() inst[key] = target end,
			})
		elseif vtype == "UDim2" then
			local c  = current :: UDim2
			local tg = target  :: UDim2
			local sxs = Spring.new(c.X.Scale,  speed, damper)
			local sxo = Spring.new(c.X.Offset, speed, damper)
			local sys = Spring.new(c.Y.Scale,  speed, damper)
			local syo = Spring.new(c.Y.Offset, speed, damper)
			sxs:SetTarget(tg.X.Scale);  sxo:SetTarget(tg.X.Offset)
			sys:SetTarget(tg.Y.Scale);  syo:SetTarget(tg.Y.Offset)
			table.insert(channels, {
				tick = function(dt)
					sxs:Step(dt); sxo:Step(dt); sys:Step(dt); syo:Step(dt)
					inst[key] = UDim2.new(
						sxs.Position, math.round(sxo.Position),
						sys.Position, math.round(syo.Position)
					)
				end,
				settled  = function()
					return sxs:IsSettled() and sxo:IsSettled()
						and sys:IsSettled() and syo:IsSettled()
				end,
				finalize = function() inst[key] = target end,
			})
		elseif vtype == "Vector2" then
			local c  = current :: Vector2
			local tg = target  :: Vector2
			local sx = Spring.new(c.X, speed, damper)
			local sy = Spring.new(c.Y, speed, damper)
			sx:SetTarget(tg.X); sy:SetTarget(tg.Y)
			table.insert(channels, {
				tick     = function(dt) sx:Step(dt); sy:Step(dt); inst[key] = Vector2.new(sx.Position, sy.Position) end,
				settled  = function() return sx:IsSettled() and sy:IsSettled() end,
				finalize = function() inst[key] = target end,
			})
		end
	end

	local cancelled = false
	local connection: RBXScriptConnection

	connection = RunService.Heartbeat:Connect(function(dt: number)
		if cancelled then
			connection:Disconnect()
			return
		end
		local allSettled = true
		for _, ch in channels do
			ch.tick(dt)
			if not ch.settled() then
				allSettled = false
			end
		end
		if allSettled then
			for _, ch in channels do
				ch.finalize()
			end
			connection:Disconnect()
		end
	end)

	return {
		Cancel = function()
			cancelled = true
		end,
	}
end

return Tween
