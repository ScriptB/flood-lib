local Spring = {}
Spring.__index = Spring


function Spring.new(initial, speed, damper)
	local self = setmetatable({
		Target   = initial or 0,
		Position = initial or 0,
		Velocity = 0,
		Speed    = speed  or 15,
		Damper   = damper or 0.85,
	}, Spring)
	return (self)
end

function Spring:SetTarget(target)
	self.Target = target
end

function Spring:Step(dt)
	local d    = self.Damper
	local s    = self.Speed
	local diff = self.Target - self.Position
	local f    = diff * (s * s)
	self.Velocity = (self.Velocity + f * dt) * math.clamp(1 - d * s * dt, 0, 1)
	self.Position = self.Position + self.Velocity * dt
	return self.Position
end

function Spring:IsSettled()
	return math.abs(self.Target - self.Position) < 0.002
		and math.abs(self.Velocity) < 0.002
end

return Spring
