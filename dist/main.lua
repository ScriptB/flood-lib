-- Flood UI Library
-- https://github.com/ScriptB/flood-lib
local __M = {}
local function __R(n)
    if __M[n] == nil then error("Flood: module not found: "..n, 2) end
    if type(__M[n]) == "function" then __M[n] = __M[n]() end
    return __M[n]
end
__M["Signal"]=function()
-- High-performance micro-signal implementation for Flood UI Library

local Signal = {}
Signal.__index = Signal



function Signal.new()
    local self = setmetatable({
        _handlers = {},
    }, Signal)
    return (self)
end

function Signal:Connect(fn)
    table.insert(self._handlers, fn)
    local connected = true
    local handlers = self._handlers

    local conn = {
        Connected = true,
    }

    function conn:Disconnect()
        if not connected then return end
        connected = false
        conn.Connected = false
        local idx = table.find(handlers, fn)
        if idx then
            table.remove(handlers, idx)
        end
    end

    return conn
end

function Signal:Once(fn)
    local conn
    conn = self:Connect(function(...)
        conn:Disconnect()
        fn(...)
    end)
    return conn
end

function Signal:Fire(...)
    for _, handler in ipairs(table.clone(self._handlers)) do
        task.spawn(handler, ...)
    end
end

function Signal:Wait()
    local thread = coroutine.running()
    self:Once(function(...)
        task.spawn(thread, ...)
    end)
    return coroutine.yield()
end

function Signal:Destroy()
    table.clear(self._handlers)
end

return Signal
end

__M["Maid"]=function()
-- Maid / Task cleanup manager for connection and resource lifecycle

local Maid = {}
Maid.__index = Maid


function Maid.new()
    return setmetatable({
        _tasks = {},
    }, Maid)
end

function Maid:GiveTask(taskItem)
    local id = #self._tasks + 1
    self._tasks[id] = taskItem
    return id
end

function Maid:Clean()
    local tasks = self._tasks
    self._tasks = {}
    for i = #tasks, 1, -1 do
        local taskItem = tasks[i]
        if typeof(taskItem) == "RBXScriptConnection" then
            taskItem:Disconnect()
        elseif typeof(taskItem) == "Instance" then
            taskItem:Destroy()
        elseif typeof(taskItem) == "function" then
            task.spawn(taskItem)
        elseif typeof(taskItem) == "table" then
            if typeof(taskItem.Destroy) == "function" then
                taskItem:Destroy()
            elseif typeof(taskItem.Disconnect) == "function" then
                taskItem:Disconnect()
            elseif typeof(taskItem.disconnect) == "function" then
                taskItem:disconnect()
            end
        end
    end
end

function Maid:Destroy()
    self:Clean()
end

return Maid
end

__M["Spring"]=function()
local Spring = {}
Spring.__index = Spring


function Spring.new(initial, speed, damper)
	local self = setmetatable({
		Target   = initial or 0,
		Position = initial or 0,
		Velocity = 0,
		Speed    = speed  or 15,
		Damper   = damper or 0.85,
	}, Spring)
	return (self)
end

function Spring:SetTarget(target)
	self.Target = target
end

function Spring:Step(dt)
	local d    = self.Damper
	local s    = self.Speed
	local diff = self.Target - self.Position
	local f    = diff * (s * s)
	self.Velocity = (self.Velocity + f * dt) * math.clamp(1 - d * s * dt, 0, 1)
	self.Position = self.Position + self.Velocity * dt
	return self.Position
end

function Spring:IsSettled()
	return math.abs(self.Target - self.Position) < 0.002
		and math.abs(self.Velocity) < 0.002
end

return Spring
end

__M["Tween"]=function()
local RunService   = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Spring       = __R("Spring")

local Tween = {}

Tween.Fast   = TweenInfo.new(0.15, Enum.EasingStyle.Quad,        Enum.EasingDirection.Out)
Tween.Normal = TweenInfo.new(0.25, Enum.EasingStyle.Quad,        Enum.EasingDirection.Out)
Tween.Smooth = TweenInfo.new(0.35, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
Tween.Bounce = TweenInfo.new(0.3,  Enum.EasingStyle.Back,        Enum.EasingDirection.Out)
Tween.Pop    = TweenInfo.new(0.12, Enum.EasingStyle.Back,        Enum.EasingDirection.Out)
Tween.Settle = TweenInfo.new(0.28, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
Tween.Slug   = TweenInfo.new(0.45, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)


Tween.SpringPop    = { Speed = 32, Damper = 0.82 }
Tween.SpringSettle = { Speed = 20, Damper = 0.78 }
Tween.SpringSlug   = { Speed = 14, Damper = 0.72 }


function Tween.Play(instance, tweenInfo, properties)
	local tween = TweenService:Create(instance, tweenInfo, properties)
	tween:Play()
	return tween
end

function Tween.SpringAnimate(instance, props, preset)
	local speed
	if preset then speed = preset.Speed else speed = 20 end
	local damper
	if preset then damper = preset.Damper else damper = 0.78 end
	local inst   = instance

	local channels= {}

	for key, target in props do
		local current = inst[key]
		local vtype   = typeof(current)

		if vtype == "number" then
			local s = Spring.new(current, speed, damper)
			s:SetTarget(target)
			table.insert(channels, {
				tick     = function(dt) s:Step(dt); inst[key] = s.Position end,
				settled  = function() return s:IsSettled() end,
				finalize = function() inst[key] = target end,
			})
		elseif vtype == "Color3" then
			local c  = current
			local tg = target
			local sr = Spring.new(c.R, speed, damper)
			local sg = Spring.new(c.G, speed, damper)
			local sb = Spring.new(c.B, speed, damper)
			sr:SetTarget(tg.R); sg:SetTarget(tg.G); sb:SetTarget(tg.B)
			table.insert(channels, {
				tick = function(dt)
					sr:Step(dt); sg:Step(dt); sb:Step(dt)
					inst[key] = Color3.new(
						math.clamp(sr.Position, 0, 1),
						math.clamp(sg.Position, 0, 1),
						math.clamp(sb.Position, 0, 1)
					)
				end,
				settled  = function() return sr:IsSettled() and sg:IsSettled() and sb:IsSettled() end,
				finalize = function() inst[key] = target end,
			})
		elseif vtype == "UDim2" then
			local c  = current
			local tg = target
			local sxs = Spring.new(c.X.Scale,  speed, damper)
			local sxo = Spring.new(c.X.Offset, speed, damper)
			local sys = Spring.new(c.Y.Scale,  speed, damper)
			local syo = Spring.new(c.Y.Offset, speed, damper)
			sxs:SetTarget(tg.X.Scale);  sxo:SetTarget(tg.X.Offset)
			sys:SetTarget(tg.Y.Scale);  syo:SetTarget(tg.Y.Offset)
			table.insert(channels, {
				tick = function(dt)
					sxs:Step(dt); sxo:Step(dt); sys:Step(dt); syo:Step(dt)
					inst[key] = UDim2.new(
						sxs.Position, math.round(sxo.Position),
						sys.Position, math.round(syo.Position)
					)
				end,
				settled  = function()
					return sxs:IsSettled() and sxo:IsSettled()
						and sys:IsSettled() and syo:IsSettled()
				end,
				finalize = function() inst[key] = target end,
			})
		elseif vtype == "Vector2" then
			local c  = current
			local tg = target
			local sx = Spring.new(c.X, speed, damper)
			local sy = Spring.new(c.Y, speed, damper)
			sx:SetTarget(tg.X); sy:SetTarget(tg.Y)
			table.insert(channels, {
				tick     = function(dt) sx:Step(dt); sy:Step(dt); inst[key] = Vector2.new(sx.Position, sy.Position) end,
				settled  = function() return sx:IsSettled() and sy:IsSettled() end,
				finalize = function() inst[key] = target end,
			})
		end
	end

	local cancelled = false
	local connection

	connection = RunService.Heartbeat:Connect(function(dt)
		if cancelled then
			connection:Disconnect()
			return
		end
		local allSettled = true
		for _, ch in channels do
			ch.tick(dt)
			if not ch.settled() then
				allSettled = false
			end
		end
		if allSettled then
			for _, ch in channels do
				ch.finalize()
			end
			connection:Disconnect()
		end
	end)

	return {
		Cancel = function()
			cancelled = true
		end,
	}
end

return Tween
end

__M["SafeParent"]=function()
local RunService = game:GetService("RunService")
local CoreGui    = game:GetService("CoreGui")
local Players    = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

local function SafeParent(gui)
	if RunService:IsStudio() and not RunService:IsRunning() then
		local ok = pcall(function()
			local existing = StarterGui:FindFirstChild(gui.Name)
			if existing and existing ~= gui then
				existing:Destroy()
			end
			gui.Parent = StarterGui
		end)
		if ok and gui.Parent == StarterGui then return end
	end

	if typeof(gethui) == "function" then
		local ok, res = pcall(gethui)
		if ok and res then
			gui.Parent = res
			return
		end
	end

	if typeof(protectgui) == "function" then
		pcall(protectgui, gui)
	end

	local coreOk = pcall(function()
		gui.Parent = CoreGui
	end)
	if coreOk and gui.Parent == CoreGui then return end

	local player = Players.LocalPlayer
	if player then
		local pg = player:FindFirstChildOfClass("PlayerGui") or player:WaitForChild("PlayerGui", 2)
		if pg then
			gui.Parent = pg
			return
		end
	end

	pcall(function()
		gui.Parent = StarterGui
	end)
end

local function Create(name)
	local gui = Instance.new("ScreenGui")
	gui.Name = name
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	SafeParent(gui)
	return gui
end

return {
	Create = Create,
}
end

__M["Drag"]=function()
local UserInputService = game:GetService("UserInputService")

local Drag = {}


function Drag.Attach(handle, target, onMove)
	local active = false
	local ox, oy = 0, 0

	local c0 = handle.InputBegan:Connect(function(inp)
		if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
		active = true
		local abs = target.AbsolutePosition
		ox = abs.X - inp.Position.X
		oy = abs.Y - inp.Position.Y
	end)

	local c1 = UserInputService.InputChanged:Connect(function(inp)
		if not active or inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
		local nx = math.round(inp.Position.X + ox)
		local ny = math.round(inp.Position.Y + oy)
		target.Position = UDim2.fromOffset(nx, ny)
		if onMove then onMove(nx, ny) end
	end)

	local c2 = UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 then
			active = false
		end
	end)

	return {
		Disconnect = function()
			active = false
			c0:Disconnect()
			c1:Disconnect()
			c2:Disconnect()
		end,
	}
end

return Drag
end

__M["Ocean"]=function()
return {
    Name = "Ocean",
    Canvas = Color3.fromRGB(8, 13, 17),
    TopBar = Color3.fromRGB(11, 19, 24),
    Panel = Color3.fromRGB(13, 23, 29),
    PanelHover = Color3.fromRGB(19, 34, 42),
    Card = Color3.fromRGB(10, 18, 23),
    CardHover = Color3.fromRGB(16, 30, 37),
    ControlBg = Color3.fromRGB(14, 25, 31),
    ControlHover = Color3.fromRGB(20, 38, 46),
    BadgeBg = Color3.fromRGB(18, 34, 41),
    Border = Color3.fromRGB(39, 61, 67),
    BorderBright = Color3.fromRGB(72, 111, 118),
    Text = Color3.fromRGB(223, 236, 232),
    SubText = Color3.fromRGB(132, 158, 158),
    TextDisabled = Color3.fromRGB(69, 91, 94),
    Accent = Color3.fromRGB(58, 222, 205),
    AccentMuted = Color3.fromRGB(24, 91, 89),
    AccentTrack = Color3.fromRGB(17, 58, 59),
    AccentDanger = Color3.fromRGB(238, 90, 74),
    AccentSuccess = Color3.fromRGB(94, 207, 128),
    Success = Color3.fromRGB(94, 207, 128),
    Danger = Color3.fromRGB(238, 90, 74),
    Warning = Color3.fromRGB(239, 184, 74),
    CloseHover = Color3.fromRGB(238, 90, 74),
    Glass = 0.02,
    GlassBlur = 0,
}
end

__M["Dark"]=function()
return {
    Name = "Dark",
    Canvas = Color3.fromRGB(18, 19, 20),
    TopBar = Color3.fromRGB(24, 25, 26),
    Panel = Color3.fromRGB(29, 30, 31),
    PanelHover = Color3.fromRGB(42, 43, 43),
    Card = Color3.fromRGB(22, 23, 24),
    CardHover = Color3.fromRGB(33, 34, 35),
    ControlBg = Color3.fromRGB(29, 30, 31),
    ControlHover = Color3.fromRGB(45, 46, 46),
    BadgeBg = Color3.fromRGB(42, 43, 43),
    Border = Color3.fromRGB(68, 69, 66),
    BorderBright = Color3.fromRGB(113, 112, 102),
    Text = Color3.fromRGB(239, 237, 222),
    SubText = Color3.fromRGB(166, 164, 150),
    TextDisabled = Color3.fromRGB(94, 94, 87),
    Accent = Color3.fromRGB(239, 193, 89),
    AccentMuted = Color3.fromRGB(112, 83, 33),
    AccentTrack = Color3.fromRGB(71, 54, 29),
    AccentDanger = Color3.fromRGB(231, 89, 74),
    AccentSuccess = Color3.fromRGB(110, 201, 125),
    Success = Color3.fromRGB(110, 201, 125),
    Danger = Color3.fromRGB(231, 89, 74),
    Warning = Color3.fromRGB(239, 193, 89),
    CloseHover = Color3.fromRGB(231, 89, 74),
    Glass = 0,
    GlassBlur = 0,
}
end

__M["Abyss"]=function()
return {
    Name = "Abyss",
    Canvas = Color3.fromRGB(5, 6, 8),
    TopBar = Color3.fromRGB(9, 10, 13),
    Panel = Color3.fromRGB(12, 14, 18),
    PanelHover = Color3.fromRGB(19, 22, 29),
    Card = Color3.fromRGB(8, 10, 13),
    CardHover = Color3.fromRGB(15, 18, 24),
    ControlBg = Color3.fromRGB(13, 15, 20),
    ControlHover = Color3.fromRGB(22, 26, 34),
    BadgeBg = Color3.fromRGB(22, 26, 34),
    Border = Color3.fromRGB(42, 48, 61),
    BorderBright = Color3.fromRGB(83, 94, 119),
    Text = Color3.fromRGB(237, 241, 250),
    SubText = Color3.fromRGB(138, 148, 169),
    TextDisabled = Color3.fromRGB(70, 78, 94),
    Accent = Color3.fromRGB(137, 112, 255),
    AccentMuted = Color3.fromRGB(62, 49, 121),
    AccentTrack = Color3.fromRGB(38, 30, 75),
    AccentDanger = Color3.fromRGB(246, 90, 105),
    AccentSuccess = Color3.fromRGB(81, 212, 153),
    Success = Color3.fromRGB(81, 212, 153),
    Danger = Color3.fromRGB(246, 90, 105),
    Warning = Color3.fromRGB(247, 190, 83),
    CloseHover = Color3.fromRGB(246, 90, 105),
    Glass = 0,
    GlassBlur = 0,
}
end

__M["Light"]=function()
return {
    Name = "Light",
    Canvas = Color3.fromRGB(227, 230, 223),
    TopBar = Color3.fromRGB(239, 241, 234),
    Panel = Color3.fromRGB(235, 238, 231),
    PanelHover = Color3.fromRGB(220, 226, 219),
    Card = Color3.fromRGB(243, 245, 239),
    CardHover = Color3.fromRGB(229, 234, 226),
    ControlBg = Color3.fromRGB(232, 236, 229),
    ControlHover = Color3.fromRGB(215, 224, 216),
    BadgeBg = Color3.fromRGB(213, 221, 213),
    Border = Color3.fromRGB(170, 181, 173),
    BorderBright = Color3.fromRGB(114, 134, 127),
    Text = Color3.fromRGB(27, 39, 37),
    SubText = Color3.fromRGB(83, 102, 98),
    TextDisabled = Color3.fromRGB(133, 147, 142),
    Accent = Color3.fromRGB(20, 134, 124),
    AccentMuted = Color3.fromRGB(130, 192, 181),
    AccentTrack = Color3.fromRGB(181, 218, 210),
    AccentDanger = Color3.fromRGB(192, 65, 53),
    AccentSuccess = Color3.fromRGB(40, 142, 79),
    Success = Color3.fromRGB(40, 142, 79),
    Danger = Color3.fromRGB(192, 65, 53),
    Warning = Color3.fromRGB(181, 122, 26),
    CloseHover = Color3.fromRGB(192, 65, 53),
    Glass = 0,
    GlassBlur = 0,
}
end

__M["Manager"]=function()
local Signal = __R("Signal")
local Ocean  = __R("Ocean")
local Dark   = __R("Dark")
local Abyss  = __R("Abyss")
local Light  = __R("Light")

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
end

__M["Icons"]=function()
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

function Icons.Get(iconName)
    return Icons.Assets[iconName] or Icons.Assets["home"]
end

return Icons
end

__M["Creator"]=function()
-- Creator: Declarative instance factory, property applicator & theme registry

local ThemeManager = __R("Manager")

local Creator = {
    Registry = {},
}

function Creator.New(className, properties, children)
    local instance = Instance.new(className)
    local themeTag = properties.ThemeTag
    properties.ThemeTag = nil

    for prop, val in pairs(properties) do
        (instance)[prop] = val
    end

    if themeTag then
        Creator.Registry[instance] = themeTag
        local currentTheme = ThemeManager.CurrentTheme
        for prop, token in pairs(themeTag) do
            local color = currentTheme[token]
            if color ~= nil then
                (instance)[prop] = color
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

function Creator.UpdateTheme(newTheme)
    local theme = newTheme or ThemeManager.CurrentTheme
    for instance, tagMap in pairs(Creator.Registry) do
        if instance.Parent ~= nil then
            for prop, token in pairs(tagMap) do
                local color = theme[token]
                if color ~= nil then
                    (instance)[prop] = color
                end
            end
        else
            -- Garbage-collect unparented / destroyed instances
            Creator.Registry[instance] = nil
        end
    end
end

return Creator
end

__M["Button"]=function()
local Creator      = __R("Creator")
local ThemeManager = __R("Manager")
local Tween        = __R("Tween")

local Button = {}

function Button.Create(parent, config)
	local theme = ThemeManager.CurrentTheme

	local hasDesc  = config.Description ~= nil
	local baseH
	if hasDesc then baseH = 38 else baseH = 28 end
	local container = Creator.New("Frame", {
		Name             = "Button_" .. config.Title,
		Size             = UDim2.new(1, 0, 0, baseH),
		BackgroundColor3 = theme.ControlBg,
		BorderSizePixel  = 0,
		ThemeTag         = { BackgroundColor3 = "ControlBg" },
		Parent           = parent,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 5) }),
		Creator.New("UIStroke", {
			Thickness       = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color           = theme.Border,
			ThemeTag        = { Color = "Border" },
		}),
	})

	local titleY

	if hasDesc then titleY = 5 else titleY = 0 end
	local titleH
	if hasDesc then titleH = 14 else titleH = baseH end
	Creator.New("TextLabel", {
		Name                   = "Title",
		Position               = UDim2.fromOffset(9, titleY),
		Size                   = UDim2.new(1, -32, 0, titleH),
		BackgroundTransparency = 1,
		Text                   = config.Title,
		TextSize               = 11,
		FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextColor3             = theme.Text,
		ThemeTag               = { TextColor3 = "Text" },
		Parent                 = container,
	})

	if hasDesc then
		Creator.New("TextLabel", {
			Name                   = "Description",
			Position               = UDim2.fromOffset(9, 20),
			Size                   = UDim2.new(1, -32, 0, 13),
			BackgroundTransparency = 1,
			Text                   = config.Description,
			TextSize               = 9,
			FontFace               = Font.fromEnum(Enum.Font.Gotham),
			TextXAlignment         = Enum.TextXAlignment.Left,
			TextColor3             = theme.SubText,
			ThemeTag               = { TextColor3 = "SubText" },
			Parent                 = container,
		})
	end

	local arrow = Creator.New("TextLabel", {
		Name                   = "Arrow",
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, -9, 0.5, 0),
		Size                   = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Text                   = "→",
		TextSize               = 11,
		FontFace               = Font.fromEnum(Enum.Font.Gotham),
		TextColor3             = theme.SubText,
		ThemeTag               = { TextColor3 = "SubText" },
		Parent                 = container,
	})

	local clickBtn = Creator.New("TextButton", {
		Size                   = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text                   = "",
		Parent                 = container,
	})

	clickBtn.MouseEnter:Connect(function()
		Tween.Play(container, Tween.Fast, { BackgroundColor3 = theme.ControlHover })
		Tween.Play(arrow,     Tween.Fast, { TextColor3       = theme.Accent })
	end)
	clickBtn.MouseLeave:Connect(function()
		Tween.Play(container, Tween.Fast, { BackgroundColor3 = theme.ControlBg })
		Tween.Play(arrow,     Tween.Fast, { TextColor3       = theme.SubText })
	end)

	clickBtn.MouseButton1Down:Connect(function()
		Tween.SpringAnimate(container, {
			Size = UDim2.new(1, 0, 0, baseH - 2),
		}, Tween.SpringPop)
	end)
	clickBtn.MouseButton1Up:Connect(function()
		Tween.SpringAnimate(container, {
			Size = UDim2.new(1, 0, 0, baseH),
		}, Tween.SpringPop)
	end)
	clickBtn.MouseButton1Click:Connect(function()
		if config.Callback then
			task.spawn(config.Callback)
		end
	end)

	return container
