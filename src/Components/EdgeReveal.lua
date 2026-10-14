local RunService   = game:GetService("RunService")
local Spring       = require(script.Parent.Parent.Utils.Spring)
local Tween        = require(script.Parent.Parent.Utils.Tween)
local Creator      = require(script.Parent.Parent.Creator)
local ThemeManager = require(script.Parent.Parent.Themes.Manager)

local SIDEBAR_W = 164
local TRIGGER_W = 22


local EdgeReveal = {}
EdgeReveal.__index = EdgeReveal

function EdgeReveal.new(screenGui, restoreFn)
	local self = setmetatable({}, EdgeReveal)
	self._active      = false
	self._leaveTimer  = nil
	self._tabs        = {}
	self._tabItems    = {}
	self._restoreFn   = restoreFn

	local t = ThemeManager.CurrentTheme

	local triggerZone = Creator.New("Frame", {
		Name                 = "EdgeTrigger",
		Position             = UDim2.fromOffset(0, 0),
		Size                 = UDim2.new(0, TRIGGER_W, 1, 0),
		BackgroundTransparency = 1,
		ZIndex               = 97,
		Visible              = false,
		Parent               = screenGui,
	})

	local sidebar = Creator.New("Frame", {
		Name                   = "EdgeSidebar",
		Position               = UDim2.fromOffset(-SIDEBAR_W, 0),
		Size                   = UDim2.new(0, SIDEBAR_W, 1, 0),
		BackgroundColor3       = t.Panel,
		BackgroundTransparency = 0.08,
		BorderSizePixel        = 0,
		ClipsDescendants       = true,
		ZIndex                 = 98,
		Visible                = false,
		Parent                 = screenGui,
		ThemeTag               = { BackgroundColor3 = "Panel" },
	}, {
		Creator.New("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0,   Color3.fromRGB(28, 36, 58)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10, 12, 20)),
				ColorSequenceKeypoint.new(1,   Color3.fromRGB(6,   8, 14)),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0,   0.0),
				NumberSequenceKeypoint.new(1,   0.1),
			}),
			Rotation = 100,
		}),
		Creator.New("UIStroke", {
			Thickness      = 1,
			Color          = t.Border,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag       = { Color = "Border" },
		}),
	})

	Creator.New("Frame", {
		Name                   = "RightEdge",
		AnchorPoint            = Vector2.new(1, 0),
		Position               = UDim2.fromScale(1, 0),
		Size                   = UDim2.new(0, 1, 1, 0),
		BackgroundColor3       = t.BorderBright,
		BackgroundTransparency = 0.6,
		BorderSizePixel        = 0,
		ZIndex                 = 99,
		ThemeTag               = { BackgroundColor3 = "BorderBright" },
		Parent                 = sidebar,
	})

	local header = Creator.New("Frame", {
		Name                   = "Header",
		Size                   = UDim2.new(1, 0, 0, 60),
		BackgroundTransparency = 1,
		ZIndex                 = 99,
		Parent                 = sidebar,
	}, {
		Creator.New("Frame", {
			Name             = "AccentMark",
			AnchorPoint      = Vector2.new(0, 0.5),
			Position         = UDim2.fromOffset(18, 30),
			Size             = UDim2.fromOffset(3, 20),
			BackgroundColor3 = t.Accent,
			BorderSizePixel  = 0,
			ZIndex           = 99,
			ThemeTag         = { BackgroundColor3 = "Accent" },
		}, { Creator.New("UICorner", { CornerRadius = UDim.new(0, 2) }) }),
		Creator.New("TextLabel", {
			Name                 = "LibName",
			AnchorPoint          = Vector2.new(0, 0.5),
			Position             = UDim2.fromOffset(30, 30),
			Size                 = UDim2.new(1, -34, 0, 16),
			BackgroundTransparency = 1,
			Text                 = "FLOOD",
			TextSize             = 11,
			FontFace             = Font.fromEnum(Enum.Font.GothamMedium),
			TextColor3           = t.Text,
			TextXAlignment       = Enum.TextXAlignment.Left,
			ZIndex               = 99,
			ThemeTag             = { TextColor3 = "Text" },
		}),
		Creator.New("Frame", {
			Name             = "Divider",
			AnchorPoint      = Vector2.new(0, 1),
			Position         = UDim2.fromScale(0, 1),
			Size             = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = t.Border,
			BorderSizePixel  = 0,
			ZIndex           = 99,
			ThemeTag         = { BackgroundColor3 = "Border" },
		}),
	})

	local tabList = Creator.New("Frame", {
		Name                   = "TabList",
		Position               = UDim2.fromOffset(0, 61),
		Size                   = UDim2.new(1, 0, 1, -93),
		BackgroundTransparency = 1,
		ClipsDescendants       = true,
		ZIndex                 = 99,
		Parent                 = sidebar,
	}, {
		Creator.New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding   = UDim.new(0, 2),
		}),
		Creator.New("UIPadding", {
			PaddingTop    = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft   = UDim.new(0, 8),
			PaddingRight  = UDim.new(0, 8),
		}),
	})

	Creator.New("Frame", {
		Name                   = "Footer",
		AnchorPoint            = Vector2.new(0, 1),
		Position               = UDim2.fromScale(0, 1),
		Size                   = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		ZIndex                 = 99,
		Parent                 = sidebar,
	}, {
		Creator.New("Frame", {
			Name             = "Divider",
			Size             = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = t.Border,
			BorderSizePixel  = 0,
			ZIndex           = 99,
			ThemeTag         = { BackgroundColor3 = "Border" },
		}),
		Creator.New("TextLabel", {
			Position             = UDim2.fromOffset(18, 2),
			Size                 = UDim2.new(1, -18, 1, -2),
			BackgroundTransparency = 1,
			Text                 = "hover to restore",
			TextSize             = 9,
			FontFace             = Font.fromEnum(Enum.Font.Gotham),
			TextColor3           = t.TextDisabled,
			TextXAlignment       = Enum.TextXAlignment.Left,
			ZIndex               = 99,
			ThemeTag             = { TextColor3 = "TextDisabled" },
		}),
	})

	local springX = Spring.new(-SIDEBAR_W, 22, 0.76)

	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not self._active then return end
		springX:Step(dt)
		local x = math.round(springX.Position)
		sidebar.Position      = UDim2.fromOffset(x, 0)
		triggerZone.Position  = UDim2.fromOffset(math.max(0, x + SIDEBAR_W - TRIGGER_W), 0)
	end)

	local function startSpring(target)
		springX:SetTarget(target)
	end

	local function cancelLeave()
		if self._leaveTimer then
			task.cancel(self._leaveTimer)
			self._leaveTimer = nil
		end
	end

	local function scheduleHide()
		cancelLeave()
		self._leaveTimer = task.delay(0.55, function()
			self._leaveTimer = nil
			startSpring(-SIDEBAR_W)
		end)
	end

	triggerZone.MouseEnter:Connect(function()
		cancelLeave()
		startSpring(0)
	end)
	sidebar.MouseEnter:Connect(function()
		cancelLeave()
		startSpring(0)
	end)
	triggerZone.MouseLeave:Connect(scheduleHide)
	sidebar.MouseLeave:Connect(scheduleHide)

	self._triggerZone = triggerZone
	self._sidebar     = sidebar
	self._tabList     = tabList
	self._springX     = springX
	self._conn        = conn

	return self
