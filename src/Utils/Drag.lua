--!strict
local UserInputService = game:GetService("UserInputService")

local Drag = {}

export type Handle = { Disconnect: () -> () }

function Drag.Attach(handle: GuiObject, target: Frame, onMove: ((x: number, y: number) -> ())?): Handle
	local active = false
	local ox, oy = 0, 0

	local c0 = handle.InputBegan:Connect(function(inp: InputObject)
		if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		active = true
		local abs = target.AbsolutePosition
		ox = abs.X - inp.Position.X
		oy = abs.Y - inp.Position.Y
	end)

	local c1 = UserInputService.InputChanged:Connect(function(inp: InputObject)
		if not active or inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		local nx = math.round(inp.Position.X + ox)
		local ny = math.round(inp.Position.Y + oy)
		target.Position = UDim2.fromOffset(nx, ny)
		if onMove then onMove(nx, ny) end
	end)

	local c2 = UserInputService.InputEnded:Connect(function(inp: InputObject)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			active = false
		end
	end)

	return {
		Disconnect = function()
			active = false
			c0:Disconnect()
			c1:Disconnect()
			c2:Disconnect()
		end,
	}
end

return Drag