end

return Button
end

__M["Toggle"]=function()
local Creator      = __R("Creator")
local ThemeManager = __R("Manager")
local Tween        = __R("Tween")
local Signal       = __R("Signal")

local Toggle = {}

function Toggle.Create(parent, id, config)
	local value     = config.Default or false
	local onChanged = Signal.new()
	local theme     = ThemeManager.CurrentTheme

	local container = Creator.New("Frame", {
		Name             = "Toggle_" .. id,
		Size             = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = theme.ControlBg,
		BorderSizePixel  = 0,
		ThemeTag         = { BackgroundColor3 = "ControlBg" },
		Parent           = parent,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 5) }),
		Creator.New("UIStroke", {
			Thickness       = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color           = theme.Border,
			ThemeTag        = { Color = "Border" },
		}),
		Creator.New("TextLabel", {
			Name                   = "Title",
			Position               = UDim2.fromOffset(9, 0),
			Size                   = UDim2.new(1, -52, 1, 0),
			BackgroundTransparency = 1,
			Text                   = config.Title,
			TextSize               = 11,
			FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
			TextXAlignment         = Enum.TextXAlignment.Left,
			TextColor3             = theme.Text,
			ThemeTag               = { TextColor3 = "Text" },
		}),
	})

	local switchTrack = Creator.New("Frame", {
		Name             = "Track",
		AnchorPoint      = Vector2.new(1, 0.5),
		Position         = UDim2.new(1, -9, 0.5, 0),
		Size             = UDim2.fromOffset(30, 16),
		BackgroundColor3 = (function() if value then return theme.Accent else return theme.BadgeBg end end)(),
		BorderSizePixel  = 0,
		Parent           = container,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	local knobOn  = UDim2.new(1, -14, 0.5, 0)
	local knobOff = UDim2.new(0,   2, 0.5, 0)

	local knob = Creator.New("Frame", {
		Name             = "Knob",
		AnchorPoint      = Vector2.new(0, 0.5),
		Position         = (function() if value then return knobOn else return knobOff end end)(),
		Size             = UDim2.fromOffset(12, 12),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel  = 0,
		Parent           = switchTrack,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	local clickBtn = Creator.New("TextButton", {
		Size                   = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text                   = "",
		Parent                 = container,
	})

	clickBtn.MouseEnter:Connect(function()
		Tween.Play(container, Tween.Fast, { BackgroundColor3 = theme.ControlHover })
	end)
	clickBtn.MouseLeave:Connect(function()
		Tween.Play(container, Tween.Fast, { BackgroundColor3 = theme.ControlBg })
	end)

	local function updateVisual(state)
		if state then
			Tween.SpringAnimate(knob,        { Position         = knobOn        }, Tween.SpringPop)
			Tween.SpringAnimate(switchTrack, { BackgroundColor3 = theme.Accent  }, Tween.SpringSettle)
		else
			Tween.SpringAnimate(knob,        { Position         = knobOff       }, Tween.SpringPop)
			Tween.SpringAnimate(switchTrack, { BackgroundColor3 = theme.BadgeBg }, Tween.SpringSettle)
		end
	end

	local toggleObj = {
		Value     = value,
		OnChanged = onChanged,
	}

	function toggleObj:SetValue(newVal)
		value = newVal
		toggleObj.Value = newVal
		updateVisual(newVal)
		onChanged:Fire(newVal)
		if config.Callback then
			task.spawn(config.Callback, newVal)
		end
	end

	clickBtn.MouseButton1Click:Connect(function()
		toggleObj:SetValue(not value)
	end)

	return toggleObj
end

return Toggle
end

__M["Slider"]=function()
local UserInputService = game:GetService("UserInputService")
local Creator          = __R("Creator")
local ThemeManager     = __R("Manager")
local Tween            = __R("Tween")
local Signal           = __R("Signal")

local Slider = {}

function Slider.Create(parent, id, config)
	local min       = config.Min     or 0
	local max       = config.Max     or 100
	local rounding  = config.Rounding or 0
	local value     = config.Default or min
	local suffix    = config.Suffix  or ""
	local onChanged = Signal.new()
	local theme     = ThemeManager.CurrentTheme
	local dragging  = false

	local container = Creator.New("Frame", {
		Name             = "Slider_" .. id,
		Size             = UDim2.new(1, 0, 0, 34),
		BackgroundColor3 = theme.ControlBg,
		BorderSizePixel  = 0,
		Parent           = parent,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 5) }),
		Creator.New("UIStroke", {
			Thickness       = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color           = theme.Border,
			ThemeTag        = { Color = "Border" },
		}),
	})

	Creator.New("TextLabel", {
		Name                   = "Title",
		Position               = UDim2.fromOffset(9, 4),
		Size                   = UDim2.new(1, -60, 0, 14),
		BackgroundTransparency = 1,
		Text                   = config.Title,
		TextSize               = 11,
		FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextColor3             = theme.Text,
		ThemeTag               = { TextColor3 = "Text" },
		Parent                 = container,
	})

	local valueBadge = Creator.New("Frame", {
		Name             = "ValueBadge",
		AnchorPoint      = Vector2.new(1, 0),
		Position         = UDim2.new(1, -9, 0, 4),
		Size             = UDim2.fromOffset(46, 14),
		BackgroundColor3 = theme.BadgeBg,
		BorderSizePixel  = 0,
		Parent           = container,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 3) }),
		Creator.New("TextLabel", {
			Name                   = "ValueLabel",
			Size                   = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text                   = tostring(value) .. suffix,
			TextSize               = 9,
			FontFace               = Font.fromEnum(Enum.Font.Gotham),
			TextColor3             = theme.SubText,
			ThemeTag               = { TextColor3 = "SubText" },
		}),
	})

	local track = Creator.New("TextButton", {
		Name             = "Track",
		Position         = UDim2.fromOffset(9, 24),
		Size             = UDim2.new(1, -18, 0, 4),
		Text             = "",
		AutoButtonColor  = false,
		BackgroundColor3 = theme.BadgeBg,
		BorderSizePixel  = 0,
		Parent           = container,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	local progress = Creator.New("Frame", {
		Name             = "Progress",
		Size             = UDim2.fromScale(math.clamp((value - min) / (max - min), 0, 1), 1),
		BackgroundColor3 = theme.Accent,
		BorderSizePixel  = 0,
		Parent           = track,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	local thumb = Creator.New("Frame", {
		Name             = "Thumb",
		AnchorPoint      = Vector2.new(0.5, 0.5),
		Position         = UDim2.fromScale(math.clamp((value - min) / (max - min), 0, 1), 0.5),
		Size             = UDim2.fromOffset(12, 12),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderSizePixel  = 0,
		Parent           = track,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	local sliderObj = {
		Value     = value,
		OnChanged = onChanged,
	}

	local valueLabel = valueBadge:FindFirstChild("ValueLabel")

	local function setValue(val)
		val = math.clamp(val, min, max)
		if rounding > 0 then
			val = math.floor(val * (10 ^ rounding) + 0.5) / (10 ^ rounding)
		else
			val = math.floor(val + 0.5)
		end
		value = val
		sliderObj.Value = val
		valueLabel.Text = tostring(val) .. suffix

		local t = math.clamp((val - min) / (max - min), 0, 1)
		Tween.SpringAnimate(progress, { Size     = UDim2.fromScale(t, 1)    }, Tween.SpringSettle)
		Tween.SpringAnimate(thumb,    { Position = UDim2.fromScale(t, 0.5)  }, Tween.SpringSettle)

		onChanged:Fire(val)
		if config.Callback then
			task.spawn(config.Callback, val)
		end
	end
	sliderObj.SetValue = setValue

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			Tween.Play(valueBadge, Tween.Fast, { BackgroundColor3 = theme.AccentMuted })
			Tween.SpringAnimate(thumb, { Size = UDim2.fromOffset(14, 14) }, Tween.SpringPop)
			local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
			setValue(min + rel * (max - min))
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then
			local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
			setValue(min + rel * (max - min))
		end
	end)

	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			if dragging then
				dragging = false
				Tween.Play(valueBadge, Tween.Fast, { BackgroundColor3 = theme.BadgeBg })
				Tween.SpringAnimate(thumb, { Size = UDim2.fromOffset(12, 12) }, Tween.SpringSettle)
			end
		end
	end)

	return sliderObj
end

return Slider
end

__M["Dropdown"]=function()
local Creator      = __R("Creator")
local ThemeManager = __R("Manager")
local Tween        = __R("Tween")
local Signal       = __R("Signal")

local Dropdown = {}

function Dropdown.Create(parent, id, config)
	local values    = config.Values or {}
	local selected  = config.Default or (values[1] or "")
	local opened    = false
	local onChanged = Signal.new()
	local theme     = ThemeManager.CurrentTheme

	local container = Creator.New("Frame", {
		Name             = "Dropdown_" .. id,
		Size             = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = theme.ControlBg,
		BorderSizePixel  = 0,
		ThemeTag         = { BackgroundColor3 = "ControlBg" },
		Parent           = parent,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 5) }),
		Creator.New("UIStroke", {
			Thickness       = 1,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color           = theme.Border,
			ThemeTag        = { Color = "Border" },
		}),
	})

	local header = Creator.New("TextButton", {
		Name                   = "Header",
		Size                   = UDim2.new(1, 0, 0, 28),
		BackgroundTransparency = 1,
		Text                   = "",
		Parent                 = container,
	}, {
		Creator.New("TextLabel", {
			Name                   = "Title",
			Position               = UDim2.fromOffset(9, 0),
			Size                   = UDim2.new(1, -96, 1, 0),
			BackgroundTransparency = 1,
			Text                   = config.Title,
			TextSize               = 11,
			FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
			TextXAlignment         = Enum.TextXAlignment.Left,
			TextColor3             = theme.Text,
			ThemeTag               = { TextColor3 = "Text" },
		}),
	})

	local valueBadge = Creator.New("Frame", {
		Name             = "ValueBadge",
		AnchorPoint      = Vector2.new(1, 0.5),
		Position         = UDim2.new(1, -9, 0.5, 0),
		Size             = UDim2.fromOffset(80, 18),
		BackgroundColor3 = theme.BadgeBg,
		BorderSizePixel  = 0,
		Parent           = header,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 3) }),
		Creator.New("TextLabel", {
			Name                   = "SelectedText",
			Position               = UDim2.fromOffset(6, 0),
			Size                   = UDim2.new(1, -20, 1, 0),
			BackgroundTransparency = 1,
			Text                   = selected,
			TextSize               = 10,
			FontFace               = Font.fromEnum(Enum.Font.Gotham),
			TextXAlignment         = Enum.TextXAlignment.Left,
			TextColor3             = theme.SubText,
			TextTruncate           = Enum.TextTruncate.AtEnd,
			ThemeTag               = { TextColor3 = "SubText" },
		}),
		Creator.New("TextLabel", {
			Name                   = "Chevron",
			AnchorPoint            = Vector2.new(1, 0.5),
			Position               = UDim2.new(1, -4, 0.5, 0),
			Size                   = UDim2.fromOffset(10, 10),
			BackgroundTransparency = 1,
			Text                   = "▾",
			TextSize               = 9,
			FontFace               = Font.fromEnum(Enum.Font.Gotham),
			TextColor3             = theme.SubText,
			ThemeTag               = { TextColor3 = "SubText" },
		}),
	})

	-- Overlay list: parented to ScreenGui to avoid clipping by ScrollingFrame
	local optionListHeight = #values * 22 + 8
	local overlayList= nil

	local dropdownObj = {
		Value     = selected,
		OnChanged = onChanged,
	}

	local selectedLabel = valueBadge:FindFirstChild("SelectedText")

	local function closeList()
		opened = false
		if overlayList then
			local ol = overlayList
			Tween.Play(ol, Tween.Fast, { Size = UDim2.fromOffset(ol.Size.X.Offset, 0) })
			task.delay(0.16, function()
				if not opened then
					ol.Visible = false
				end
			end)
		end
		local chevron = valueBadge:FindFirstChild("Chevron")
		if chevron then
			Tween.Play(chevron, Tween.Fast, { Rotation = 0 })
		end
	end

	local function selectValue(val)
		selected = val
		dropdownObj.Value = val
		selectedLabel.Text = val
		onChanged:Fire(val)
		if config.Callback then task.spawn(config.Callback, val) end
		closeList()
	end
	dropdownObj.SetValue = selectValue

	local function buildOverlay()
		local screenGui = container:FindFirstAncestorOfClass("ScreenGui")
		if not screenGui then return end

		if overlayList then
			overlayList:Destroy()
			overlayList = nil
		end

		local abs  = container.AbsolutePosition
		local absW = container.AbsoluteSize.X

		local ol = Creator.New("Frame", {
			Name             = "DropOverlay_" .. id,
			Position         = UDim2.fromOffset(abs.X, abs.Y + 28),
			Size             = UDim2.fromOffset(absW, 0),
			BackgroundColor3 = theme.Panel,
			BorderSizePixel  = 0,
			ZIndex           = 50,
			ClipsDescendants = true,
			Parent           = screenGui,
		}, {
			Creator.New("UICorner", { CornerRadius = UDim.new(0, 5) }),
			Creator.New("UIStroke", {
				Thickness       = 1,
				Color           = theme.Border,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			Creator.New("UIListLayout", {
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding   = UDim.new(0, 2),
			}),
			Creator.New("UIPadding", {
				PaddingTop    = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
				PaddingLeft   = UDim.new(0, 4),
				PaddingRight  = UDim.new(0, 4),
			}),
		})

		for _, val in ipairs(values) do
			local isSelected = val == selected
			local optBtn = Creator.New("TextButton", {
				Size                   = UDim2.new(1, 0, 0, 22),
				BackgroundColor3       = (function() if isSelected then return theme.AccentMuted else return theme.ControlBg end end)(),
				BackgroundTransparency = (function() if isSelected then return 0.6 else return 1 end end)(),
				Text                   = "",
				AutoButtonColor        = false,
				ZIndex                 = 51,
				Parent                 = ol,
			}, {
				Creator.New("UICorner", { CornerRadius = UDim.new(0, 3) }),
				Creator.New("TextLabel", {
					Position               = UDim2.fromOffset(8, 0),
					Size                   = UDim2.new(1, -20, 1, 0),
					BackgroundTransparency = 1,
					Text                   = val,
					TextSize               = 10,
					FontFace               = Font.fromEnum(Enum.Font.Gotham),
					TextXAlignment         = Enum.TextXAlignment.Left,
					TextColor3             = (function() if isSelected then return theme.Text else return theme.SubText end end)(),
					ZIndex                 = 51,
				}),
			})

			if isSelected then
				Creator.New("TextLabel", {
					AnchorPoint            = Vector2.new(1, 0.5),
					Position               = UDim2.new(1, -6, 0.5, 0),
					Size                   = UDim2.fromOffset(10, 10),
					BackgroundTransparency = 1,
					Text                   = "✓",
					TextSize               = 9,
					FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
					TextColor3             = theme.Accent,
					ZIndex                 = 51,
					Parent                 = optBtn,
				})
			end

			optBtn.MouseEnter:Connect(function()
				Tween.Play(optBtn, Tween.Fast, {
					BackgroundTransparency = 0,
					BackgroundColor3       = theme.ControlBg,
				})
			end)
			optBtn.MouseLeave:Connect(function()
				local tp
				if val == selected then tp = 0.6 else tp = 1 end
				Tween.Play(optBtn, Tween.Fast, { BackgroundTransparency = tp })
			end)
			optBtn.MouseButton1Click:Connect(function()
				selectValue(val)
			end)
		end

		overlayList = ol
		Tween.Play(ol, Tween.Settle, { Size = UDim2.fromOffset(absW, optionListHeight) })
	end

	header.MouseEnter:Connect(function()
		Tween.Play(container, Tween.Fast, { BackgroundColor3 = theme.ControlHover })
	end)
	header.MouseLeave:Connect(function()
		Tween.Play(container, Tween.Fast, { BackgroundColor3 = theme.ControlBg })
	end)

	header.MouseButton1Click:Connect(function()
		if opened then
			closeList()
		else
			opened = true
			local chevron = valueBadge:FindFirstChild("Chevron")
			if chevron then Tween.Play(chevron, Tween.Fast, { Rotation = 180 }) end
			buildOverlay()
		end
	end)

	return dropdownObj
end

return Dropdown
end

__M["Input"]=function()
local Creator      = __R("Creator")
local ThemeManager = __R("Manager")
local Tween        = __R("Tween")
local Signal       = __R("Signal")

local Input = {}

function Input.Create(parent, id, config)
	local value     = config.Default or ""
	local onChanged = Signal.new()
	local theme     = ThemeManager.CurrentTheme

	local container = Creator.New("Frame", {
		Name             = "Input_" .. id,
		Size             = UDim2.new(1, 0, 0, 28),
		BackgroundColor3 = theme.ControlBg,
		BorderSizePixel  = 0,
		ThemeTag         = { BackgroundColor3 = "ControlBg" },
		Parent           = parent,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 5) }),
	})

	local stroke = Creator.New("UIStroke", {
		Thickness       = 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Color           = theme.Border,
		ThemeTag        = { Color = "Border" },
		Parent          = container,
	})

	Creator.New("TextLabel", {
		Name                   = "Title",
		Position               = UDim2.fromOffset(9, 0),
		Size                   = UDim2.new(0.42, -12, 1, 0),
		BackgroundTransparency = 1,
		Text                   = config.Title,
		TextSize               = 11,
		FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
		TextXAlignment         = Enum.TextXAlignment.Left,
		TextColor3             = theme.Text,
		TextTruncate           = Enum.TextTruncate.AtEnd,
		ThemeTag               = { TextColor3 = "Text" },
		Parent                 = container,
	})

	local textBox = Creator.New("TextBox", {
		Name                   = "TextBox",
		AnchorPoint            = Vector2.new(1, 0.5),
		Position               = UDim2.new(1, -9, 0.5, 0),
		Size                   = UDim2.new(0.55, 0, 0, 18),
		Text                   = value,
		PlaceholderText        = config.Placeholder or "Value...",
		TextSize               = 10,
		FontFace               = Font.fromEnum(Enum.Font.Gotham),
		ClearTextOnFocus       = false,
		BackgroundColor3       = theme.BadgeBg,
		BackgroundTransparency = 0,
		TextColor3             = theme.Text,
		PlaceholderColor3      = theme.TextDisabled,
		BorderSizePixel        = 0,
		ThemeTag               = {
			BackgroundColor3  = "BadgeBg",
			TextColor3        = "Text",
			PlaceholderColor3 = "TextDisabled",
		},
		Parent = container,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 3) }),
		Creator.New("UIPadding", {
			PaddingLeft  = UDim.new(0, 5),
			PaddingRight = UDim.new(0, 5),
		}),
	})

	local inputObj = {
		Value     = value,
		OnChanged = onChanged,
	}

	textBox.Focused:Connect(function()
		Tween.SpringAnimate(stroke, { Color = theme.Accent }, Tween.SpringSettle)
	end)

	textBox.FocusLost:Connect(function(_enterPressed)
		Tween.SpringAnimate(stroke, { Color = theme.Border }, Tween.SpringSettle)
		value = textBox.Text
		inputObj.Value = value
		onChanged:Fire(value)
		if config.Callback then
			task.spawn(config.Callback, value)
		end
	end)

	function inputObj:SetValue(newVal)
		value = newVal
		inputObj.Value = newVal
		textBox.Text = newVal
	end

	return inputObj
