local UNIX = package.config:sub(1, 1) == '/'

local Shell = {}
Shell.__index = Shell


local function join(...)
    return table.concat({ ... }, UNIX and '; ' or ' && ')
end

local function run(s)
    local result, output
    result = io.popen(string.format('%s 2>&1', s))
    output = result:read('*a')
    result:close()

    return output
end

local function run_in_reaper(s)
    s = string.format("%s 2>&1", s)
    -- reaper.ShowConsoleMsg(s .. '\n')
    local result = reaper.ExecProcess(s, 0)
    -- reaper.ShowConsoleMsg(result .. '\n')
    if result then
        local output = result:match('([^\n]+)\n(.+)')
        return output
    end
end

setmetatable(Shell, {
    __call = function(_, ...)
        local args = join(...)
        if reaper then
            return run_in_reaper(args)
        else
            return run(args)
        end
    end
})


return Shell
