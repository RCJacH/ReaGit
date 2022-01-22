function string:trim(pattern)
    pattern = pattern or '%s'
    return self:match(string.format("^[%s]*(.*)", pattern)):match(string.format("(.-)[%s]*$", pattern))
end

function string:split(sep)
    sep = sep or '%s'
    local t = {}
    for str in self:gmatch('([^'..sep..']+)') do
        table.insert(t, str)
    end
    return t
end
