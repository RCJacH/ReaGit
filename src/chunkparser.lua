local ChunkParser = {}
ChunkParser.__index = ChunkParser


function ChunkParser:__tostring()
    local t = {string.format('%s %s', self.type, (self.subtype or ''))}
    for _, line in ipairs(self) do
        table.insert(t, line)
    end
    for _, child in ipairs(self.children) do
        if child.subtype ~= 'NULL' then
            table.insert(t, tostring(child))
        end
    end
    return '<'..table.concat(t, '\n')..'\n>'
end


function ChunkParser:get_location()
    local foldername, filename
    if self.type == 'GROUP' then
        foldername = self.subtype
        filename = 'main'
    else
        foldername = self.type
        filename = self.id
    end
    return {foldername, filename}
end

function ChunkParser:get_dirname()
    return self:get_location()[1]
end

function ChunkParser:get_filename()
    return self:get_location()[2]
end

function ChunkParser:prepare_target(base_path)
    local folder_path, foldername, filename
    foldername, filename = table.unpack(self:get_location())
    folder_path = base_path / (foldername..'/')
    folder_path:mkdir()
    return folder_path, folder_path / filename
end

function ChunkParser:create_file_structure(base_path)
    local folder, f = self:prepare_target(base_path)
    local t = {string.format('%s %s', self.type, self.subtype)}
    for _, line in ipairs(self) do
        table.insert(t, line)
    end
    for _, child in ipairs(self.children) do
        if child.subtype ~= 'NULL' then
            child:create_file_structure(folder)
        end
        table.insert(t, string.format('CHILD %s %s', child.type, child.id))
    end
    f:write(table.concat(t, '\n')..'\n')
end

function ChunkParser:parse_meta(content)
    if not self.id then
        local id = content:match('ID {([%dA-F]+%-[%dA-F]+%-[%dA-F]+%-[%dA-F]+%-[%dA-F]+)}')
        if id then self.id = id end
    end
    if not self.name then
        local name = content:match('^NAME \"(.+)\"')
        if name then self.name = name end
    end
end

function ChunkParser:parse_line(index, content)
    content = content:trim()
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

function ChunkParser:add_child(content)
    table.insert(self.children, ChunkParser(content))
end

function ChunkParser:parse_children(content)
    local s = content
    for child in content:gmatch('%b<>') do
        self:add_child(child)
        local i, j = s:find(child, 1, true)
        s = s:sub(1, i-1) .. s:sub(j+1)
    end
    return s
end

function ChunkParser:parse_item(content)
    content = content:gsub('(IID %d+)', '%1\nTAKE FIRST') .. 'TAKE '
    local i = 1
    for v in content:gmatch('(.-)TAKE[\n%s]') do
        if i == 1 then
            for j, line in ipairs(v:split('\n')) do
                self:parse_line(j, line)
            end
        else
            self:add_child('TAKE '..v)
        end
        i = i + 1
    end
end

function ChunkParser:parse_content(content)
    content = self:parse_children(content)
    for i, v in ipairs(content:split('\n')) do
        self:parse_line(i, v)
    end
end

function ChunkParser:parse(content)
    if content:sub(1, 4) == 'ITEM' then return self:parse_item(content) end
    self:parse_content(content)
end

function ChunkParser.new(content)
    local self = {
        content = content:trim(),
        children = {}
    }
    setmetatable(self, ChunkParser)
    return self
end

function ChunkParser.new_from_chunk(chunk)
    local self = ChunkParser.new(chunk)
    local content = self.content:match('^<(.+)>$')
    if content then self.content = content end
    self:parse(self.content)
    return self
end

function ChunkParser.new_from_file(path)
    local args, f
    local self = ChunkParser.new(path:read())
    for i, line in ipairs(self.content:split('\n') )do
        if i == 1 then
            args = line:split()
            self.type = args[1]
            self.subtype = args[2]
            goto skip_to_next
        end
        if line:sub(1, 5) == 'CHILD' then
            if line == 'CHILD TAKE nil' then
                self:add_child('TAKE NULL')
                goto skip_to_next
            end
            args = line:split()
            f = path:parent() / args[2] / args[3]
            self:add_child(f)
            goto skip_to_next
        end
        table.insert(self, line)
        ::skip_to_next::
    end
    return self
end


setmetatable(ChunkParser, {
    __call = function (_, content)
        if type(content) == 'string' then
            return ChunkParser.new_from_chunk(content)
        else
            local path = content:is_folder() and content / 'main' or content
            return ChunkParser.new_from_file(path)
        end
    end
})

return ChunkParser