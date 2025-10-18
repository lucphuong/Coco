-- RED MENU SAFE (FULL FUNCTIONS, DRAGGABLE)
-- All external scripts wrapped in pcall
-- Menu Horizontal, Buttons toggle ON/OFF

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- State
local state = {
    InfJump = false,
    FlyV3 = false,
    Shader = false,
    TeleportGUI = false,
    Speed = false,
    AntiAFK = false,
    Roll = false,
    Invisible = false,
    Immortal = false,
    Noclip = false,
    WallWalk = false,
    ReduceLag = false
}

local handles = {}

local function tryCleanup(key)
    local h = handles[key]
    if not h then return end
    if type(h) == "function" then
        pcall(h)
    elseif typeof(h) == "Instance" and h.Destroy then
        pcall(function() h:Destroy() end)
    end
    handles[key] = nil
end

local function safeLoadFromUrl(key, url)
    if not url or url == "" then return end
    local ok,res = pcall(function() return game:HttpGet(url,true) end)
    if ok and res then
        pcall(function()
            local f = loadstring(res)
            if f then handles[key] = f() end
        end)
    end
end

-- Hooks for each function
local hooks = {}

-- INFJUMP
hooks.InfJump = function(enable)
    if enable then
        if handles.InfJump then return end
        local conn
        conn = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then pcall(function() humanoid:ChangeState("Jumping") end) end
            end
        end)
        handles.InfJump = function() conn:Disconnect() end
    else tryCleanup("InfJump") end
end

-- FLY
hooks.FlyV3 = function(enable)
    if enable then
        safeLoadFromUrl("FlyV3","https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt")
    else tryCleanup("FlyV3") end
end

-- SHADER
hooks.Shader = function(enable)
    if enable then
        safeLoadFromUrl("Shader","https://pastefy.app/xXkUxA0P/raw")
    else tryCleanup("Shader") end
end

-- TELEPORT GUI
hooks.TeleportGUI = function(enable)
    if enable then
        safeLoadFromUrl("TeleportGUI","https://raw.githubusercontent.com/lucphuong/Minhhub/main/TeleportGUI.lua")
    else tryCleanup("TeleportGUI") end
end

-- SPEED
hooks.Speed = function(enable)
    if enable then
        safeLoadFromUrl("Speed","https://raw.githubusercontent.com/MrScripterrFr/Speed-Changer/main/Speed%20Changer")
    else tryCleanup("Speed") end
end

-- ANTI AFK
hooks.AntiAFK = function(enable)
    if enable then
        if handles._antiAfkConn then return end
        handles._antiAfkConn = LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0,0))
        end)
    else tryCleanup("_antiAfkConn") end
end

-- ROLL (feFlip)
hooks.Roll = function(enable)
    if enable then
        safeLoadFromUrl("Roll","https://pastebin.com/raw/dC1D8aU2") -- pastebin URL placeholder
    else tryCleanup("Roll") end
end

-- INVISIBLE
hooks.Invisible = function(enable)
    if enable then
        safeLoadFromUrl("Invisible","https://abre.ai/invisible-v2")
    else tryCleanup("Invisible") end
end

-- IMMORTAL
hooks.Immortal = function(enable)
    if enable then
        workspace.FallenPartsDestroyHeight = 0/0
    else
        workspace.FallenPartsDestroyHeight = -500
    end
end

-- NOCLIP
local noclipConn
hooks.Noclip = function(enable)
    if enable then
        noclipConn = game:GetService("RunService").Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _,v in pairs(char:GetDescendants()) do
                    if v:IsA("BasePart") and v.CanCollide then
                        v.CanCollide = false
                    end
                end
            end
        end)
    else
        if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
    end
end

-- WALL WALK
hooks.WallWalk = function(enable)
    if enable then
        safeLoadFromUrl("WallWalk","https://pastebin.com/raw/5T7KsEWy")
    else tryCleanup("WallWalk") end
end

-- REDUCE LAG
hooks.ReduceLag = function(enable)
    if enable then
        safeLoadFromUrl("ReduceLag","https://pastebin.com/raw/KiSYpej6")
    else tryCleanup("ReduceLag") end
end

-- MENU UI
local function createMenu()
    if PlayerGui:FindFirstChild("RedMenuSafe") then PlayerGui.RedMenuSafe:Destroy() end
    local screenGui = Instance.new("ScreenGui", PlayerGui)
    screenGui.Name = "RedMenuSafe"
    screenGui.ResetOnSpawn = false

    local frame = Instance.new("Frame", screenGui)
    frame.Size = UDim2.new(0, 600, 0, 60)
    frame.Position = UDim2.new(0.02,0,0.02,0)
    frame.BackgroundColor3 = Color3.fromRGB(145,20,20)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(0,150,1,0)
    title.BackgroundColor3 = Color3.fromRGB(190,30,30)
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Text = "🔴 RED MENU"

    local buttons = {}
    local keys = {"InfJump","FlyV3","Shader","TeleportGUI","Speed","AntiAFK","Roll","Invisible","Immortal","Noclip","WallWalk","ReduceLag"}
    for i,key in ipairs(keys) do
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0,80,1,0)
        btn.Position = UDim2.new(0, 150 + (i-1)*45, 0,0)
        btn.BackgroundColor3 = state[key] and Color3.fromRGB(20,140,20) or Color3.fromRGB(140,10,10)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.Text = key .. (state[key] and " [ON]" or " [OFF]")
        btn.MouseButton1Click:Connect(function()
            state[key] = not state[key]
            btn.BackgroundColor3 = state[key] and Color3.fromRGB(20,140,20) or Color3.fromRGB(140,10,10)
            btn.Text = key .. (state[key] and " [ON]" or " [OFF]")
            pcall(function() hooks[key](state[key]) end)
        end)
        buttons[key] = btn
    end

    -- Drag
    local dragging=false
    local dragStart, startPos
    title.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true
            dragStart=input.Position
            startPos=frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            local delta=input.Position-dragStart
            frame.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+delta.X,startPos.Y.Scale,startPos.Y.Offset+delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=false
        end
    end)
end

createMenu()
print("✅ RedMenuSafe FULL loaded, draggable, pcall safe!")
