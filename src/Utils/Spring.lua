--!strict
local Spring = {}
Spring.__index = Spring

export type Spring = {
	Target:   number,
	Position: number,
	Velocity: number,
	Speed:    number,
	Damper:   number,
	Step:       (self: Spring, dt: number) -> number,
	SetTarget:  (self: Spring, target: number) -> (),
	IsSettled:  (self: Spring) -> boolean,
}

function Spring.new(initial: number?, speed: number?, damper: number?): Spring
	local self = setmetatable({
		Target   = initial or 0,
		Position = initial or 0,
		Velocity = 0,
		Speed    = speed  or 15,
		Damper   = damper or 0.85,
	}, Spring)
	return (self :: any)
end

function Spring:SetTarget(target: number)
	self.Target = target
end

function Spring:Step(dt: number): number
	local d    = self.Damper
	local s    = self.Speed
	local diff = self.Target - self.Position
	local f    = diff * (s * s)
	self.Velocity = (self.Velocity + f * dt) * math.clamp(1 - d * s * dt, 0, 1)
	self.Position = self.Position + self.Velocity * dt
	return self.Position
end

function Spring:IsSettled(): boolean
	return math.abs(self.Target - self.Position) < 0.002
		and math.abs(self.Velocity) < 0.002
end

return Spring
