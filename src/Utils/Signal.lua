--!strict
-- High-performance micro-signal implementation for Flood UI Library

local Signal = {}
Signal.__index = Signal

export type Connection = {
    Disconnect: (self: Connection) -> (),
    Connected: boolean,
}

export type Signal<T...> = {
    Connect: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
    Once: (self: Signal<T...>, fn: (T...) -> ()) -> Connection,
    Fire: (self: Signal<T...>, T...) -> (),
    Wait: (self: Signal<T...>) -> T...,
    Destroy: (self: Signal<T...>) -> (),
}

function Signal.new<T...>(): Signal<T...>
    local self = setmetatable({
        _handlers = {},
    }, Signal)
    return (self :: any)
end

function Signal:Connect(fn: (...any) -> ()): Connection
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

function Signal:Once(fn: (...any) -> ()): Connection
    local conn: Connection
    conn = self:Connect(function(...)
        conn:Disconnect()
        fn(...)
    end)
    return conn
end

function Signal:Fire(...: any)
    for _, handler in ipairs(table.clone(self._handlers)) do
        task.spawn(handler, ...)
    end
end

function Signal:Wait(): ...any
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
