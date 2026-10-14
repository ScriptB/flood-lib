--!strict
-- SaveManager: JSON configuration serialization, file I/O & autoloading

local HttpService = game:GetService("HttpService")

local SaveManager = {
    Library = nil :: any,
    Folder = "FloodConfigs",
}

function SaveManager:SetLibrary(library: any)
    self.Library = library
end

function SaveManager:SetFolder(folder: string)
    self.Folder = folder
end

function SaveManager:Save(configName: string)
    assert(self.Library, "SaveManager: Library not assigned.")
    local data = {}

    for id, element in pairs(self.Library.Options) do
        if element.Value ~= nil then
            if typeof(element.Value) == "EnumItem" then
                data[id] = { Type = "EnumItem", Value = element.Value.Name }
            elseif typeof(element.Value) == "Color3" then
                data[id] = { Type = "Color3", R = element.Value.R, G = element.Value.G, B = element.Value.B }
            else
                data[id] = element.Value
            end
        end
    end

    local encoded = HttpService:JSONEncode(data)

    if typeof(writefile) == "function" then
        if typeof(makefolder) == "function" and typeof(isfolder) == "function" then
            if not isfolder(self.Folder) then
                makefolder(self.Folder)
            end
        end
        writefile(self.Folder .. "/" .. configName .. ".json", encoded)
    else
        warn("SaveManager: writefile is not available in standard Studio environment.")
    end
end

function SaveManager:Load(configName: string)
    assert(self.Library, "SaveManager: Library not assigned.")
    local path = self.Folder .. "/" .. configName .. ".json"

    if typeof(readfile) == "function" and typeof(isfile) == "function" and isfile(path) then
        local raw = readfile(path)
        local success, data = pcall(function()
            return HttpService:JSONDecode(raw)
        end)

        if success and typeof(data) == "table" then
            for id, savedVal in pairs(data) do
                local element = self.Library.Options[id]
                if element and typeof(element.SetValue) == "function" then
                    if typeof(savedVal) == "table" and savedVal.Type == "Color3" then
                        element:SetValue(Color3.new(savedVal.R, savedVal.G, savedVal.B))
                    elseif typeof(savedVal) == "table" and savedVal.Type == "EnumItem" then
                        element:SetValue(Enum.KeyCode[savedVal.Value])
                    else
                        element:SetValue(savedVal)
                    end
                end
            end
        end
    end
end

return SaveManager
