--!strict
-- Acrylic: Frosted glass / blur backdrop component

local Creator = require(script.Parent.Parent.Creator)

local Acrylic = {}

function Acrylic.Create(parent: GuiObject): Frame
    local acrylicFrame = Creator.New("Frame", {
        Name = "AcrylicBackdrop",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        BorderSizePixel = 0,
        BackgroundTransparency = 0.25,
        ThemeTag = {
            BackgroundColor3 = "Acrylic",
        },
        ZIndex = parent.ZIndex - 1,
        Parent = parent,
    }, {
        Creator.New("UICorner", {
            CornerRadius = UDim.new(0, 10),
        }),
    })

    return acrylicFrame
end

return Acrylic