end

return Input
end

__M["Keybind"]=function()
-- Production Keybind Component (Frontend UI Engineering Spec)
-- 28px height, 4px corner radius, hotkey pill badge

local UserInputService = game:GetService("UserInputService")
local Creator = __R("Creator")
local ThemeManager = __R("Manager")
local Signal = __R("Signal")

local Keybind = {}

function Keybind.Create(parent, id, config)
    local currentKey = config.Default or Enum.KeyCode.RightControl
    local listening = false
    local onChanged = Signal.new()
    local theme = ThemeManager.CurrentTheme

    local container = Creator.New("Frame", {
        Name = "Keybind_" .. id,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = theme.ControlBg,
        BorderSizePixel = 0,
        Parent = parent,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) }),
        Creator.New("UIStroke", {
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = theme.Border,
        }),
        Creator.New("TextLabel", {
            Name = "Title",
            Position = UDim2.fromOffset(8, 0),
            Size = UDim2.new(1, -74, 1, 0),
            BackgroundTransparency = 1,
            Text = config.Title,
            TextSize = 11,
            FontFace = Font.fromEnum(Enum.Font.GothamMedium),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = theme.Text,
        }),
    })

    local keyBtn = Creator.New("TextButton", {
        Name = "KeyBadge",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(56, 18),
        BackgroundColor3 = theme.BadgeBg,
        BorderSizePixel = 0,
        Text = string.upper(currentKey.Name),
        TextSize = 9,
        FontFace = Font.fromEnum(Enum.Font.GothamBold),
        TextColor3 = theme.SubText,
        Parent = container,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 3) }),
    })

    local keyObj = {
        Value = currentKey,
        OnChanged = onChanged,
    }

    keyBtn.MouseButton1Click:Connect(function()
        listening = true
        keyBtn.Text = "..."
        keyBtn.TextColor3 = theme.Accent
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if listening and input.UserInputType == Enum.UserInputType.Keyboard then
            listening = false
            currentKey = input.KeyCode
            keyObj.Value = currentKey
            keyBtn.Text = string.upper(currentKey.Name)
            keyBtn.TextColor3 = theme.SubText
            onChanged:Fire(currentKey)
            if config.Callback then task.spawn(config.Callback, currentKey) end
        end
    end)

    return keyObj
end

return Keybind
end

__M["Colorpicker"]=function()
local UserInputService = game:GetService("UserInputService")
local Creator          = __R("Creator")
local ThemeManager     = __R("Manager")
local Tween            = __R("Tween")
local Signal           = __R("Signal")

local HUE_STOPS = {
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(255,   0,   0)),
    ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255,   0)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(  0, 255,   0)),
    ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(  0, 255, 255)),
    ColorSequenceKeypoint.new(0.67, Color3.fromRGB(  0,   0, 255)),
    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,   0, 255)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(255,   0,   0)),
}

local function clamp01(v)
    return math.clamp(v, 0, 1)
end

local function relativePos(inputPos, frame)
    return Vector2.new(
        clamp01((inputPos.X - frame.AbsolutePosition.X) / frame.AbsoluteSize.X),
        clamp01((inputPos.Y - frame.AbsolutePosition.Y) / frame.AbsoluteSize.Y)
    )
end

