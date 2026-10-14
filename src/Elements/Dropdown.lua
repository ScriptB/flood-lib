local Creator      = require(script.Parent.Parent.Creator)
local ThemeManager = require(script.Parent.Parent.Themes.Manager)
local Tween        = require(script.Parent.Parent.Utils.Tween)
local Signal       = require(script.Parent.Parent.Utils.Signal)

local Dropdown = {}

function Dropdown.Create(parent, id, config)
	local values    = config.Values or {}
	local selected  = config.Default or (values[1] or "")
	local opened    = false
	local onChanged = Signal.new()
	local theme     = ThemeManager.CurrentTheme

	local container = Creator.New("Frame", {
		Name             = "Dropdown_" .. id,
		Size             = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = theme.ControlBg,
		BorderSizePixel  = 0,
		ThemeTag         = { BackgroundColor3 = "ControlBg" },
		Parent           = parent,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 5) }),
		Creator.New("UIStroke", {
			Thickness       = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color           = theme.Border,
			ThemeTag        = { Color = "Border" },
		}),
	})

	local header = Creator.New("TextButton", {
		Name                   = "Header",
		Size                   = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		Text                   = "",
		Parent                 = container,
	}, {
		Creator.New("TextLabel", {
			Name                   = "Title",
			Position               = UDim2.fromOffset(9, 0),
			Size                   = UDim2.new(1, -96, 1, 0),
			BackgroundTransparency = 1,
			Text                   = config.Title,
			TextSize               = 11,
			FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
			TextXAlignment         = Enum.TextXAlignment.Left,
			TextColor3             = theme.Text,
			ThemeTag               = { TextColor3 = "Text" },
		}),
	})

	local valueBadge = Creator.New("Frame", {
		Name             = "ValueBadge",
		AnchorPoint      = Vector2.new(1, 0.5),
		Position         = UDim2.new(1, -9, 0.5, 0),
		Size             = UDim2.fromOffset(80, 18),
		BackgroundColor3 = theme.BadgeBg,
		BorderSizePixel  = 0,
		Parent           = header,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 3) }),
		Creator.New("TextLabel", {
			Name                   = "SelectedText",
			Position               = UDim2.fromOffset(6, 0),
			Size                   = UDim2.new(1, -20, 1, 0),
			BackgroundTransparency = 1,
			Text                   = selected,
			TextSize               = 10,
			FontFace               = Font.fromEnum(Enum.Font.Gotham),
			TextXAlignment         = Enum.TextXAlignment.Left,
			TextColor3             = theme.SubText,
			TextTruncate           = Enum.TextTruncate.AtEnd,
			ThemeTag               = { TextColor3 = "SubText" },
		}),
		Creator.New("TextLabel", {
			Name                   = "Chevron",
			AnchorPoint            = Vector2.new(1, 0.5),
			Position               = UDim2.new(1, -4, 0.5, 0),
			Size                   = UDim2.fromOffset(10, 10),
			BackgroundTransparency = 1,
			Text                   = "▾",
			TextSize               = 9,
			FontFace               = Font.fromEnum(Enum.Font.Gotham),
			TextColor3             = theme.SubText,
			ThemeTag               = { TextColor3 = "SubText" },
		}),
	})

	-- Overlay list: parented to ScreenGui to avoid clipping by ScrollingFrame
	local optionListHeight = #values * 22 + 8
	local overlayList= nil

	local dropdownObj = {
		Value     = selected,
		OnChanged = onChanged,
	}

	local selectedLabel = valueBadge:FindFirstChild("SelectedText")

	local function closeList()
		opened = false
		if overlayList then
			local ol = overlayList
			Tween.Play(ol, Tween.Fast, { Size = UDim2.fromOffset(ol.Size.X.Offset, 0) })
			task.delay(0.16, function()
				if not opened then
					ol.Visible = false
				end
			end)
		end
		local chevron = valueBadge:FindFirstChild("Chevron")
		if chevron then
			Tween.Play(chevron, Tween.Fast, { Rotation = 0 })
		end
	end

	local function selectValue(val)
		selected = val
		dropdownObj.Value = val
		selectedLabel.Text = val
		onChanged:Fire(val)
		if config.Callback then task.spawn(config.Callback, val) end
		closeList()
	end
	dropdownObj.SetValue = selectValue

	local function buildOverlay()
		local screenGui = container:FindFirstAncestorOfClass("ScreenGui")
		if not screenGui then return end

		if overlayList then
			overlayList:Destroy()
			overlayList = nil
		end

		local abs  = container.AbsolutePosition
		local absW = container.AbsoluteSize.X

		local ol = Creator.New("Frame", {
			Name             = "DropOverlay_" .. id,
			Position         = UDim2.fromOffset(abs.X, abs.Y + 28),
			Size             = UDim2.fromOffset(absW, 0),
			BackgroundColor3 = theme.Panel,
			BorderSizePixel  = 0,
			ZIndex           = 50,
			ClipsDescendants = true,
			Parent           = screenGui,
		}, {
			Creator.New("UICorner", { CornerRadius = UDim.new(0, 5) }),
			Creator.New("UIStroke", {
				Thickness       = 1,
				Color           = theme.Border,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Creator.New("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding   = UDim.new(0, 2),
			}),
			Creator.New("UIPadding", {
				PaddingTop    = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
				PaddingLeft   = UDim.new(0, 4),
				PaddingRight  = UDim.new(0, 4),
			}),
		})

		for _, val in ipairs(values) do
			local isSelected = val == selected
			local optBtn = Creator.New("TextButton", {
				Size                   = UDim2.new(1, 0, 0, 22),
				BackgroundColor3       = (function() if isSelected then return theme.AccentMuted else return theme.ControlBg end end)(),
				BackgroundTransparency = (function() if isSelected then return 0.6 else return 1 end end)(),
				Text                   = "",
				AutoButtonColor        = false,
				ZIndex                 = 51,
				Parent                 = ol,
			}, {
				Creator.New("UICorner", { CornerRadius = UDim.new(0, 3) }),
				Creator.New("TextLabel", {
					Position               = UDim2.fromOffset(8, 0),
					Size                   = UDim2.new(1, -20, 1, 0),
					BackgroundTransparency = 1,
					Text                   = val,
					TextSize               = 10,
					FontFace               = Font.fromEnum(Enum.Font.Gotham),
					TextXAlignment         = Enum.TextXAlignment.Left,
					TextColor3             = (function() if isSelected then return theme.Text else return theme.SubText end end)(),
					ZIndex                 = 51,
				}),
			})

			if isSelected then
				Creator.New("TextLabel", {
					AnchorPoint            = Vector2.new(1, 0.5),
					Position               = UDim2.new(1, -6, 0.5, 0),
					Size                   = UDim2.fromOffset(10, 10),
					BackgroundTransparency = 1,
					Text                   = "✓",
					TextSize               = 9,
					FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
					TextColor3             = theme.Accent,
					ZIndex                 = 51,
					Parent                 = optBtn,
				})
			end

			optBtn.MouseEnter:Connect(function()
				Tween.Play(optBtn, Tween.Fast, {
					BackgroundTransparency = 0,
					BackgroundColor3       = theme.ControlBg,
				})
			end)
			optBtn.MouseLeave:Connect(function()
				local tp
				if val == selected then tp = 0.6 else tp = 1 end
				Tween.Play(optBtn, Tween.Fast, { BackgroundTransparency = tp })
			end)
			optBtn.MouseButton1Click:Connect(function()
				selectValue(val)
			end)
		end

		overlayList = ol
		Tween.Play(ol, Tween.Settle, { Size = UDim2.fromOffset(absW, optionListHeight) })
	end

	header.MouseEnter:Connect(function()
		Tween.Play(container, Tween.Fast, { BackgroundColor3 = theme.ControlHover })
	end)
	header.MouseLeave:Connect(function()
		Tween.Play(container, Tween.Fast, { BackgroundColor3 = theme.ControlBg })
	end)

	header.MouseButton1Click:Connect(function()
		if opened then
			closeList()
		else
			opened = true
			local chevron = valueBadge:FindFirstChild("Chevron")
			if chevron then Tween.Play(chevron, Tween.Fast, { Rotation = 180 }) end
			buildOverlay()
		end
	end)

	return dropdownObj
end

return Dropdown
