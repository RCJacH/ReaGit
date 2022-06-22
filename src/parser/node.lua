local Node = {
    parent = nil,
    name = nil,
    param = nil
}

function Node:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Node:parse(line)
    self.name, self.param = line:split()
end

function Node:__tostring()
    return self.name .. ' ' .. tostring(self.param)
end

function Node:remove()
    if self.parent then
        table.remove(self.parent.children, self.parent:indexOf(self))
    end
    self = nil
    return nil
end

setmetatable(Node, {
    __call = function(_, line)
        local node = Node:new()
        node:parse(line)
        return node
    end
})

return Node
