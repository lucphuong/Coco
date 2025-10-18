-- RED MENU ALL-IN-ONE (SAFE) FOR BLOX FRUITS
-- Menu rộng, kéo thả, tất cả loadstring pcall

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local state = {
    InfJump = false,
    FlyV3 = false,
    Shader = false,
    TeleportGUI = false,
    Speed = false,
    AntiAFK = false,
    Antimat = false,
    BatTu = false,
    TanHinh = false,
    Noclip = false,
    WallWalk = false,
    AntiLag = false,
    FeFlip = false
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
    if not url then return end
    local ok, res = pcall(function()
        return game:HttpGet(url, true)
    end)
    if ok then
        pcall(function()
            local f = loadstring(res)
            if f then
                handles[key] = f()
            end
        end)
    end
end

local hooks = {}

-- INFJUMP
hooks.InfJump = function(enable)
    if enable then
        if handles.InfJump then return end
        local conn = UserInputService.JumpRequest:Connect(function()
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then pcall(function() hum:ChangeState("Jumping") end) end
            end
        end)
        handles.InfJump = function() conn:Disconnect() end
    else
        tryCleanup("InfJump")
    end
end

-- FLY
hooks.FlyV3 = function(enable)
    if enable then
        safeLoadFromUrl("FlyV3", "https://raw.githubusercontent.com/XNEOFF/FlyGuiV3/main/FlyGuiV3.txt")
    else
        tryCleanup("FlyV3")
    end
end

-- SHADER
hooks.Shader = function(enable)
    if enable then
        safeLoadFromUrl("Shader", "https://pastefy.app/xXkUxA0P/raw")
    else
        tryCleanup("Shader")
    end
end

-- TELEPORT GUI
hooks.TeleportGUI = function(enable)
    if enable then
        safeLoadFromUrl("TeleportGUI", "https://raw.githubusercontent.com/lucphuong/Minhhub/main/TeleportGUI.lua")
    else
        tryCleanup("TeleportGUI")
    end
end

-- SPEED
hooks.Speed = function(enable)
    if enable then
        safeLoadFromUrl("Speed", "https://raw.githubusercontent.com/MrScripterrFr/Speed-Changer/main/Speed%20Changer")
    else
        tryCleanup("Speed")
    end
end

-- ANTI AFK
hooks.AntiAFK = function(enable)
    if enable then
        if handles._afkConn then return end
        local conn = LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new(0,0))
        end)
        handles._afkConn = conn
    else
        tryCleanup("_afkConn")
    end
end

-- BAT TU
hooks.BatTu = function(enable)
    workspace.FallenPartsDestroyHeight = enable and 0/0 or -1000
end

-- TAN HINH
hooks.TanHinh = function(enable)
    if enable then
        safeLoadFromUrl("TanHinh", "https://abre.ai/invisible-v2")
    else
        tryCleanup("TanHinh")
    end
end

-- NOCOLIP
hooks.Noclip = function(enable)
    if enable then
        local Clip = false
        local Noclip
        Noclip = game:GetService("RunService").Stepped:Connect(function()
            if not Clip and LocalPlayer.Character then
                for _,v in pairs(LocalPlayer.Character:GetDescendants()) do
                    if v:IsA("BasePart") then v.CanCollide = false end
                end
            end
        end)
        handles.Noclip = function() Noclip:Disconnect() end
    else
        tryCleanup("Noclip")
    end
end

-- WALL WALK
hooks.WallWalk = function(enable)
    if enable then
        safeLoadFromUrl("WallWalk", "https://pastebin.com/raw/5T7KsEWy")
    else
        tryCleanup("WallWalk")
    end
end

-- Anti LAG
hooks.LowLag = function(enable)
    if enable then
        safeLoadFromUrl("LowLag", "https://pastebin.com/raw/KiSYpej6")
    else
        tryCleanup("LowLag")
    end
end

-- FELIP
hooks.FeFlip = function(enable)
    if enable then
        safeLoadFromUrl("FeFlip", "https://pastebin.com/raw/abcd1234") -- Thay bằng link raw chính xác
    else
        tryCleanup("FeFlip")
    end
end

-- UI MENU
local function createMenu()
    if PlayerGui:FindFirstChild("RedMenuAll") then PlayerGui.RedMenuAll:Destroy() end
    local gui = Instance.new("ScreenGui")
    gui.Name = "RedMenuAll"
    gui.ResetOnSpawn = false
    gui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 600)
    frame.Position = UDim2.new(0.02,0,0.1,0)
    frame.BackgroundColor3 = Color3.fromRGB(145,20,20)
    frame.Parent = gui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,50)
    title.BackgroundColor3 = Color3.fromRGB(190,30,30)
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.Text = "🔴 RED MENU ALL-IN-ONE"
    title.Parent = frame

    local items = {
        {key="InfJump", label="InfJump"},
        {key="FlyV3", label="Fly V3"},
        {key="Shader", label="Shader"},
        {key="TeleportGUI", label="Teleport GUI"},
        {key="Speed", label="Speed"},
        {key="AntiAFK", label="Anti-AFK"},
        {key="BatTu", label="Bất tử"},
        {key="TanHinh", label="Tàn hình"},
        {key="Noclip", label="Noclip"},
        {key="WallWalk", label="Đi bộ trên tường"},
        {key="LowLag", label="Giảm lag"},
        {key="FeFlip", label="Lăn (feFlip)"}
    }

    for i, info in ipairs(items) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1,-20,0,44)
        btn.Position = UDim2.new(0,10,0,54+(i-1)*50)
        btn.BackgroundColor3 = state[info.key] and Color3.fromRGB(20,140,20) or Color3.fromRGB(140,10,10)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 16
        btn.Text = info.label .. (state[info.key] and " [ON]" or " [OFF]")
        btn.Parent = frame

        btn.MouseButton1Click:Connect(function()
            state[info.key] = not state[info.key]
            btn.BackgroundColor3 = state[info.key] and Color3.fromRGB(20,140,20) or Color3.fromRGB(140,10,10)
            btn.Text = info.label .. (state[info.key] and " [ON]" or " [OFF]")
            pcall(function() hooks[info.key](state[info.key]) end)
        end)
    end

    -- Drag
    local dragging, dragStart, startPos = false
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                                       startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
end

createMenu()
print("✅ RedMenuAll loaded (drag enabled, safe, pcall).")