end

function EdgeReveal:AddTab(entry)
	table.insert(self._tabs, entry)
	local t = ThemeManager.CurrentTheme

	local item = Creator.New("TextButton", {
		Name                   = "Tab_" .. entry.Title,
		Size                   = UDim2.new(1, 0, 0, 34),
		BackgroundColor3       = t.ControlBg,
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		BorderSizePixel        = 0,
		ZIndex                 = 100,
		Parent                 = self._tabList,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Creator.New("TextLabel", {
			Name                   = "Icon",
			AnchorPoint            = Vector2.new(0, 0.5),
			Position               = UDim2.fromOffset(8, 17),
			Size                   = UDim2.fromOffset(20, 20),
			BackgroundTransparency = 1,
			Text                   = entry.Icon,
			TextSize               = 11,
			FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
			TextColor3             = t.SubText,
			ZIndex                 = 100,
			ThemeTag               = { TextColor3 = "SubText" },
		}),
		Creator.New("TextLabel", {
			Name                   = "Label",
			AnchorPoint            = Vector2.new(0, 0.5),
			Position               = UDim2.fromOffset(32, 17),
			Size                   = UDim2.new(1, -36, 0, 14),
			BackgroundTransparency = 1,
			Text                   = entry.Title,
			TextSize               = 10,
			FontFace               = Font.fromEnum(Enum.Font.Gotham),
			TextColor3             = t.SubText,
			TextXAlignment         = Enum.TextXAlignment.Left,
			ZIndex                 = 100,
			ThemeTag               = { TextColor3 = "SubText" },
		}),
	})

	item.MouseEnter:Connect(function()
		Tween.Play(item, Tween.Fast, {
			BackgroundTransparency = 0,
			BackgroundColor3       = t.ControlBg,
		})
		local lbl = item:FindFirstChild("Label")
		local ico = item:FindFirstChild("Icon")
		if lbl then Tween.Play(lbl, Tween.Fast, { TextColor3 = t.Text }) end
		if ico then Tween.Play(ico, Tween.Fast, { TextColor3 = t.Accent }) end
	end)
	item.MouseLeave:Connect(function()
		Tween.Play(item, Tween.Fast, { BackgroundTransparency = 1 })
		local lbl = item:FindFirstChild("Label")
		local ico = item:FindFirstChild("Icon")
		if lbl then Tween.Play(lbl, Tween.Fast, { TextColor3 = t.SubText }) end
		if ico then Tween.Play(ico, Tween.Fast, { TextColor3 = t.SubText }) end
	end)
	item.MouseButton1Click:Connect(function()
		entry.SelectFn()
	end)

	table.insert(self._tabItems, item)
end

function EdgeReveal:Activate()
	self._active = true
	self._springX.Target   = -SIDEBAR_W
	self._springX.Position = -SIDEBAR_W
	self._springX.Velocity = 0
	self._triggerZone.Visible = true
	self._sidebar.Visible     = true
end

function EdgeReveal:Deactivate()
	self._active = false
	self._springX:SetTarget(-SIDEBAR_W)
	task.delay(0.55, function()
		if not self._active then
			self._triggerZone.Visible = false
			self._sidebar.Visible     = false
		end
	end)
end

function EdgeReveal:Destroy()
	self._conn:Disconnect()
end

return EdgeReveal
