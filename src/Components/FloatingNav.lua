local RunService   = game:GetService("RunService")
local Creator      = require(script.Parent.Parent.Creator)
local ThemeManager = require(script.Parent.Parent.Themes.Manager)
local Tween        = require(script.Parent.Parent.Utils.Tween)
local Spring       = require(script.Parent.Parent.Utils.Spring)

local NAV_W  = 58
local BTN_SZ = 42
local CORNER = 8
local GAP    = 12



local FloatingNav = {}
FloatingNav.__index = FloatingNav

local ICONS = {
	["layout-dashboard"] = "▦",
	["bar-chart"] = "▤",
	["settings-2"] = "⚙",
	["egg"] = "◇",
	["terminal"] = ">_",
	["globe"] = "◎",
	["settings"] = "⚙",
	["star"] = "★",
}

local LABELS = {
	["layout-dashboard"] = "HOME",
	["bar-chart"] = "STATS",
	["settings-2"] = "FARM",
	["egg"] = "HATCH",
	["terminal"] = "LOGS",
	["globe"] = "WORLD",
	["settings"] = "SETTINGS",
	["star"] = "INFO",
}

local function iconText(icon)
	return ICONS[icon] or icon
end

local function labelText(entry)
	return LABELS[entry.Icon] or string.upper(string.sub(entry.Label, 1, 8))
end

local function glassGradient()
	return Creator.New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,    Color3.fromRGB(30, 44, 64)),
			ColorSequenceKeypoint.new(0.42, Color3.fromRGB(10, 14, 22)),
			ColorSequenceKeypoint.new(1,    Color3.fromRGB(5,   7, 14)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.08),
			NumberSequenceKeypoint.new(1, 0.22),
		}),
		Rotation = 155,
	})
end

function FloatingNav.new(screenGui, anchorX, anchorY, height)
	local self    = setmetatable({}, FloatingNav)
	self._entries = {}
	self._btns    = {}
	self._activeId = ""
	self._attached = true

	local t = ThemeManager.CurrentTheme

	local shadow = Creator.New("Frame", {
		Name                   = "NavShadow",
		Position               = UDim2.fromOffset(anchorX - GAP - NAV_W - 5, anchorY - 5),
		Size                   = UDim2.fromOffset(NAV_W + 10, height + 10),
		BackgroundColor3       = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.6,
		BorderSizePixel        = 0,
		ZIndex                 = 3,
		Parent                 = screenGui,
	}, { Creator.New("UICorner", { CornerRadius = UDim.new(0, CORNER + 2) }) })

	local panel = Creator.New("Frame", {
		Name                   = "FloatingNav",
		Position               = UDim2.fromOffset(anchorX - GAP - NAV_W, anchorY),
		Size                   = UDim2.fromOffset(NAV_W, height),
		BackgroundColor3       = t.Panel,
		BackgroundTransparency = t.Glass,
		BorderSizePixel        = 0,
		ZIndex                 = 4,
		ThemeTag               = { BackgroundColor3 = "Panel" },
		Parent                 = screenGui,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, CORNER) }),
		Creator.New("UIStroke", {
			Thickness       = 1,
			Color           = t.BorderBright,
			Transparency    = 0.50,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag        = { Color = "BorderBright" },
		}),
		Creator.New("UIListLayout", {
			SortOrder           = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding             = UDim.new(0, 2),
		}),
		Creator.New("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }),
		glassGradient(),
	})

	self._panel  = panel
	self._shadow = shadow

	local sprX = Spring.new(panel.Position.X.Offset, 18, 0.80)
	local sprY = Spring.new(panel.Position.Y.Offset, 18, 0.80)
	self._sprX = sprX
	self._sprY = sprY

	local conn = RunService.Heartbeat:Connect(function(dt)
		if not self._attached then return end
		sprX:Step(dt)
		sprY:Step(dt)
		local x = math.round(sprX.Position)
		local y = math.round(sprY.Position)
		panel.Position  = UDim2.fromOffset(x, y)
		shadow.Position = UDim2.fromOffset(x - 5, y - 5)
	end)
	self._conn = conn

	return self
end

