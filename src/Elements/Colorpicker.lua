--!strict
local UserInputService = game:GetService("UserInputService")
local Creator          = require(script.Parent.Parent.Creator)
local ThemeManager     = require(script.Parent.Parent.Themes.Manager)
local Tween            = require(script.Parent.Parent.Utils.Tween)
local Signal           = require(script.Parent.Parent.Utils.Signal)

local HUE_STOPS = {
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(255,   0,   0)),
    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255,   0)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(  0, 255,   0)),
    ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(  0, 255, 255)),
    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(  0,   0, 255)),
    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,   0, 255)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(255,   0,   0)),
}

local function clamp01(v: number): number
    return math.clamp(v, 0, 1)
end

local function relativePos(inputPos: Vector3, frame: Frame): Vector2
    return Vector2.new(
        clamp01((inputPos.X - frame.AbsolutePosition.X) / frame.AbsoluteSize.X),
        clamp01((inputPos.Y - frame.AbsolutePosition.Y) / frame.AbsoluteSize.Y)
    )
end

local function hexFromColor(c: Color3): string
    return string.format("#%02X%02X%02X",
        math.floor(c.R * 255 + 0.5),
        math.floor(c.G * 255 + 0.5),
        math.floor(c.B * 255 + 0.5)
    )
end

local function colorFromHex(hex: string): Color3?
    hex = hex:gsub("^#", "")
    if #hex == 3 then
        hex = hex:gsub("(.)", "%1%1")
    end
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if not (r and g and b) then return nil end
    return Color3.fromRGB(r, g, b)
end

local Colorpicker = {}

