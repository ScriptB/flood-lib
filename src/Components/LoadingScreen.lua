local TweenService = game:GetService("TweenService")

local LoadingScreen = {}
LoadingScreen.__index = LoadingScreen


local FADE    = TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local DOT_ON  = TweenInfo.new(0.14)
local DOT_OFF = TweenInfo.new(0.28)

function LoadingScreen.new(config)
	local self = setmetatable({}, LoadingScreen)
	self._dismissed = false

	local overlay = Instance.new("Frame")
	overlay.Name                   = "LoadingOverlay"
	overlay.Size                   = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3       = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0
	overlay.BorderSizePixel        = 0
	overlay.ZIndex                 = 500
	overlay.Parent                 = config.Parent

	local haze = Instance.new("Frame")
	haze.AnchorPoint            = Vector2.new(0.5, 0.5)
	haze.Position               = UDim2.fromScale(0.5, 0.5)
	haze.Size                   = UDim2.fromOffset(680, 480)
	haze.BackgroundColor3       = Color3.fromRGB(10, 28, 60)
	haze.BackgroundTransparency = 0.92
	haze.BorderSizePixel        = 0
	haze.ZIndex                 = 500
	haze.Parent                 = overlay
	local hazeCorner            = Instance.new("UICorner")
	hazeCorner.CornerRadius     = UDim.new(1, 0)
	hazeCorner.Parent           = haze

	local center = Instance.new("Frame")
	center.AnchorPoint          = Vector2.new(0.5, 0.5)
	center.Position             = UDim2.fromScale(0.5, 0.5)
	center.AutomaticSize        = Enum.AutomaticSize.Y
	center.Size                 = UDim2.fromOffset(240, 0)
	center.BackgroundTransparency = 1
	center.ZIndex               = 501
	center.Parent               = overlay

	local layout               = Instance.new("UIListLayout")
	layout.SortOrder           = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding             = UDim.new(0, 10)
	layout.Parent              = center

	local titleLbl               = Instance.new("TextLabel")
	titleLbl.LayoutOrder         = 1
	titleLbl.AutomaticSize       = Enum.AutomaticSize.XY
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text                = string.upper(config.Title or "FLOOD LIB")
	titleLbl.TextSize            = 13
	titleLbl.FontFace            = Font.fromEnum(Enum.Font.GothamMedium)
	titleLbl.TextColor3          = Color3.fromRGB(200, 215, 235)
	titleLbl.ZIndex              = 501
	titleLbl.Parent              = center

	local statusLbl               = Instance.new("TextLabel")
	statusLbl.Name                = "Status"
	statusLbl.LayoutOrder         = 2
	statusLbl.AutomaticSize       = Enum.AutomaticSize.XY
	statusLbl.BackgroundTransparency = 1
	statusLbl.Text                = "Initialising"
	statusLbl.TextSize            = 10
	statusLbl.FontFace            = Font.fromEnum(Enum.Font.Gotham)
	statusLbl.TextColor3          = Color3.fromRGB(58, 82, 105)
	statusLbl.ZIndex              = 501
	statusLbl.Parent              = center

	local dotRow               = Instance.new("Frame")
	dotRow.LayoutOrder         = 3
	dotRow.AutomaticSize       = Enum.AutomaticSize.XY
	dotRow.BackgroundTransparency = 1
	dotRow.ZIndex              = 501
	dotRow.Parent              = center

	local dotLayout            = Instance.new("UIListLayout")
	dotLayout.FillDirection    = Enum.FillDirection.Horizontal
	dotLayout.VerticalAlignment  = Enum.VerticalAlignment.Center
	dotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	dotLayout.Padding          = UDim.new(0, 6)
	dotLayout.Parent           = dotRow

	local dots= {}
	for _ = 1, 3 do
		local dot           = Instance.new("Frame")
		dot.Size            = UDim2.fromOffset(4, 4)
		dot.BackgroundColor3 = Color3.fromRGB(30, 55, 80)
		dot.BorderSizePixel = 0
		dot.ZIndex          = 502
		dot.Parent          = dotRow
		local dc            = Instance.new("UICorner")
		dc.CornerRadius     = UDim.new(1, 0)
		dc.Parent           = dot
		table.insert(dots, dot)
	end

	self._overlay   = overlay
	self._statusLbl = statusLbl

	local animRunning = true
	task.spawn(function()
		local i = 1
		while animRunning do
			for j, dot in ipairs(dots) do
				TweenService:Create(dot, j == i and DOT_ON or DOT_OFF, {
					BackgroundColor3 = j == i
						and Color3.fromRGB(60, 150, 230)
						or Color3.fromRGB(30, 55, 80),
					Size = j == i
						and UDim2.fromOffset(5, 5)
						or UDim2.fromOffset(4, 4),
				}):Play()
			end
			i = (i % 3) + 1
			task.wait(0.38)
		end
	end)
	self._stopAnim = function() animRunning = false end

	return self
end

function LoadingScreen:SetStatus(text)
	if self._dismissed or not self._statusLbl then return end
	self._statusLbl.Text = text
end

function LoadingScreen:Dismiss()
	if self._dismissed then return end
	self._dismissed = true
	if self._stopAnim then self._stopAnim() end
	local overlay = self._overlay
	if not overlay or not overlay.Parent then return end
	local t = TweenService:Create(overlay, FADE, { BackgroundTransparency = 1 })
	t:Play()
	t.Completed:Connect(function()
		if overlay.Parent then overlay:Destroy() end
	end)
end

return LoadingScreen
