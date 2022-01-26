LU = require('luaunit')
local workspace_folder = debug.getinfo(1).source:match("@(.*[/\\]).+[/\\]")

package.path = package.path .. ';' .. workspace_folder ..'?.lua'

require('src.std+')
Settings = require('src.settings')

local project_path = workspace_folder .. 'test/project/'


local SETTING_CONTENT = [[ x=1
    y=2
    z=3
    list=1,2,3
]]

local EXPECT = {x=1, y=2, z=3, list={1,2,3}}

function testEmpty()
    local settings = Settings()
    LU.assertEquals(#settings, 0)
end

function testPaser()
    LU.assertEquals(Settings.parse(SETTING_CONTENT), EXPECT)
end

function testIO()
    local setting = Settings(EXPECT)
    LU.assertEquals(setting['x'], 1)
    setting['x'] = 5
    setting:write()
    setting:read()
    LU.assertEquals(setting['x'], 5)
    Settings.SETTING_FILE:rm_no_regret()
end

os.exit(LU.LuaUnit.run())
