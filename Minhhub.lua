-- DF Helper (Full) - ESP + AutoPickup + AutoStore + ServerHop + Improved Menu + Toaster
-- Author: assistant (example)
getgenv().DFHelper = getgenv().DFHelper or {}
local cfg = getgenv().DFHelper

-- CONFIG
cfg.autoPickupRange = cfg.autoPickupRange or 250
cfg.noFruitServerHopAfter = cfg.noFruitServerHopAfter or 60
cfg.checkInterval = cfg.checkInterval or 2
cfg.pickupSpeed = cfg.pickupSpeed or 120
cfg.espEnabled = cfg.espEnabled or false
cfg.autoPickupEnabled = cfg.autoPickupEnabled or false
cfg.serverHopEnabled = cfg.serverHopEnabled or true
cfg.autoStoreEnabled = cfg.autoStoreEnabled or true
cfg.hotkeys = cfg.hotkeys or {
    toggleGui = Enum.KeyCode.F1,
    toggleESP = Enum.KeyCode.F2,
    toggleAutoPickup = Enum.KeyCode.F3,
    toggleServerHop = Enum.KeyCode.F4
}

-- SERVICES
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

if not LocalPlayer then warn("[DFHelper] LocalPlayer missing") return end

-- STATE
local createdEsp = {}
local lastFruitFoundTime = os.time()
local guiRef = nil
local notified = {} -- model -> lastNotifyTime

-- UTIL
local function safeCall(f,... ) local ok,res = pcall(f, ...) return ok,res end
local function isFruitFolder()
    return workspace:FindFirstChild("Fruit") or workspace:FindFirstChild("Fruits")
        or workspace:FindFirstChild("DevilFruit") or workspace:FindFirstChild("ServerFruit") or workspace:FindFirstChild("SpawnedFruits")
end

-- TOASTER (popup)
local function makeToaster()
    if LocalPlayer.PlayerGui:FindFirstChild("DFHelperToaster") then return end
    local screen = Instance.new("ScreenGui")
    screen.Name = "DFHelperToaster"
    screen.ResetOnSpawn = false
    screen.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local container = Instance.new("Frame", screen)
    container.Size = UDim2.new(0, 260, 0, 110)
    container.Position = UDim2.new(1, -270, 0, 18)
    container.BackgroundTransparency = 1
    container.Name = "Container"

    return screen, container
end

local toasterScreen, toasterContainer = makeToaster()

local function showToast(text, dur)
    dur = dur or 4
    if not toasterContainer then toasterScreen, toasterContainer = makeToaster() end
    local frame = Instance.new("Frame", toasterContainer)
    frame.Size = UDim2.new(1,0,0,36)
    frame.Position = UDim2.new(0,0,0,(#toasterContainer:GetChildren()-0)*38)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.ZIndex = 50

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1, -8, 1, -8)
    lbl.Position = UDim2.new(0, 4, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextScaled = true
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    spawn(function()
        task.wait(dur)
        pcall(function() frame:Destroy() end)
    end)
end

-- ESP
local function createESP(obj)
    if createdEsp[obj] then return end
    local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
    if not part then return end
    local bill = Instance.new("BillboardGui")
    bill.Name = "DFHelper_ESP"
    bill.Adornee = part
    bill.Size = UDim2.new(0,120,0,36)
    bill.AlwaysOnTop = true
    bill.StudsOffset = Vector3.new(0,1.6,0)
    bill.Parent = part
    local f = Instance.new("Frame", bill)
    f.Size = UDim2.new(1,0,1,0); f.BackgroundTransparency = 0.45; f.BorderSizePixel = 0
    local lbl = Instance.new("TextLabel", f)
    lbl.Size = UDim2.new(1,-4,1,-4); lbl.Position = UDim2.new(0,2,0,2)
    lbl.BackgroundTransparency = 1; lbl.Text = "🍏 Devil Fruit"; lbl.TextScaled = true; lbl.Font = Enum.Font.SourceSansBold
    createdEsp[obj] = bill
end

local function removeESP(obj)
    if createdEsp[obj] then pcall(function() createdEsp[obj]:Destroy() end); createdEsp[obj] = nil end
end

-- SCAN FRUITS
local function scanForFruits()
    local fruitsFolder = isFruitFolder()
    local res = {}
    if not fruitsFolder then return res end
    for _, obj in ipairs(fruitsFolder:GetChildren()) do
        if obj and (obj:IsA("Tool") or obj:IsA("Model") or obj:IsA("BasePart")) then
            local primary = (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))) or obj
            if primary and primary.Position then
                table.insert(res, {model = obj, part = primary, pos = primary.Position})
            end
        end
    end
    return res
end

