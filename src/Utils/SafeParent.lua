local RunService = game:GetService("RunService")
local CoreGui    = game:GetService("CoreGui")
local Players    = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local function SafeParent(gui)
	if RunService:IsStudio() and not RunService:IsRunning() then
		local ok = pcall(function()
			local existing = StarterGui:FindFirstChild(gui.Name)
			if existing and existing ~= gui then
				existing:Destroy()
			end
			gui.Parent = StarterGui
		end)
		if ok and gui.Parent == StarterGui then return end
	end

	if typeof(gethui) == "function" then
		local ok, res = pcall(gethui)
		if ok and res then
			gui.Parent = res
			return
		end
	end

	if typeof(protectgui) == "function" then
		pcall(protectgui, gui)
	end

	local coreOk = pcall(function()
		gui.Parent = CoreGui
	end)
	if coreOk and gui.Parent == CoreGui then return end

	local player = Players.LocalPlayer
	if player then
		local pg = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 2)
		if pg then
			gui.Parent = pg
			return
		end
	end

	pcall(function()
		gui.Parent = StarterGui
	end)
end

local function Create(name)
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	SafeParent(gui)
	return gui
end

return {
	Create = Create,
}
