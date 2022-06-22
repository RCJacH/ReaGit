local Token = { token = nil }
Token.__index = Token

function Token:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function Token:get_string()
    return self.token
end

function Token:get_number()
    return tonumber(self.token)
end

function Token:get_boolean()
    return self.token ~= "0"
end

function Token:set_string(token)
    self.token = tostring(token)
end

function Token:set_number(token, is_int)
    is_int = is_int or false
    if is_int then
        token, _ = math.modf(token)
    end
    self.token = tostring(token)
end

function Token:set_boolean(b)
    self.token = b and "1" or "0"
end

function Token:toSafeString(s)
    -- check param contains no quotes
    -- if needs quotes then surround with correct quotes
    -- NOTE: if quotes are present but not needed, they will be deleted - why? Reaper surrounds with different type of quote in that instance i.e "MyQuoted" -> '"MyQuoted"'
    -- i.e. You may name your track "Scary" Noise -> '"Scary" Noise' -- it's weird but reaper does it - check in an RPP - You can use quotes in names - if a certain quote is present it uses an extra quote that isn't present
    if not s or s:len() == 0 then
        return "\"\"" -- Empty string must be quoted
    elseif s:find(" ") then
        -- We must quote in weird ways if has spaces
        if s:find("\"") then
            if s:find("'") then
                s = s:gsub("`", "'")
                return "`" .. s .. "`"
            else
                return "'" .. s .. "'"
            end
        else
            return "\"" .. s .. "\""
        end

    else --
        return s -- param unchanged - no spaces or quotes required
    end
end
