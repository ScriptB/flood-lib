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
