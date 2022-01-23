local CHUNKPARSER = {}
CHUNKPARSER.__index = CHUNKPARSER

local function prepare_target(parser, base_path)
    local folder_path, foldername, filename
    if parser.type == 'GROUP' then
        foldername = parser.subtype
        filename = 'main'
    else
        foldername = parser.type
        filename = parser.id
    end
    folder_path = base_path / (foldername..'/')
    folder_path:mkdir()
    return folder_path, folder_path / filename
end

function CHUNKPARSER:create_file_structure(base_path)
    local folder, f = prepare_target(self, base_path)
    local t = {string.format('%s %s', self.type, self.subtype)}
    for _, line in ipairs(self) do
        table.insert(t, line)
    end
    for _, child in ipairs(self.children) do
        child:create_file_structure(folder)
        table.insert(t, string.format('CHILD %s %s', child.type, child.id))
    end
    f:write(table.concat(t, '\n')..'\n')
end

function CHUNKPARSER:parse_meta(content)
    if not self.id then
        local id = content:match('ID {([%dA-F]+%-[%dA-F]+%-[%dA-F]+%-[%dA-F]+%-[%dA-F]+)}')
        if id then self.id = id end
    end
    if not self.name then
        local name = content:match('^NAME \"(.+)\"')
        if name then self.name = name end
    end
end

function CHUNKPARSER:parse_line(index, content)
    if content == '' then return end
    if index == 1 then
        local t = content:split()
        self.type = t[1]
        self.subtype = t[2] or ''
        return
    end
    self:parse_meta(content)
    table.insert(self, content)
end

function CHUNKPARSER:add_child(content)
    table.insert(self.children, CHUNKPARSER(content))
end

function CHUNKPARSER:parse_children(content)
    local s = content
    for child in content:gmatch('%b<>') do
        self:add_child(child)
        local i, j = s:find(child, 1, true)
        s = s:sub(1, i-1) .. s:sub(j+1)
    end
    return s
end

function CHUNKPARSER:parse_item(content)
    content = content:gsub('(IID %d+)', '%1\nTAKE FIRST') .. 'TAKE'
    local i = 1
    for v in content:gmatch('(.-)TAKE') do
        if i == 1 then
            for j, line in ipairs(v:split('\n')) do
                self:parse_line(j, line)
            end
        else
            self:add_child('TAKE'..v)
        end
        i = i + 1
    end
end

function CHUNKPARSER:parse_content(content)
    content = self:parse_children(content)
    for i, v in ipairs(content:split('\n')) do
        self:parse_line(i, v)
    end
end

function CHUNKPARSER:parse(content)
    if content:sub(1, 4) == 'ITEM' then return self:parse_item(content) end
    self:parse_content(content)
end

function CHUNKPARSER.new(content)
    local self = {
        content = content:trim(),
        children = {}
    }
    setmetatable(self, CHUNKPARSER)
    return self
end

function CHUNKPARSER.new_from_chunk(chunk)
    local self = CHUNKPARSER.new(chunk)
    local content = self.content:match('^<(.+)>$')
    if content then self.content = content end
    self:parse(self.content)
    return self
end

function CHUNKPARSER.new_from_file(path)
    local self = CHUNKPARSER.new(path:read())
    return self
end


setmetatable(CHUNKPARSER, {
    __call = function (_, content)
        if type(content) == 'string' then
            return CHUNKPARSER.new_from_chunk(content)
        else
            return CHUNKPARSER.new_from_file(content)
        end
    end
})

return CHUNKPARSER