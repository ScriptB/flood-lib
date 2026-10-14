--!strict
-- Production Keybind Component (Frontend UI Engineering Spec)
-- 28px height, 4px corner radius, hotkey pill badge

local UserInputService = game:GetService("UserInputService")
local Creator = require(script.Parent.Parent.Creator)
local ThemeManager = require(script.Parent.Parent.Themes.Manager)
local Signal = require(script.Parent.Parent.Utils.Signal)

local Keybind = {}

function Keybind.Create(parent: Instance, id: string, config: { Title: string, Default: Enum.KeyCode?, Callback: ((Enum.KeyCode) -> ())? })
    local currentKey = config.Default or Enum.KeyCode.RightControl
    local listening = false
    local onChanged = Signal.new()
    local theme = ThemeManager.CurrentTheme

    local container = Creator.New("Frame", {
        Name = "Keybind_" .. id,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = theme.ControlBg,
        BorderSizePixel = 0,
        Parent = parent,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) }),
        Creator.New("UIStroke", {
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = theme.Border,
        }),
        Creator.New("TextLabel", {
            Name = "Title",
            Position = UDim2.fromOffset(8, 0),
            Size = UDim2.new(1, -74, 1, 0),
            BackgroundTransparency = 1,
            Text = config.Title,
            TextSize = 11,
            FontFace = Font.fromEnum(Enum.Font.GothamMedium),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = theme.Text,
        }),
    })

    local keyBtn = Creator.New("TextButton", {
        Name = "KeyBadge",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(56, 18),
        BackgroundColor3 = theme.BadgeBg,
        BorderSizePixel = 0,
        Text = string.upper(currentKey.Name),
        TextSize = 9,
        FontFace = Font.fromEnum(Enum.Font.GothamBold),
        TextColor3 = theme.SubText,
        Parent = container,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 3) }),
    })

    local keyObj = {
        Value = currentKey,
        OnChanged = onChanged,
    }

    keyBtn.MouseButton1Click:Connect(function()
        listening = true
        keyBtn.Text = "..."
        keyBtn.TextColor3 = theme.Accent
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            listening = false
            currentKey = input.KeyCode
            keyObj.Value = currentKey
            keyBtn.Text = string.upper(currentKey.Name)
            keyBtn.TextColor3 = theme.SubText
            onChanged:Fire(currentKey)
            if config.Callback then task.spawn(config.Callback, currentKey) end
        end
    end)

    return keyObj
end

return Keybind
