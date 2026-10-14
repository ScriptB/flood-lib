local UserInputService = game:GetService("UserInputService")
local Creator          = require(script.Parent.Parent.Creator)
local ThemeManager     = require(script.Parent.Parent.Themes.Manager)
local Tween            = require(script.Parent.Parent.Utils.Tween)
local Signal           = require(script.Parent.Parent.Utils.Signal)

local Slider = {}

function Slider.Create(parent, id, config)
	local min       = config.Min     or 0
	local max       = config.Max     or 100
	local rounding  = config.Rounding or 0
	local value     = config.Default or min
	local suffix    = config.Suffix  or ""
	local onChanged = Signal.new()
	local theme     = ThemeManager.CurrentTheme
	local dragging  = false

	local container = Creator.New("Frame", {
		Name             = "Slider_" .. id,
		Size             = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = theme.ControlBg,
		BorderSizePixel  = 0,
		Parent           = parent,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 5) }),
		Creator.New("UIStroke", {
			Thickness       = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color           = theme.Border,
			ThemeTag        = { Color = "Border" },
		}),
	})

	Creator.New("TextLabel", {
		Name                   = "Title",
		Position               = UDim2.fromOffset(9, 4),
		Size                   = UDim2.new(1, -60, 0, 14),
		BackgroundTransparency = 1,
		Text                   = config.Title,
		TextSize               = 11,
		FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextColor3             = theme.Text,
		ThemeTag               = { TextColor3 = "Text" },
		Parent                 = container,
	})

	local valueBadge = Creator.New("Frame", {
		Name             = "ValueBadge",
		AnchorPoint      = Vector2.new(1, 0),
		Position         = UDim2.new(1, -9, 0, 4),
		Size             = UDim2.fromOffset(46, 14),
		BackgroundColor3 = theme.BadgeBg,
		BorderSizePixel  = 0,
		Parent           = container,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 3) }),
		Creator.New("TextLabel", {
			Name                   = "ValueLabel",
			Size                   = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text                   = tostring(value) .. suffix,
			TextSize               = 9,
			FontFace               = Font.fromEnum(Enum.Font.Gotham),
			TextColor3             = theme.SubText,
			ThemeTag               = { TextColor3 = "SubText" },
		}),
	})

	local track = Creator.New("TextButton", {
		Name             = "Track",
		Position         = UDim2.fromOffset(9, 24),
		Size             = UDim2.new(1, -18, 0, 4),
		Text             = "",
		AutoButtonColor  = false,
		BackgroundColor3 = theme.BadgeBg,
		BorderSizePixel  = 0,
		Parent           = container,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	local progress = Creator.New("Frame", {
		Name             = "Progress",
		Size             = UDim2.fromScale(math.clamp((value - min) / (max - min), 0, 1), 1),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel  = 0,
		Parent           = track,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	local thumb = Creator.New("Frame", {
		Name             = "Thumb",
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.fromScale(math.clamp((value - min) / (max - min), 0, 1), 0.5),
		Size             = UDim2.fromOffset(12, 12),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel  = 0,
		Parent           = track,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	local sliderObj = {
		Value     = value,
		OnChanged = onChanged,
	}

	local valueLabel = valueBadge:FindFirstChild("ValueLabel")

	local function setValue(val)
		val = math.clamp(val, min, max)
		if rounding > 0 then
			val = math.floor(val * (10 ^ rounding) + 0.5) / (10 ^ rounding)
		else
			val = math.floor(val + 0.5)
		end
		value = val
		sliderObj.Value = val
		valueLabel.Text = tostring(val) .. suffix

		local t = math.clamp((val - min) / (max - min), 0, 1)
		Tween.SpringAnimate(progress, { Size     = UDim2.fromScale(t, 1)    }, Tween.SpringSettle)
		Tween.SpringAnimate(thumb,    { Position = UDim2.fromScale(t, 0.5)  }, Tween.SpringSettle)

		onChanged:Fire(val)
		if config.Callback then
			task.spawn(config.Callback, val)
		end
	end
	sliderObj.SetValue = setValue

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			Tween.Play(valueBadge, Tween.Fast, { BackgroundColor3 = theme.AccentMuted })
			Tween.SpringAnimate(thumb, { Size = UDim2.fromOffset(14, 14) }, Tween.SpringPop)
			local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
			setValue(min + rel * (max - min))
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
			setValue(min + rel * (max - min))
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				dragging = false
				Tween.Play(valueBadge, Tween.Fast, { BackgroundColor3 = theme.BadgeBg })
				Tween.SpringAnimate(thumb, { Size = UDim2.fromOffset(12, 12) }, Tween.SpringSettle)
			end
		end
	end)

	return sliderObj
end

return Slider
