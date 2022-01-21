LU = require('luaunit')
local workspace_folder = debug.getinfo(1).source:match("@(.*[/\\]).+[/\\]")

package.path = package.path .. ';' .. workspace_folder ..'?.lua'

PATHLIB = require('src.pathlib')

local project_path = workspace_folder .. 'test/project/'


function testPathInit()
    local folder_path = PATHLIB(project_path)
    LU.assertEquals(folder_path:name(), 'project')
    LU.assertEquals(folder_path:ext(), '')
    local path = folder_path / 'init.file'
    LU.assertEquals(path:ext(), '.file')
    LU.assertEquals(path:parent(), folder_path)
end

function testExists()
    local folder_path = PATHLIB(project_path)
    LU.assertIsTrue(folder_path:exists())
    local filepath = folder_path / 'init.file'
    LU.assertIsTrue(filepath:exists())
    filepath = folder_path / 'invalid.file'
    LU.assertIsFalse(filepath:exists())
end


os.exit(LU.LuaUnit.run())
