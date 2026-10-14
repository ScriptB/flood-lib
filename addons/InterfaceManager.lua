--!strict
-- InterfaceManager: Cross-game global preferences (Themes, Hotkeys, Scale)

local UserInputService = game:GetService("UserInputService")

local InterfaceManager = {
    Library = nil :: any,
    Folder = "FloodGlobal",
}

function InterfaceManager:SetLibrary(library: any)
    self.Library = library
end

function InterfaceManager:SetFolder(folder: string)
    self.Folder = folder
end

function InterfaceManager:BuildInterfaceSection(tabOrSection: any)
    assert(self.Library, "InterfaceManager: Library not assigned.")

    local sec = tabOrSection.AddSection and tabOrSection:AddSection("Theme & Interface") or tabOrSection

    local themesList = {}
    for name, _ in pairs(self.Library.Themes) do
        table.insert(themesList, name)
    end

    sec:AddDropdown("GlobalThemeDropdown", {
        Title = "Theme Palette",
        Values = themesList,
        Default = "Ocean",
        Callback = function(themeName)
            self.Library:SetTheme(themeName)
        end,
    })

    sec:AddKeybind("ToggleMenuKeybind", {
        Title = "Toggle UI Keybind",
        Default = Enum.KeyCode.RightControl,
        Callback = function(key)
            print("Toggle UI key set to:", key.Name)
        end,
    })
end

return InterfaceManager
