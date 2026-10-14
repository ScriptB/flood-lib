local Creator      = require(script.Parent.Parent.Creator)
local ThemeManager = require(script.Parent.Parent.Themes.Manager)
local Toggle       = require(script.Parent.Parent.Elements.Toggle)
local Slider       = require(script.Parent.Parent.Elements.Slider)
local Button       = require(script.Parent.Parent.Elements.Button)
local Dropdown     = require(script.Parent.Parent.Elements.Dropdown)
local Input        = require(script.Parent.Parent.Elements.Input)
local Keybind      = require(script.Parent.Parent.Elements.Keybind)
local Colorpicker  = require(script.Parent.Parent.Elements.Colorpicker)
local Paragraph    = require(script.Parent.Parent.Elements.Paragraph)
local Divider      = require(script.Parent.Parent.Elements.Divider)

local Section = {}
Section.__index = Section

function Section.new(parent, title)
    local self = setmetatable({}, Section)
    local theme = ThemeManager.CurrentTheme

    local panel = Creator.New("Frame", {
        Name = "Panel_" .. (title or "Group"),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Parent = parent,
    }, {
        Creator.New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 6),
        }),
    })

    if title and title ~= "" then
        Creator.New("TextLabel", {
            Name = "Header",
            Size = UDim2.new(1, 0, 0, 16),
            BackgroundTransparency = 1,
            LayoutOrder = 0,
            Text = string.upper(title),
            TextSize = 10,
            FontFace = Font.fromEnum(Enum.Font.GothamMedium),
            TextColor3 = theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            ThemeTag = { TextColor3 = "SubText" },
            Parent = panel,
        })
    end

    self.Container = panel
    self._order = 1

    return self
end

local function nextOrder(self)
    self._order = self._order + 1
    return self._order
end

function Section:AddToggle(id, config)
    local obj = Toggle.Create(self.Container, id, config)
    local frame = self.Container:FindFirstChild("Toggle_" .. id)
    if frame then frame.LayoutOrder = nextOrder(self) end
    return obj
end

function Section:AddSlider(id, config)
    local obj = Slider.Create(self.Container, id, config)
    local frame = self.Container:FindFirstChild("Slider_" .. id)
    if frame then frame.LayoutOrder = nextOrder(self) end
    return obj
end

function Section:AddButton(config)
    local frame = Button.Create(self.Container, config)
    frame.LayoutOrder = nextOrder(self)
    return frame
end

function Section:AddDropdown(id, config)
    local obj = Dropdown.Create(self.Container, id, config)
    local frame = self.Container:FindFirstChild("Dropdown_" .. id)
    if frame then frame.LayoutOrder = nextOrder(self) end
    return obj
end

function Section:AddInput(id, config)
    local obj = Input.Create(self.Container, id, config)
    local frame = self.Container:FindFirstChild("Input_" .. id)
    if frame then frame.LayoutOrder = nextOrder(self) end
    return obj
end

function Section:AddKeybind(id, config)
    local obj = Keybind.Create(self.Container, id, config)
    local frame = self.Container:FindFirstChild("Keybind_" .. id)
    if frame then frame.LayoutOrder = nextOrder(self) end
    return obj
end

function Section:AddColorpicker(id, config)
    local obj = Colorpicker.Create(self.Container, id, config)
    local frame = self.Container:FindFirstChild("Colorpicker_" .. id)
    if frame then frame.LayoutOrder = nextOrder(self) end
    return obj
end

function Section:AddParagraph(config)
    local paragraph = Paragraph.Create(self.Container, config)
    paragraph.Container.LayoutOrder = nextOrder(self)
    return paragraph
end

function Section:AddDivider()
    local frame = Divider.Create(self.Container)
    frame.LayoutOrder = nextOrder(self)
    return frame
end

return Section
