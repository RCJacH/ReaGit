 PATHLIB = require('src.pathlib')
local GIT = require('src.git')
local CHUNKPARSER = require('src.chunkparser')


local SUBPROJECT = {}
SUBPROJECT.__index = SUBPROJECT

function SUBPROJECT:read()
    return CHUNKPARSER(self.path / 'main')
end

function SUBPROJECT:write(chunk, message)
    local parser = CHUNKPARSER(chunk)
    parser:create_file_structure(self.path:parent())
    self.git:add_all()
    message = message or os.date('commit @ %Y/%m/%d-%H:%M:%S')
    self.git:commit(message)
    return parser
end

function SUBPROJECT:update(chunk, message)
    message = message or os.date('update @ %Y/%m/%d-%H:%M:%S')
    self.git:rm('TRACK')
    return self:write(chunk, message)
end

function SUBPROJECT:init()
    self.path:mkdir()
    self.git:init()
    self.mainfile:write('')
    self.git:add_all()
    self.git:commit('init project')
end

function SUBPROJECT.new(path)
    local self = {}
    setmetatable(self, SUBPROJECT)
    self.path = path
    self.git = GIT(path)
    self.mainfile = self.path / 'main'

    return self
end

setmetatable(SUBPROJECT, {
    __call = function(_, ...)
        return SUBPROJECT.new(...)
    end
})


local PROJECT = {}
PROJECT.__index = PROJECT


function PROJECT:add(name, ...)
    local project = SUBPROJECT(self.path / (name..'/'))
    project:init()
    self.mainfile:append_line(name)
    self.git:add(self.mainfile.path)
    self.git:commit('add '.. name .. ' as subproject')
    self.children[name] = project
    if #{...} > 0 then
        self:update(name, ...)
    end
end

function PROJECT:update(name, tracks, message)
    message = message or os.date('update '..name)
    local s = string.format('<GROUP %s\n%s\n>', name, table.concat(tracks, '\n'))
    self.children[name]:write(s)
    self.git:add(name)
    self.git:commit(message)
end

function PROJECT:list()
    local t = {}
    for _, v in ipairs(self.mainfile:read():split('\n')) do
        t[v] = SUBPROJECT(self.path / (v .. '/'))
    end
    return t
end

function PROJECT:contains(trackid)
    for _, child in ipairs(self.children) do
        if child.mainfile:read():find(trackid) then return child end
    end
    return false
end

function PROJECT.new(path)
    path = PATHLIB(path)
    local dir = path:parent() / '.reagit/'
    local filename = path:stem()
    local self = {
        name = filename,
        mainfile = dir / filename,
        path = dir,
        git = GIT(dir),
    }
    setmetatable(self, PROJECT)

    if not self.path:exists() then
        self.path:mkdir()
        self.git:init()
        self.mainfile:write('')
        self.git:add_all()
        self.git:commit('init project')
    end

    self.children = self:list()

    return self
end

setmetatable(PROJECT, {
    __call = function(_, ...)
        return PROJECT.new(...)
    end
})

return PROJECT
