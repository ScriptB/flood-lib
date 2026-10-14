--!strict
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

function Section.new(parent: Instance, title: string?)
    local self = setmetatable({}, Section)
    local theme = ThemeManager.CurrentTheme

    local panel = Creator.New("Frame", {
        Name = "Panel_" .. (title or "Group"),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = theme.Card,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        ThemeTag = { BackgroundColor3 = "Card" },
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
    })

    if title and title ~= "" then
        Creator.New("TextLabel", {
            Name = "Header",
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            LayoutOrder = 0,
            Text = title,
            TextSize = 9,
            FontFace = Font.fromEnum(Enum.Font.Gotham),
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

local function nextOrder(self: any): number
    self._order = self._order + 1
    return self._order
end

function Section:AddToggle(id: string, config: { Title: string, Default: boolean?, Callback: ((boolean) -> ())? })
    local obj = Toggle.Create(self.Container, id, config)
    local frame = self.Container:FindFirstChild("Toggle_" .. id) :: Frame?
    if frame then frame.LayoutOrder = nextOrder(self) end
    return obj
end

function Section:AddSlider(id: string, config: { Title: string, Min: number, Max: number, Default: number?, Rounding: number?, Suffix: string?, Callback: ((number) -> ())? })
    local obj = Slider.Create(self.Container, id, config)
    local frame = self.Container:FindFirstChild("Slider_" .. id) :: Frame?
    if frame then frame.LayoutOrder = nextOrder(self) end
    return obj
end

function Section:AddButton(config: { Title: string, Description: string?, Callback: (() -> ())? })
    local frame = Button.Create(self.Container, config)
    frame.LayoutOrder = nextOrder(self)
    return frame
end

function Section:AddDropdown(id: string, config: { Title: string, Values: { string }, Default: string?, Callback: ((string) -> ())? })
    local obj = Dropdown.Create(self.Container, id, config)
    local frame = self.Container:FindFirstChild("Dropdown_" .. id) :: Frame?
    if frame then frame.LayoutOrder = nextOrder(self) end
    return obj
end

function Section:AddInput(id: string, config: { Title: string, Default: string?, Placeholder: string?, Callback: ((string) -> ())? })
    local obj = Input.Create(self.Container, id, config)
    local frame = self.Container:FindFirstChild("Input_" .. id) :: Frame?
    if frame then frame.LayoutOrder = nextOrder(self) end
    return obj
end

function Section:AddKeybind(id: string, config: { Title: string, Default: Enum.KeyCode?, Callback: ((Enum.KeyCode) -> ())? })
    local obj = Keybind.Create(self.Container, id, config)
    local frame = self.Container:FindFirstChild("Keybind_" .. id) :: Frame?
    if frame then frame.LayoutOrder = nextOrder(self) end
    return obj
end

function Section:AddColorpicker(id: string, config: { Title: string, Default: Color3?, Callback: ((Color3) -> ())? })
    local obj = Colorpicker.Create(self.Container, id, config)
    local frame = self.Container:FindFirstChild("Colorpicker_" .. id) :: Frame?
    if frame then frame.LayoutOrder = nextOrder(self) end
    return obj
end

function Section:AddParagraph(config: { Title: string, Content: string })
    local frame = Paragraph.Create(self.Container, config)
    frame.LayoutOrder = nextOrder(self)
    return frame
end

function Section:AddDivider()
    local frame = Divider.Create(self.Container)
    frame.LayoutOrder = nextOrder(self)
    return frame
end

return Section
