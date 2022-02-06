local Project = require('src.project')
local Settings = require('src.settings')


local Interface = {}
Interface.__index = Interface

function Interface:init()
    self.font = {}
    self.ctx = reaper.ImGui_CreateContext(self.title)
    local sizeOffset = reaper.GetAppVersion():match('OSX') and 0 or 2
    self.font.h1 = reaper.ImGui_CreateFont('sans-serif', 28 + sizeOffset)
    self.font.h2 = reaper.ImGui_CreateFont('sans-serif', 24 + sizeOffset)
    self.font.h3 = reaper.ImGui_CreateFont('sans-serif', 20 + sizeOffset)
    self.font.h4 = reaper.ImGui_CreateFont('sans-serif', 18 + sizeOffset)
    self.font.h5 = reaper.ImGui_CreateFont('sans-serif', 16 + sizeOffset)
    self.font.p = reaper.ImGui_CreateFont('sans-serif', 14 + sizeOffset)
    reaper.ImGui_AttachFont(self.ctx, self.font.h1)
    reaper.ImGui_AttachFont(self.ctx, self.font.h2)
    reaper.ImGui_AttachFont(self.ctx, self.font.h3)
    reaper.ImGui_AttachFont(self.ctx, self.font.h4)
    reaper.ImGui_AttachFont(self.ctx, self.font.h5)
    reaper.ImGui_AttachFont(self.ctx, self.font.p)
end

function Interface:exit()
    local dockstate, wx, wy, ww, wh = gfx.dock(-1, 0, 0, 0, 0)
    self.settings:update({
        x=wx,
        y=wy,
        width=ww,
        height=wh,
        dockstate=dockstate
    })
    self.settings:write()
    reaper.ImGui_DestroyContext(self.ctx)
end

function Interface:onExit()

end

function Interface:uploadPressed()
end

function Interface:downloadPressed()
end

function Interface:drawInit()
    local w, h = reaper.ImGui_GetWindowSize(self.ctx)
    reaper.ImGui_PushFont(self.ctx, self.font.p)
    reaper.ImGui_Text(self.ctx, "ReaGit uninitiated.")
    reaper.ImGui_PopFont(self.ctx)
    reaper.ImGui_PushFont(self.ctx, self.font.h2)
    if reaper.ImGui_Button(self.ctx, "INITIATE NOW") then
        self.project:init()
    end
    reaper.ImGui_PopFont(self.ctx)
    reaper.ImGui_PushFont(self.ctx, self.font.p)
    reaper.ImGui_Text(self.ctx, "Note this will create a '.reagit' folder in the space directory as the project file")
    reaper.ImGui_PopFont(self.ctx)
end

function Interface:drawSync(w, h)
    local left_w = w * 0.5
    local right_w = w - left_w
    reaper.ImGui_BeginChildFrame(self.ctx, "header_sync", w, h)
    reaper.ImGui_PushFont(self.ctx, self.font.p)
    reaper.ImGui_PushStyleVar(self.ctx, reaper.ImGui_StyleVar_FramePadding(), 0, 0)
    local frame_w = left_w * 0.85
    reaper.ImGui_BeginChildFrame(
        self.ctx,
        "header_sync_left",
        frame_w,
        h,
        reaper.ImGui_WindowFlags_NoBackground()
    )
    if reaper.ImGui_Button(self.ctx, "Push", frame_w) then
        Interface:uploadPressed()
    end
    if reaper.ImGui_Button(self.ctx, "Pull", frame_w) then
        Interface:downloadPressed()
    end
    reaper.ImGui_EndChildFrame(self.ctx)

    reaper.ImGui_SameLine(self.ctx)

    local frame_w = right_w * 0.85
    reaper.ImGui_BeginChildFrame(
        self.ctx,
        "header_sync_right",
        frame_w,
        h,
        reaper.ImGui_WindowFlags_NoBackground()
    )
    if reaper.ImGui_Button(self.ctx, "Remote", frame_w) then
        self:repoPressed()
    end
    reaper.ImGui_PushStyleVar(self.ctx, reaper.ImGui_StyleVar_ItemInnerSpacing(), w * 0.05, 0)
    if reaper.ImGui_Checkbox(self.ctx, "--force", self.settings.force) then
        self.settings.force = not self.settings.force
    end
    reaper.ImGui_PopStyleVar(self.ctx)
    reaper.ImGui_PopFont(self.ctx)
    reaper.ImGui_EndChildFrame(self.ctx)
    reaper.ImGui_PopStyleVar(self.ctx)

    reaper.ImGui_EndChildFrame(self.ctx)

end

function Interface:drawTitle()
    local w, h = reaper.ImGui_GetWindowSize(self.ctx)
    local fh = h * 0.10
    local title_w = w * 0.6
    reaper.ImGui_BeginChildFrame(
        self.ctx,
        "header_title",
        title_w,
        fh
    )
    reaper.ImGui_PushFont(self.ctx, self.font.h1)
    reaper.ImGui_TextColored(self.ctx, 2868903935, "PROJECT")
    reaper.ImGui_PopFont(self.ctx)
    reaper.ImGui_EndChildFrame(self.ctx)
    reaper.ImGui_SameLine(self.ctx)
    self:drawSync(w - title_w, fh)
end

function Interface:drawGroups()

end

function Interface:update()
    if not self.project.initiated then
        self:drawInit()
        return
    end
    self:drawTitle()
    reaper.ImGui_Spacing(self.ctx)
    self:drawGroups()
end

function Interface:loop()
    reaper.ImGui_PushFont(self.ctx, self.font.p)
    reaper.ImGui_SetNextWindowSize(
        self.ctx,
        self.settings.width,
        self.settings.height,
        reaper.ImGui_Cond_FirstUseEver()
    )
    local visible, open = reaper.ImGui_Begin(self.ctx, self.title, true)
    if visible then
        self:update()
        reaper.ImGui_End(self.ctx)
    end
    reaper.ImGui_PopFont(self.ctx)

    return open
end

function Interface.new(project_file)
    local self = {
        select_index=0,
        scroll_index=0,
        pending_close=false
    }
    setmetatable(self, Interface)
    self.settings = Settings()
    self.project = Project(project_file)
    self.title = 'ReaGit: '
    self:init()

    return self
end


setmetatable(Interface, {
    __call = function(_, ...)
        return Interface.new(...)
    end
})

return Interface
