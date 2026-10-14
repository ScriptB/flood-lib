local Creator      = require(script.Parent.Parent.Creator)
local ThemeManager = require(script.Parent.Parent.Themes.Manager)
local Tween        = require(script.Parent.Parent.Utils.Tween)
local SafeParent   = require(script.Parent.Parent.Utils.SafeParent)
local Drag         = require(script.Parent.Parent.Utils.Drag)
local Tab          = require(script.Parent.Tab)
local FloatingNav  = require(script.Parent.FloatingNav)
local SearchBar    = require(script.Parent.SearchBar)
local EdgeSidebar  = require(script.Parent.EdgeSidebar)
local Dashboard    = require(script.Parent.Dashboard)
local LoadingScreen = require(script.Parent.LoadingScreen)

local MAIN_W   = 620
local MAIN_H   = 420
local TOPBAR_H = 36
local CORNER   = 8
local SEARCH_W = 230
local SEARCH_X = MAIN_W - SEARCH_W - 72
local SEARCH_Y = 5


local Window = {}
Window.__index = Window

local function centerPos()
	return UDim2.fromOffset(
		math.round((workspace.CurrentCamera.ViewportSize.X - MAIN_W) / 2),
		math.round((workspace.CurrentCamera.ViewportSize.Y - MAIN_H) / 2)
	)
end

function Window.new(config)
	local self          = setmetatable({}, Window)
	self._tabs          = {}
	self._visible       = true
	self._minimized     = false
	self._tabCount      = 0

	local t = ThemeManager.CurrentTheme

	local gui = SafeParent.Create("FloodUI")
	self._gui = gui

	local startPos = centerPos()
	local startX   = startPos.X.Offset
	local startY   = startPos.Y.Offset

	local main = Creator.New("Frame", {
		Name                   = "MainFrame",
		Position               = UDim2.fromOffset(startX, startY),
		Size                   = UDim2.fromOffset(MAIN_W, MAIN_H),
		BackgroundColor3       = t.Canvas,
		BackgroundTransparency = 0,
		BorderSizePixel        = 0,
		ZIndex                 = 2,
		ThemeTag               = { BackgroundColor3 = "Canvas" },
		Parent                 = gui,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, CORNER) }),
		Creator.New("UIStroke", {
			Thickness       = 1,
			Color           = t.Border,
			Transparency    = 0.25,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag        = { Color = "Border" },
		}),
	})

	local topBar = Creator.New("Frame", {
		Name                   = "TopBar",
		Size                   = UDim2.new(1, 0, 0, TOPBAR_H),
		BackgroundColor3       = t.TopBar,
		BackgroundTransparency = 0,
		BorderSizePixel        = 0,
		ZIndex                 = 3,
		ThemeTag               = { BackgroundColor3 = "TopBar" },
		Parent                 = main,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, CORNER) }),
		Creator.New("Frame", {
			Name                   = "BottomFill",
			AnchorPoint            = Vector2.new(0, 1),
			Position               = UDim2.new(0, 0, 1, 0),
			Size                   = UDim2.new(1, 0, 0, CORNER),
			BackgroundColor3       = t.TopBar,
			BackgroundTransparency = 0,
			BorderSizePixel        = 0,
			ThemeTag               = { BackgroundColor3 = "TopBar" },
		}),
		Creator.New("Frame", {
			Name                   = "Divider",
			AnchorPoint            = Vector2.new(0, 1),
			Position               = UDim2.new(0, 0, 1, 0),
			Size                   = UDim2.new(1, 0, 0, 1),
			BackgroundColor3       = t.Border,
			BackgroundTransparency = 0.40,
			BorderSizePixel        = 0,
			ThemeTag               = { BackgroundColor3 = "Border" },
		}),
	})

	Creator.New("TextLabel", {
		Name                   = "Title",
		AnchorPoint            = Vector2.new(0, 0.5),
		Position               = UDim2.new(0, 14, 0.5, 0),
		Size                   = UDim2.new(1, -SEARCH_W - 94, 0, 18),
		BackgroundTransparency = 1,
		Text                   = config.Title or "Flood",
		TextSize               = 13,
		FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
		TextColor3             = t.Text,
		TextXAlignment         = Enum.TextXAlignment.Left,
		ZIndex                 = 4,
		ThemeTag               = { TextColor3 = "Text" },
		Parent                 = topBar,
	})

	local function makeMinimizeButton()
		local btn = Creator.New("TextButton", {
			Name                   = "Minimize",
			AnchorPoint            = Vector2.new(1, 0.5),
			Position               = UDim2.new(1, -8, 0.5, 0),
			Size                   = UDim2.fromOffset(28, 24),
			BackgroundColor3       = t.ControlBg,
			BackgroundTransparency = 0.25,
			Text                   = "◀",
			TextSize               = 11,
			FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
			TextColor3             = t.SubText,
			AutoButtonColor        = false,
			BorderSizePixel        = 0,
			ZIndex                 = 4,
			ThemeTag               = { BackgroundColor3 = "ControlBg", TextColor3 = "SubText" },
			Parent                 = topBar,
		}, { Creator.New("UICorner", { CornerRadius = UDim.new(0, 5) }) })
		btn.MouseEnter:Connect(function()
			Tween.Play(btn, Tween.Fast, { BackgroundColor3 = ThemeManager.CurrentTheme.ControlHover, BackgroundTransparency = 0 })
		end)
		btn.MouseLeave:Connect(function()
			Tween.Play(btn, Tween.Fast, { BackgroundColor3 = ThemeManager.CurrentTheme.ControlBg, BackgroundTransparency = 0.25 })
		end)
		return btn
	end

	local minimizeBtn = makeMinimizeButton()

	local content = Creator.New("Frame", {
		Name                   = "ContentContainer",
		Position               = UDim2.fromOffset(0, TOPBAR_H),
		Size                   = UDim2.new(1, 0, 1, -TOPBAR_H),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		ClipsDescendants       = true,
		ZIndex                 = 2,
		Parent                 = main,
	})

	self._gui     = gui
	self._main    = main
	self._topBar  = topBar
	self._content = content
	self.ContentContainer = content
	self.Theme    = t

	local nav = FloatingNav.new(gui, startX, startY, MAIN_H)
	self._nav = nav

	local searchEnabled = config.Search and config.Search.Enabled
	local searchBar= nil
	if searchEnabled then
		searchBar = SearchBar.new(gui, startX + SEARCH_X, startY + SEARCH_Y, SEARCH_W)
		self._searchBar = searchBar
	end

	local sidebar = EdgeSidebar.new(gui, startY, MAIN_H)
	self._sidebar = sidebar
	sidebar:OnRestore(function()
		self:ToggleMinimize()
	end)

	local loadingScreen= nil
	if config.Loading and config.Loading.Enabled then
		loadingScreen = LoadingScreen.new({
			Title  = config.Loading.Title,
			Parent = gui,
		})
		self._loading = loadingScreen
	end

	local function syncPositions()
		local p = main.Position
		local x = p.X.Offset
		local y = p.Y.Offset
		nav:Follow(x, y, MAIN_H)
		if searchBar then
			searchBar:Follow(x + SEARCH_X, y + SEARCH_Y, SEARCH_W)
		end
		sidebar:Reposition(y, MAIN_H)
	end

	local dragHandle = Drag.Attach(topBar, main, function(x, y)
		nav:Follow(x, y, MAIN_H)
		if searchBar then
			searchBar:Follow(x + SEARCH_X, y + SEARCH_Y, SEARCH_W)
		end
		sidebar:Reposition(y, MAIN_H)
	end)
	self._dragHandle = dragHandle

	minimizeBtn.MouseButton1Click:Connect(function()
		self:ToggleMinimize()
	end)

	syncPositions()

	self:_AddDashboard()

	return self
