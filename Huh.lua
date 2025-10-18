-- RED MENU vFinal (Blox Fruits Update 27) + Xeter 2
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- state
local state = {
    Hiru = false,
    Xeter3 = false,
    Soul = false,
    Quantum = false,
    Txz = false,
    Omg = false,
    Xeter2 = false,
    AntiAFK = false,
    AntiBan = false,
    Visible = true
}

local handles = {}

local function tryLoad(key, func)
    if handles[key] then return end
    local ok, ret = pcall(func)
    if not ok then
        warn(key.." load error:", ret)
    else
        handles[key] = ret
    end
end

local function tryCleanup(key)
    local h = handles[key]
    if h then
        if type(h) == "function" then
            pcall(h)
        elseif typeof(h) == "Instance" and h.Destroy then
            pcall(function() h:Destroy() end)
        end
        handles[key] = nil
    end
end

-- UI
local function createMenu()
    if PlayerGui:FindFirstChild("RedMenuSafe") then
        PlayerGui.RedMenuSafe:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "RedMenuSafe"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 500, 0, 500) -- rộng hơn để vừa 9 nút
    frame.Position = UDim2.new(0.5, -250, 0.1, 0)
    frame.BackgroundColor3 = Color3.fromRGB(145,20,20)
    frame.BorderSizePixel = 2
    frame.Parent = screenGui

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,0,0,30)
    title.BackgroundColor3 = Color3.fromRGB(190,30,30)
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 18
    title.Text = "🔴 KOI HUB ALL SCRIPT BF27"
    title.Parent = frame

    -- buttons
    local buttonNames = {"Hiru","Xeter","Soul","Quantum","Txz","Omg","Xeter2","AntiAFK","AntiBan"}
    local btnWidth = 90
    local spacing = 5
    for i, key in ipairs(buttonNames) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, btnWidth, 0, 30)
        btn.Position = UDim2.new(0, 5 + (btnWidth + spacing)*(i-1), 0, 40)
        btn.BackgroundColor3 = Color3.fromRGB(20,140,20)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.Text = key .. " [OFF]"
        btn.Parent = frame

        btn.MouseButton1Click:Connect(function()
            state[key] = not state[key]
            btn.BackgroundColor3 = state[key] and Color3.fromRGB(20,140,20) or Color3.fromRGB(140,10,10)
            btn.Text = key .. (state[key] and " [ON]" or " [OFF]")

            if key == "Hiru" and state[key] then
                tryLoad("Hiru", function()
                    getgenv().Settings = {JoinTeam=true, Team="Marines"}
                    return loadstring(game:HttpGet("https://raw.githubusercontent.com/kiddohiru/Source/main/BloxFruits.lua"))()
                end)
            elseif key == "Xeter" and state[key] then
                tryLoad("Xeter", function()
                    getgenv().Version = "V3"
                    getgenv().Team = "Marines"
                    return loadstring(game:HttpGet("https://raw.githubusercontent.com/TlDinhKhoi/Xeter/refs/heads/main/Main.lua"))()
                end)
            elseif key == "Soul" and state[key] then
                tryLoad("Soul", function()
                    return loadstring(game:HttpGet("https://raw.githubusercontent.com/GoblinKun009/Script/refs/heads/main/soulhub",true))()
                end)
            elseif key == "Quantum" and state[key] then
                tryLoad("Quantum", function()
                    return loadstring(game:HttpGet("https://raw.githubusercontent.com/flazhy/QuantumOnyx/refs/heads/main/QuantumOnyx.lua"))()
                end)
            elseif key == "Txz" and state[key] then
                tryLoad("Txz", function()
                    return loadstring(game:HttpGet("https://raw.githubusercontent.com/DrTxZ/Mercure-Hub/refs/heads/main/Mercure%20Hub.lua"))()
                end)
            elseif key == "Omg" and state[key] then
                tryLoad("Omg", function()
                    return loadstring(game:HttpGet("https://raw.githubusercontent.com/Omgshit/Scripts/main/MainLoader.lua"))()
                end)
            elseif key == "Xeter2" and state[key] then
                tryLoad("Xeter2", function()
                    getgenv().Team = "Marines"
                    return loadstring(game:HttpGet("https://raw.githubusercontent.com/TlDinhKhoi/Xeter/refs/heads/main/Main.lua"))()
                end)
            elseif key == "AntiAFK" then
                if state[key] then
                    handles._AntiAFKConn = Players.LocalPlayer.Idled:Connect(function()
                        game:GetService("VirtualUser"):CaptureController()
                        game:GetService("VirtualUser"):ClickButton2(Vector2.new(0,0))
                    end)
                else
                    if handles._AntiAFKConn then
                        pcall(function() handles._AntiAFKConn:Disconnect() end)
                        handles._AntiAFKConn = nil
                    end
                end
            elseif key == "AntiBan" then
                if state[key] then
                    warn("AntiBan cannot be executed (disallowed).")
                end
            end
        end)
    end

    -- drag support
    local dragging, dragInput, dragStart, startPos
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    title.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    title.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

createMenu()
print("Thanks for use.")
