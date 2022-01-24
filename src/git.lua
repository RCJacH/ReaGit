local SHELL = require('src.sh')


local GIT = {}
GIT.__index = GIT


function GIT:run(...)
    return self.path:run(...)
end

function GIT:status()
    return self:run('git status')
end

function GIT:init(...)
    return self:run(table.concat({'git init', ...}, ' '))
end

function GIT:init_new(...)
    if self:status() == 'fatal: not a git repository (or any of the parent directories): .git' then
        self:init(...)
    end
end

function GIT:add(...)
    for _, v in ipairs({...}) do
        self:run(string.format('git add "%s"', v))
    end
end

function GIT:rm(file)
    self:run('git rm -r'..file)
end

function GIT:add_all()
    self:run('git add -A')
end

function GIT:commit(message, ...)
    self:run(table.concat({string.format('git commit -m "%s"', message), ...}))
end

function GIT:commit_amend()
    self:run('git commit --amend')
end

function GIT:switch_branch(branchname)
    self:run('git switch -c '..branchname)
end

function GIT:checkout_branch(branchname)
    self:run('git checkout -b '..branchname)
end

function GIT:list_branch()
    self:run('git branch -l')
end

function GIT:delete_branch(branchname)
    self:run('git branchname -D '..branchname)
end

function GIT:current_branch()
    self:run('git branch --show-current')
end

function GIT.new(path)
    local self = {path=path}
    setmetatable(self, GIT)
    return self
end


setmetatable(GIT, {
    __call = function(_, ...)
        return GIT.new(...)
    end
})

return GIT
