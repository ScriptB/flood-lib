local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Creator          = require(script.Parent.Parent.Creator)
local ThemeManager     = require(script.Parent.Parent.Themes.Manager)
local Tween            = require(script.Parent.Parent.Utils.Tween)
local Spring           = require(script.Parent.Parent.Utils.Spring)

local BAR_H  = 26
local GAP    = 0
local CORNER = 6


local SearchBar = {}
SearchBar.__index = SearchBar

function SearchBar.new(screenGui, anchorX, anchorY, width)
	local self       = setmetatable({}, SearchBar)
	self._entries    = {}
	self._resultFrames = {}
	self._query      = ""

	local t = ThemeManager.CurrentTheme

	local bar = Creator.New("Frame", {
		Name                   = "SearchBar",
		Position               = UDim2.fromOffset(anchorX, anchorY + GAP),
		Size                   = UDim2.fromOffset(width, BAR_H),
		BackgroundColor3       = t.Panel,
		BackgroundTransparency = 0,
		BorderSizePixel        = 0,
		ZIndex                 = 4,
		ThemeTag               = { BackgroundColor3 = "Panel" },
		Parent                 = screenGui,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, CORNER) }),
		Creator.New("UIStroke", {
			Thickness       = 1,
			Color           = t.Border,
			Transparency    = 0.40,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag        = { Color = "Border" },
		}),
	})

	local iconLbl = Creator.New("TextLabel", {
		Name                   = "Icon",
		AnchorPoint            = Vector2.new(0, 0.5),
		Position               = UDim2.new(0, 8, 0.5, 0),
		Size                   = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Text                   = "⌕",
		TextSize               = 11,
		FontFace               = Font.fromEnum(Enum.Font.Gotham),
		TextColor3             = t.SubText,
		ZIndex                 = 5,
		ThemeTag               = { TextColor3 = "SubText" },
		Parent                 = bar,
	})
	_ = iconLbl

	local input = Creator.New("TextBox", {
		Name                        = "Input",
		AnchorPoint                 = Vector2.new(0, 0.5),
		Position                    = UDim2.new(0, 26, 0.5, 0),
		Size                        = UDim2.new(1, -34, 0, 18),
		BackgroundTransparency      = 1,
		Text                        = "",
		PlaceholderText             = "Search",
		PlaceholderColor3           = t.TextDisabled,
		TextSize                    = 10,
		FontFace                    = Font.fromEnum(Enum.Font.Gotham),
		TextColor3                  = t.Text,
		TextXAlignment              = Enum.TextXAlignment.Left,
		ClearTextOnFocus            = false,
		ZIndex                      = 5,
		ThemeTag                    = { TextColor3 = "Text", PlaceholderColor3 = "TextDisabled" },
		Parent                      = bar,
	})

	local resultsFrame = Creator.New("Frame", {
		Name                   = "Results",
		AnchorPoint            = Vector2.new(0, 0),
		Position               = UDim2.new(0, 0, 1, 4),
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		BackgroundColor3       = t.Panel,
		BackgroundTransparency = 0.04,
		BorderSizePixel        = 0,
		ZIndex                 = 6,
		Visible                = false,
		ClipsDescendants       = true,
		ThemeTag               = { BackgroundColor3 = "Panel" },
		Parent                 = bar,
	}, {
		Creator.New("UICorner",    { CornerRadius = UDim.new(0, CORNER) }),
		Creator.New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding   = UDim.new(0, 1),
		}),
		Creator.New("UIStroke", {
			Thickness       = 1,
			Color           = t.Border,
			Transparency    = 0.40,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag        = { Color = "Border" },
		}),
	})

	self._bar          = bar
	self._input        = input
	self._resultsFrame = resultsFrame

	local sprX = Spring.new(bar.Position.X.Offset, 18, 0.80)
	local sprY = Spring.new(bar.Position.Y.Offset, 18, 0.80)
	self._sprX = sprX
	self._sprY = sprY

	local heartbeat = RunService.Heartbeat:Connect(function(dt)
		sprX:Step(dt)
		sprY:Step(dt)
		local x = math.round(sprX.Position)
		local y = math.round(sprY.Position)
		bar.Position = UDim2.fromOffset(x, y)
	end)
	self._heartbeat = heartbeat

	input:GetPropertyChangedSignal("Text"):Connect(function()
		self:_Refresh(input.Text)
	end)

	input.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			self:_SelectFirst()
		end
		task.delay(0.15, function()
			if not input:IsFocused() then
				resultsFrame.Visible = false
			end
		end)
	end)

	input.Focused:Connect(function()
		if self._query ~= "" then
			resultsFrame.Visible = true
		end
	end)

	UserInputService.InputBegan:Connect(function(inp, processed)
		if processed then return end
		if inp.KeyCode == Enum.KeyCode.Slash then
			input:CaptureFocus()
		end
	end)

	return self
