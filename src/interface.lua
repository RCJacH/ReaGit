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

function Interface:drawInit(w, h)
    reaper.ImGui_Text(self.ctx, "ReaGit uninitiated.")
    reaper.ImGui_PushFont(self.ctx, self.font.h2)
    if reaper.ImGui_Button(self.ctx, "INITIATE NOW") then
        self.project:init()
    end
    reaper.ImGui_PopFont(self.ctx)
    reaper.ImGui_Text(self.ctx, "Note this will create a '.reagit' folder in the space directory as the project file")
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

function Interface:drawTitle(w, h)
    local title_w = w * 0.6
    reaper.ImGui_BeginChildFrame(self.ctx, "header_title", title_w, h)
    reaper.ImGui_PushFont(self.ctx, self.font.h1)
    reaper.ImGui_TextColored(self.ctx, 2868903935, self.project.name)
    reaper.ImGui_PopFont(self.ctx)
    reaper.ImGui_EndChildFrame(self.ctx)
    reaper.ImGui_SameLine(self.ctx)
    self:drawSync(w - title_w, h)
end

function Interface:drawGroup(w, h, name, child)
    reaper.ImGui_Text(self.ctx, name)
end

function Interface:drawAddNewChild(w, h)
    local pad_x, pad_y = reaper.ImGui_GetStyleVar(self.ctx, reaper.ImGui_StyleVar_FramePadding())
    local button_s = h*0.5
    reaper.ImGui_BeginChildFrame(self.ctx, "new_group", w, h)
    reaper.ImGui_PushStyleVar(self.ctx, reaper.ImGui_StyleVar_FrameRounding(), button_s)
    reaper.ImGui_PushFont(self.ctx, self.font.h2)
    local x, y = reaper.ImGui_GetCursorPos(self.ctx)
    reaper.ImGui_SetCursorPos(self.ctx, x + w/2 - button_s/2, y + h/2 - button_s/2 - pad_y)
    if reaper.ImGui_Button(self.ctx, "+", button_s, button_s) then
        local retval, s = reaper.GetUserInputs("New group from selected tracks", 2, "Group name without space,commit message,extrawidth=100", "")
        if retval then
            local name, commit_msg = table.unpack(s:split(','))
            local track_chunks = {}
            for i = 0, reaper.CountSelectedTracks(-1) - 1, 1 do
                local track = reaper.GetSelectedTrack(-1, i)
                local _, chunk = reaper.GetTrackStateChunk(track, "", false)
                table.insert(track_chunks, chunk)
            end
            self.project:add(
                name:gsub("[%s\t\n]+", "-"),
                commit_msg == "" and nil or commit_msg,
                track_chunks
            )
        end
    end
    reaper.ImGui_PopFont(self.ctx)
    reaper.ImGui_PopStyleVar(self.ctx)
    reaper.ImGui_EndChildFrame(self.ctx)
end

function Interface:drawGroups(w, h)
    local pad_x, pad_y = reaper.ImGui_GetStyleVar(self.ctx, reaper.ImGui_StyleVar_FramePadding())
    local pad2_x, pad2_y = pad_x * 2, pad_y * 2
    local group_h = h * 0.2
    reaper.ImGui_BeginChild(self.ctx, "groups", w, h)
    for k, child in pairs(self.project.children) do
        self:drawGroup(w-pad2_x, group_h, k, child)
    end
    self:drawAddNewChild(w-pad2_x, group_h)
    reaper.ImGui_EndChild(self.ctx)
end

function Interface:update()
    local w, h = reaper.ImGui_GetWindowSize(self.ctx)
    if not self.project.initiated then
        self:drawInit(w, h)
        return
    end

    local header_h = h * 0.10
    self:drawTitle(w, header_h)
    reaper.ImGui_Spacing(self.ctx)
    self:drawGroups(w, h-header_h)
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
