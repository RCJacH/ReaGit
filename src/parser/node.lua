local Node = {}
Node.__index = Node

function Node.new()
    local self = {
        parent = nil,
        name = '',
        param = ''
    }
    setmetatable(self, Node)
    return self
end

function Node:parse(line)
    self.name, self.param = line:match('^([^%s]+)%s(.+)$')
    return self
end

function Node:__tostring()
    return string.format("%s %s", self.name, self.parem)
end

function Node:remove()
    if self.parent then
        table.remove(self.parent.nodes, self.parent.nodes:indexOf(self))
    end
    self = nil
    return nil
end

setmetatable(Node, {
    __call = function(_, line)
        local node = Node.new()
        node:parse(line)
        return node
    end
})

return Node