end

function SearchBar:_ClearResults()
	for _, f in ipairs(self._resultFrames) do
		f:Destroy()
	end
	self._resultFrames = {}
end

function SearchBar:_Refresh(query)
	self._query = query
	self:_ClearResults()

	if query == "" then
		self._resultsFrame.Visible = false
		return
	end

	local lower = string.lower(query)
	local matches= {}
	for _, e in ipairs(self._entries) do
		if string.find(string.lower(e.Label), lower, 1, true) then
			table.insert(matches, e)
			if #matches >= 6 then break end
		end
	end

	if #matches == 0 then
		self._resultsFrame.Visible = false
		return
	end

	local t = ThemeManager.CurrentTheme
	for i, entry in ipairs(matches) do
		local row = Creator.New("TextButton", {
			Name                   = "Row_" .. entry.Id,
			LayoutOrder            = i,
			Size                   = UDim2.new(1, 0, 0, 28),
			BackgroundColor3       = t.ControlBg,
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			BorderSizePixel        = 0,
			ZIndex                 = 7,
			Parent                 = self._resultsFrame,
		})

		Creator.New("TextLabel", {
			AnchorPoint            = Vector2.new(0, 0.5),
			Position               = UDim2.new(0, 12, 0.5, 0),
			Size                   = UDim2.new(1, -12, 0, 14),
			BackgroundTransparency = 1,
			Text                   = entry.Label,
			TextSize               = 10,
			FontFace               = Font.fromEnum(Enum.Font.Gotham),
			TextColor3             = t.Text,
			TextXAlignment         = Enum.TextXAlignment.Left,
			ZIndex                 = 7,
			ThemeTag               = { TextColor3 = "Text" },
			Parent                 = row,
		})

		row.MouseEnter:Connect(function()
			Tween.Play(row, Tween.Fast, { BackgroundTransparency = 0.60 })
		end)
		row.MouseLeave:Connect(function()
			Tween.Play(row, Tween.Fast, { BackgroundTransparency = 1 })
		end)
		row.MouseButton1Click:Connect(function()
			self._resultsFrame.Visible = false
			self._input.Text           = ""
			self._query                = ""
			entry.SelectFn()
		end)

		table.insert(self._resultFrames, row)
	end

	self._resultsFrame.Visible = true
end

function SearchBar:_SelectFirst()
	if #self._resultFrames > 0 then
		(self._resultFrames[1]).MouseButton1Click:Fire()
	end
end

function SearchBar:RegisterElement(entry)
	table.insert(self._entries, entry)
end

function SearchBar:Follow(x, y, width)
	self._sprX:SetTarget(x)
	self._sprY:SetTarget(y + GAP)
	self._bar.Size = UDim2.fromOffset(width, BAR_H)
end

function SearchBar:SetVisible(visible)
	self._bar.Visible = visible
	if not visible then
		self._resultsFrame.Visible = false
	end
end

function SearchBar:Destroy()
	self._heartbeat:Disconnect()
	self._bar:Destroy()
end

return SearchBar
