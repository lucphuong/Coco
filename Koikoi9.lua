-- 🛡️ Anti Ban
local function AntiBan()
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        if method == "Kick" then return nil end
        return oldNamecall(self, unpack(args))
    end)
end
AntiBan()

-- ⚔️ Auto Attack
local AutoAttack = false
local function StartAutoAttack()
    AutoAttack = not AutoAttack
    while AutoAttack do
        task.wait(1/315)
        local VirtualUser = game:GetService("VirtualUser")
        VirtualUser:CaptureController()
        VirtualUser:ClickButton1(Vector2.new())
    end
end

-- 🌾 Auto Farm
local AutoFarm = false
local function StartAutoFarm()
    AutoFarm = not AutoFarm
    while AutoFarm do
        task.wait(1)
        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("StartQuest", "BanditQuest1", 1)
        for _, enemy in pairs(game:GetService("Workspace").Enemies:GetChildren()) do
            if enemy:IsA("Model") and enemy:FindFirstChild("HumanoidRootPart") then
                game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = enemy.HumanoidRootPart.CFrame
                task.wait(0.5)
                StartAutoAttack()
            end
        end
    end
end

-- 🛡️ Teleport Safe Zone (Fix Không Tele Ra Biển)
local function TeleportSafeZone()
    local SafeZones = {
        Vector3.new(-500, 100, 300),
        Vector3.new(2200, 50, -3500),
        Vector3.new(12000, 100, -7000)
    }
    game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(SafeZones[math.random(1, #SafeZones)])
end

-- 👁️ ESP Player
local function ESPPlayer()
    for _, player in pairs(game.Players:GetPlayers()) do
        if player ~= game.Players.LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
            local Billboard = Instance.new("BillboardGui", player.Character.Head)
            Billboard.Size = UDim2.new(1, 0, 1, 0)
            Billboard.Adornee = player.Character.Head
            local Text = Instance.new("TextLabel", Billboard)
            Text.Text = player.Name
            Text.TextColor3 = Color3.new(1, 0, 0)
            Text.Size = UDim2.new(1, 0, 1, 0)
        end
    end
end

-- 🍎 ESP Fruit
local function ESPFruit()
    for _, fruit in pairs(game.Workspace:GetChildren()) do
        if fruit:IsA("Tool") and fruit:FindFirstChild("Handle") then
            local Billboard = Instance.new("BillboardGui", fruit.Handle)
            Billboard.Size = UDim2.new(1, 0, 1, 0)
            Billboard.Adornee = fruit.Handle
            local Text = Instance.new("TextLabel", Billboard)
            Text.Text = "🥭 Trái Ác Quỷ"
            Text.TextColor3 = Color3.new(1, 1, 0)
            Text.Size = UDim2.new(1, 0, 1, 0)
        end
    end
end

-- 📜 Tạo GUI (Menu Có Kéo Thả)
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 300, 0, 350)
MainFrame.Position = UDim2.new(0.5, -150, 0.3, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = true
MainFrame.Active = true
MainFrame.Draggable = true -- Kéo thả menu

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0.15, 0)
Title.BackgroundColor3 = Color3.fromRGB(85, 85, 255)
Title.Text = "Blox Fruits Hub by Koi"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.Font = Enum.Font.SourceSansBold
Title.TextSize = 18

-- 🌟 Tạo Tabs
local Tabs = {"Main", "ESP", "Settings"}
local CurrentTab = "Main"

local function ShowTab(tabName)
    for _, child in ipairs(MainFrame:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= tabName then
            child.Visible = false
        elseif child.Name == tabName then
            child.Visible = true
        end
    end
    CurrentTab = tabName
end

for i, tabName in ipairs(Tabs) do
    local TabButton = Instance.new("TextButton", MainFrame)
    TabButton.Size = UDim2.new(0.3, 0, 0.1, 0)
    TabButton.Position = UDim2.new((i - 1) * 0.35, 0, 0.15, 0)
    TabButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    TabButton.TextColor3 = Color3.new(1, 1, 1)
    TabButton.Font = Enum.Font.SourceSansBold
    TabButton.TextSize = 14
    TabButton.Text = tabName
    TabButton.MouseButton1Click:Connect(function()
        ShowTab(tabName)
    end)
end

-- 🔹 Tạo Nút
local function CreateButton(tab, text, callback)
    local Button = Instance.new("TextButton", tab)
    Button.Size = UDim2.new(1, 0, 0.15, 0)
    Button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    Button.TextColor3 = Color3.new(1, 1, 1)
    Button.Font = Enum.Font.SourceSansBold
    Button.TextSize = 14
    Button.Text = text
    Button.MouseButton1Click:Connect(callback)
end

-- 🌟 Main Tab
local MainTab = Instance.new("Frame", MainFrame)
MainTab.Name = "Main"
MainTab.Size = UDim2.new(1, 0, 0.7, 0)
MainTab.Position = UDim2.new(0, 0, 0.25, 0)
MainTab.Visible = true

CreateButton(MainTab, "⚔️ Auto Attack", StartAutoAttack)
CreateButton(MainTab, "🌾 Auto Farm", StartAutoFarm)
CreateButton(MainTab, "🛡️ Teleport Safe Zone", TeleportSafeZone)

-- 👁️ ESP Tab
local ESPTab = Instance.new("Frame", MainFrame)
ESPTab.Name = "ESP"
ESPTab.Size = UDim2.new(1, 0, 0.7, 0)
ESPTab.Position = UDim2.new(0, 0, 0.25, 0)
ESPTab.Visible = false

CreateButton(ESPTab, "👁️ ESP Player", ESPPlayer)
CreateButton(ESPTab, "🍎 ESP Fruit", ESPFruit)

-- ⚙️ Settings Tab
local SettingsTab = Instance.new("Frame", MainFrame)
SettingsTab.Name = "Settings"
SettingsTab.Size = UDim2.new(1, 0, 0.7, 0)
SettingsTab.Position = UDim2.new(0, 0, 0.25, 0)
SettingsTab.Visible = false

CreateButton(SettingsTab, "🛡️ Anti Ban", AntiBan)

-- 🎮 Đóng/Mở Menu (Phím "M")
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.M then
        MainFrame.Visible = not MainFrame.Visible
    end
end)