local function hexFromColor(c)
    return string.format("#%02X%02X%02X",
        math.floor(c.R * 255 + 0.5),
        math.floor(c.G * 255 + 0.5),
        math.floor(c.B * 255 + 0.5)
    )
end

local function colorFromHex(hex)
    hex = hex:gsub("^#", "")
    if #hex == 3 then
        hex = hex:gsub("(.)", "%1%1")
    end
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1, 2), 16)
    local g = tonumber(hex:sub(3, 4), 16)
    local b = tonumber(hex:sub(5, 6), 16)
    if not (r and g and b) then return nil end
    return Color3.fromRGB(r, g, b)
end

local Colorpicker = {}

function Colorpicker.Create(parent, id, config)
    local initColor = config.Default or Color3.fromRGB(0, 168, 255)
    local h, s, v   = Color3.toHSV(initColor)
    local alpha      = 1
    local onChanged  = Signal.new()
    local theme      = ThemeManager.CurrentTheme
    local pickerOpen = false

    local svDragging  = false
    local hueDragging = false
    local aDragging   = false

    -- =========================================================================
    -- HEADER ROW (28px, always visible)
    -- =========================================================================
    local outerFrame = Creator.New("Frame", {
        Name = "Colorpicker_" .. id,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = theme.ControlBg,
        BorderSizePixel = 0,
        ThemeTag = { BackgroundColor3 = "ControlBg" },
        Parent = parent,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) }),
        Creator.New("UIStroke", {
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = theme.Border,
            ThemeTag = { Color = "Border" },
        }),
    })

    local headerRow = Creator.New("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Parent = outerFrame,
    })

    Creator.New("TextLabel", {
        Position = UDim2.fromOffset(8, 0),
        Size = UDim2.new(1, -50, 1, 0),
        BackgroundTransparency = 1,
        Text = config.Title,
        TextSize = 11,
        FontFace = Font.fromEnum(Enum.Font.GothamMedium),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextColor3 = theme.Text,
        ThemeTag = { TextColor3 = "Text" },
        Parent = headerRow,
    })

    local swatch = Creator.New("TextButton", {
        Name = "Swatch",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -8, 0.5, 0),
        Size = UDim2.fromOffset(28, 16),
        BackgroundColor3 = initColor,
        BorderSizePixel = 0,
        Text = "",
        AutoButtonColor = false,
        Parent = headerRow,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 3) }),
        Creator.New("UIStroke", { Thickness = 1, Color = theme.Border, ThemeTag = { Color = "Border" } }),
    })

    -- =========================================================================
    -- PICKER PANEL (hidden until swatch clicked, 168px tall)
    -- =========================================================================
    local PICKER_H = 168
    local SV_H     = 110

    local pickerPanel = Creator.New("Frame", {
        Name = "PickerPanel",
        Position = UDim2.fromOffset(0, 28),
        Size = UDim2.new(1, 0, 0, 0),
        ClipsDescendants = true,
        BackgroundTransparency = 1,
        Parent = outerFrame,
    })

    local pickerInner = Creator.New("Frame", {
        Name = "Inner",
        Size = UDim2.new(1, 0, 0, PICKER_H),
        BackgroundTransparency = 1,
        Parent = pickerPanel,
    }, {
        Creator.New("UIPadding", {
            PaddingTop    = UDim.new(0, 6),
            PaddingBottom = UDim.new(0, 6),
            PaddingLeft   = UDim.new(0, 8),
            PaddingRight  = UDim.new(0, 8),
        }),
        Creator.New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 4),
        }),
    })

    -- SV Square
    local svSquare = Creator.New("Frame", {
        Name = "SVSquare",
        Size = UDim2.new(1, 0, 0, SV_H),
        BackgroundColor3 = Color3.fromHSV(h, 1, 1),
        BorderSizePixel = 0,
        LayoutOrder = 1,
        Parent = pickerInner,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) }),
        Creator.New("Frame", {
            Name = "SatOverlay",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(255, 255, 255),
            BorderSizePixel = 0,
        }, {
            Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) }),
            Creator.New("UIGradient", {
                Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(255, 255, 255)),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 1),
                }),
                Rotation = 0,
            }),
        }),
        Creator.New("Frame", {
            Name = "ValOverlay",
            Size = UDim2.fromScale(1, 1),
            BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0,
        }, {
            Creator.New("UICorner", { CornerRadius = UDim.new(0, 4) }),
            Creator.New("UIGradient", {
                Color = ColorSequence.new(Color3.fromRGB(0, 0, 0), Color3.fromRGB(0, 0, 0)),
                Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 1),
                    NumberSequenceKeypoint.new(1, 0),
                }),
                Rotation = 90,
            }),
        }),
        Creator.New("TextButton", {
            Name = "SVInput",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
        }),
    })

    local svCursor = Creator.New("Frame", {
        Name = "SVCursor",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(s, 0, 1 - v, 0),
        Size = UDim2.fromOffset(8, 8),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = svSquare.ZIndex + 10,
        Parent = svSquare,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
        Creator.New("UIStroke", { Thickness = 1.5, Color = Color3.fromRGB(0, 0, 0) }),
    })

    -- Hue Strip
    local hueStrip = Creator.New("Frame", {
        Name = "HueStrip",
        Size = UDim2.new(1, 0, 0, 10),
        BackgroundColor3 = Color3.fromRGB(255, 0, 0),
        BorderSizePixel = 0,
        LayoutOrder = 2,
        Parent = pickerInner,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
        Creator.New("UIGradient", { Color = ColorSequence.new(HUE_STOPS) }),
        Creator.New("TextButton", { Name = "HueInput", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }),
    })

    local hueCursor = Creator.New("Frame", {
        Name = "HueCursor",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(h, 0, 0.5, 0),
        Size = UDim2.fromOffset(4, 14),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = hueStrip.ZIndex + 5,
        Parent = hueStrip,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 2) }),
        Creator.New("UIStroke", { Thickness = 1, Color = Color3.fromRGB(0, 0, 0) }),
    })

    -- Alpha Strip
    local alphaStrip = Creator.New("Frame", {
        Name = "AlphaStrip",
        Size = UDim2.new(1, 0, 0, 10),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        LayoutOrder = 3,
        Parent = pickerInner,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
        Creator.New("UIGradient", {
            Color = ColorSequence.new(Color3.fromHSV(h, s, v), Color3.fromHSV(h, s, v)),
            Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            }),
        }),
        Creator.New("TextButton", { Name = "AlphaInput", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "" }),
    })

    local alphaCursor = Creator.New("Frame", {
        Name = "AlphaCursor",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(alpha, 0, 0.5, 0),
        Size = UDim2.fromOffset(4, 14),
        BackgroundColor3 = Color3.fromRGB(255, 255, 255),
        BorderSizePixel = 0,
        ZIndex = alphaStrip.ZIndex + 5,
        Parent = alphaStrip,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 2) }),
        Creator.New("UIStroke", { Thickness = 1, Color = Color3.fromRGB(0, 0, 0) }),
    })

    -- Bottom row: hex input + preview
    local bottomRow = Creator.New("Frame", {
        Name = "BottomRow",
        Size = UDim2.new(1, 0, 0, 22),
        BackgroundTransparency = 1,
        LayoutOrder = 4,
        Parent = pickerInner,
    })

    local hexBox = Creator.New("TextBox", {
        Name = "HexBox",
        Position = UDim2.fromOffset(0, 2),
        Size = UDim2.new(1, -36, 0, 18),
        BackgroundColor3 = theme.ControlBg,
        BorderSizePixel = 0,
        Text = hexFromColor(initColor),
        PlaceholderText = "#RRGGBB",
        TextSize = 10,
        FontFace = Font.fromEnum(Enum.Font.Gotham),
        TextColor3 = theme.Text,
        PlaceholderColor3 = theme.TextDisabled,
        ClearTextOnFocus = false,
        ThemeTag = { BackgroundColor3 = "ControlBg", TextColor3 = "Text" },
        Parent = bottomRow,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 3) }),
        Creator.New("UIStroke", { Thickness = 1, Color = theme.Border, ThemeTag = { Color = "Border" } }),
        Creator.New("UIPadding", { PaddingLeft = UDim.new(0, 6) }),
    })

    local previewSwatch = Creator.New("Frame", {
        Name = "Preview",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, 0, 0.5, 0),
        Size = UDim2.fromOffset(28, 18),
        BackgroundColor3 = initColor,
        BorderSizePixel = 0,
        Parent = bottomRow,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 3) }),
        Creator.New("UIStroke", { Thickness = 1, Color = theme.Border, ThemeTag = { Color = "Border" } }),
    })

    -- =========================================================================
    -- STATE UPDATE HELPERS
    -- =========================================================================
    local colorObj = {
        Value    = initColor,
        OnChanged = onChanged,
    }

    local function applyColor()
        local color = Color3.fromHSV(h, s, v)
        colorObj.Value = color
        swatch.BackgroundColor3       = color
        previewSwatch.BackgroundColor3 = color
        svSquare.BackgroundColor3      = Color3.fromHSV(h, 1, 1)

        local alphaGrad = alphaStrip:FindFirstChildOfClass("UIGradient")
        if alphaGrad then
            alphaGrad.Color = ColorSequence.new(Color3.fromHSV(h, s, v), Color3.fromHSV(h, s, v))
        end

        hexBox.Text = hexFromColor(color)
        onChanged:Fire(color)
        if config.Callback then task.spawn(config.Callback, color) end
    end

    local function updateSVCursor()
        svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
    end

    local function updateHueCursor()
        hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
    end

    local function updateAlphaCursor()
        alphaCursor.Position = UDim2.new(alpha, 0, 0.5, 0)
    end

    function colorObj:SetValue(newColor)
        local nh, ns, nv = Color3.toHSV(newColor)
        h, s, v = nh, ns, nv
        updateSVCursor()
        updateHueCursor()
        applyColor()
    end

    -- =========================================================================
    -- PICKER TOGGLE
    -- =========================================================================
    swatch.MouseButton1Click:Connect(function()
        pickerOpen = not pickerOpen
        local targetH = pickerOpen and PICKER_H or 0
        local totalH  = pickerOpen and (28 + PICKER_H) or 28
        Tween.Play(pickerPanel, Tween.Smooth, { Size = UDim2.new(1, 0, 0, targetH) })
        Tween.Play(outerFrame, Tween.Smooth, { Size = UDim2.new(1, 0, 0, totalH) })
    end)

    -- =========================================================================
    -- SV SQUARE DRAG
    -- =========================================================================
    local svInput = svSquare:FindFirstChild("SVInput")
    svInput.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            svDragging = true
            local rel = relativePos(inp.Position, svSquare)
            s = rel.X; v = 1 - rel.Y
            updateSVCursor(); applyColor()
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if svDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = relativePos(inp.Position, svSquare)
            s = rel.X; v = 1 - rel.Y
            updateSVCursor(); applyColor()
        elseif hueDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = relativePos(inp.Position, hueStrip)
            h = rel.X
            updateHueCursor(); applyColor()
        elseif aDragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local rel = relativePos(inp.Position, alphaStrip)
            alpha = rel.X
            updateAlphaCursor()
        end
    end)

    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            svDragging  = false
            hueDragging = false
            aDragging   = false
        end
    end)

    -- =========================================================================
    -- HUE STRIP DRAG
    -- =========================================================================
    local hueInput = hueStrip:FindFirstChild("HueInput")
    hueInput.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            hueDragging = true
            local rel = relativePos(inp.Position, hueStrip)
            h = rel.X
            updateHueCursor(); applyColor()
        end
    end)

    -- =========================================================================
    -- ALPHA STRIP DRAG
    -- =========================================================================
    local alphaInput = alphaStrip:FindFirstChild("AlphaInput")
    alphaInput.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            aDragging = true
            local rel = relativePos(inp.Position, alphaStrip)
            alpha = rel.X
            updateAlphaCursor()
        end
    end)

    -- =========================================================================
    -- HEX INPUT
    -- =========================================================================
    hexBox.FocusLost:Connect(function()
        local parsed = colorFromHex(hexBox.Text)
        if parsed then
            colorObj:SetValue(parsed)
        else
            hexBox.Text = hexFromColor(Color3.fromHSV(h, s, v))
        end
    end)

    return colorObj
end

return Colorpicker
end

__M["Paragraph"]=function()
local Creator      = __R("Creator")
local ThemeManager = __R("Manager")

local Paragraph = {}

function Paragraph.Create(parent, config)
    local theme = ThemeManager.CurrentTheme

    local container = Creator.New("Frame", {
        Name = "Paragraph_" .. config.Title,
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = theme.ControlBg,
        BorderSizePixel = 0,
        ThemeTag = { BackgroundColor3 = "ControlBg" },
        Parent = parent,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Creator.New("UIStroke", {
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = theme.Border,
            ThemeTag = { Color = "Border" },
        }),
        Creator.New("UIPadding", {
            PaddingTop    = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft   = UDim.new(0, 10),
            PaddingRight  = UDim.new(0, 10),
        }),
        Creator.New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 4),
        }),
        Creator.New("TextLabel", {
            Name = "Title",
            Size = UDim2.new(1, 0, 0, 14),
            BackgroundTransparency = 1,
            Text = config.Title,
            TextSize = 12,
            FontFace = Font.fromEnum(Enum.Font.GothamBold),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextColor3 = theme.Text,
            ThemeTag = { TextColor3 = "Text" },
            LayoutOrder = 1,
        }),
        Creator.New("TextLabel", {
            Name = "Content",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            Text = config.Content,
            TextSize = 11,
            TextWrapped = true,
            FontFace = Font.fromEnum(Enum.Font.Gotham),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextColor3 = theme.SubText,
            ThemeTag = { TextColor3 = "SubText" },
            LayoutOrder = 2,
        }),
    })

    return container
end

return Paragraph
end

__M["Divider"]=function()
local Creator      = __R("Creator")
local ThemeManager = __R("Manager")

local Divider = {}

function Divider.Create(parent)
    local theme = ThemeManager.CurrentTheme
    local line = Creator.New("Frame", {
        Name = "Divider",
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = theme.Border,
        BorderSizePixel = 0,
        ThemeTag = { BackgroundColor3 = "Border" },
        Parent = parent,
    })
    return line
end

return Divider
end

__M["Notification"]=function()
-- Toast Notification queue and rendering container

local Creator = __R("Creator")
local Tween = __R("Tween")

local Notification = {
    Container = nil,
}

function Notification.Init(screenGui)
    if Notification.Container then return end

    Notification.Container = Creator.New("Frame", {
        Name = "NotificationQueue",
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -24, 1, -24),
        Size = UDim2.fromOffset(300, 400),
        BackgroundTransparency = 1,
        ZIndex = 999,
        Parent = screenGui,
    }, {
        Creator.New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            VerticalAlignment = Enum.VerticalAlignment.Bottom,
            Padding = UDim.new(0, 8),
        }),
    })
end