function FloatingNav:AddEntry(entry)
	table.insert(self._entries, entry)
	local t     = ThemeManager.CurrentTheme
	local order = #self._entries

	local railBtn = Creator.New("Frame", {
		Name                   = "NavBtn_" .. entry.Id,
		LayoutOrder            = order,
		Size                   = UDim2.fromOffset(NAV_W - 10, BTN_SZ),
		BackgroundColor3       = t.ControlBg,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		ThemeTag               = { BackgroundColor3 = "ControlBg" },
		Parent                 = self._panel,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Creator.New("Frame", {
			Name                   = "ActiveBar",
			AnchorPoint            = Vector2.new(0, 0.5),
			Position               = UDim2.new(0, -7, 0.5, 0),
			Size                   = UDim2.fromOffset(2, 16),
			BackgroundColor3       = t.Accent,
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			ThemeTag               = { BackgroundColor3 = "Accent" },
		}, { Creator.New("UICorner", { CornerRadius = UDim.new(0, 1) }) }),
		Creator.New("TextLabel", {
			Name                   = "Icon",
			AnchorPoint            = Vector2.new(0.5, 0),
			Position               = UDim2.new(0.5, 0, 0, 5),
			Size                   = UDim2.new(1, 0, 0, 18),
			BackgroundTransparency = 1,
			Text                   = iconText(entry.Icon),
			TextSize               = 13,
			FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
			TextColor3             = t.SubText,
			ThemeTag               = { TextColor3 = "SubText" },
		}),
		Creator.New("TextLabel", {
			Name                   = "Label",
			AnchorPoint            = Vector2.new(0.5, 1),
			Position               = UDim2.new(0.5, 0, 1, -4),
			Size                   = UDim2.new(1, -4, 0, 10),
			BackgroundTransparency = 1,
			Text                   = labelText(entry),
			TextSize               = 7,
			FontFace               = Font.fromEnum(Enum.Font.Gotham),
			TextColor3             = t.SubText,
			TextXAlignment         = Enum.TextXAlignment.Center,
			ThemeTag               = { TextColor3 = "SubText" },
		}),
	})

	local clickBtn = Creator.New("TextButton", {
		Name                   = "Click",
		Size                   = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		Parent                 = railBtn,
	})

	local icon  = railBtn:FindFirstChild("Icon")
	local label = railBtn:FindFirstChild("Label")
	local bar   = railBtn:FindFirstChild("ActiveBar")

	local function onActivate()
		Tween.Play(railBtn, Tween.Fast, { BackgroundTransparency = 0 })
		Tween.Play(icon,  Tween.Fast, { TextColor3 = ThemeManager.CurrentTheme.Accent })
		Tween.Play(label, Tween.Fast, { TextColor3 = ThemeManager.CurrentTheme.Accent })
		Tween.Play(bar,   Tween.Fast, { BackgroundTransparency = 0 })
	end

	local function onDeactivate()
		Tween.Play(railBtn, Tween.Fast, { BackgroundTransparency = 1 })
		Tween.Play(icon,  Tween.Fast, { TextColor3 = ThemeManager.CurrentTheme.SubText })
		Tween.Play(label, Tween.Fast, { TextColor3 = ThemeManager.CurrentTheme.SubText })
		Tween.Play(bar,   Tween.Fast, { BackgroundTransparency = 1 })
	end

	clickBtn.MouseEnter:Connect(function()
		if self._activeId ~= entry.Id then
			Tween.Play(railBtn, Tween.Fast, { BackgroundTransparency = 0.7 })
		end
	end)
	clickBtn.MouseLeave:Connect(function()
		if self._activeId ~= entry.Id then
			onDeactivate()
		end
	end)
	clickBtn.MouseButton1Click:Connect(function()
		entry.SelectFn()
	end)

	local record= {
		id           = entry.Id,
		rail         = railBtn,
		onActivate   = onActivate,
		onDeactivate = onDeactivate,
	}
	table.insert(self._btns, record)
end

function FloatingNav:SelectById(id)
	self._activeId = id
	for _, b in ipairs(self._btns) do
		if b.id == id then
			b.onActivate()
		else
			b.onDeactivate()
		end
	end
end

function FloatingNav:Follow(x, y, height)
	if not self._attached then return end
	self._sprX:SetTarget(x - GAP - NAV_W)
	self._sprY:SetTarget(y)
	self._panel.Size  = UDim2.fromOffset(NAV_W, height)
	self._shadow.Size = UDim2.fromOffset(NAV_W + 10, height + 10)
end

function FloatingNav:SetVisible(visible)
	self._panel.Visible  = visible
	self._shadow.Visible = visible
end

function FloatingNav:GetWidth()
	return NAV_W
end

function FloatingNav:GetGap()
	return GAP
end

function FloatingNav:Destroy()
	self._conn:Disconnect()
	self._panel:Destroy()
	self._shadow:Destroy()
end

return FloatingNav
