local Signal = require(script.Parent.Parent.Utils.Signal)
local Ocean  = require(script.Parent.Ocean)
local Dark   = require(script.Parent.Dark)
local Abyss  = require(script.Parent.Abyss)
local Light  = require(script.Parent.Light)

local Manager = {
    CurrentTheme     = Ocean,
    CurrentThemeName = "Ocean",
    Themes = {
        Ocean = Ocean,
        Dark  = Dark,
        Abyss = Abyss,
        Light = Light,
    },
    _changed = Signal.new(),
}

function Manager.GetTheme(name)
    return Manager.Themes[name] or Manager.CurrentTheme
end

function Manager.SetTheme(name)
    local theme = Manager.Themes[name]
    if not theme then return end
    Manager.CurrentTheme     = theme
    Manager.CurrentThemeName = name
    Manager._changed:Fire(theme)
end

function Manager.OnThemeChanged(fn)
    return Manager._changed:Connect(fn)
end

function Manager.RegisterTheme(name, themeTable)
    Manager.Themes[name] = themeTable
end

return Manager
