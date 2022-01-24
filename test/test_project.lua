LU = require('luaunit')
local workspace_folder = debug.getinfo(1).source:match("@(.*[/\\]).+[/\\]")

package.path = package.path .. ';' .. workspace_folder ..'?.lua'

PROJECT = require('src.project')

local project_path = workspace_folder .. 'test/project/'

function testCreation()
    local project = PROJECT(project_path..'ReaGit.rpp')
    LU.assertEquals(project.name, 'ReaGit')
    LU.assertIsTrue(project.path:exists())
    project.path:rm_no_regret()
end

os.exit(LU.LuaUnit.run())
