local ThemeManager   = require(script.Themes.Manager)
local Window         = require(script.Components.Window)
local Notification   = require(script.Components.Notification)

local Library = {
	Flags   = {},
	Options = {},
	Themes  = ThemeManager.Themes,
}

local function bindFlag(lib, id, obj)
	if obj and obj.OnChanged then
		lib.Flags[id] = obj.Value
		obj.OnChanged:Connect(function(v)
			lib.Flags[id] = v
		end)
	end
end

local function makeSecApi(lib, sec, searchBar)
	local secApi = {}

	function secApi:AddToggle(id, cfg)
		local obj = sec:AddToggle(id, cfg)
		bindFlag(lib, id, obj)
		lib.Options[id] = obj
		if searchBar then
			searchBar:RegisterElement({ Id = id, Label = cfg.Title, TabId = "", SelectFn = function() end })
		end
		return obj
	end

	function secApi:AddSlider(id, cfg)
		local obj = sec:AddSlider(id, cfg)
		bindFlag(lib, id, obj)
		lib.Options[id] = obj
		if searchBar then
			searchBar:RegisterElement({ Id = id, Label = cfg.Title, TabId = "", SelectFn = function() end })
		end
		return obj
	end

	function secApi:AddButton(cfg)
		local obj = sec:AddButton(cfg)
		if searchBar then
			searchBar:RegisterElement({ Id = cfg.Title, Label = cfg.Title, TabId = "", SelectFn = cfg.Callback or function() end })
		end
		return obj
	end

	function secApi:AddDropdown(id, cfg)
		local obj = sec:AddDropdown(id, cfg)
		bindFlag(lib, id, obj)
		lib.Options[id] = obj
		if searchBar then
			searchBar:RegisterElement({ Id = id, Label = cfg.Title, TabId = "", SelectFn = function() end })
		end
		return obj
	end

	function secApi:AddInput(id, cfg)
		local obj = sec:AddInput(id, cfg)
		bindFlag(lib, id, obj)
		lib.Options[id] = obj
		return obj
	end

	function secApi:AddKeybind(id, cfg)
		local obj = sec:AddKeybind(id, cfg)
		bindFlag(lib, id, obj)
		lib.Options[id] = obj
		return obj
	end

	function secApi:AddColorpicker(id, cfg)
		local obj = sec:AddColorpicker(id, cfg)
		bindFlag(lib, id, obj)
		lib.Options[id] = obj
		return obj
	end

	function secApi:AddParagraph(cfg)
		return sec:AddParagraph(cfg)
	end

	function secApi:AddDivider()
		return sec:AddDivider()
	end

	return secApi
end

local function makeTabApi(lib, tab, searchBar)
	local tabApi = {}

	function tabApi:AddSection(title, column)
		local sec = tab:AddSection(title, column)
		return makeSecApi(lib, sec, searchBar)
	end

	function tabApi:AddLeftSection(title)
		return tabApi:AddSection(title, 1)
	end

	function tabApi:AddRightSection(title)
		return tabApi:AddSection(title, 2)
	end

	return tabApi
end

function Library:CreateWindow(config)
	if config.Theme then
		ThemeManager.SetTheme(config.Theme)
	end

	local win        = Window.new(config)
	local searchBar  = win:GetSearchBar()
	Notification.Init(win._gui)

	local winApi = {}

	function winApi:AddTab(tabConfig)
		local tab = win:AddTab(tabConfig)
		return makeTabApi(Library, tab, searchBar)
	end

	function winApi:AddQuickAction(entry)
		win:AddQuickAction(entry)
	end

	function winApi:SelectTab(id)
		win:SelectTab(id)
	end

	function winApi:DismissLoading()
		win:DismissLoading()
	end

	function winApi:SetLoadingStatus(text)
		win:SetLoadingStatus(text)
	end

	function winApi:SetVisible(visible)
		if visible then win:Show() else win:Hide() end
	end

	function winApi:Toggle()
		win:ToggleVisible()
	end

	function winApi:ToggleMinimize()
		win:ToggleMinimize()
	end

	function winApi:Unload()
		win:Destroy()
	end

	function winApi:Destroy()
		win:Destroy()
	end

	return winApi
end

function Library:SetTheme(name)
	ThemeManager.SetTheme(name)
	self.Themes = ThemeManager.Themes
end

function Library:GetTheme()
	return ThemeManager.CurrentTheme
end

function Library:GetThemeName()
	return ThemeManager.CurrentThemeName
end

function Library:RegisterTheme(name, themeTable)
	ThemeManager.RegisterTheme(name, themeTable)
	self.Themes = ThemeManager.Themes
end

function Library:Notify(config)
	Notification.Notify(config)
end

function Library:Unload()
	if typeof(getgenv) == "function" then
		getgenv().FloodLibrary = nil
	end
end

if typeof(getgenv) == "function" then
	getgenv().FloodLibrary = Library
end

return Library
