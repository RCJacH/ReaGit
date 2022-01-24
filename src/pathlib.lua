local SHELL = require('src.sh')

local UNIX = package.config:sub(1,1) == '/'


local PATHLIB = {}
PATHLIB.__index = PATHLIB

local function join(...)
    return table.concat({...}, '/'):gsub('[/\\]+', '/')
end

function PATHLIB:__tostring()
    return self.path
end

function PATHLIB.__eq(self, other)
    if type(other) == 'string' then
        return self.path == other:gsub('\\', '/')
    elseif other.path then
        return self.path == other.path
    end
end

function PATHLIB.__div (self, other)
    return PATHLIB.new(self.path, other)
end


function PATHLIB:is_folder()
    return self.path:sub(-1) == '/'
end

function PATHLIB:name()
    return self._name
end

function PATHLIB:stem()
    return self._stem
end

function PATHLIB:ext()
    return self._ext
end

function PATHLIB:parent()
    return PATHLIB(self._folder)
end

function PATHLIB:run(...)
    local dir = self:is_folder() and self.path or self.parent().path
    return SHELL(string.format('cd "%s"', dir), ...)
end

function PATHLIB:exists()
    local status, _, code = os.rename(self.path, self.path)
    return status or code == 13
end

function PATHLIB:read()
    local f = io.open(self.path)
    f:flush()
    local result = f:read('*a')
    f:close()
    return result
end

function PATHLIB:write(content)
    local f = io.open(self.path, 'w')
    f:write(content)
    f:close()
end

function PATHLIB:append(content)
    local f = io.open(self.path, 'a+')
    f:write(content)
    f:close()
end

function PATHLIB:mkdir()
    if not self:is_folder() then return end
    return SHELL(string.format('mkdir "%s"', self.path))
end

function PATHLIB:rm_no_regret()
    local command = 'rm'
    if self:is_folder() then
        command = UNIX and 'rm -rf' or 'rmdir /s /q'
    end
    return SHELL(string.format('%s "%s"', command, self.path))
end


function PATHLIB.new(...)
    local path = join(...)
    local self = {path = path}
    setmetatable(self, PATHLIB)
    self._folder, self._name = self.path:match('(.+/)(%.?[^/]+)/?')
    local pos = self._name:find('%.')
    self._stem = pos and self._name:sub(1, pos-1) or self._name
    self._ext = pos and self._name:sub(pos) or ''
    return self
end


setmetatable(PATHLIB, {
    __call = function(_, ...)
        return PATHLIB.new(...)
    end
})

return PATHLIB