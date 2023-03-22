local UNIX = package.config:sub(1, 1) == '/'

local Shell = {}
Shell.__index = Shell


local function join(...)
    return table.concat({ ... }, UNIX and '; ' or ' && ')
end

local function run(s)
    local handle, result
    handle = io.popen(string.format('%s 2>&1', s))
    if handle == nil then
        return false, '', 1
    end

    result = handle:read('*a')
    local retval, _, code = handle:close()

    return retval, result, tonumber(code)
end

local function run_in_reaper(s)
    s = string.format("%s 2>&1", s)
    -- reaper.ShowConsoleMsg(s .. '\n')
    local result = reaper.ExecProcess(s, 0)
    -- reaper.ShowConsoleMsg(result .. '\n')
    if result then
        local code, output = result:match('(%d+)\n(.+)')
        code = tonumber(code)
        return code == 0, output, code
    else
        return false, nil, 1
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