function Notification.Notify(config)
    if not Notification.Container then return end

    local card = Creator.New("Frame", {
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundTransparency = 0.1,
        ThemeTag = {
            BackgroundColor3 = "Card",
        },
        Parent = Notification.Container,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 8) }),
        Creator.New("UIStroke", {
            Thickness = 1,
            ThemeTag = { Color = "Border" },
        }),
        Creator.New("TextLabel", {
            Name = "Title",
            Position = UDim2.fromOffset(12, 10),
            Size = UDim2.new(1, -24, 0, 18),
            BackgroundTransparency = 1,
            Text = config.Title or "Notification",
            TextSize = 14,
            FontFace = Font.fromEnum(Enum.Font.GothamBold),
            TextXAlignment = Enum.TextXAlignment.Left,
            ThemeTag = { TextColor3 = "Text" },
        }),
        Creator.New("TextLabel", {
            Name = "Content",
            Position = UDim2.fromOffset(12, 30),
            Size = UDim2.new(1, -24, 0, 24),
            BackgroundTransparency = 1,
            Text = config.Content or "",
            TextSize = 12,
            TextWrapped = true,
            FontFace = Font.fromEnum(Enum.Font.Gotham),
            TextXAlignment = Enum.TextXAlignment.Left,
            ThemeTag = { TextColor3 = "SubText" },
        }),
    })

    local duration = config.Duration or 3.5
    task.delay(duration, function()
        if card.Parent then
            local tw = Tween.Play(card, Tween.Fast, { BackgroundTransparency = 1 })
            tw.Completed:Wait()
            card:Destroy()
        end
    end)
end

return Notification
end

__M["Dialog"]=function()
-- Modal Confirmation / Alert Dialog

local Creator = __R("Creator")
local Tween = __R("Tween")

local Dialog = {}

function Dialog.Prompt(screenGui, config)
    local backdrop = Creator.New("TextButton", {
        Name = "DialogBackdrop",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BackgroundTransparency = 0.5,
        Text = "",
        ZIndex = 500,
        Parent = screenGui,
    })

    local modal = Creator.New("Frame", {
        Name = "DialogModal",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(360, 180),
        ThemeTag = {
            BackgroundColor3 = "Card",
        },
        Parent = backdrop,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 12) }),
        Creator.New("UIStroke", {
            Thickness = 1,
            ThemeTag = { Color = "Border" },
        }),
        Creator.New("TextLabel", {
            Position = UDim2.fromOffset(20, 16),
            Size = UDim2.new(1, -40, 0, 24),
            BackgroundTransparency = 1,
            Text = config.Title or "Dialog",
            TextSize = 16,
            FontFace = Font.fromEnum(Enum.Font.GothamBold),
            TextXAlignment = Enum.TextXAlignment.Left,
            ThemeTag = { TextColor3 = "Text" },
        }),
        Creator.New("TextLabel", {
            Position = UDim2.fromOffset(20, 48),
            Size = UDim2.new(1, -40, 0, 60),
            BackgroundTransparency = 1,
            Text = config.Content or "",
            TextSize = 13,
            TextWrapped = true,
            FontFace = Font.fromEnum(Enum.Font.Gotham),
            TextXAlignment = Enum.TextXAlignment.Left,
            ThemeTag = { TextColor3 = "SubText" },
        }),
    })

    local confirmBtn = Creator.New("TextButton", {
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -20, 1, -16),
        Size = UDim2.fromOffset(90, 32),
        Text = "Confirm",
        TextSize = 13,
        FontFace = Font.fromEnum(Enum.Font.GothamBold),
        ThemeTag = {
            BackgroundColor3 = "Accent",
            TextColor3 = "Text",
        },
        Parent = modal,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
    })

    confirmBtn.MouseButton1Click:Connect(function()
        if config.OnConfirm then config.OnConfirm() end
        backdrop:Destroy()
    end)
end

return Dialog
end

__M["Acrylic"]=function()
-- Acrylic: Frosted glass / blur backdrop component

local Creator = __R("Creator")

local Acrylic = {}

function Acrylic.Create(parent)
    local acrylicFrame = Creator.New("Frame", {
        Name = "AcrylicBackdrop",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        BorderSizePixel = 0,
        BackgroundTransparency = 0.25,
        ThemeTag = {
            BackgroundColor3 = "Acrylic",
        },
        ZIndex = parent.ZIndex - 1,
        Parent = parent,
    }, {
        Creator.New("UICorner", {
            CornerRadius = UDim.new(0, 10),
        }),
    })

    return acrylicFrame
end

return Acrylic
end

__M["Tooltip"]=function()
-- Tooltip component for hover hints

local Creator = __R("Creator")
local Tween = __R("Tween")

local Tooltip = {}

function Tooltip.Attach(target, text)
    local tooltip = Creator.New("TextLabel", {
        Name = "Tooltip",
        Size = UDim2.fromOffset(120, 26),
        Visible = false,
        Text = text,
        TextSize = 12,
        FontFace = Font.fromEnum(Enum.Font.GothamMedium),
        ThemeTag = {
            BackgroundColor3 = "Card",
            TextColor3 = "Text",
        },
        ZIndex = 100,
        Parent = target,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Creator.New("UIStroke", {
            Thickness = 1,
            ThemeTag = { Color = "Border" },
        }),
    })

    target.MouseEnter:Connect(function()
        tooltip.Visible = true
        Tween.Play(tooltip, Tween.Fast, { BackgroundTransparency = 0, TextTransparency = 0 })
    end)

    target.MouseLeave:Connect(function()
        tooltip.Visible = false
    end)

    return tooltip
end

return Tooltip
end

__M["Section"]=function()
local Creator      = __R("Creator")
local ThemeManager = __R("Manager")
local Toggle       = __R("Toggle")
local Slider       = __R("Slider")
local Button       = __R("Button")
local Dropdown     = __R("Dropdown")
local Input        = __R("Input")
local Keybind      = __R("Keybind")
local Colorpicker  = __R("Colorpicker")
local Paragraph    = __R("Paragraph")
local Divider      = __R("Divider")

local Section = {}
Section.__index = Section

function Section.new(parent, title)
    local self = setmetatable({}, Section)
    local theme = ThemeManager.CurrentTheme

    local panel = Creator.New("Frame", {
        Name = "Panel_" .. (title or "Group"),
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = theme.Card,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        ThemeTag = { BackgroundColor3 = "Card" },
        Parent = parent,
    }, {
        Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
        Creator.New("UIStroke", {
            Thickness = 1,
            ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
            Color = theme.Border,
            ThemeTag = { Color = "Border" },
        }),
        Creator.New("UIPadding", {
            PaddingTop    = UDim.new(0, 8),
            PaddingBottom = UDim.new(0, 8),
            PaddingLeft   = UDim.new(0, 10),
            PaddingRight  = UDim.new(0, 10),
        }),
        Creator.New("UIListLayout", {
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding   = UDim.new(0, 4),
        }),
    })

    if title and title ~= "" then
        Creator.New("TextLabel", {
            Name = "Header",
            Size = UDim2.new(1, 0, 0, 18),
            BackgroundTransparency = 1,
            LayoutOrder = 0,
            Text = title,
            TextSize = 9,
            FontFace = Font.fromEnum(Enum.Font.Gotham),
            TextColor3 = theme.SubText,
            TextXAlignment = Enum.TextXAlignment.Left,
            ThemeTag = { TextColor3 = "SubText" },
            Parent = panel,
        })
    end

    self.Container = panel
    self._order = 1

    return self
end

local function nextOrder(self)
    self._order = self._order + 1
    return self._order
end

function Section:AddToggle(id, config)
    local obj = Toggle.Create(self.Container, id, config)
    local frame = self.Container:FindFirstChild("Toggle_" .. id)
    if frame then frame.LayoutOrder = nextOrder(self) end
    return obj
end

function Section:AddSlider(id, config)
    local obj = Slider.Create(self.Container, id, config)
    local frame = self.Container:FindFirstChild("Slider_" .. id)
    if frame then frame.LayoutOrder = nextOrder(self) end
    return obj
end

function Section:AddButton(config)
    local frame = Button.Create(self.Container, config)
    frame.LayoutOrder = nextOrder(self)
    return frame
end

function Section:AddDropdown(id, config)
    local obj = Dropdown.Create(self.Container, id, config)
    local frame = self.Container:FindFirstChild("Dropdown_" .. id)
    if frame then frame.LayoutOrder = nextOrder(self) end
    return obj
end

function Section:AddInput(id, config)
    local obj = Input.Create(self.Container, id, config)
    local frame = self.Container:FindFirstChild("Input_" .. id)
    if frame then frame.LayoutOrder = nextOrder(self) end
    return obj
end

function Section:AddKeybind(id, config)
    local obj = Keybind.Create(self.Container, id, config)
    local frame = self.Container:FindFirstChild("Keybind_" .. id)
    if frame then frame.LayoutOrder = nextOrder(self) end
    return obj
end

function Section:AddColorpicker(id, config)
    local obj = Colorpicker.Create(self.Container, id, config)
    local frame = self.Container:FindFirstChild("Colorpicker_" .. id)
    if frame then frame.LayoutOrder = nextOrder(self) end
    return obj
end

function Section:AddParagraph(config)
    local frame = Paragraph.Create(self.Container, config)
    frame.LayoutOrder = nextOrder(self)
    return frame
end

function Section:AddDivider()
    local frame = Divider.Create(self.Container)
    frame.LayoutOrder = nextOrder(self)
    return frame
end

return Section
end

__M["LoadingScreen"]=function()
local TweenService = game:GetService("TweenService")

local LoadingScreen = {}
LoadingScreen.__index = LoadingScreen


local FADE    = TweenInfo.new(0.38, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local DOT_ON  = TweenInfo.new(0.14)
local DOT_OFF = TweenInfo.new(0.28)

function LoadingScreen.new(config)
	local self = setmetatable({}, LoadingScreen)
	self._dismissed = false

	local overlay = Instance.new("Frame")
	overlay.Name                   = "LoadingOverlay"
	overlay.Size                   = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3       = Color3.new(0, 0, 0)
	overlay.BackgroundTransparency = 0
	overlay.BorderSizePixel        = 0
	overlay.ZIndex                 = 500
	overlay.Parent                 = config.Parent

	local haze = Instance.new("Frame")
	haze.AnchorPoint            = Vector2.new(0.5, 0.5)
	haze.Position               = UDim2.fromScale(0.5, 0.5)
	haze.Size                   = UDim2.fromOffset(680, 480)
	haze.BackgroundColor3       = Color3.fromRGB(10, 28, 60)
	haze.BackgroundTransparency = 0.92
	haze.BorderSizePixel        = 0
	haze.ZIndex                 = 500
	haze.Parent                 = overlay
	local hazeCorner            = Instance.new("UICorner")
	hazeCorner.CornerRadius     = UDim.new(1, 0)
	hazeCorner.Parent           = haze

	local center = Instance.new("Frame")
	center.AnchorPoint          = Vector2.new(0.5, 0.5)
	center.Position             = UDim2.fromScale(0.5, 0.5)
	center.AutomaticSize        = Enum.AutomaticSize.Y
	center.Size                 = UDim2.fromOffset(240, 0)
	center.BackgroundTransparency = 1
	center.ZIndex               = 501
	center.Parent               = overlay

	local layout               = Instance.new("UIListLayout")
	layout.SortOrder           = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.Padding             = UDim.new(0, 10)
	layout.Parent              = center

	local titleLbl               = Instance.new("TextLabel")
	titleLbl.LayoutOrder         = 1
	titleLbl.AutomaticSize       = Enum.AutomaticSize.XY
	titleLbl.BackgroundTransparency = 1
	titleLbl.Text                = string.upper(config.Title or "FLOOD LIB")
	titleLbl.TextSize            = 13
	titleLbl.FontFace            = Font.fromEnum(Enum.Font.GothamMedium)
	titleLbl.TextColor3          = Color3.fromRGB(200, 215, 235)
	titleLbl.ZIndex              = 501
	titleLbl.Parent              = center

	local statusLbl               = Instance.new("TextLabel")
	statusLbl.Name                = "Status"
	statusLbl.LayoutOrder         = 2
	statusLbl.AutomaticSize       = Enum.AutomaticSize.XY
	statusLbl.BackgroundTransparency = 1
	statusLbl.Text                = "Initialising"
	statusLbl.TextSize            = 10
	statusLbl.FontFace            = Font.fromEnum(Enum.Font.Gotham)
	statusLbl.TextColor3          = Color3.fromRGB(58, 82, 105)
	statusLbl.ZIndex              = 501
	statusLbl.Parent              = center

	local dotRow               = Instance.new("Frame")
	dotRow.LayoutOrder         = 3
	dotRow.AutomaticSize       = Enum.AutomaticSize.XY
	dotRow.BackgroundTransparency = 1
	dotRow.ZIndex              = 501
	dotRow.Parent              = center

	local dotLayout            = Instance.new("UIListLayout")
	dotLayout.FillDirection    = Enum.FillDirection.Horizontal
	dotLayout.VerticalAlignment  = Enum.VerticalAlignment.Center
	dotLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	dotLayout.Padding          = UDim.new(0, 6)
	dotLayout.Parent           = dotRow

	local dots= {}
	for _ = 1, 3 do
		local dot           = Instance.new("Frame")
		dot.Size            = UDim2.fromOffset(4, 4)
		dot.BackgroundColor3 = Color3.fromRGB(30, 55, 80)
		dot.BorderSizePixel = 0
		dot.ZIndex          = 502
		dot.Parent          = dotRow
		local dc            = Instance.new("UICorner")
		dc.CornerRadius     = UDim.new(1, 0)
		dc.Parent           = dot
		table.insert(dots, dot)
	end

	self._overlay   = overlay
	self._statusLbl = statusLbl

	local animRunning = true
	task.spawn(function()
		local i = 1
		while animRunning do
			for j, dot in ipairs(dots) do
				TweenService:Create(dot, j == i and DOT_ON or DOT_OFF, {
					BackgroundColor3 = j == i
						and Color3.fromRGB(60, 150, 230)
						or Color3.fromRGB(30, 55, 80),
					Size = j == i
						and UDim2.fromOffset(5, 5)
						or UDim2.fromOffset(4, 4),
				}):Play()
			end
			i = (i % 3) + 1
			task.wait(0.38)
		end
	end)
	self._stopAnim = function() animRunning = false end

	return self
end

function LoadingScreen:SetStatus(text)
	if self._dismissed or not self._statusLbl then return end
	self._statusLbl.Text = text
end

function LoadingScreen:Dismiss()
	if self._dismissed then return end
	self._dismissed = true
	if self._stopAnim then self._stopAnim() end
	local overlay = self._overlay
	if not overlay or not overlay.Parent then return end
	local t = TweenService:Create(overlay, FADE, { BackgroundTransparency = 1 })
	t:Play()
	t.Completed:Connect(function()
		if overlay.Parent then overlay:Destroy() end
	end)
end

return LoadingScreen
end

__M["FloatingNav"]=function()
local RunService   = game:GetService("RunService")
local Creator      = __R("Creator")
local ThemeManager = __R("Manager")
local Tween        = __R("Tween")
local Spring       = __R("Spring")

local NAV_W  = 62
local BTN_SZ = 44
local CORNER = 8
local GAP    = 12



local FloatingNav = {}
FloatingNav.__index = FloatingNav

local function glassGradient()
	return Creator.New("UIGradient", {
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0,    Color3.fromRGB(30, 44, 64)),
			ColorSequenceKeypoint.new(0.42, Color3.fromRGB(10, 14, 22)),
			ColorSequenceKeypoint.new(1,    Color3.fromRGB(5,   7, 14)),
		}),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.08),
			NumberSequenceKeypoint.new(1, 0.22),
		}),
		Rotation = 155,
	})
