local SHELL = require('src.sh')


local GIT = {}
GIT.__index = GIT


function GIT:run(head, ...)
    return SHELL(string.format("git --git-dir %s/.git %s", tostring(self.path), head), ...)
end

function GIT:status()
    return self:run('status')
end

function GIT:init(...)
    return self:run(table.concat({ 'init', ... }, ' '))
end

function GIT:init_new(...)
    local _, result, _ = self:status()
    if result == 'fatal: not a git repository (or any of the parent directories): .git' then
        return self:init(...)
    end
end

function GIT:add(...)
    for _, v in ipairs({ ... }) do
        self:run(string.format('add "%s"', v))
    end
end

function GIT:rm(file)
    return self:run('rm -r' .. file)
end

function GIT:add_all()
    return self:run('add -A')
end

function GIT:commit(message, ...)
    return self:run(table.concat({ string.format('commit -m "%s"', message), ... }))
end

function GIT:commit_amend()
    return self:run('commit --amend')
end

function GIT:switch_branch(branchname)
    return self:run('switch -c ' .. branchname)
end

function GIT:checkout_branch(branchname)
    return self:run('checkout -b ' .. branchname)
end

function GIT:list_branch()
    return self:run('branch -l')
end

function GIT:delete_branch(branchname)
    return self:run('branchname -D ' .. branchname)
end

function GIT:current_branch()
    return self:run('branch --show-current')
end

function GIT.new(path)
    local self = { path = path }
    setmetatable(self, GIT)
    return self
end

setmetatable(GIT, {
    __call = function(_, ...)
        return GIT.new(...)
    end
})

return GIT
