--!strict
local ThemeManager = require(script.Themes.Manager)
local Window       = require(script.Components.Window)

local Library = {
	Flags  = {} :: { [string]: any },
	Themes = ThemeManager.Themes,
}

local function bindFlag(lib: typeof(Library), id: string, obj: any)
	if obj and obj.OnChanged then
		lib.Flags[id] = obj.Value
		obj.OnChanged:Connect(function(v: any)
			lib.Flags[id] = v
		end)
	end
end

local function makeSecApi(lib: typeof(Library), sec: any, searchBar: any): any
	local secApi = {}

	function secApi:AddToggle(id: string, cfg: {
		Title: string, Default: boolean?, Callback: ((boolean) -> ())?
	}): any
		local obj = sec:AddToggle(id, cfg)
		bindFlag(lib, id, obj)
		if searchBar then
			searchBar:RegisterElement({ Id = id, Label = cfg.Title, TabId = "", SelectFn = function() end })
		end
		return obj
	end

	function secApi:AddSlider(id: string, cfg: {
		Title: string, Min: number, Max: number, Default: number?,
		Rounding: number?, Suffix: string?, Callback: ((number) -> ())?
	}): any
		local obj = sec:AddSlider(id, cfg)
		bindFlag(lib, id, obj)
		if searchBar then
			searchBar:RegisterElement({ Id = id, Label = cfg.Title, TabId = "", SelectFn = function() end })
		end
		return obj
	end

	function secApi:AddButton(cfg: { Title: string, Description: string?, Callback: (() -> ())? }): any
		local obj = sec:AddButton(cfg)
		if searchBar then
			searchBar:RegisterElement({ Id = cfg.Title, Label = cfg.Title, TabId = "", SelectFn = cfg.Callback or function() end })
		end
		return obj
	end

	function secApi:AddDropdown(id: string, cfg: {
		Title: string, Values: { string }, Default: string?, Callback: ((string) -> ())?
	}): any
		local obj = sec:AddDropdown(id, cfg)
		bindFlag(lib, id, obj)
		if searchBar then
			searchBar:RegisterElement({ Id = id, Label = cfg.Title, TabId = "", SelectFn = function() end })
		end
		return obj
	end

	function secApi:AddInput(id: string, cfg: {
		Title: string, Default: string?, Placeholder: string?, Callback: ((string) -> ())?
	}): any
		local obj = sec:AddInput(id, cfg)
		bindFlag(lib, id, obj)
		return obj
	end

	function secApi:AddKeybind(id: string, cfg: {
		Title: string, Default: Enum.KeyCode?, Callback: ((Enum.KeyCode) -> ())?
	}): any
		local obj = sec:AddKeybind(id, cfg)
		bindFlag(lib, id, obj)
		return obj
	end

	function secApi:AddColorpicker(id: string, cfg: {
		Title: string, Default: Color3?, Callback: ((Color3) -> ())?
	}): any
		local obj = sec:AddColorpicker(id, cfg)
		bindFlag(lib, id, obj)
		return obj
	end

	function secApi:AddParagraph(cfg: { Title: string, Content: string }): any
		return sec:AddParagraph(cfg)
	end

	function secApi:AddDivider(): any
		return sec:AddDivider()
	end

	return secApi
end

local function makeTabApi(lib: typeof(Library), tab: any, searchBar: any): any
	local tabApi = {}

	function tabApi:AddSection(title: string?, column: number?): any
		local sec = tab:AddSection(title, column)
		return makeSecApi(lib, sec, searchBar)
	end

	function tabApi:AddLeftSection(title: string?): any
		return tabApi:AddSection(title, 1)
	end

	function tabApi:AddRightSection(title: string?): any
		return tabApi:AddSection(title, 2)
	end

	return tabApi
end

function Library:CreateWindow(config: {
	Title:   string?,
	Loading: { Enabled: boolean?, Title: string? }?,
	Search:  { Enabled: boolean? }?,
	Theme:   string?,
}): any
	if config.Theme then
		ThemeManager.SetTheme(config.Theme)
	end

	local win        = Window.new(config)
	local searchBar  = win:GetSearchBar()

	local winApi = {}

	function winApi:AddTab(tabConfig: { Title: string, Icon: string? }): any
		local tab = win:AddTab(tabConfig)
		return makeTabApi(Library, tab, searchBar)
	end

	function winApi:AddQuickAction(entry: { Id: string, Icon: string, OnClick: () -> () })
		win:AddQuickAction(entry)
	end

	function winApi:SelectTab(id: string)
		win:SelectTab(id)
	end

	function winApi:DismissLoading()
		win:DismissLoading()
	end

	function winApi:SetLoadingStatus(text: string)
		win:SetLoadingStatus(text)
	end

	function winApi:SetVisible(visible: boolean)
		if visible then win:Show() else win:Hide() end
	end

	function winApi:Toggle()
		win:ToggleVisible()
	end

	function winApi:ToggleMinimize()
		win:ToggleMinimize()
	end

	function winApi:Destroy()
		win:Destroy()
	end

	return winApi
end

function Library:SetTheme(name: string)
	ThemeManager.SetTheme(name)
	self.Themes = ThemeManager.Themes
end

function Library:GetTheme(): { [string]: any }
	return ThemeManager.CurrentTheme
end

function Library:GetThemeName(): string
	return ThemeManager.CurrentThemeName
end

function Library:RegisterTheme(name: string, themeTable: { [string]: any })
	ThemeManager.RegisterTheme(name, themeTable)
	self.Themes = ThemeManager.Themes
end

if typeof(getgenv) == "function" then
	getgenv().FloodLibrary = Library
end

return Library
