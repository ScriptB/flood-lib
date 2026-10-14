local Creator      = require(script.Parent.Parent.Creator)
local ThemeManager = require(script.Parent.Parent.Themes.Manager)
local Tween        = require(script.Parent.Parent.Utils.Tween)

local Button = {}

function Button.Create(parent, config)
	local theme = ThemeManager.CurrentTheme

	local hasDesc  = config.Description ~= nil
	local baseH
	if hasDesc then baseH = 38 else baseH = 28 end
	local container = Creator.New("Frame", {
		Name             = "Button_" .. config.Title,
		Size             = UDim2.new(1, 0, 0, baseH),
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
	})

	local titleY

	if hasDesc then titleY = 5 else titleY = 0 end
	local titleH
	if hasDesc then titleH = 14 else titleH = baseH end
	Creator.New("TextLabel", {
		Name                   = "Title",
		Position               = UDim2.fromOffset(9, titleY),
		Size                   = UDim2.new(1, -32, 0, titleH),
		BackgroundTransparency = 1,
		Text                   = config.Title,
		TextSize               = 11,
		FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextColor3             = theme.Text,
		ThemeTag               = { TextColor3 = "Text" },
		Parent                 = container,
	})

	if hasDesc then
		Creator.New("TextLabel", {
			Name                   = "Description",
			Position               = UDim2.fromOffset(9, 20),
			Size                   = UDim2.new(1, -32, 0, 13),
			BackgroundTransparency = 1,
			Text                   = config.Description,
			TextSize               = 9,
			FontFace               = Font.fromEnum(Enum.Font.Gotham),
			TextXAlignment         = Enum.TextXAlignment.Left,
			TextColor3             = theme.SubText,
			ThemeTag               = { TextColor3 = "SubText" },
			Parent                 = container,
		})
	end

	local arrow = Creator.New("TextLabel", {
		Name                   = "Arrow",
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, -9, 0.5, 0),
		Size                   = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Text                   = "→",
		TextSize               = 11,
		FontFace               = Font.fromEnum(Enum.Font.Gotham),
		TextColor3             = theme.SubText,
		ThemeTag               = { TextColor3 = "SubText" },
		Parent                 = container,
	})

	local clickBtn = Creator.New("TextButton", {
		Size                   = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text                   = "",
		Parent                 = container,
	})

	clickBtn.MouseEnter:Connect(function()
		Tween.Play(container, Tween.Fast, { BackgroundColor3 = theme.ControlHover })
		Tween.Play(arrow,     Tween.Fast, { TextColor3       = theme.Accent })
	end)
	clickBtn.MouseLeave:Connect(function()
		Tween.Play(container, Tween.Fast, { BackgroundColor3 = theme.ControlBg })
		Tween.Play(arrow,     Tween.Fast, { TextColor3       = theme.SubText })
	end)

	clickBtn.MouseButton1Down:Connect(function()
		Tween.SpringAnimate(container, {
			Size = UDim2.new(1, 0, 0, baseH - 2),
		}, Tween.SpringPop)
	end)
	clickBtn.MouseButton1Up:Connect(function()
		Tween.SpringAnimate(container, {
			Size = UDim2.new(1, 0, 0, baseH),
		}, Tween.SpringPop)
	end)
	clickBtn.MouseButton1Click:Connect(function()
		if config.Callback then
			task.spawn(config.Callback)
		end
	end)

	return container
end

return Button
