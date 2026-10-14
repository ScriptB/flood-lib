local Creator = require(script.Parent.Parent.Creator)
local Section = require(script.Parent.Section)
local Tween   = require(script.Parent.Parent.Utils.Tween)

local Tab = {}
Tab.__index = Tab

function Tab.new(window, config)
	local self   = setmetatable({}, Tab)
	self.Window  = window
	self.Title   = config.Title
	self._id     = config.Title
	self.Active  = false
	self._sectionCount = 0

	local t = window.Theme

	local page = Creator.New("Frame", {
		Name                   = "TabPage_" .. config.Title,
		Size                   = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Visible                = false,
		Parent                 = window.ContentContainer,
	})

	local cols = Creator.New("Frame", {
		Name                   = "Columns",
		Size                   = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Parent                 = page,
	}, {
		Creator.New("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder     = Enum.SortOrder.LayoutOrder,
			Padding       = UDim.new(0, 8),
		}),
		Creator.New("UIPadding", {
			PaddingLeft   = UDim.new(0, 10),
			PaddingRight  = UDim.new(0, 10),
			PaddingTop    = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),
	})

	local leftCol = Creator.New("ScrollingFrame", {
		Name                       = "LeftCol",
		LayoutOrder                = 1,
		Size                       = UDim2.new(0.5, -4, 1, 0),
		BackgroundTransparency     = 1,
		BorderSizePixel            = 0,
		ScrollBarThickness         = 3,
		ScrollBarImageColor3       = t.Border,
		AutomaticCanvasSize        = Enum.AutomaticSize.Y,
		CanvasSize                 = UDim2.fromScale(0, 0),
		ThemeTag                   = { ScrollBarImageColor3 = "Border" },
		Parent                     = cols,
	}, {
		Creator.New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding   = UDim.new(0, 8),
		}),
	})

	local rightCol = Creator.New("ScrollingFrame", {
		Name                       = "RightCol",
		LayoutOrder                = 2,
		Size                       = UDim2.new(0.5, -4, 1, 0),
		BackgroundTransparency     = 1,
		BorderSizePixel            = 0,
		ScrollBarThickness         = 3,
		ScrollBarImageColor3       = t.Border,
		AutomaticCanvasSize        = Enum.AutomaticSize.Y,
		CanvasSize                 = UDim2.fromScale(0, 0),
		ThemeTag                   = { ScrollBarImageColor3 = "Border" },
		Parent                     = cols,
	}, {
		Creator.New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding   = UDim.new(0, 8),
		}),
	})

	self._page     = page
	self._leftCol  = leftCol
	self._rightCol = rightCol

	return self
end

function Tab:AddSection(title, column)
	self._sectionCount = self._sectionCount + 1
	local col = column == 2 and self._rightCol or self._leftCol
	local sec = Section.new(col, title)
	sec.Container.LayoutOrder = self._sectionCount
	return sec
end

function Tab:AddLeftSection(title)
	return self:AddSection(title, 1)
end

function Tab:AddRightSection(title)
	return self:AddSection(title, 2)
end

function Tab:SetVisible(visible)
	self._page.Visible = visible
	self.Active = visible
end

function Tab:Activate()
	self:SetVisible(true)
end

function Tab:Deactivate()
	self:SetVisible(false)
end

function Tab:Destroy()
	self._page:Destroy()
end

return Tab
