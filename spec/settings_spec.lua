describe("test settings", function()
    local workspace_folder = debug.getinfo(1).source:match("@(.*[/\\]).+[/\\]")

    package.path = package.path .. ';' .. workspace_folder ..'?.lua'
    
    require('src.std+')
    Settings = require('src.settings')

    it("test empty setting", function()
        local settings = Settings()
        assert.are.equals(#settings, 0)
    end)

    SETTING_CONTENT = [[ x=1
        y=2
        z=3
        list=1,2,3
        empty= 
    ]]

    EXPECT = {x=1, y=2, z=3, list={1,2,3}}
    
    it("test parser", function()
        assert.are.same(Settings.parse(SETTING_CONTENT), EXPECT)
    end)

    it("test IO", function()
        local setting = Settings(EXPECT)
        assert.are.equals(setting['x'], 1)
        setting['x'] = 5
        setting:write()
        setting:read()
        assert.are.equals(setting['x'], 5)
        Settings.SETTING_FILE:rm_no_regret()
    end)
end)