end

function FloatingNav.new(screenGui, anchorX, anchorY, height)
	local self    = setmetatable({}, FloatingNav)
	self._entries = {}
	self._btns    = {}
	self._activeId = ""
	self._attached = true

	local t = ThemeManager.CurrentTheme

	local shadow = Creator.New("Frame", {
		Name                   = "NavShadow",
		Position               = UDim2.fromOffset(anchorX - GAP - NAV_W - 5, anchorY - 5),
		Size                   = UDim2.fromOffset(NAV_W + 10, height + 10),
		BackgroundColor3       = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.6,
		BorderSizePixel        = 0,
		ZIndex                 = 3,
		Parent                 = screenGui,
	}, { Creator.New("UICorner", { CornerRadius = UDim.new(0, CORNER + 2) }) })

	local panel = Creator.New("Frame", {
		Name                   = "FloatingNav",
		Position               = UDim2.fromOffset(anchorX - GAP - NAV_W, anchorY),
		Size                   = UDim2.fromOffset(NAV_W, height),
		BackgroundColor3       = t.Panel,
		BackgroundTransparency = t.Glass,
		BorderSizePixel        = 0,
		ZIndex                 = 4,
		ThemeTag               = { BackgroundColor3 = "Panel" },
		Parent                 = screenGui,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, CORNER) }),
		Creator.New("UIStroke", {
			Thickness       = 1,
			Color           = t.BorderBright,
			Transparency    = 0.50,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag        = { Color = "BorderBright" },
		}),
		Creator.New("UIListLayout", {
			SortOrder           = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding             = UDim.new(0, 2),
		}),
		Creator.New("UIPadding", { PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }),
		glassGradient(),
	})

	self._panel  = panel
	self._shadow = shadow

	local sprX = Spring.new(panel.Position.X.Offset, 18, 0.80)
	local sprY = Spring.new(panel.Position.Y.Offset, 18, 0.80)
	self._sprX = sprX
	self._sprY = sprY

	local conn = RunService.Heartbeat:Connect(function(dt)
		if not self._attached then return end
		sprX:Step(dt)
		sprY:Step(dt)
		local x = math.round(sprX.Position)
		local y = math.round(sprY.Position)
		panel.Position  = UDim2.fromOffset(x, y)
		shadow.Position = UDim2.fromOffset(x - 5, y - 5)
	end)
	self._conn = conn

	return self
end

function FloatingNav:AddEntry(entry)
	table.insert(self._entries, entry)
	local t     = ThemeManager.CurrentTheme
	local order = #self._entries

	local railBtn = Creator.New("Frame", {
		Name                   = "NavBtn_" .. entry.Id,
		LayoutOrder            = order,
		Size                   = UDim2.fromOffset(NAV_W - 12, BTN_SZ),
		BackgroundColor3       = t.ControlBg,
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		ThemeTag               = { BackgroundColor3 = "ControlBg" },
		Parent                 = self._panel,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Creator.New("Frame", {
			Name                   = "ActiveBar",
			AnchorPoint            = Vector2.new(0, 0.5),
			Position               = UDim2.new(0, -7, 0.5, 0),
			Size                   = UDim2.fromOffset(2, 16),
			BackgroundColor3       = t.Accent,
			BackgroundTransparency = 1,
			BorderSizePixel        = 0,
			ThemeTag               = { BackgroundColor3 = "Accent" },
		}, { Creator.New("UICorner", { CornerRadius = UDim.new(0, 1) }) }),
		Creator.New("TextLabel", {
			Name                   = "Icon",
			AnchorPoint            = Vector2.new(0.5, 0),
			Position               = UDim2.new(0.5, 0, 0, 6),
			Size                   = UDim2.new(1, 0, 0, 16),
			BackgroundTransparency = 1,
			Text                   = entry.Icon,
			TextSize               = 11,
			FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
			TextColor3             = t.SubText,
			ThemeTag               = { TextColor3 = "SubText" },
		}),
		Creator.New("TextLabel", {
			Name                   = "Label",
			AnchorPoint            = Vector2.new(0.5, 1),
			Position               = UDim2.new(0.5, 0, 1, -5),
			Size                   = UDim2.new(1, -4, 0, 11),
			BackgroundTransparency = 1,
			Text                   = string.upper(entry.Label),
			TextSize               = 7,
			FontFace               = Font.fromEnum(Enum.Font.Gotham),
			TextColor3             = t.SubText,
			TextXAlignment         = Enum.TextXAlignment.Center,
			ThemeTag               = { TextColor3 = "SubText" },
		}),
	})

	local clickBtn = Creator.New("TextButton", {
		Name                   = "Click",
		Size                   = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		Parent                 = railBtn,
	})

	local icon  = railBtn:FindFirstChild("Icon")
	local label = railBtn:FindFirstChild("Label")
	local bar   = railBtn:FindFirstChild("ActiveBar")

	local function onActivate()
		Tween.Play(railBtn, Tween.Fast, { BackgroundTransparency = 0 })
		Tween.Play(icon,  Tween.Fast, { TextColor3 = ThemeManager.CurrentTheme.Accent })
		Tween.Play(label, Tween.Fast, { TextColor3 = ThemeManager.CurrentTheme.Accent })
		Tween.Play(bar,   Tween.Fast, { BackgroundTransparency = 0 })
	end

	local function onDeactivate()
		Tween.Play(railBtn, Tween.Fast, { BackgroundTransparency = 1 })
		Tween.Play(icon,  Tween.Fast, { TextColor3 = ThemeManager.CurrentTheme.SubText })
		Tween.Play(label, Tween.Fast, { TextColor3 = ThemeManager.CurrentTheme.SubText })
		Tween.Play(bar,   Tween.Fast, { BackgroundTransparency = 1 })
	end

	clickBtn.MouseEnter:Connect(function()
		if self._activeId ~= entry.Id then
			Tween.Play(railBtn, Tween.Fast, { BackgroundTransparency = 0.7 })
		end
	end)
	clickBtn.MouseLeave:Connect(function()
		if self._activeId ~= entry.Id then
			onDeactivate()
		end
	end)
	clickBtn.MouseButton1Click:Connect(function()
		entry.SelectFn()
	end)

	local record= {
		id           = entry.Id,
		rail         = railBtn,
		onActivate   = onActivate,
		onDeactivate = onDeactivate,
	}
	table.insert(self._btns, record)
end

function FloatingNav:SelectById(id)
	self._activeId = id
	for _, b in ipairs(self._btns) do
		if b.id == id then
			b.onActivate()
		else
			b.onDeactivate()
		end
	end
end

function FloatingNav:Follow(x, y, height)
	if not self._attached then return end
	self._sprX:SetTarget(x - GAP - NAV_W)
	self._sprY:SetTarget(y)
	self._panel.Size  = UDim2.fromOffset(NAV_W, height)
	self._shadow.Size = UDim2.fromOffset(NAV_W + 10, height + 10)
end

function FloatingNav:SetVisible(visible)
	self._panel.Visible  = visible
	self._shadow.Visible = visible
end

function FloatingNav:GetWidth()
	return NAV_W
end

function FloatingNav:GetGap()
	return GAP
end

function FloatingNav:Destroy()
	self._conn:Disconnect()
	self._panel:Destroy()
	self._shadow:Destroy()
end

return FloatingNav
end

__M["SearchBar"]=function()
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Creator          = __R("Creator")
local ThemeManager     = __R("Manager")
local Tween            = __R("Tween")
local Spring           = __R("Spring")

local BAR_H  = 34
local GAP    = 10
local CORNER = 8


local SearchBar = {}
SearchBar.__index = SearchBar

function SearchBar.new(screenGui, anchorX, anchorY, width)
	local self       = setmetatable({}, SearchBar)
	self._entries    = {}
	self._resultFrames = {}
	self._query      = ""

	local t = ThemeManager.CurrentTheme

	local shadow = Creator.New("Frame", {
		Name                   = "SearchShadow",
		Position               = UDim2.fromOffset(anchorX - 4, anchorY + GAP - 4),
		Size                   = UDim2.fromOffset(width + 8, BAR_H + 8),
		BackgroundColor3       = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.62,
		BorderSizePixel        = 0,
		ZIndex                 = 3,
		Parent                 = screenGui,
	}, { Creator.New("UICorner", { CornerRadius = UDim.new(0, CORNER + 2) }) })

	local bar = Creator.New("Frame", {
		Name                   = "SearchBar",
		Position               = UDim2.fromOffset(anchorX, anchorY + GAP),
		Size                   = UDim2.fromOffset(width, BAR_H),
		BackgroundColor3       = t.Panel,
		BackgroundTransparency = t.Glass,
		BorderSizePixel        = 0,
		ZIndex                 = 4,
		ThemeTag               = { BackgroundColor3 = "Panel" },
		Parent                 = screenGui,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, CORNER) }),
		Creator.New("UIStroke", {
			Thickness       = 1,
			Color           = t.Border,
			Transparency    = 0.40,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag        = { Color = "Border" },
		}),
		Creator.New("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0,   Color3.fromRGB(16, 28, 40)),
				ColorSequenceKeypoint.new(1,   Color3.fromRGB(8,  13, 20)),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.05),
				NumberSequenceKeypoint.new(1, 0.18),
			}),
			Rotation = 90,
		}),
	})

	local iconLbl = Creator.New("TextLabel", {
		Name                   = "Icon",
		AnchorPoint            = Vector2.new(0, 0.5),
		Position               = UDim2.new(0, 10, 0.5, 0),
		Size                   = UDim2.fromOffset(14, 14),
		BackgroundTransparency = 1,
		Text                   = "⌕",
		TextSize               = 13,
		FontFace               = Font.fromEnum(Enum.Font.Gotham),
		TextColor3             = t.SubText,
		ZIndex                 = 5,
		ThemeTag               = { TextColor3 = "SubText" },
		Parent                 = bar,
	})
	_ = iconLbl

	local input = Creator.New("TextBox", {
		Name                        = "Input",
		AnchorPoint                 = Vector2.new(0, 0.5),
		Position                    = UDim2.new(0, 30, 0.5, 0),
		Size                        = UDim2.new(1, -44, 0, 20),
		BackgroundTransparency      = 1,
		Text                        = "",
		PlaceholderText             = "Search",
		PlaceholderColor3           = t.TextDisabled,
		TextSize                    = 11,
		FontFace                    = Font.fromEnum(Enum.Font.Gotham),
		TextColor3                  = t.Text,
		TextXAlignment              = Enum.TextXAlignment.Left,
		ClearTextOnFocus            = false,
		ZIndex                      = 5,
		ThemeTag                    = { TextColor3 = "Text", PlaceholderColor3 = "TextDisabled" },
		Parent                      = bar,
	})

	local resultsFrame = Creator.New("Frame", {
		Name                   = "Results",
		AnchorPoint            = Vector2.new(0, 0),
		Position               = UDim2.new(0, 0, 1, 4),
		Size                   = UDim2.new(1, 0, 0, 0),
		AutomaticSize          = Enum.AutomaticSize.Y,
		BackgroundColor3       = t.Panel,
		BackgroundTransparency = 0.04,
		BorderSizePixel        = 0,
		ZIndex                 = 6,
		Visible                = false,
		ClipsDescendants       = true,
		ThemeTag               = { BackgroundColor3 = "Panel" },
		Parent                 = bar,
	}, {
		Creator.New("UICorner",    { CornerRadius = UDim.new(0, CORNER) }),
		Creator.New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding   = UDim.new(0, 1),
		}),
		Creator.New("UIStroke", {
			Thickness       = 1,
			Color           = t.Border,
			Transparency    = 0.40,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag        = { Color = "Border" },
		}),
	})

	self._bar          = bar
	self._shadow       = shadow
	self._input        = input
	self._resultsFrame = resultsFrame

	local sprX = Spring.new(bar.Position.X.Offset, 18, 0.80)
	local sprY = Spring.new(bar.Position.Y.Offset, 18, 0.80)
	self._sprX = sprX
	self._sprY = sprY

	local heartbeat = RunService.Heartbeat:Connect(function(dt)
		sprX:Step(dt)
		sprY:Step(dt)
		local x = math.round(sprX.Position)
		local y = math.round(sprY.Position)
		bar.Position    = UDim2.fromOffset(x, y)
		shadow.Position = UDim2.fromOffset(x - 4, y - 4)
	end)
	self._heartbeat = heartbeat

	input:GetPropertyChangedSignal("Text"):Connect(function()
		self:_Refresh(input.Text)
	end)

	input.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			self:_SelectFirst()
		end
		task.delay(0.15, function()
			if not input:IsFocused() then
				resultsFrame.Visible = false
			end
		end)
	end)

	input.Focused:Connect(function()
		if self._query ~= "" then
			resultsFrame.Visible = true
		end
	end)

	UserInputService.InputBegan:Connect(function(inp, processed)
		if processed then return end
		if inp.KeyCode == Enum.KeyCode.Slash then
			input:CaptureFocus()
		end
	end)

	return self
end

function SearchBar:_ClearResults()
	for _, f in ipairs(self._resultFrames) do
		f:Destroy()
	end
	self._resultFrames = {}
end

