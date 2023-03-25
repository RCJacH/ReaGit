local workspace_folder = debug.getinfo(1).source:match("@(.*[/\\]).+[/\\]")

local Pathlib = require('src.pathlib')

local Settings = {}
Settings.__index = Settings
Settings.SETTING_FILE = Pathlib(workspace_folder .. 'settings.ini')


Settings.DEFAULT = {
    title = "ReaGit",
    width = 600,
    height = 600,
    x = 0,
    y = 0,
    dockstate = 0,

}


function Settings.parse(str)
    local setting_data = {}
    for line in str:gmatch('[^\r\n]+') do
        local key, values = table.unpack(line:trim():split('='))
        if not key or not values then
            goto continue
        end

        local v = {}
        for value in values:gmatch('([^,]+)') do
            local tmp = tonumber(value)
            table.insert(v, tmp or value)
        end
        if #v == 1 then v = v[1] end
        setting_data[key:trim()] = v
        ::continue::
    end
    return setting_data
end

function Settings:read()
    local result = pcall(self.SETTING_FILE:read())
    if not result then return Settings.DEFAULT end
    self:update(self.parse(result))
end

function Settings:update(...)
    for k, v in pairs({...}) do
        self[k] = v
    end
end

function Settings:write()
    local t = {}
    for k, v in pairs(self) do
        if type(v) == 'table' then
            v = table.concat(v, ',')
        end
        table.insert(t, string.format('%s=%s', k, v))
    end
    self.SETTING_FILE:write(table.concat(t, '\n'))
end

function Settings.new(settings)
    local self = settings
    if not self then
        self = Settings:read()
    end
    setmetatable(self, Settings)

    return self
end


setmetatable(Settings, {
    __call = function(_, ...)
        return Settings.new(...)
    end
})

return Settings