end

function Window:_AddDashboard()
	local dash = Dashboard.new(self._content)
	self._dashboard = dash

	self._nav:AddEntry({
		Id       = "__dashboard",
		Icon     = "⌂",
		Label    = "Home",
		SelectFn = function()
			self:_SelectPage("__dashboard")
		end,
	})
	self._nav:SelectById("__dashboard")
	self._tabCount = self._tabCount + 1
end

function Window:_SelectPage(id)
	if self._dashboard then
		self._dashboard:SetVisible(id == "__dashboard")
	end
	for _, tab in ipairs(self._tabs) do
		tab:SetVisible(tab._id == id)
	end
	self._nav:SelectById(id)
	self._activeId = id
end

function Window:AddTab(config)
	local id  = config.Title
	local tab = Tab.new(self, config)
	tab._id   = id
	table.insert(self._tabs, tab)

	self._nav:AddEntry({
		Id       = id,
		Icon     = config.Icon or string.upper(string.sub(config.Title, 1, 2)),
		Label    = config.Title,
		SelectFn = function()
			self:_SelectPage(id)
		end,
	})

	tab:SetVisible(false)
	return tab
end

function Window:AddQuickAction(entry)
	self._sidebar:AddEntry(entry)
end

function Window:DismissLoading()
	if self._loading then
		self._loading:Dismiss()
		self._loading = nil
	end
end

function Window:SetLoadingStatus(text)
	if self._loading then
		self._loading:SetStatus(text)
	end
end

function Window:Show()
	self._visible = true
	self._gui.Enabled = true
	self._nav:SetVisible(true)
	if self._searchBar then self._searchBar:SetVisible(true) end
end

function Window:Hide()
	self._visible = false
	self._gui.Enabled = false
	self._nav:SetVisible(false)
	if self._searchBar then self._searchBar:SetVisible(false) end
end

function Window:ToggleVisible()
	if self._visible then
		self:Hide()
	else
		self:Show()
	end
end

function Window:ToggleMinimize()
	self._minimized = not self._minimized
	if self._minimized then
		self._main.Visible    = false
		self._nav:SetVisible(false)
		if self._searchBar then self._searchBar:SetVisible(false) end
		self._sidebar:Show()
	else
		self._main.Visible    = true
		self._nav:SetVisible(true)
		if self._searchBar then self._searchBar:SetVisible(true) end
		self._sidebar:Hide()
	end
end

function Window:SelectTab(id)
	self:_SelectPage(id)
end

function Window:GetSearchBar()
	return self._searchBar
end

function Window:Destroy()
	self._dragHandle:Disconnect()
	self._nav:Destroy()
	if self._searchBar then self._searchBar:Destroy() end
	self._sidebar:Destroy()
	if self._loading then self._loading:Dismiss() end
	self._gui:Destroy()
end

return Window
