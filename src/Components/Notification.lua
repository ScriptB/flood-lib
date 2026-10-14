--!strict
-- Toast Notification queue and rendering container

local Creator = require(script.Parent.Parent.Creator)
local Tween = require(script.Parent.Parent.Utils.Tween)

local Notification = {
    Container = nil :: Frame?,
}

function Notification.Init(screenGui: ScreenGui)
    if Notification.Container then return end

    Notification.Container = Creator.New("Frame", {
        Name = "NotificationQueue",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -24, 1, -24),
        Size = UDim2.fromOffset(300, 400),
        BackgroundTransparency = 1,
        ZIndex = 999,
        Parent = screenGui,
    }, {
        Creator.New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(0, 8),
        }),
    })
end

function Notification.Notify(config: { Title: string, Content: string, Duration: number? })
    if not Notification.Container then return end

    local card = Creator.New("Frame", {
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundTransparency = 0.1,
        ThemeTag = {
            BackgroundColor3 = "Card",
        },
        Parent = Notification.Container,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Creator.New("UIStroke", {
            Thickness = 1,
            ThemeTag = { Color = "Border" },
        }),
        Creator.New("TextLabel", {
            Name = "Title",
            Position = UDim2.fromOffset(12, 10),
            Size = UDim2.new(1, -24, 0, 18),
            BackgroundTransparency = 1,
            Text = config.Title or "Notification",
            TextSize = 14,
            FontFace = Font.fromEnum(Enum.Font.GothamBold),
            TextXAlignment = Enum.TextXAlignment.Left,
            ThemeTag = { TextColor3 = "Text" },
        }),
        Creator.New("TextLabel", {
            Name = "Content",
            Position = UDim2.fromOffset(12, 30),
            Size = UDim2.new(1, -24, 0, 24),
            BackgroundTransparency = 1,
            Text = config.Content or "",
            TextSize = 12,
            TextWrapped = true,
            FontFace = Font.fromEnum(Enum.Font.Gotham),
            TextXAlignment = Enum.TextXAlignment.Left,
            ThemeTag = { TextColor3 = "SubText" },
        }),
    })

    local duration = config.Duration or 3.5
    task.delay(duration, function()
        if card.Parent then
            local tw = Tween.Play(card, Tween.Fast, { BackgroundTransparency = 1 })
            tw.Completed:Wait()
            card:Destroy()
        end
    end)
end

return Notification
