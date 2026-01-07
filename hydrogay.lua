--[[
    HYDROBRIDGE V5: FINAL STABLE
    - Fixes "Same ID" Race Condition
    - Auto-cleans stale files
    - Live ID Re-sorting
--]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()

local FOLDER = "hydrobridge"
local SECRET_KEY = "SECURE_KEY_123"
local JOB_ID = (game.JobId ~= "" and game.JobId) or "STUDIO"
local MY_FILE_NAME = string.format("%s_%s.json", LocalPlayer.Name, JOB_ID:sub(1, 8))
local MY_FILE_PATH = FOLDER .. "/" .. MY_FILE_NAME

if not isfolder(FOLDER) then makefolder(FOLDER) end

getgenv().hydrobridge = { InstanceId = 0 }
local hb = getgenv().hydrobridge

-- [[ UTILITIES ]] --
local function safeDecode(str)
    local s, r = pcall(HttpService.JSONDecode, HttpService, str)
    return s and r or nil
end

local function safeEncode(tbl)
    local s, r = pcall(HttpService.JSONEncode, HttpService, tbl)
    return s and r or "{}"
end

-- [[ CLEANUP STALE FILES ]] --
-- Deletes files that haven't been updated in over 15 seconds
local function cleanup()
    local files = listfiles(FOLDER)
    local now = os.time()
    for _, path in ipairs(files) do
        local lastMod = 0
        pcall(function()
            local data = safeDecode(readfile(path))
            lastMod = data and data.lastHeartbeat or 0
        end)
        if now - lastMod > 15 then
            pcall(delfile, path)
        end
    end
end

-- [[ DYNAMIC ID SORTING ]] --
local function updateInstanceId()
    local files = listfiles(FOLDER)
    local activeJson = {}
    
    for _, path in ipairs(files) do
        if path:sub(-5) == ".json" then table.insert(activeJson, path) end
    end
    table.sort(activeJson)
    
    for i, path in ipairs(activeJson) do
        if path:find(MY_FILE_NAME, 1, true) then
            if hb.InstanceId ~= i then
                hb.InstanceId = i
                local ui = game:GetService("CoreGui"):FindFirstChild("HydroBridgeUI")
                if ui then ui.TextLabel.Text = "BRIDGE ID: " .. i end
            end
            return i
        end
    end
end

-- [[ UI ]] --
local function createUI(id)
    local sg = Instance.new("ScreenGui")
    sg.Name = "HydroBridgeUI"
    sg.DisplayOrder = 999
    
    local label = Instance.new("TextLabel", sg)
    label.Size = UDim2.new(0, 140, 0, 30)
    label.Position = UDim2.new(1, -150, 0, 10)
    label.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    label.TextColor3 = Color3.fromRGB(0, 255, 150)
    label.Text = "BRIDGE ID: " .. id
    label.Font = Enum.Font.Code
    label.BorderSizePixel = 0
    
    pcall(function() sg.Parent = game:GetService("CoreGui") end)
    if not sg.Parent then sg.Parent = LocalPlayer:WaitForChild("PlayerGui") end
end

-- [[ API ]] --
hb.execute = function(id, code)
    local files = listfiles(FOLDER)
    local activeJson = {}
    for _, p in ipairs(files) do if p:sub(-5) == ".json" then table.insert(activeJson, p) end end
    table.sort(activeJson)
    
    local target = activeJson[id]
    if target then
        local data = safeDecode(readfile(target)) or {commands = {}}
        table.insert(data.commands, {script = code, secret = SECRET_KEY})
        writefile(target, safeEncode(data))
        return true
    end
    return false
end

hb.executeAll = function(code)
    local files = listfiles(FOLDER)
    for _, path in ipairs(files) do
        if path:sub(-5) == ".json" then
            local data = safeDecode(readfile(path)) or {commands = {}}
            table.insert(data.commands, {script = code, secret = SECRET_KEY})
            writefile(path, safeEncode(data))
        end
    end
end

-- [[ MAIN EXECUTION ]] --
task.spawn(function()
    cleanup() -- Clear old files from previous crashes
    
    -- INITIAL CLAIM: Write file immediately
    writefile(MY_FILE_PATH, safeEncode({
        lastHeartbeat = os.time(),
        commands = {}
    }))
    
    -- JITTER: Prevent simultaneous reading
    task.wait(math.random(1, 100) / 100)
    
    updateInstanceId()
    createUI(hb.InstanceId)
    
    while task.wait(1) do
        updateInstanceId() -- Re-check IDs in case someone joined/left
        
        local content = isfile(MY_FILE_PATH) and readfile(MY_FILE_PATH) or "{}"
        local data = safeDecode(content) or {commands = {}}
        
        if #data.commands > 0 then
            for _, cmd in ipairs(data.commands) do
                if cmd.secret == SECRET_KEY then
                    task.spawn(function()
                        local func, err = loadstring(cmd.script)
                        if func then pcall(func) end
                    end)
                end
            end
            data.commands = {}
        end
        
        data.lastHeartbeat = os.time()
        pcall(writefile, MY_FILE_PATH, safeEncode(data))
    end
end)

-- Remove file on normal close (Optional/Executor dependent)
game:BindToClose(function()
    pcall(delfile, MY_FILE_PATH)
end)
