--!strict
local Creator      = require(script.Parent.Parent.Creator)
local ThemeManager = require(script.Parent.Parent.Themes.Manager)
local Tween        = require(script.Parent.Parent.Utils.Tween)
local Signal       = require(script.Parent.Parent.Utils.Signal)

local Input = {}

function Input.Create(parent: Instance, id: string, config: {
	Title:       string,
	Default:     string?,
	Placeholder: string?,
	Callback:    ((string) -> ())?,
})
	local value     = config.Default or ""
	local onChanged = Signal.new()
	local theme     = ThemeManager.CurrentTheme

	local container = Creator.New("Frame", {
		Name             = "Input_" .. id,
		Size             = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = theme.ControlBg,
		BorderSizePixel  = 0,
		ThemeTag         = { BackgroundColor3 = "ControlBg" },
		Parent           = parent,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 5) }),
	})

	local stroke = Creator.New("UIStroke", {
		Thickness       = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color           = theme.Border,
		ThemeTag        = { Color = "Border" },
		Parent          = container,
	})

	Creator.New("TextLabel", {
		Name                   = "Title",
		Position               = UDim2.fromOffset(9, 0),
		Size                   = UDim2.new(0.42, -12, 1, 0),
		BackgroundTransparency = 1,
		Text                   = config.Title,
		TextSize               = 11,
		FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextColor3             = theme.Text,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		ThemeTag               = { TextColor3 = "Text" },
		Parent                 = container,
	})

	local textBox = Creator.New("TextBox", {
		Name                   = "TextBox",
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, -9, 0.5, 0),
		Size                   = UDim2.new(0.55, 0, 0, 18),
		Text                   = value,
		PlaceholderText        = config.Placeholder or "Value...",
		TextSize               = 10,
		FontFace               = Font.fromEnum(Enum.Font.Gotham),
		ClearTextOnFocus       = false,
		BackgroundColor3       = theme.BadgeBg,
		BackgroundTransparency = 0,
		TextColor3             = theme.Text,
		PlaceholderColor3      = theme.TextDisabled,
		BorderSizePixel        = 0,
		ThemeTag               = {
			BackgroundColor3  = "BadgeBg",
			TextColor3        = "Text",
			PlaceholderColor3 = "TextDisabled",
		},
		Parent = container,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 3) }),
		Creator.New("UIPadding", {
			PaddingLeft  = UDim.new(0, 5),
			PaddingRight = UDim.new(0, 5),
		}),
	})

	local inputObj = {
		Value     = value,
		OnChanged = onChanged,
	}

	textBox.Focused:Connect(function()
		Tween.SpringAnimate(stroke, { Color = theme.Accent }, Tween.SpringSettle)
	end)

	textBox.FocusLost:Connect(function(_enterPressed: boolean)
		Tween.SpringAnimate(stroke, { Color = theme.Border }, Tween.SpringSettle)
		value = textBox.Text
		inputObj.Value = value
		onChanged:Fire(value)
		if config.Callback then
			task.spawn(config.Callback, value)
		end
	end)

	function inputObj:SetValue(newVal: string)
		value = newVal
		inputObj.Value = newVal
		textBox.Text = newVal
	end

	return inputObj
end

return Input
