--!strict
-- Icon asset directory & Lucide icon mapper for Flood UI Library

local Icons = {
    -- Common UI icons mapped to Roblox image asset IDs
    Assets = {
        ["home"] = "rbxassetid://10723407389",
        ["settings"] = "rbxassetid://10734950309",
        ["user"] = "rbxassetid://10747373176",
        ["shield"] = "rbxassetid://10734951847",
        ["sliders"] = "rbxassetid://10734952402",
        ["code"] = "rbxassetid://10709790202",
        ["crosshair"] = "rbxassetid://10709798950",
        ["eye"] = "rbxassetid://10723415132",
        ["search"] = "rbxassetid://10734883986",
        ["chevron-down"] = "rbxassetid://10709790948",
        ["chevron-right"] = "rbxassetid://10709791281",
        ["check"] = "rbxassetid://10709790644",
        ["x"] = "rbxassetid://10747384394",
        ["bell"] = "rbxassetid://10709778789",
        ["moon"] = "rbxassetid://10734886892",
        ["sun"] = "rbxassetid://10734953351",
    },
}

function Icons.Get(iconName: string): string
    return Icons.Assets[iconName] or Icons.Assets["home"]
end

return Icons