function SearchBar:_Refresh(query)
	self._query = query
	self:_ClearResults()

	if query == "" then
		self._resultsFrame.Visible = false
		return
	end

	local lower = string.lower(query)
	local matches= {}
	for _, e in ipairs(self._entries) do
		if string.find(string.lower(e.Label), lower, 1, true) then
			table.insert(matches, e)
			if #matches >= 6 then break end
		end
	end

	if #matches == 0 then
		self._resultsFrame.Visible = false
		return
	end

	local t = ThemeManager.CurrentTheme
	for i, entry in ipairs(matches) do
		local row = Creator.New("TextButton", {
			Name                   = "Row_" .. entry.Id,
			LayoutOrder            = i,
			Size                   = UDim2.new(1, 0, 0, 28),
			BackgroundColor3       = t.ControlBg,
			BackgroundTransparency = 1,
			Text                   = "",
			AutoButtonColor        = false,
			BorderSizePixel        = 0,
			ZIndex                 = 7,
			Parent                 = self._resultsFrame,
		})

		Creator.New("TextLabel", {
			AnchorPoint            = Vector2.new(0, 0.5),
			Position               = UDim2.new(0, 12, 0.5, 0),
			Size                   = UDim2.new(1, -12, 0, 14),
			BackgroundTransparency = 1,
			Text                   = entry.Label,
			TextSize               = 10,
			FontFace               = Font.fromEnum(Enum.Font.Gotham),
			TextColor3             = t.Text,
			TextXAlignment         = Enum.TextXAlignment.Left,
			ZIndex                 = 7,
			ThemeTag               = { TextColor3 = "Text" },
			Parent                 = row,
		})

		row.MouseEnter:Connect(function()
			Tween.Play(row, Tween.Fast, { BackgroundTransparency = 0.60 })
		end)
		row.MouseLeave:Connect(function()
			Tween.Play(row, Tween.Fast, { BackgroundTransparency = 1 })
		end)
		row.MouseButton1Click:Connect(function()
			self._resultsFrame.Visible = false
			self._input.Text           = ""
			self._query                = ""
			entry.SelectFn()
		end)

		table.insert(self._resultFrames, row)
	end

	self._resultsFrame.Visible = true
end

function SearchBar:_SelectFirst()
	if #self._resultFrames > 0 then
		(self._resultFrames[1]).MouseButton1Click:Fire()
	end
end

function SearchBar:RegisterElement(entry)
	table.insert(self._entries, entry)
end

function SearchBar:Follow(x, y, width)
	self._sprX:SetTarget(x)
	self._sprY:SetTarget(y + GAP)
	self._bar.Size    = UDim2.fromOffset(width, BAR_H)
	self._shadow.Size = UDim2.fromOffset(width + 8, BAR_H + 8)
end

function SearchBar:SetVisible(visible)
	self._bar.Visible    = visible
	self._shadow.Visible = visible
	if not visible then
		self._resultsFrame.Visible = false
	end
end

function SearchBar:Destroy()
	self._heartbeat:Disconnect()
	self._bar:Destroy()
	self._shadow:Destroy()
end

return SearchBar
end

__M["EdgeReveal"]=function()
local RunService   = game:GetService("RunService")
local Spring       = __R("Spring")
local Tween        = __R("Tween")
local Creator      = __R("Creator")
local ThemeManager = __R("Manager")

local SIDEBAR_W = 164
local TRIGGER_W = 22


local EdgeReveal = {}
EdgeReveal.__index = EdgeReveal

function EdgeReveal.new(screenGui, restoreFn)
	local self = setmetatable({}, EdgeReveal)
	self._active      = false
	self._leaveTimer  = nil
	self._tabs        = {}
	self._tabItems    = {}
	self._restoreFn   = restoreFn

	local t = ThemeManager.CurrentTheme

	local triggerZone = Creator.New("Frame", {
		Name                 = "EdgeTrigger",
		Position             = UDim2.fromOffset(0, 0),
		Size                 = UDim2.new(0, TRIGGER_W, 1, 0),
		BackgroundTransparency = 1,
		ZIndex               = 97,
		Visible              = false,
		Parent               = screenGui,
	})

	local sidebar = Creator.New("Frame", {
		Name                   = "EdgeSidebar",
		Position               = UDim2.fromOffset(-SIDEBAR_W, 0),
		Size                   = UDim2.new(0, SIDEBAR_W, 1, 0),
		BackgroundColor3       = t.Panel,
		BackgroundTransparency = 0.08,
		BorderSizePixel        = 0,
		ClipsDescendants       = true,
		ZIndex                 = 98,
		Visible                = false,
		Parent                 = screenGui,
		ThemeTag               = { BackgroundColor3 = "Panel" },
	}, {
		Creator.New("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0,   Color3.fromRGB(28, 36, 58)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(10, 12, 20)),
				ColorSequenceKeypoint.new(1,   Color3.fromRGB(6,   8, 14)),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0,   0.0),
				NumberSequenceKeypoint.new(1,   0.1),
			}),
			Rotation = 100,
		}),
		Creator.New("UIStroke", {
			Thickness      = 1,
			Color          = t.Border,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag       = { Color = "Border" },
		}),
	})

	Creator.New("Frame", {
		Name                   = "RightEdge",
		AnchorPoint            = Vector2.new(1, 0),
		Position               = UDim2.fromScale(1, 0),
		Size                   = UDim2.new(0, 1, 1, 0),
		BackgroundColor3       = t.BorderBright,
		BackgroundTransparency = 0.6,
		BorderSizePixel        = 0,
		ZIndex                 = 99,
		ThemeTag               = { BackgroundColor3 = "BorderBright" },
		Parent                 = sidebar,
	})

	local header = Creator.New("Frame", {
		Name                   = "Header",
		Size                   = UDim2.new(1, 0, 0, 60),
		BackgroundTransparency = 1,
		ZIndex                 = 99,
		Parent                 = sidebar,
	}, {
		Creator.New("Frame", {
			Name             = "AccentMark",
			AnchorPoint      = Vector2.new(0, 0.5),
			Position         = UDim2.fromOffset(18, 30),
			Size             = UDim2.fromOffset(3, 20),
			BackgroundColor3 = t.Accent,
			BorderSizePixel  = 0,
			ZIndex           = 99,
			ThemeTag         = { BackgroundColor3 = "Accent" },
		}, { Creator.New("UICorner", { CornerRadius = UDim.new(0, 2) }) }),
		Creator.New("TextLabel", {
			Name                 = "LibName",
			AnchorPoint          = Vector2.new(0, 0.5),
			Position             = UDim2.fromOffset(30, 30),
			Size                 = UDim2.new(1, -34, 0, 16),
			BackgroundTransparency = 1,
			Text                 = "FLOOD",
			TextSize             = 11,
			FontFace             = Font.fromEnum(Enum.Font.GothamMedium),
			TextColor3           = t.Text,
			TextXAlignment       = Enum.TextXAlignment.Left,
			ZIndex               = 99,
			ThemeTag             = { TextColor3 = "Text" },
		}),
		Creator.New("Frame", {
			Name             = "Divider",
			AnchorPoint      = Vector2.new(0, 1),
			Position         = UDim2.fromScale(0, 1),
			Size             = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = t.Border,
			BorderSizePixel  = 0,
			ZIndex           = 99,
			ThemeTag         = { BackgroundColor3 = "Border" },
		}),
	})

	local tabList = Creator.New("Frame", {
		Name                   = "TabList",
		Position               = UDim2.fromOffset(0, 61),
		Size                   = UDim2.new(1, 0, 1, -93),
		BackgroundTransparency = 1,
		ClipsDescendants       = true,
		ZIndex                 = 99,
		Parent                 = sidebar,
	}, {
		Creator.New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding   = UDim.new(0, 2),
		}),
		Creator.New("UIPadding", {
			PaddingTop    = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft   = UDim.new(0, 8),
			PaddingRight  = UDim.new(0, 8),
		}),
	})

	Creator.New("Frame", {
		Name                   = "Footer",
		AnchorPoint            = Vector2.new(0, 1),
		Position               = UDim2.fromScale(0, 1),
		Size                   = UDim2.new(1, 0, 0, 32),
		BackgroundTransparency = 1,
		ZIndex                 = 99,
		Parent                 = sidebar,
	}, {
		Creator.New("Frame", {
			Name             = "Divider",
			Size             = UDim2.new(1, 0, 0, 1),
			BackgroundColor3 = t.Border,
			BorderSizePixel  = 0,
			ZIndex           = 99,
			ThemeTag         = { BackgroundColor3 = "Border" },
		}),
		Creator.New("TextLabel", {
			Position             = UDim2.fromOffset(18, 2),
			Size                 = UDim2.new(1, -18, 1, -2),
			BackgroundTransparency = 1,
			Text                 = "hover to restore",
			TextSize             = 9,
			FontFace             = Font.fromEnum(Enum.Font.Gotham),
			TextColor3           = t.TextDisabled,
			TextXAlignment       = Enum.TextXAlignment.Left,
			ZIndex               = 99,
			ThemeTag             = { TextColor3 = "TextDisabled" },
		}),
	})

	local springX = Spring.new(-SIDEBAR_W, 22, 0.76)

	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		if not self._active then return end
		springX:Step(dt)
		local x = math.round(springX.Position)
		sidebar.Position      = UDim2.fromOffset(x, 0)
		triggerZone.Position  = UDim2.fromOffset(math.max(0, x + SIDEBAR_W - TRIGGER_W), 0)
	end)

	local function startSpring(target)
		springX:SetTarget(target)
	end

	local function cancelLeave()
		if self._leaveTimer then
			task.cancel(self._leaveTimer)
			self._leaveTimer = nil
		end
	end

	local function scheduleHide()
		cancelLeave()
		self._leaveTimer = task.delay(0.55, function()
			self._leaveTimer = nil
			startSpring(-SIDEBAR_W)
		end)
	end

	triggerZone.MouseEnter:Connect(function()
		cancelLeave()
		startSpring(0)
	end)
	sidebar.MouseEnter:Connect(function()
		cancelLeave()
		startSpring(0)
	end)
	triggerZone.MouseLeave:Connect(scheduleHide)
	sidebar.MouseLeave:Connect(scheduleHide)

	self._triggerZone = triggerZone
	self._sidebar     = sidebar
	self._tabList     = tabList
	self._springX     = springX
	self._conn        = conn

	return self
end

function EdgeReveal:AddTab(entry)
	table.insert(self._tabs, entry)
	local t = ThemeManager.CurrentTheme

	local item = Creator.New("TextButton", {
		Name                   = "Tab_" .. entry.Title,
		Size                   = UDim2.new(1, 0, 0, 34),
		BackgroundColor3       = t.ControlBg,
		BackgroundTransparency = 1,
		Text                   = "",
		AutoButtonColor        = false,
		BorderSizePixel        = 0,
		ZIndex                 = 100,
		Parent                 = self._tabList,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }),
		Creator.New("TextLabel", {
			Name                   = "Icon",
			AnchorPoint            = Vector2.new(0, 0.5),
			Position               = UDim2.fromOffset(8, 17),
			Size                   = UDim2.fromOffset(20, 20),
			BackgroundTransparency = 1,
			Text                   = entry.Icon,
			TextSize               = 11,
			FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
			TextColor3             = t.SubText,
			ZIndex                 = 100,
			ThemeTag               = { TextColor3 = "SubText" },
		}),
		Creator.New("TextLabel", {
			Name                   = "Label",
			AnchorPoint            = Vector2.new(0, 0.5),
			Position               = UDim2.fromOffset(32, 17),
			Size                   = UDim2.new(1, -36, 0, 14),
			BackgroundTransparency = 1,
			Text                   = entry.Title,
			TextSize               = 10,
			FontFace               = Font.fromEnum(Enum.Font.Gotham),
			TextColor3             = t.SubText,
			TextXAlignment         = Enum.TextXAlignment.Left,
			ZIndex                 = 100,
			ThemeTag               = { TextColor3 = "SubText" },
		}),
	})

	item.MouseEnter:Connect(function()
		Tween.Play(item, Tween.Fast, {
			BackgroundTransparency = 0,
			BackgroundColor3       = t.ControlBg,
		})
		local lbl = item:FindFirstChild("Label")
		local ico = item:FindFirstChild("Icon")
		if lbl then Tween.Play(lbl, Tween.Fast, { TextColor3 = t.Text }) end
		if ico then Tween.Play(ico, Tween.Fast, { TextColor3 = t.Accent }) end
	end)
	item.MouseLeave:Connect(function()
		Tween.Play(item, Tween.Fast, { BackgroundTransparency = 1 })
		local lbl = item:FindFirstChild("Label")
		local ico = item:FindFirstChild("Icon")
		if lbl then Tween.Play(lbl, Tween.Fast, { TextColor3 = t.SubText }) end
		if ico then Tween.Play(ico, Tween.Fast, { TextColor3 = t.SubText }) end
	end)
	item.MouseButton1Click:Connect(function()
		entry.SelectFn()
	end)

	table.insert(self._tabItems, item)
end

function EdgeReveal:Activate()
	self._active = true
	self._springX.Target   = -SIDEBAR_W
	self._springX.Position = -SIDEBAR_W
	self._springX.Velocity = 0
	self._triggerZone.Visible = true
	self._sidebar.Visible     = true
end

function EdgeReveal:Deactivate()
	self._active = false
	self._springX:SetTarget(-SIDEBAR_W)
	task.delay(0.55, function()
		if not self._active then
			self._triggerZone.Visible = false
			self._sidebar.Visible     = false
		end
	end)
end

function EdgeReveal:Destroy()
	self._conn:Disconnect()
end

return EdgeReveal
end

__M["EdgeSidebar"]=function()
local RunService   = game:GetService("RunService")
local Creator      = __R("Creator")
local ThemeManager = __R("Manager")
local Tween        = __R("Tween")
local Spring       = __R("Spring")

local CLIP_W   = 40
local INNER_W  = 48
local INNER_OX = -8
local BTN_SZ   = 36
local CORNER   = 10
local GAP_TOP  = 8


local EdgeSidebar = {}
EdgeSidebar.__index = EdgeSidebar

function EdgeSidebar.new(screenGui, anchorY, height)
	local self    = setmetatable({}, EdgeSidebar)
	self._entries = {}
	self._shown   = false

	local t = ThemeManager.CurrentTheme

	local clipper = Creator.New("Frame", {
		Name                   = "EdgeSidebarClip",
		AnchorPoint            = Vector2.new(0, 0),
		Position               = UDim2.fromOffset(0, anchorY),
		Size                   = UDim2.fromOffset(CLIP_W, height),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		ClipsDescendants       = true,
		ZIndex                 = 8,
		Parent                 = screenGui,
	})

	local inner = Creator.New("Frame", {
		Name                   = "EdgeSidebarInner",
		Position               = UDim2.fromOffset(INNER_OX, 0),
		Size                   = UDim2.fromOffset(INNER_W, height),
		BackgroundColor3       = t.Panel,
		BackgroundTransparency = t.Glass,
		BorderSizePixel        = 0,
		ZIndex                 = 8,
		ThemeTag               = { BackgroundColor3 = "Panel" },
		Parent                 = clipper,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(0, CORNER) }),
		Creator.New("UIStroke", {
			Thickness       = 1,
			Color           = t.BorderBright,
			Transparency    = 0.55,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag        = { Color = "BorderBright" },
		}),
		Creator.New("UIListLayout", {
			SortOrder           = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding             = UDim.new(0, 4),
		}),
		Creator.New("UIPadding", {
			PaddingTop    = UDim.new(0, GAP_TOP),
			PaddingBottom = UDim.new(0, GAP_TOP),
			PaddingLeft   = UDim.new(0, INNER_W - CLIP_W),
		}),
		Creator.New("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 36, 52)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(8,  13, 20)),
			}),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.06),
				NumberSequenceKeypoint.new(1, 0.20),
			}),
			Rotation = 90,
		}),
	})

	self._clipper = clipper
	self._inner   = inner
	self._height  = height
	self._anchorY = anchorY

	local hiddenX  = -CLIP_W
	local shownX   = 0
	local sprX     = Spring.new(hiddenX, 22, 0.82)
	self._sprX     = sprX
	self._hiddenX  = hiddenX
	self._shownX   = shownX

	local conn = RunService.Heartbeat:Connect(function(dt)
		sprX:Step(dt)
		local x = math.round(sprX.Position)
		clipper.Position = UDim2.fromOffset(x, self._anchorY)
	end)
	self._conn = conn

	self:_AddRestoreButton()

	return self