function Colorpicker.Create(parent: Instance, id: string, config: { Title: string, Default: Color3?, Callback: ((Color3) -> ())? })
    local initColor = config.Default or Color3.fromRGB(0, 168, 255)
    local h, s, v   = Color3.toHSV(initColor)
    local alpha      = 1
    local onChanged  = Signal.new()
    local theme      = ThemeManager.CurrentTheme
    local pickerOpen = false

    local svDragging  = false
    local hueDragging = false
    local aDragging   = false

    -- =========================================================================
    -- HEADER ROW (28px, always visible)
    -- =========================================================================
    local outerFrame = Creator.New("Frame", {
        Name = "Colorpicker_" .. id,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = theme.ControlBg,
        BorderSizePixel = 0,
        ThemeTag = { BackgroundColor3 = "ControlBg" },
        Parent = parent,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) }),
        Creator.New("UIStroke", {
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = theme.Border,
            ThemeTag = { Color = "Border" },
        }),
    })

    local headerRow = Creator.New("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Parent = outerFrame,
    })

    Creator.New("TextLabel", {
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.new(1, -50, 1, 0),
        BackgroundTransparency = 1,
        Text = config.Title,
        TextSize = 11,
        FontFace = Font.fromEnum(Enum.Font.GothamMedium),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = theme.Text,
        ThemeTag = { TextColor3 = "Text" },
        Parent = headerRow,
    })

    local swatch = Creator.New("TextButton", {
        Name = "Swatch",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(28, 16),
        BackgroundColor3 = initColor,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = headerRow,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 3) }),
        Creator.New("UIStroke", { Thickness = 1, Color = theme.Border, ThemeTag = { Color = "Border" } }),
    }) :: TextButton

    -- =========================================================================
    -- PICKER PANEL (hidden until swatch clicked, 168px tall)
    -- =========================================================================
    local PICKER_H = 168
    local SV_H     = 110

    local pickerPanel = Creator.New("Frame", {
        Name = "PickerPanel",
        Position = UDim2.fromOffset(0, 28),
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        BackgroundTransparency = 1,
        Parent = outerFrame,
    })

    local pickerInner = Creator.New("Frame", {
        Name = "Inner",
        Size = UDim2.new(1, 0, 0, PICKER_H),
        BackgroundTransparency = 1,
        Parent = pickerPanel,
    }, {
        Creator.New("UIPadding", {
            PaddingTop    = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft   = UDim.new(0, 8),
            PaddingRight  = UDim.new(0, 8),
        }),
        Creator.New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 4),
        }),
    })

    -- SV Square
    local svSquare = Creator.New("Frame", {
        Name = "SVSquare",
        Size = UDim2.new(1, 0, 0, SV_H),
        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        BorderSizePixel = 0,
        LayoutOrder = 1,
        Parent = pickerInner,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) }),
        Creator.New("Frame", {
            Name = "SatOverlay",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
        }, {
            Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) }),
            Creator.New("UIGradient", {
                Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Rotation = 0,
            }),
        }),
        Creator.New("Frame", {
            Name = "ValOverlay",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
        }, {
            Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) }),
            Creator.New("UIGradient", {
                Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(0, 0, 0)),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                }),
                Rotation = 90,
            }),
        }),
        Creator.New("TextButton", {
            Name = "SVInput",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
        }),
    }) :: Frame

    local svCursor = Creator.New("Frame", {
        Name = "SVCursor",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(s, 0, 1 - v, 0),
        Size = UDim2.fromOffset(8, 8),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = svSquare.ZIndex + 10,
        Parent = svSquare,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
        Creator.New("UIStroke", { Thickness = 1.5, Color = Color3.fromRGB(0, 0, 0) }),
    })

    -- Hue Strip
    local hueStrip = Creator.New("Frame", {
        Name = "HueStrip",
        Size = UDim2.new(1, 0, 0, 10),
        BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        BorderSizePixel = 0,
        LayoutOrder = 2,
        Parent = pickerInner,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
        Creator.New("UIGradient", { Color = ColorSequence.new(HUE_STOPS) }),
        Creator.New("TextButton", { Name = "HueInput", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }),
    }) :: Frame

    local hueCursor = Creator.New("Frame", {
        Name = "HueCursor",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(h, 0, 0.5, 0),
        Size = UDim2.fromOffset(4, 14),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = hueStrip.ZIndex + 5,
        Parent = hueStrip,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 2) }),
        Creator.New("UIStroke", { Thickness = 1, Color = Color3.fromRGB(0, 0, 0) }),
    })

    -- Alpha Strip
    local alphaStrip = Creator.New("Frame", {
        Name = "AlphaStrip",
        Size = UDim2.new(1, 0, 0, 10),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        LayoutOrder = 3,
        Parent = pickerInner,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
        Creator.New("UIGradient", {
            Color = ColorSequence.new(Color3.fromHSV(h, s, v), Color3.fromHSV(h, s, v)),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            }),
        }),
        Creator.New("TextButton", { Name = "AlphaInput", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }),
    }) :: Frame

    local alphaCursor = Creator.New("Frame", {
        Name = "AlphaCursor",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(alpha, 0, 0.5, 0),
        Size = UDim2.fromOffset(4, 14),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = alphaStrip.ZIndex + 5,
        Parent = alphaStrip,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 2) }),
        Creator.New("UIStroke", { Thickness = 1, Color = Color3.fromRGB(0, 0, 0) }),
    })

    -- Bottom row: hex input + preview
    local bottomRow = Creator.New("Frame", {
        Name = "BottomRow",
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        LayoutOrder = 4,
        Parent = pickerInner,
    })

    local hexBox = Creator.New("TextBox", {
        Name = "HexBox",
        Position = UDim2.fromOffset(0, 2),
        Size = UDim2.new(1, -36, 0, 18),
        BackgroundColor3 = theme.ControlBg,
        BorderSizePixel = 0,
        Text = hexFromColor(initColor),
        PlaceholderText = "#RRGGBB",
        TextSize = 10,
        FontFace = Font.fromEnum(Enum.Font.Gotham),
        TextColor3 = theme.Text,
        PlaceholderColor3 = theme.TextDisabled,
        ClearTextOnFocus = false,
        ThemeTag = { BackgroundColor3 = "ControlBg", TextColor3 = "Text" },
        Parent = bottomRow,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 3) }),
        Creator.New("UIStroke", { Thickness = 1, Color = theme.Border, ThemeTag = { Color = "Border" } }),
        Creator.New("UIPadding", { PaddingLeft = UDim.new(0, 6) }),
    }) :: TextBox

    local previewSwatch = Creator.New("Frame", {
        Name = "Preview",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(28, 18),
        BackgroundColor3 = initColor,
        BorderSizePixel = 0,
        Parent = bottomRow,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 3) }),
        Creator.New("UIStroke", { Thickness = 1, Color = theme.Border, ThemeTag = { Color = "Border" } }),
    }) :: Frame

    -- =========================================================================
    -- STATE UPDATE HELPERS
    -- =========================================================================
    local colorObj = {
        Value    = initColor,
        OnChanged = onChanged,
    }

    local function applyColor()
        local color = Color3.fromHSV(h, s, v)
        colorObj.Value = color
        swatch.BackgroundColor3       = color
        previewSwatch.BackgroundColor3 = color
        svSquare.BackgroundColor3      = Color3.fromHSV(h, 1, 1)

        local alphaGrad = alphaStrip:FindFirstChildOfClass("UIGradient") :: UIGradient?
        if alphaGrad then
            alphaGrad.Color = ColorSequence.new(Color3.fromHSV(h, s, v), Color3.fromHSV(h, s, v))
        end

        hexBox.Text = hexFromColor(color)
        onChanged:Fire(color)
        if config.Callback then task.spawn(config.Callback, color) end
    end

    local function updateSVCursor()
        svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
    end

    local function updateHueCursor()
        hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
    end

    local function updateAlphaCursor()
        alphaCursor.Position = UDim2.new(alpha, 0, 0.5, 0)
    end

    function colorObj:SetValue(newColor: Color3)
        local nh, ns, nv = Color3.toHSV(newColor)
        h, s, v = nh, ns, nv
        updateSVCursor()
        updateHueCursor()
        applyColor()
    end

    -- =========================================================================
    -- PICKER TOGGLE
    -- =========================================================================
    swatch.MouseButton1Click:Connect(function()
        pickerOpen = not pickerOpen
        local targetH = pickerOpen and PICKER_H or 0
        local totalH  = pickerOpen and (28 + PICKER_H) or 28
        Tween.Play(pickerPanel, Tween.Smooth, { Size = UDim2.new(1, 0, 0, targetH) })
        Tween.Play(outerFrame, Tween.Smooth, { Size = UDim2.new(1, 0, 0, totalH) })
    end)

    -- =========================================================================
    -- SV SQUARE DRAG
    -- =========================================================================
    local svInput = svSquare:FindFirstChild("SVInput") :: TextButton
    svInput.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            svDragging = true
            local rel = relativePos(inp.Position, svSquare)
            s = rel.X; v = 1 - rel.Y
            updateSVCursor(); applyColor()
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if svDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = relativePos(inp.Position, svSquare)
            s = rel.X; v = 1 - rel.Y
            updateSVCursor(); applyColor()
        elseif hueDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = relativePos(inp.Position, hueStrip)
            h = rel.X
            updateHueCursor(); applyColor()
        elseif aDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = relativePos(inp.Position, alphaStrip)
            alpha = rel.X
            updateAlphaCursor()
        end
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            svDragging  = false
            hueDragging = false
            aDragging   = false
        end
    end)

    -- =========================================================================
    -- HUE STRIP DRAG
    -- =========================================================================
    local hueInput = hueStrip:FindFirstChild("HueInput") :: TextButton
    hueInput.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            hueDragging = true
            local rel = relativePos(inp.Position, hueStrip)
            h = rel.X
            updateHueCursor(); applyColor()
        end
    end)

    -- =========================================================================
    -- ALPHA STRIP DRAG
    -- =========================================================================
    local alphaInput = alphaStrip:FindFirstChild("AlphaInput") :: TextButton
    alphaInput.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            aDragging = true
            local rel = relativePos(inp.Position, alphaStrip)
            alpha = rel.X
            updateAlphaCursor()
        end
    end)

    -- =========================================================================
    -- HEX INPUT
    -- =========================================================================
    hexBox.FocusLost:Connect(function()
        local parsed = colorFromHex(hexBox.Text)
        if parsed then
            colorObj:SetValue(parsed)
        else
            hexBox.Text = hexFromColor(Color3.fromHSV(h, s, v))
        end
    end)

    return colorObj
end

return Colorpicker
