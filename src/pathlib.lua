local SHELL = require('src.sh')


local PATHLIB = {}
PATHLIB.__index = PATHLIB


function PATHLIB.__tostring(self)
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
    local path = self:is_folder() and self.path or self.path .. '/'
    return PATHLIB.new(path .. other)
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
    return os.rename(self.path, self.path) and true or false
end

function PATHLIB:mkdir()
    if not self.is_folder() then return end
    return self:run(string.format('mkdir "%s"', self.path))
end


function PATHLIB.new(...)
    local path = table.concat({...}, '/'):gsub('\\', '/')
    local self = {path = path}
    setmetatable(self, PATHLIB)
    self._folder, self._name = self.path:match('(.+/)(%.?[^/]+)/?')
    local pos = self._name:find('%.')
    self._stem = pos and self._name:sub(1, pos) or self._name
    self._ext = pos and self._name:sub(pos, -1) or ''
    return self
end


setmetatable(PATHLIB, {
    __call = function(_, ...)
        return PATHLIB.new(...)
    end
})

return PATHLIB