end

function EdgeSidebar:_AddRestoreButton()
	local t  = ThemeManager.CurrentTheme
	local btn = Creator.New("TextButton", {
		Name                   = "RestoreBtn",
		LayoutOrder            = 0,
		Size                   = UDim2.fromOffset(BTN_SZ - 4, BTN_SZ - 4),
		BackgroundColor3       = t.Accent,
		BackgroundTransparency = 0.70,
		Text                   = "▶",
		TextSize               = 9,
		FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
		TextColor3             = t.Accent,
		AutoButtonColor        = false,
		BorderSizePixel        = 0,
		ZIndex                 = 9,
		ThemeTag               = { BackgroundColor3 = "AccentMuted", TextColor3 = "Accent" },
		Parent                 = self._inner,
	}, { Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }) })

	btn.MouseEnter:Connect(function()
		Tween.Play(btn, Tween.Fast, { BackgroundTransparency = 0.40 })
	end)
	btn.MouseLeave:Connect(function()
		Tween.Play(btn, Tween.Fast, { BackgroundTransparency = 0.70 })
	end)

	self._restoreBtn    = btn
	self._restoreSignal = btn.MouseButton1Click
end

function EdgeSidebar:OnRestore(fn)
	self._restoreConn = self._restoreSignal:Connect(fn)
end

function EdgeSidebar:AddEntry(entry)
	table.insert(self._entries, entry)
	local t     = ThemeManager.CurrentTheme
	local order = #self._entries + 1

	local btn = Creator.New("TextButton", {
		Name                   = "SideBtn_" .. entry.Id,
		LayoutOrder            = order,
		Size                   = UDim2.fromOffset(BTN_SZ - 4, BTN_SZ - 4),
		BackgroundColor3       = t.ControlBg,
		BackgroundTransparency = 0.80,
		Text                   = entry.Icon,
		TextSize               = 11,
		FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
		TextColor3             = t.SubText,
		AutoButtonColor        = false,
		BorderSizePixel        = 0,
		ZIndex                 = 9,
		ThemeTag               = { BackgroundColor3 = "ControlBg", TextColor3 = "SubText" },
		Parent                 = self._inner,
	}, { Creator.New("UICorner", { CornerRadius = UDim.new(0, 6) }) })

	btn.MouseEnter:Connect(function()
		Tween.Play(btn, Tween.Fast, { BackgroundTransparency = 0.40, TextColor3 = ThemeManager.CurrentTheme.Text })
	end)
	btn.MouseLeave:Connect(function()
		Tween.Play(btn, Tween.Fast, { BackgroundTransparency = 0.80, TextColor3 = ThemeManager.CurrentTheme.SubText })
	end)
	btn.MouseButton1Click:Connect(function()
		entry.OnClick()
	end)
end

function EdgeSidebar:Show()
	self._shown = true
	self._sprX:SetTarget(self._shownX)
	self._clipper.Visible = true
end

function EdgeSidebar:Hide()
	self._shown = false
	self._sprX:SetTarget(self._hiddenX)
end

function EdgeSidebar:Reposition(anchorY, height)
	self._anchorY = anchorY
	self._height  = height
	self._clipper.Size = UDim2.fromOffset(CLIP_W, height)
	self._inner.Size   = UDim2.fromOffset(INNER_W, height)
end

function EdgeSidebar:Destroy()
	self._conn:Disconnect()
	if self._restoreConn then self._restoreConn:Disconnect() end
	self._clipper:Destroy()
end

return EdgeSidebar
end

__M["Dashboard"]=function()
local Players          = game:GetService("Players")
local Creator          = __R("Creator")
local ThemeManager     = __R("Manager")

local AVATAR_SZ = 52
local THUMB_TYPE = Enum.ThumbnailType.HeadShot
local THUMB_SZ   = Enum.ThumbnailSize.Size100x100

local Dashboard = {}
Dashboard.__index = Dashboard

function Dashboard.new(parent)
	local self = setmetatable({}, Dashboard)

	local t = ThemeManager.CurrentTheme

	local page = Creator.New("Frame", {
		Name                   = "DashboardPage",
		Size                   = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Visible                = true,
		Parent                 = parent,
	})

	local headerRow = Creator.New("Frame", {
		Name                   = "HeaderRow",
		Size                   = UDim2.new(1, -24, 0, AVATAR_SZ),
		Position               = UDim2.fromOffset(12, 16),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Parent                 = page,
	}, {
		Creator.New("UIListLayout", {
			FillDirection       = Enum.FillDirection.Horizontal,
			VerticalAlignment   = Enum.VerticalAlignment.Center,
			SortOrder           = Enum.SortOrder.LayoutOrder,
			Padding             = UDim.new(0, 12),
		}),
	})

	local avatarFrame = Creator.New("Frame", {
		Name                   = "AvatarFrame",
		LayoutOrder            = 1,
		Size                   = UDim2.fromOffset(AVATAR_SZ, AVATAR_SZ),
		BackgroundColor3       = t.ControlBg,
		BackgroundTransparency = 0,
		BorderSizePixel        = 0,
		ThemeTag               = { BackgroundColor3 = "ControlBg" },
		Parent                 = headerRow,
	}, {
		Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }),
		Creator.New("UIStroke", {
			Thickness       = 1.5,
			Color           = t.Accent,
			Transparency    = 0.60,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			ThemeTag        = { Color = "Accent" },
		}),
	})

	local avatarImg = Creator.New("ImageLabel", {
		Name                   = "AvatarImg",
		Size                   = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image                  = "",
		ZIndex                 = 2,
		Parent                 = avatarFrame,
	}, { Creator.New("UICorner", { CornerRadius = UDim.new(1, 0) }) })

	local textCol = Creator.New("Frame", {
		Name                   = "TextCol",
		LayoutOrder            = 2,
		Size                   = UDim2.new(1, -(AVATAR_SZ + 12), 0, AVATAR_SZ),
		BackgroundTransparency = 1,
		BorderSizePixel        = 0,
		Parent                 = headerRow,
	}, {
		Creator.New("UIListLayout", {
			SortOrder           = Enum.SortOrder.LayoutOrder,
			VerticalAlignment   = Enum.VerticalAlignment.Center,
			Padding             = UDim.new(0, 3),
		}),
	})

	Creator.New("TextLabel", {
		Name                   = "WelcomeLabel",
		LayoutOrder            = 1,
		AutomaticSize          = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text                   = "WELCOME",
		TextSize               = 8,
		FontFace               = Font.fromEnum(Enum.Font.Gotham),
		TextColor3             = t.SubText,
		TextXAlignment         = Enum.TextXAlignment.Left,
		ThemeTag               = { TextColor3 = "SubText" },
		Parent                 = textCol,
	})

	local nameLbl = Creator.New("TextLabel", {
		Name                   = "NameLabel",
		LayoutOrder            = 2,
		AutomaticSize          = Enum.AutomaticSize.XY,
		BackgroundTransparency = 1,
		Text                   = "...",
		TextSize               = 16,
		FontFace               = Font.fromEnum(Enum.Font.GothamBold),
		TextColor3             = t.Text,
		TextXAlignment         = Enum.TextXAlignment.Left,
		ThemeTag               = { TextColor3 = "Text" },
		Parent                 = textCol,
	})

	local divider = Creator.New("Frame", {
		Name                   = "Divider",
		Position               = UDim2.fromOffset(12, AVATAR_SZ + 28),
		Size                   = UDim2.new(1, -24, 0, 1),
		BackgroundColor3       = t.Border,
		BackgroundTransparency = 0.40,
		BorderSizePixel        = 0,
		ThemeTag               = { BackgroundColor3 = "Border" },
		Parent                 = page,
	})
	_ = divider

	local contentArea = Creator.New("ScrollingFrame", {
		Name                       = "ContentArea",
		Position                   = UDim2.fromOffset(0, AVATAR_SZ + 38),
		Size                       = UDim2.new(1, 0, 1, -(AVATAR_SZ + 38)),
		BackgroundTransparency     = 1,
		BorderSizePixel            = 0,
		ScrollBarThickness         = 3,
		ScrollBarImageColor3       = t.Border,
		AutomaticCanvasSize        = Enum.AutomaticSize.Y,
		CanvasSize                 = UDim2.fromScale(0, 0),
		ThemeTag                   = { ScrollBarImageColor3 = "Border" },
		Parent                     = page,
	}, {
		Creator.New("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding   = UDim.new(0, 8),
		}),
		Creator.New("UIPadding", {
			PaddingLeft   = UDim.new(0, 12),
			PaddingRight  = UDim.new(0, 12),
			PaddingTop    = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),
	})

	self._page        = page
	self._contentArea = contentArea
	self._nameLbl     = nameLbl
	self._avatarImg   = avatarImg

	task.spawn(function()
		local player = Players.LocalPlayer
		if not player then return end
		nameLbl.Text = player.DisplayName
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(player.UserId, THUMB_TYPE, THUMB_SZ)
		end)
		if ok and img then
			avatarImg.Image = img
		end
	end)

	return self
end

function Dashboard:GetPage()
	return self._page
end

function Dashboard:GetContentArea()
	return self._contentArea
end

function Dashboard:SetVisible(visible)
	self._page.Visible = visible
end

function Dashboard:Destroy()
	self._page:Destroy()
end

return Dashboard
end

__M["Tab"]=function()
local Creator = __R("Creator")
local Section = __R("Section")
local Tween   = __R("Tween")

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
	sec._frame.LayoutOrder = self._sectionCount
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
end

__M["Window"]=function()
local Creator      = __R("Creator")
local ThemeManager = __R("Manager")
local Tween        = __R("Tween")
local SafeParent   = __R("SafeParent")
local Drag         = __R("Drag")
local Tab          = __R("Tab")
local FloatingNav  = __R("FloatingNav")
local SearchBar    = __R("SearchBar")
local EdgeSidebar  = __R("EdgeSidebar")
local Dashboard    = __R("Dashboard")
local LoadingScreen = __R("LoadingScreen")

local MAIN_W   = 680
local MAIN_H   = 460
local TOPBAR_H = 38
local CORNER   = 10


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

	local shadow = Creator.New("Frame", {
		Name                   = "Shadow",
		Position               = UDim2.fromOffset(startX - 8, startY - 8),
		Size                   = UDim2.fromOffset(MAIN_W + 16, MAIN_H + 16),
		BackgroundColor3       = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.52,
		BorderSizePixel        = 0,
		ZIndex                 = 1,
		Parent                 = gui,
	}, { Creator.New("UICorner", { CornerRadius = UDim.new(0, CORNER + 2) }) })

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
		Size                   = UDim2.new(0.5, 0, 0, 18),
		BackgroundTransparency = 1,
		Text                   = config.Title or "Flood",
		TextSize               = 12,
		FontFace               = Font.fromEnum(Enum.Font.GothamMedium),
		TextColor3             = t.Text,
		TextXAlignment         = Enum.TextXAlignment.Left,
		ZIndex                 = 4,
		ThemeTag               = { TextColor3 = "Text" },
		Parent                 = topBar,
	})

	local function makeCtrl(label, anchorOffsetX)
		local btn = Creator.New("TextButton", {
			Name                   = label,
			AnchorPoint            = Vector2.new(1, 0.5),
			Position               = UDim2.new(1, anchorOffsetX, 0.5, 0),
			Size                   = UDim2.fromOffset(24, 24),
			BackgroundColor3       = t.ControlBg,
			BackgroundTransparency = 0.70,
			Text                   = label == "Close" and "✕" or "─",
			TextSize               = 9,
			FontFace               = Font.fromEnum(Enum.Font.Gotham),
			TextColor3             = t.SubText,
			AutoButtonColor        = false,
			BorderSizePixel        = 0,
			ZIndex                 = 4,
			ThemeTag               = { BackgroundColor3 = "ControlBg", TextColor3 = "SubText" },
			Parent                 = topBar,
		}, { Creator.New("UICorner", { CornerRadius = UDim.new(0, 5) }) })
		btn.MouseEnter:Connect(function()
			local hoverColor = label == "Close" and ThemeManager.CurrentTheme.CloseHover or ThemeManager.CurrentTheme.ControlHover
			Tween.Play(btn, Tween.Fast, { BackgroundColor3 = hoverColor, BackgroundTransparency = 0 })
		end)
		btn.MouseLeave:Connect(function()
			Tween.Play(btn, Tween.Fast, { BackgroundColor3 = ThemeManager.CurrentTheme.ControlBg, BackgroundTransparency = 0.70 })
		end)
		return btn
	end

	local closeBtn    = makeCtrl("Close",    -8)
	local minimizeBtn = makeCtrl("Minimize", -36)

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
	self._shadow  = shadow
	self._topBar  = topBar
	self._content = content
	self.ContentContainer = content
	self.Theme    = t

	local nav = FloatingNav.new(gui, startX, startY, MAIN_H)
	self._nav = nav

	local searchEnabled = config.Search and config.Search.Enabled
	local searchBar= nil
	if searchEnabled then
		searchBar = SearchBar.new(gui, startX, startY + MAIN_H, MAIN_W)
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
		shadow.Position = UDim2.fromOffset(x - 8, y - 8)
		nav:Follow(x, y, MAIN_H)
		if searchBar then
			searchBar:Follow(x, y + MAIN_H, MAIN_W)
		end
		sidebar:Reposition(y, MAIN_H)
	end

	local dragHandle = Drag.Attach(topBar, main, function(x, y)
		shadow.Position = UDim2.fromOffset(x - 8, y - 8)
		nav:Follow(x, y, MAIN_H)
		if searchBar then
			searchBar:Follow(x, y + MAIN_H, MAIN_W)
		end
		sidebar:Reposition(y, MAIN_H)
	end)
	self._dragHandle = dragHandle

	closeBtn.MouseButton1Click:Connect(function()
		self:Hide()
	end)
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
end

__M["init"]=function()
local ThemeManager   = __R("Manager")
local Window         = __R("Window")
local Notification   = __R("Notification")

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
end

return __R("init")
