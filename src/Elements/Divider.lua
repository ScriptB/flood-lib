--!strict
local Creator      = require(script.Parent.Parent.Creator)
local ThemeManager = require(script.Parent.Parent.Themes.Manager)

local Divider = {}

function Divider.Create(parent: Instance): Frame
    local theme = ThemeManager.CurrentTheme
    local line = Creator.New("Frame", {
        Name = "Divider",
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = theme.Border,
        BorderSizePixel = 0,
        ThemeTag = { BackgroundColor3 = "Border" },
        Parent = parent,
    }) :: Frame
    return line
end

return Divider
