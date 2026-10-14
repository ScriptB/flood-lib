-- Tooltip component for hover hints

local Creator = require(script.Parent.Parent.Creator)
local Tween = require(script.Parent.Parent.Utils.Tween)

local Tooltip = {}

function Tooltip.Attach(target, text)
    local tooltip = Creator.New("TextLabel", {
        Name = "Tooltip",
        Size = UDim2.fromOffset(120, 26),
        Visible = false,
        Text = text,
        TextSize = 12,
        FontFace = Font.fromEnum(Enum.Font.GothamMedium),
        ThemeTag = {
            BackgroundColor3 = "Card",
            TextColor3 = "Text",
        },
        ZIndex = 100,
        Parent = target,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Creator.New("UIStroke", {
            Thickness = 1,
            ThemeTag = { Color = "Border" },
        }),
    })

    target.MouseEnter:Connect(function()
        tooltip.Visible = true
        Tween.Play(tooltip, Tween.Fast, { BackgroundTransparency = 0, TextTransparency = 0 })
    end)

    target.MouseLeave:Connect(function()
        tooltip.Visible = false
    end)

    return tooltip
end

return Tooltip
