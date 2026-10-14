--!strict
-- Maid / Task cleanup manager for connection and resource lifecycle

local Maid = {}
Maid.__index = Maid

export type Destructible = {
    Destroy: (self: any) -> (),
} | {
    disconnect: (self: any) -> (),
} | {
    Disconnect: (self: any) -> (),
} | RBXScriptConnection | Instance | () -> ()

function Maid.new()
    return setmetatable({
        _tasks = {},
    }, Maid)
end

function Maid:GiveTask(taskItem: Destructible): number
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
