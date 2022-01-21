local SHELL = {}
SHELL.__index = SHELL


local function join(...)
    return table.concat({...}, ' && ')
end

local function run(s)
    local result, output
    result = io.popen(string.format('%s 2>&1', s))
    output = result:read('*a')
    result:close()

    return output
end


setmetatable(SHELL, {
    __call = function (_, ...)
        return run(join(...))
    end
})


return SHELL
