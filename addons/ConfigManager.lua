--!strict
local HttpService = game:GetService("HttpService")

local ConfigManager = {}
ConfigManager.__index = ConfigManager

export type ConfigEntry = {
	Default: any,
}

export type Config = {
	FolderName: string?,
	FileName:   string?,
}

local FOLDER = "FloodConfigs"

local function readFile(path: string): string?
	if not (readfile :: any) then return nil end
	local ok, data = pcall(readfile, path)
	return ok and data or nil
end

local function writeFile(path: string, data: string)
	if not (writefile :: any) then return end
	pcall(writefile, path, data)
end

local function makeFolder(name: string)
	if not (isfolder :: any) then return end
	if not isfolder(name) then
		if (makefolder :: any) then
			pcall(makefolder, name)
		end
	end
end

function ConfigManager.new(config: Config?): any
	local self    = setmetatable({}, ConfigManager)
	self._folder  = (config and config.FolderName) or FOLDER
	self._file    = (config and config.FileName)   or "config.json"
	self._flags   = {} :: { [string]: any }
	self._schema  = {} :: { [string]: ConfigEntry }
	makeFolder(self._folder)
	self:_Load()
	return self
end

function ConfigManager:_Path(): string
	return self._folder .. "/" .. self._file
end

function ConfigManager:_Load()
	local raw = readFile(self:_Path())
	if not raw then return end
	local ok, decoded = pcall(HttpService.JSONDecode, HttpService, raw)
	if ok and type(decoded) == "table" then
		self._flags = decoded
	end
end

function ConfigManager:_Save()
	local ok, encoded = pcall(HttpService.JSONEncode, HttpService, self._flags)
	if ok then
		writeFile(self:_Path(), encoded)
	end
end

function ConfigManager:Register(key: string, entry: ConfigEntry)
	self._schema[key] = entry
	if self._flags[key] == nil then
		self._flags[key] = entry.Default
	end
end

function ConfigManager:Get(key: string): any
	if self._flags[key] ~= nil then
		return self._flags[key]
	end
	if self._schema[key] then
		return self._schema[key].Default
	end
	return nil
end

function ConfigManager:Set(key: string, value: any)
	self._flags[key] = value
	self:_Save()
end

function ConfigManager:Reset(key: string)
	if self._schema[key] then
		self._flags[key] = self._schema[key].Default
		self:_Save()
	end
end

function ConfigManager:ResetAll()
	for key, entry in pairs(self._schema) do
		self._flags[key] = entry.Default
	end
	self:_Save()
end

return ConfigManager
