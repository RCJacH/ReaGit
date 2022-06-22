require("src.parser.node")


-----------------------------------------------------------
-- Parser
-----------------------------------------------------------

local Parser = {}
Parser.__index = Parser

function Parser.new(chunk)
    return { parent = chunk }
end

function Parser.parse_meta(content, chunk)
    if not chunk.id then
        local id = content:match('ID {([%dA-F]+%-[%dA-F]+%-[%dA-F]+%-[%dA-F]+%-[%dA-F]+)}')
        if id then chunk.id = id end
    end
    if not chunk.name then
        local name = content:match('^NAME \"(.+)\"')
        if name then chunk.name = name end
    end
end

function Parser.parse_line(index, content, chunk)
    content = content:trim()
    if content == '' then return end
    if index == 1 then
        local t = content:split()
        chunk.type = t[1]
        chunk.subtype = t[2] or ''
        return
    end
    Parser.parse_meta(content, chunk)
    chunk.add_node(Node(content))
end

function Parser.parse_children(content, chunk)
    local s = content
    for child in content:gmatch('%b<>') do
        chunk:new_child(child)
        local i, j = s:find(child, 1, true)
        s = s:sub(1, i - 1) .. s:sub(j + 1)
    end
    return s
end

function Parser.parse_item(content, chunk)
    content = content:gsub('(IID %d+)', '%1\nTAKE FIRST') .. 'TAKE '
    local i = 1
    for v in content:gmatch('(.-)TAKE[\n%s]') do
        if i == 1 then
            for j, line in ipairs(v:split('\n')) do
                Parser.parse_line(j, line, chunk)
            end
        else
            chunk:add_child('TAKE ' .. v)
        end
        i = i + 1
    end
end

function Parser.parse_content(content, chunk)
    content = Parser.parse_children(content, chunk)
    for i, v in ipairs(content:split('\n')) do
        Parser.parse_line(i, v, chunk)
    end
end

setmetatable(Parser, {
    __call = function(_, content, chunk)
        if content:sub(1, 4) == "ITEM" then
            return Parser.parse_item(content, chunk)
        end
        Parser.parse_content(content, chunk)
    end
})

-----------------------------------------------------------
--------------------------------- End of Parser
-----------------------------------------------------------

-----------------------------------------------------------
-- Writer
-----------------------------------------------------------

local Writer = {}
Writer.__index = Writer

function Writer.get_location(chunk)
    local foldername, filename
    if chunk.type == 'GROUP' then
        foldername = chunk.subtype
        filename = 'main'
    else
        foldername = chunk.type
        filename = chunk.id
    end
    return { foldername, filename }
end

function Writer.get_dirname(chunk)
    return Writer.get_location(chunk)[1]
end

function Writer.get_filename(chunk)
    return Writer.get_location(chunk)[2]
end

function Writer.prepare_target(base_path, chunk)
    local folder_path, foldername, filename
    foldername, filename = table.unpack(Writer.get_location(chunk))
    folder_path = base_path / (foldername .. '/')
    folder_path:mkdir()
    return folder_path, folder_path / filename
end

function Writer.create_file_structure(base_path, chunk)
    local folder, f = Writer.prepare_target(base_path, chunk)
    local t = { string.format('%s %s', chunk.type, chunk.subtype) }
    for _, line in ipairs(chunk.nod) do
        table.insert(t, line)
    end
    for _, child in ipairs(chunk.children) do
        if child.subtype ~= 'NULL' then
            child:create_file_structure(folder)
        end
        table.insert(t, string.format('CHILD %s %s', child.type, child.id))
    end
    f:write(table.concat(t, '\n') .. '\n')
end

setmetatable(Writer, {
    __call = function(_, base_path, chunk)
        Writer.create_file_structure(base_path, chunk)
    end
})

-----------------------------------------------------------
--------------------------------- End of Writer
-----------------------------------------------------------


local RChunk = {}
RChunk.__index = RChunk

function RChunk:__tostring()
    local t = { string.format('%s %s', self.type, (self.subtype or '')) }
    for _, line in ipairs(self) do
        table.insert(t, line)
    end
    for _, child in ipairs(self.children) do
        if child.subtype ~= 'NULL' then
            table.insert(t, tostring(child))
        end
    end
    return '<' .. table.concat(t, '\n') .. '\n>'
end

function RChunk:add_node(node)
    node.parent = self
    table.insert(self.nodes, node)
    return node
end

function RChunk:new_child(content)
    self:add_child(RChunk(content))
end

function RChunk:add_child(child)
    child.parent = self
    table.insert(self.children, child)
end

function RChunk.new()
    local self = {
        nodes = {},
        children = {}
    }
    setmetatable(self, RChunk)
    return self
end

local function new_from_chunk(content)
    local chunk = RChunk.new()
    local content = content:match('^<(.+)>$')
    if content then Parser(content, chunk) end
    return chunk
end

local function new_from_file(path)
    local args, f
    local chunk = RChunk.new()
    for i, line in ipairs(path:read():split('\n')) do
        if i == 1 then
            args = line:split()
            chunk.type = args[1]
            chunk.subtype = args[2]
            goto skip_to_next
        end
        if line:sub(1, 5) == 'CHILD' then
            if line == 'CHILD TAKE nil' then
                chunk:new_child('TAKE NULL')
                goto skip_to_next
            end
            args = line:split()
            f = path:parent() / args[2] / args[3]
            chunk:new_child(f)
            goto skip_to_next
        end
        table.insert(chunk, line)
        ::skip_to_next::
    end
    return chunk
end

setmetatable(RChunk, {
    __call = function(_, content)
        if type(content) == 'string' then
            return new_from_chunk(content)
        else
            local path = content:is_folder() and content / 'main' or content
            return new_from_file(path)
        end
    end
})

return RChunk
