Pathlib = require('src.pathlib')
local Git = require('src.git')
local ChunkParser = require('src.chunkparser')


local SubProject = {}
SubProject.__index = SubProject


function SubProject:current_branch()
    if not self._branch then
        self._branch = self.git:current_branch()
    end
    return self._branch
end

function SubProject:read()
    return ChunkParser(self.path / 'main')
end

function SubProject:write(chunk, message)
    local parser = ChunkParser(chunk)
    parser:create_file_structure(self.path:parent())
    self.git:add_all()
    message = message or os.date('commit @ %Y/%m/%d-%H:%M:%S')
    self.git:commit(message)
    return parser
end

function SubProject:update(chunk, message)
    message = message or os.date('update @ %Y/%m/%d-%H:%M:%S')
    self.git:rm('TRACK')
    return self:write(chunk, message)
end

function SubProject:init()
    self.path:mkdir()
    self.git:init()
    self.mainfile:write('')
    self.git:add_all()
    self.git:commit('init project')
end

function SubProject.new(path)
    local self = {}
    setmetatable(self, SubProject)
    self.path = path
    self.name = path:stem()
    self.git = Git(path)
    self.mainfile = self.path / 'main'
    self._branch = nil

    return self
end

setmetatable(SubProject, {
    __call = function(_, ...)
        return SubProject.new(...)
    end
})


local Project = {}
Project.__index = Project


function Project:init()
    self.path:mkdir()
    self.git:init()
    self.mainfile:write('')
    self.git:add_all()
    self.git:commit('init project')
    self.initiated = true
end

function Project:add(name, message, ...)
    assert(self:get(name) == nil, 'Project already has a group called: '.. name)
    local project = SubProject(self.path / (name..'/'))
    project:init()
    self.mainfile:append_line(name)
    self.git:add(self.mainfile.path)
    self.git:commit('add '.. name .. ' as subproject')
    self.children[name] = project
    if #{...} > 0 then
        self:update(name, message, ...)
    end
end

function Project:update(name, message, tracks)
    message = message or os.date('update '..name)
    local s = string.format('<GROUP %s\n%s\n>', name, table.concat(tracks, '\n'))
    self.children[name]:write(s)
    self.git:add(name)
    self.git:commit(message)
end

function Project:list()
    local t = {}
    for v in self.mainfile:read():gmatch('([^\r\n]+)') do
        t[v] = SubProject(self.path / (v..'/'))
    end
    return t
end

function Project:get(groupname)
    for name, child in pairs(self.children) do
        if name == groupname then return child end
    end
    return nil
end

function Project:search_trackid(trackid)
    for _, child in pairs(self.children) do
        if child.mainfile:read():find(trackid) then return child end
    end
    return false
end

function Project.new(path)
    path = Pathlib(path)
    local dir = path:parent() / '.reagit/'
    local filename = path:stem()
    local self = {
        name = filename,
        mainfile = dir / filename,
        path = dir,
        git = Git(dir),
        children = {},
        initiated = false
    }
    setmetatable(self, Project)

    if self.path:exists() then
        self.initiated = true
        self.children = self:list()
    end


    return self
end

setmetatable(Project, {
    __call = function(_, ...)
        return Project.new(...)
    end
})

return Project
