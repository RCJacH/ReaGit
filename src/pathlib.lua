local Shell = require('src.sh')

local UNIX = package.config:sub(1,1) == '/'


local Pathlib = {}
Pathlib.__index = Pathlib

local function join(...)
    return table.concat({...}, '/'):gsub('[/\\]+', '/')
end

function Pathlib:__tostring()
    return self.path
end

function Pathlib.__eq(self, other)
    if type(other) == 'string' then
        return self.path == other:gsub('\\', '/')
    elseif other.path then
        return self.path == other.path
    end
end

function Pathlib.__div (self, other)
    return Pathlib.new(self.path, other)
end


function Pathlib:is_folder()
    return self.path:sub(-1) == '/'
end

function Pathlib:name()
    return self._name
end

function Pathlib:stem()
    return self._stem
end

function Pathlib:ext()
    return self._ext
end

function Pathlib:parent()
    return Pathlib(self._folder)
end

function Pathlib:run(...)
    local dir = self:is_folder() and self.path or self.parent().path
    return Shell(string.format('cd "%s"', dir), ...)
end

function Pathlib:exists()
    local status, _, code = os.rename(self.path, self.path)
    return status or code == 13
end

function Pathlib:read()
    local f = io.open(self.path)
    f:flush()
    local result = f:read('*a')
    f:close()
    return result
end

function Pathlib:write(content)
    local f = io.open(self.path, 'w')
    f:write(content)
    f:close()
end

function Pathlib:append(content)
    local f = io.open(self.path, 'a+')
    f:write(content)
    f:close()
end

function Pathlib:append_line(content)
    self:append(content..'\n')
end

function Pathlib:mkdir()
    if not self:is_folder() then return end
    return Shell(string.format('mkdir "%s"', self.path))
end

function Pathlib:rm_no_regret()
    local command = 'rm'
    if self:is_folder() then
        command = UNIX and 'rm -rf' or 'rmdir /s /q'
    end
    return Shell(string.format('%s "%s"', command, self.path))
end


function Pathlib.new(...)
    local path = join(...)
    local self = {path = path}
    setmetatable(self, Pathlib)
    self._folder, self._name = self.path:match('(.+/)(%.?[^/]+)/?')
    local pos = self._name:find('%.')
    self._stem = pos and self._name:sub(1, pos-1) or self._name
    self._ext = pos and self._name:sub(pos) or ''
    return self
end


setmetatable(Pathlib, {
    __call = function(_, ...)
        return Pathlib.new(...)
    end
})

return Pathlib