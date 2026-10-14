--!strict
-- Creator: Declarative instance factory, property applicator & theme registry

local ThemeManager = require(script.Parent.Themes.Manager)

local Creator = {
    Registry = {} :: { [Instance]: { [string]: string } },
}

function Creator.New(className: string, properties: { [string]: any }, children: { Instance }?): Instance
    local instance = Instance.new(className)
    local themeTag = properties.ThemeTag
    properties.ThemeTag = nil

    for prop, val in pairs(properties) do
        (instance :: any)[prop] = val
    end

    if themeTag then
        Creator.Registry[instance] = themeTag
        local currentTheme = ThemeManager.CurrentTheme
        for prop, token in pairs(themeTag) do
            local color = currentTheme[token]
            if color ~= nil then
                (instance :: any)[prop] = color
            end
        end
    end

    if children then
        for _, child in ipairs(children) do
            child.Parent = instance
        end
    end

    return instance
end

function Creator.UpdateTheme(newTheme: { [string]: any }?)
    local theme = newTheme or ThemeManager.CurrentTheme
    for instance, tagMap in pairs(Creator.Registry) do
        if instance.Parent ~= nil then
            for prop, token in pairs(tagMap) do
                local color = theme[token]
                if color ~= nil then
                    (instance :: any)[prop] = color
                end
            end
        else
            -- Garbage-collect unparented / destroyed instances
            Creator.Registry[instance] = nil
        end
    end
end

return Creator
