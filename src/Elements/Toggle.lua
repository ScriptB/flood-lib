--!strict
local Creator      = require(script.Parent.Parent.Creator)
local ThemeManager = require(script.Parent.Parent.Themes.Manager)
local Tween        = require(script.Parent.Parent.Utils.Tween)
local Signal       = require(script.Parent.Parent.Utils.Signal)

local Toggle = {}

function Toggle.Create(parent: Instance, id: string, config: { Title: string, Default: boolean?, Callback: ((boolean) -> ())? })
	local value     = config.Default or false
	local onChanged = Signal.new()
	local theme     = ThemeManager.CurrentTheme

	local container = Creator.New("Frame", {
		Name             = "Toggle_" .. id,
		Size             = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = theme.ControlBg,
		BorderSizePixel  = 0,
		ThemeTag         = { BackgroundColor3 = "ControlBg" },
		Parent           = parent,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 5) }),
		Creator.New("UIStroke", {
			Thickness       = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color           = theme.Border,
			ThemeTag        = { Color = "Border" },
		}),
		Creator.New("TextLabel", {
			Name                   = "Title",
			Position               = UDim2.fromOffset(9, 0),
			Size                   = UDim2.new(1, -52, 1, 0),
			BackgroundTransparency = 1,
			Text                   = config.Title,
			TextSize               = 11,
			FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
			TextXAlignment         = Enum.TextXAlignment.Left,
			TextColor3             = theme.Text,
			ThemeTag               = { TextColor3 = "Text" },
		}),
	})

	local switchTrack = Creator.New("Frame", {
		Name             = "Track",
		AnchorPoint      = Vector2.new(1, 0.5),
		Position         = UDim2.new(1, -9, 0.5, 0),
		Size             = UDim2.fromOffset(30, 16),
		BackgroundColor3 = if value then theme.Accent else theme.BadgeBg,
		BorderSizePixel  = 0,
		Parent           = container,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	local knobOn  = UDim2.new(1, -14, 0.5, 0)
	local knobOff = UDim2.new(0,   2, 0.5, 0)

	local knob = Creator.New("Frame", {
		Name             = "Knob",
		AnchorPoint      = Vector2.new(0, 0.5),
		Position         = if value then knobOn else knobOff,
		Size             = UDim2.fromOffset(12, 12),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel  = 0,
		Parent           = switchTrack,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	local clickBtn = Creator.New("TextButton", {
		Size                   = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text                   = "",
		Parent                 = container,
	})

	clickBtn.MouseEnter:Connect(function()
		Tween.Play(container, Tween.Fast, { BackgroundColor3 = theme.ControlHover })
	end)
	clickBtn.MouseLeave:Connect(function()
		Tween.Play(container, Tween.Fast, { BackgroundColor3 = theme.ControlBg })
	end)

	local function updateVisual(state: boolean)
		if state then
			Tween.SpringAnimate(knob,        { Position         = knobOn        }, Tween.SpringPop)
			Tween.SpringAnimate(switchTrack, { BackgroundColor3 = theme.Accent  }, Tween.SpringSettle)
		else
			Tween.SpringAnimate(knob,        { Position         = knobOff       }, Tween.SpringPop)
			Tween.SpringAnimate(switchTrack, { BackgroundColor3 = theme.BadgeBg }, Tween.SpringSettle)
		end
	end

	local toggleObj = {
		Value     = value,
		OnChanged = onChanged,
	}

	function toggleObj:SetValue(newVal: boolean)
		value = newVal
		toggleObj.Value = newVal
		updateVisual(newVal)
		onChanged:Fire(newVal)
		if config.Callback then
			task.spawn(config.Callback, newVal)
		end
	end

	clickBtn.MouseButton1Click:Connect(function()
		toggleObj:SetValue(not value)
	end)

	return toggleObj
end

return Toggle