-- AUTO PICKUP + STORE
local function tryPickupFruit(fruitEntry)
    if not fruitEntry or not fruitEntry.part then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return false end
    local oldSpeed = humanoid.WalkSpeed
    safeCall(function() humanoid.WalkSpeed = cfg.pickupSpeed end)

    local target = fruitEntry.pos + Vector3.new(0,2,0)
    local steps = 8
    for i=1,steps do
        if not cfg.autoPickupEnabled then break end
        local alpha = i/steps
        local newPos = hrp.Position:Lerp(target, alpha)
        safeCall(function() hrp.CFrame = CFrame.new(newPos) end)
        task.wait(0.045)
    end
    safeCall(function() hrp.CFrame = CFrame.new(target) end)
    task.wait(0.25)
    safeCall(function() humanoid.WalkSpeed = oldSpeed end)

    if cfg.autoStoreEnabled then
        safeCall(function()
            local fruitTool = LocalPlayer.Backpack:FindFirstChildWhichIsA("Tool") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Tool"))
            if fruitTool then
                local rem = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CommF_")
                if rem and rem.InvokeServer then
                    rem:InvokeServer("StoreFruit", fruitTool.Name)
                    warn("[DFHelper] Stored fruit: "..fruitTool.Name)
                end
            end
        end)
    end
    return true
end

-- SERVER HOP
local function serverHop()
    local req = syn and syn.request or (http_request or request or http and http.request)
    if not req then warn("[DFHelper] No http request function (server hop disabled)"); return end
    local placeId = tostring(game.PlaceId)
    local url = ("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100"):format(placeId)
    local ok,res = pcall(function() return req({Url = url, Method = "GET"}) end)
    if not ok or not res or not res.Body then warn("[DFHelper] serverHop request failed"); return end
    local ok2,data = pcall(function() return HttpService:JSONDecode(res.Body) end)
    if not ok2 or not data or not data.data then warn("[DFHelper] serverHop: bad data"); return end
    for _,server in ipairs(data.data) do
        if tostring(server.id) ~= tostring(game.JobId) and tonumber(server.playing) < tonumber(server.maxPlayers) then
            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer) end)
            return
        end
    end
    warn("[DFHelper] serverHop: no suitable server")
end

-- GUI (menu + hotkeys + status)
local function createGUI()
    if LocalPlayer.PlayerGui:FindFirstChild("DFHelperGui") then LocalPlayer.PlayerGui.DFHelperGui:Destroy() end
    local screen = Instance.new("ScreenGui"); screen.Name = "DFHelperGui"; screen.ResetOnSpawn = false; screen.Parent = LocalPlayer:WaitForChild("PlayerGui")
    local frame = Instance.new("Frame", screen); frame.Size = UDim2.new(0,260,0,180); frame.Position = UDim2.new(0,12,0,80); frame.BackgroundTransparency = 0.25; frame.Active=true; frame.Draggable=true
    local title = Instance.new("TextLabel", frame); title.Size = UDim2.new(1,0,0,26); title.Text="🍏 DF Helper (Menu)"; title.TextScaled=true; title.BackgroundTransparency=1; title.Font=Enum.Font.SourceSansBold
    local status = Instance.new("TextLabel", frame); status.Size = UDim2.new(1,-12,0,24); status.Position = UDim2.new(0,6,0,30); status.BackgroundTransparency=1; status.TextScaled=true
    local function updateStatus() status.Text = ("ESP: %s  |  AutoPickup: %s  |  AutoStore: %s  |  ServerHop: %s")
            :format(cfg.espEnabled and "ON" or "OFF", cfg.autoPickupEnabled and "ON" or "OFF", cfg.autoStoreEnabled and "ON" or "OFF", cfg.serverHopEnabled and "ON" or "OFF") end
    updateStatus()
    local function makeBtn(txt, pos, init, cb)
        local b = Instance.new("TextButton", frame); b.Size = UDim2.new(0,120,0,28); b.Position = UDim2.new(0,8 + ((pos-1)*126)%240,0,64 + math.floor((pos-1)/2)*34)
        b.Text = txt..": "..(init and "ON" or "OFF"); b.TextScaled = true; b.BackgroundTransparency = 0.15; b.Font = Enum.Font.SourceSans
        b.MouseButton1Click:Connect(function() init = not init; b.Text = txt..": "..(init and "ON" or "OFF"); cb(init); updateStatus() end)
    end
    makeBtn("ESP",1,cfg.espEnabled,function(v) cfg.espEnabled = v end)
    makeBtn("Auto Pickup",2,cfg.autoPickupEnabled,function(v) cfg.autoPickupEnabled = v end)
    makeBtn("Auto Store",3,cfg.autoStoreEnabled,function(v) cfg.autoStoreEnabled = v end)
    makeBtn("ServerHop",4,cfg.serverHopEnabled,function(v) cfg.serverHopEnabled = v end)
    local rangeLabel = Instance.new("TextLabel", frame); rangeLabel.Size=UDim2.new(0,140,0,22); rangeLabel.Position=UDim2.new(0,8,0,140); rangeLabel.BackgroundTransparency=1; rangeLabel.TextScaled=true; rangeLabel.Text="Pickup Range: "..tostring(cfg.autoPickupRange)
    local dec = Instance.new("TextButton", frame); dec.Size=UDim2.new(0,36,0,22); dec.Position=UDim2.new(0,150,0,140); dec.Text="-"; dec.TextScaled=true; dec.MouseButton1Click:Connect(function() cfg.autoPickupRange = math.max(50, cfg.autoPickupRange - 25); rangeLabel.Text = "Pickup Range: "..tostring(cfg.autoPickupRange) end)
    local inc = Instance.new("TextButton", frame); inc.Size=UDim2.new(0,36,0,22); inc.Position=UDim2.new(0,190,0,140); inc.Text="+"; inc.TextScaled=true; inc.MouseButton1Click:Connect(function() cfg.autoPickupRange = math.min(1000, cfg.autoPickupRange + 25); rangeLabel.Text = "Pickup Range: "..tostring(cfg.autoPickupRange) end)
    local hint = Instance.new("TextLabel", frame); hint.Size=UDim2.new(1,-12,0,20); hint.Position=UDim2.new(0,6,0,166); hint.BackgroundTransparency=1; hint.TextScaled=true; hint.Text = ("Hotkeys: GUI[%s] ESP[%s] Auto[%s] Hop[%s]"):format(cfg.hotkeys.toggleGui.Name, cfg.hotkeys.toggleESP.Name, cfg.hotkeys.toggleAutoPickup.Name, cfg.hotkeys.toggleServerHop.Name)
    getgenv().DFHelper.updateStatus = updateStatus
    return screen
