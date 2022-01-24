local PATHLIB = require('src.pathlib')
local GIT = require('src.git')
local CHUNKPARSER = require('src.chunkparser')


local SUBPROJECT = {}
SUBPROJECT.__index = SUBPROJECT

function SUBPROJECT:read()
    return CHUNKPARSER(self.path / 'main')
end

function SUBPROJECT:write(chunk)
    local parser = CHUNKPARSER(chunk)
    parser:create_file_structure(self.path)
    return parser
end

function SUBPROJECT:update(chunk)
    self.git:rm('TRACK')
    return self:write(chunk)
end

function SUBPROJECT.new(path)
    local self = {}
    setmetatable(self, SUBPROJECT)
    self.path = path
    self.git = GIT(path)

    return self
end

setmetatable(SUBPROJECT, {
    __call = function(_, ...)
        return SUBPROJECT.new(...)
    end
})


local PROJECT = {}
PROJECT.__index = PROJECT


function PROJECT:add(chunk)
    local parser = CHUNKPARSER(chunk)
    local subgit = GIT(self.path / parser:get_dirname())
end

function PROJECT.new(path)
    path = PATHLIB(path)
    local dir = path:parent() / '.reagit/'
    local filename = path:stem()
    local file = dir / filename
    local self = {
        name = filename,
        file = file,
        path = dir,
        git = GIT(dir),
        children = {}
    }
    setmetatable(self, PROJECT)

    if not self.path:exists() then
        self.path:mkdir()
        self.git:init()
        self.file:write('')
        self.git:add_all()
        self.git:commit('init project')
    end

    return self
end

setmetatable(PROJECT, {
    __call = function(_, ...)
        return PROJECT.new(...)
    end
})

return PROJECT
