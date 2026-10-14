local Creator      = require(script.Parent.Parent.Creator)
local ThemeManager = require(script.Parent.Parent.Themes.Manager)

local Paragraph = {}

function Paragraph.Create(parent, config)
    local theme = ThemeManager.CurrentTheme

    local container = Creator.New("Frame", {
        Name = "Paragraph_" .. config.Title,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = theme.ControlBg,
        BorderSizePixel = 0,
        ThemeTag = { BackgroundColor3 = "ControlBg" },
        Parent = parent,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Creator.New("UIStroke", {
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = theme.Border,
            ThemeTag = { Color = "Border" },
        }),
        Creator.New("UIPadding", {
            PaddingTop    = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft   = UDim.new(0, 10),
            PaddingRight  = UDim.new(0, 10),
        }),
        Creator.New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 4),
        }),
        Creator.New("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            Text = config.Title,
            TextSize = 12,
            FontFace = Font.fromEnum(Enum.Font.GothamBold),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = theme.Text,
            ThemeTag = { TextColor3 = "Text" },
            LayoutOrder = 1,
        }),
        Creator.New("TextLabel", {
            Name = "Content",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = config.Content,
            TextSize = 11,
            TextWrapped = true,
            FontFace = Font.fromEnum(Enum.Font.Gotham),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextColor3 = theme.SubText,
            ThemeTag = { TextColor3 = "SubText" },
            LayoutOrder = 2,
        }),
    })

    local titleLabel = container:FindFirstChild("Title")
    local contentLabel = container:FindFirstChild("Content")

    return {
        Container = container,
        SetTitle = function(_, text)
            titleLabel.Text = text
        end,
        SetText = function(_, text)
            contentLabel.Text = text
        end,
    }
end

return Paragraph