end

-- Initialize GUI
guiRef = createGUI()

-- HOTKEYS
do
    local guiVisible = true
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == cfg.hotkeys.toggleGui then if guiRef then guiVisible = not guiVisible; guiRef.Enabled = guiVisible end
        elseif input.KeyCode == cfg.hotkeys.toggleESP then cfg.espEnabled = not cfg.espEnabled; if getgenv().DFHelper.updateStatus then getgenv().DFHelper.updateStatus() end
        elseif input.KeyCode == cfg.hotkeys.toggleAutoPickup then cfg.autoPickupEnabled = not cfg.autoPickupEnabled; if getgenv().DFHelper.updateStatus then getgenv().DFHelper.updateStatus() end
        elseif input.KeyCode == cfg.hotkeys.toggleServerHop then cfg.serverHopEnabled = not cfg.serverHopEnabled; if getgenv().DFHelper.updateStatus then getgenv().DFHelper.updateStatus() end
        end
    end)
end

-- CLEANUP
local function cleanup()
    for k,_ in pairs(createdEsp) do pcall(function() if createdEsp[k] and createdEsp[k].Parent then createdEsp[k]:Destroy() end end); createdEsp[k] = nil end
    if LocalPlayer.PlayerGui and LocalPlayer.PlayerGui:FindFirstChild("DFHelperGui") then pcall(function() LocalPlayer.PlayerGui.DFHelperGui:Destroy() end) end
    if LocalPlayer.PlayerGui and LocalPlayer.PlayerGui:FindFirstChild("DFHelperToaster") then pcall(function() LocalPlayer.PlayerGui.DFHelperToaster:Destroy() end) end
end
getgenv().DFHelper.cleanup = cleanup
getgenv().DFHelper.config = cfg

-- MAIN LOOP
task.spawn(function()
    while task.wait(cfg.checkInterval) do
        local fruits = scanForFruits()
        if #fruits > 0 then lastFruitFoundTime = os.time() end

        -- notify new fruits (once per model, debounce 6s)
        for _,f in ipairs(fruits) do
            if f.model and (not notified[f.model] or (os.time() - notified[f.model] >= 6)) then
                notified[f.model] = os.time()
                showToast("Fruit spawned!", 4)
            end
        end

        -- ESP
        if cfg.espEnabled then
            local present = {}
            for _, f in ipairs(fruits) do present[f.model] = true if not createdEsp[f.model] then createESP(f.model) end end
            for obj,_ in pairs(createdEsp) do if not present[obj] then removeESP(obj) end end
        else
            for obj,_ in pairs(createdEsp) do removeESP(obj) end
        end

        -- Auto pickup
        if cfg.autoPickupEnabled and #fruits > 0 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            table.sort(fruits, function(a,b) return (a.pos - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude < (b.pos - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude end)
            local nearest = fruits[1]
            if nearest and (nearest.pos - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= cfg.autoPickupRange then pcall(function() tryPickupFruit(nearest) end) end
        end

        -- Server hop
        if cfg.serverHopEnabled and (os.time() - lastFruitFoundTime >= cfg.noFruitServerHopAfter) then
            lastFruitFoundTime = os.time()
            warn("[DFHelper] No fruits found, hopping...")
            pcall(serverHop)
        end
    end
end)

print("[DFHelper] Full version loaded.")
