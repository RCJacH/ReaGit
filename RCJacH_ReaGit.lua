local workspace_folder = debug.getinfo(1).source:match("@(.*[/\\])")
package.path = package.path .. ';' .. workspace_folder ..'?.lua'

if not reaper.ImGui_CreateContext then
    reaper.MB("Missing dependency: ReaImGui extension.\nDownload it via Reapack ReaTeam extension repository.", "Error", 0)
    return false
end

require('src.std+')
local INTERFACE = require('src.interface')

local _, project_file = reaper.EnumProjects(-1)

local GUI


function init()
    GUI = INTERFACE(project_file)
    return true
end

function loop()
    local open = GUI:loop()
    if open then
        reaper.defer(loop)
    else
        GUI:exit()
    end
end


if init() then
    reaper.defer(loop)
end
