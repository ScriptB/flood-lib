-- Modal Confirmation / Alert Dialog

local Creator = require(script.Parent.Parent.Creator)
local Tween = require(script.Parent.Parent.Utils.Tween)

local Dialog = {}

function Dialog.Prompt(screenGui, config)
    local backdrop = Creator.New("TextButton", {
        Name = "DialogBackdrop",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        Text = "",
        ZIndex = 500,
        Parent = screenGui,
    })

    local modal = Creator.New("Frame", {
        Name = "DialogModal",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(360, 180),
        ThemeTag = {
            BackgroundColor3 = "Card",
        },
        Parent = backdrop,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 12) }),
        Creator.New("UIStroke", {
            Thickness = 1,
            ThemeTag = { Color = "Border" },
        }),
        Creator.New("TextLabel", {
            Position = UDim2.fromOffset(20, 16),
            Size = UDim2.new(1, -40, 0, 24),
            BackgroundTransparency = 1,
            Text = config.Title or "Dialog",
            TextSize = 16,
            FontFace = Font.fromEnum(Enum.Font.GothamBold),
            TextXAlignment = Enum.TextXAlignment.Left,
            ThemeTag = { TextColor3 = "Text" },
        }),
        Creator.New("TextLabel", {
            Position = UDim2.fromOffset(20, 48),
            Size = UDim2.new(1, -40, 0, 60),
            BackgroundTransparency = 1,
            Text = config.Content or "",
            TextSize = 13,
            TextWrapped = true,
            FontFace = Font.fromEnum(Enum.Font.Gotham),
            TextXAlignment = Enum.TextXAlignment.Left,
            ThemeTag = { TextColor3 = "SubText" },
        }),
    })

    local confirmBtn = Creator.New("TextButton", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -20, 1, -16),
        Size = UDim2.fromOffset(90, 32),
        Text = "Confirm",
        TextSize = 13,
        FontFace = Font.fromEnum(Enum.Font.GothamBold),
        ThemeTag = {
            BackgroundColor3 = "Accent",
            TextColor3 = "Text",
        },
        Parent = modal,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
    })

    confirmBtn.MouseButton1Click:Connect(function()
        if config.OnConfirm then config.OnConfirm() end
        backdrop:Destroy()
    end)
end

return Dialog
