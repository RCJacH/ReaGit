LU = require('luaunit')
local workspace_folder = debug.getinfo(1).source:match("@(.*[/\\]).+[/\\]")

package.path = package.path .. ';' .. workspace_folder ..'?.lua'

require('src.std+')
PROJECT = require('src.project')

local project_path = workspace_folder .. 'test/project/'

dofile('test/chunks.lua')

function testCreation()
    local project = PROJECT(project_path..'ReaGit.rpp')
    LU.assertEquals(project.name, 'ReaGit')
    LU.assertIsTrue(project.path:exists())
    project.path:rm_no_regret()
end

function testAdd()
    local project = PROJECT(project_path..'ReaGit.rpp')
    project:add('TEST', GROUP_TRACKS_ONLY)
    LU.assertIsTrue((project.path / 'TEST' / 'TRACK' / 'ITEM' / '4C881EF6-B8BB-4B08-892B-AF3691AD5B25'):exists())
    project.path:rm_no_regret()
end

os.exit(LU.LuaUnit.run())
