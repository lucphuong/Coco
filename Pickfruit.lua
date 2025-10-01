--// Blox Fruits Devil Fruit Helper (ESP + Auto Pickup + Auto Store + Server Hop)
-- Author: assistant (example) | GUI cải tiến (menu + hotkeys + status)
-- NOTE: Test trên account phụ trước khi dùng.

getgenv().DFHelper = getgenv().DFHelper or {}
local cfg = getgenv().DFHelper

-- ======= CONFIG =========
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
-- =========================

-- SERVICES
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

if not LocalPlayer then
    warn("[DFHelper] LocalPlayer not available.")
    return
end

-- TRACKING
local createdEsp = {}
local lastFruitFoundTime = os.time()
local guiRef = nil

-- UTIL
local function safeCall(f, ...)
    local ok, res = pcall(f, ...)
    return ok, res
end

-- ESP
local function createESP(obj)
    if createdEsp[obj] then return end
    local part = obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")) or obj
    if not part then return end

    local screenGui = Instance.new("BillboardGui")
    screenGui.Name = "DFHelper_ESP"
    screenGui.Adornee = part
    screenGui.Size = UDim2.new(0, 120, 0, 36)
    screenGui.AlwaysOnTop = true
    screenGui.StudsOffset = Vector3.new(0, 1.6, 0)
    screenGui.Parent = part

    local frame = Instance.new("Frame", screenGui)
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundTransparency = 0.45
    frame.BorderSizePixel = 0

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1,-4,1,-4)
    label.Position = UDim2.new(0,2,0,2)
    label.BackgroundTransparency = 1
    label.Text = "🍏 Devil Fruit"
    label.TextScaled = true
    label.Font = Enum.Font.SourceSansBold
    label.TextStrokeTransparency = 0.6

    createdEsp[obj] = screenGui
end

local function removeESP(obj)
    if createdEsp[obj] then
        pcall(function() createdEsp[obj]:Destroy() end)
        createdEsp[obj] = nil
    end
end

-- SCAN FRUITS (target common folders used by Blox Fruits)
local function scanForFruits()
    local fruitsFolder = workspace:FindFirstChild("Fruit") or workspace:FindFirstChild("Fruits") or workspace:FindFirstChild("DevilFruit") or workspace:FindFirstChild("ServerFruit") or workspace:FindFirstChild("SpawnedFruits")
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

-- AUTO PICKUP + AUTO STORE
local function tryPickupFruit(fruitEntry)
    if not fruitEntry or not fruitEntry.part then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return false end

    local oldSpeed = humanoid.WalkSpeed
    safeCall(function() humanoid.WalkSpeed = cfg.pickupSpeed end)

    -- move closer (simple lerp)
    local target = fruitEntry.pos + Vector3.new(0, 2, 0)
    local steps = 8
    for i = 1, steps do
        if not cfg.autoPickupEnabled then break end
        local alpha = i/steps
        local newPos = hrp.Position:Lerp(target, alpha)
        safeCall(function() hrp.CFrame = CFrame.new(newPos) end)
        task.wait(0.045)
    end
    safeCall(function() hrp.CFrame = CFrame.new(target) end)
    task.wait(0.25)
    safeCall(function() humanoid.WalkSpeed = oldSpeed end)

    -- Attempt Auto Store (if fruit tool present)
    if cfg.autoStoreEnabled then
        safeCall(function()
            local fruitTool = LocalPlayer.Backpack:FindFirstChildWhichIsA("Tool") or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChildWhichIsA("Tool"))
            if fruitTool then
                -- Use common remote name from Blox Fruits (may vary by version)
                local comm = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") or game:GetService("ReplicatedStorage")
                if comm and comm:FindFirstChild("CommF_") then
                    local rem = comm:FindFirstChild("CommF_")
                    if rem and rem.InvokeServer then
                        rem:InvokeServer("StoreFruit", fruitTool.Name)
                        warn("[DFHelper] Stored fruit: "..fruitTool.Name)
                    end
                else
                    -- fallback to known path used earlier
                    if game:GetService("ReplicatedStorage"):FindFirstChild("Remotes") and game:GetService("ReplicatedStorage").Remotes:FindFirstChild("CommF_") then
                        game:GetService("ReplicatedStorage").Remotes.CommF_:InvokeServer("StoreFruit", fruitTool.Name)
                    end
                end
            end
        end)
    end

    return true
end

-- SERVER HOP (uses executor request)
local function serverHop()
    local req = syn and syn.request or (http_request or request or http and http.request)
    if not req then
        warn("[DFHelper] No http request function available (server hop won't work).")
        return
    end

    local placeId = tostring(game.PlaceId)
    local cursor = nil
    local url = ("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100"):format(placeId)
    local success, res = pcall(function() return req({Url = url, Method = "GET"}) end)
    if not success or not res or not res.Body then
        warn("[DFHelper] serverHop: request failed.")
        return
    end

    local ok, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
    if not ok or not data or not data.data then
        warn("[DFHelper] serverHop: invalid response.")
        return
    end

    for _, server in ipairs(data.data) do
        if tostring(server.id) ~= tostring(game.JobId) and tonumber(server.playing) < tonumber(server.maxPlayers) then
            pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer) end)
            return
        end
    end
    warn("[DFHelper] serverHop: no suitable server found.")
end

-- GUI / MENU (improved)
local function createGUI()
    -- cleanup old
    if LocalPlayer.PlayerGui:FindFirstChild("DFHelperGui") then
        LocalPlayer.PlayerGui.DFHelperGui:Destroy()
    end

    local screen = Instance.new("ScreenGui")
    screen.Name = "DFHelperGui"
    screen.ResetOnSpawn = false
    screen.Parent = LocalPlayer:WaitForChild("PlayerGui")
    guiRef = screen

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 260, 0, 180)
    frame.Position = UDim2.new(0, 12, 0, 80)
    frame.BackgroundTransparency = 0.25
    frame.Active = true
    frame.Draggable = true
    frame.Parent = screen

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 26)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "🍏 DF Helper (Menu)"
    title.TextScaled = true
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold

    -- status label
    local status = Instance.new("TextLabel", frame)
    status.Size = UDim2.new(1, -12, 0, 24)
    status.Position = UDim2.new(0, 6, 0, 30)
    status.BackgroundTransparency = 1
    status.TextScaled = true
    status.Text = ("ESP: %s  |  AutoPickup: %s  |  AutoStore: %s  |  ServerHop: %s")
        :format(tostring(cfg.espEnabled and "ON" or "OFF"),
                tostring(cfg.autoPickupEnabled and "ON" or "OFF"),
                tostring(cfg.autoStoreEnabled and "ON" or "OFF"),
                tostring(cfg.serverHopEnabled and "ON" or "OFF"))
    status.TextXAlignment = Enum.TextXAlignment.Left

    -- helper to update status text
    local function updateStatus()
        status.Text = ("ESP: %s  |  AutoPickup: %s  |  AutoStore: %s  |  ServerHop: %s")
            :format(tostring(cfg.espEnabled and "ON" or "OFF"),
                    tostring(cfg.autoPickupEnabled and "ON" or "OFF"),
                    tostring(cfg.autoStoreEnabled and "ON" or "OFF"),
                    tostring(cfg.serverHopEnabled and "ON" or "OFF"))
    end

    -- small button factory
    local function makeBtn(text, posY, initial, callback)
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0, 120, 0, 28)
        btn.Position = UDim2.new(0, 8 + ((posY-1) * 126)%240, 0, 64 + math.floor((posY-1)/2)*34)
        btn.Text = text .. ": " .. (initial and "ON" or "OFF")
        btn.TextScaled = true
        btn.BackgroundTransparency = 0.15
        btn.Font = Enum.Font.SourceSans
        btn.MouseButton1Click:Connect(function()
            local new = not initial
            initial = new
            btn.Text = text .. ": " .. (initial and "ON" or "OFF")
            callback(new)
            updateStatus()
        end)
        return btn
    end

    -- place buttons in two columns (positions 1..4)
    makeBtn("ESP", 1, cfg.espEnabled, function(v) cfg.espEnabled = v end)
    makeBtn("Auto Pickup", 2, cfg.autoPickupEnabled, function(v) cfg.autoPickupEnabled = v end)
    makeBtn("Auto Store", 3, cfg.autoStoreEnabled, function(v) cfg.autoStoreEnabled = v end)
    makeBtn("ServerHop", 4, cfg.serverHopEnabled, function(v) cfg.serverHopEnabled = v end)

    -- range slider (basic numeric adjust)
    local rangeLabel = Instance.new("TextLabel", frame)
    rangeLabel.Size = UDim2.new(0, 140, 0, 22)
    rangeLabel.Position = UDim2.new(0, 8, 0, 140)
    rangeLabel.BackgroundTransparency = 1
    rangeLabel.TextScaled = true
    rangeLabel.Text = "Pickup Range: " .. tostring(cfg.autoPickupRange)

    local decrease = Instance.new("TextButton", frame)
    decrease.Size = UDim2.new(0, 36, 0, 22)
    decrease.Position = UDim2.new(0, 150, 0, 140)
    decrease.Text = "-"
    decrease.TextScaled = true
    decrease.MouseButton1Click:Connect(function()
        cfg.autoPickupRange = math.max(50, cfg.autoPickupRange - 25)
        rangeLabel.Text = "Pickup Range: " .. tostring(cfg.autoPickupRange)
    end)

    local increase = Instance.new("TextButton", frame)
    increase.Size = UDim2.new(0, 36, 0, 22)
    increase.Position = UDim2.new(0, 190, 0, 140)
    increase.Text = "+"
    increase.TextScaled = true
    increase.MouseButton1Click:Connect(function()
        cfg.autoPickupRange = math.min(1000, cfg.autoPickupRange + 25)
        rangeLabel.Text = "Pickup Range: " .. tostring(cfg.autoPickupRange)
    end)

    -- hotkey hint
    local hint = Instance.new("TextLabel", frame)
    hint.Size = UDim2.new(1, -12, 0, 20)
    hint.Position = UDim2.new(0, 6, 0, 166)
    hint.BackgroundTransparency = 1
    hint.TextScaled = true
    hint.Text = ("Hotkeys: Toggle GUI [%s], ESP [%s], AutoPickup [%s], ServerHop [%s]")
                :format(tostring(cfg.hotkeys.toggleGui.Name),
                        tostring(cfg.hotkeys.toggleESP.Name),
                        tostring(cfg.hotkeys.toggleAutoPickup.Name),
                        tostring(cfg.hotkeys.toggleServerHop.Name))
    hint.TextXAlignment = Enum.TextXAlignment.Left

    -- expose update function for external calls
    getgenv().DFHelper.updateStatus = updateStatus
end

-- HOTKEYS (toggle GUI and quick toggles)
do
    local guiVisible = true
    createGUI()

    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == cfg.hotkeys.toggleGui then
            if guiRef then
                guiVisible = not guiVisible
                guiRef.Enabled = guiVisible
            end
        elseif input.KeyCode == cfg.hotkeys.toggleESP then
            cfg.espEnabled = not cfg.espEnabled
            if getgenv().DFHelper.updateStatus then getgenv().DFHelper.updateStatus() end
        elseif input.KeyCode == cfg.hotkeys.toggleAutoPickup then
            cfg.autoPickupEnabled = not cfg.autoPickupEnabled
            if getgenv().DFHelper.updateStatus then getgenv().DFHelper.updateStatus() end
        elseif input.KeyCode == cfg.hotkeys.toggleServerHop then
            cfg.serverHopEnabled = not cfg.serverHopEnabled
            if getgenv().DFHelper.updateStatus then getgenv().DFHelper.updateStatus() end
        end
    end)
end

-- CLEANUP
local function cleanup()
    for k,_ in pairs(createdEsp) do
        pcall(function() if createdEsp[k] and createdEsp[k].Parent then createdEsp[k]:Destroy() end end)
        createdEsp[k] = nil
    end
    if LocalPlayer.PlayerGui and LocalPlayer.PlayerGui:FindFirstChild("DFHelperGui") then
        pcall(function() LocalPlayer.PlayerGui.DFHelperGui:Destroy() end)
    end
end
getgenv().DFHelper.cleanup = cleanup
getgenv().DFHelper.config = cfg

-- MAIN LOOP
task.spawn(function()
    while task.wait(cfg.checkInterval) do
        local fruits = scanForFruits()
        if #fruits > 0 then lastFruitFoundTime = os.time() end

        -- ESP
        if cfg.espEnabled then
            local present = {}
            for _, f in ipairs(fruits) do
                present[f.model] = true
                if not createdEsp[f.model] then createESP(f.model) end
            end
            for obj,_ in pairs(createdEsp) do
                if not present[obj] then removeESP(obj) end
            end
        else
            for obj,_ in pairs(createdEsp) do removeESP(obj) end
        end

        -- Auto pickup
        if cfg.autoPickupEnabled and #fruits > 0 and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            table.sort(fruits, function(a,b)
                return (a.pos - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <
                       (b.pos - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            end)
            local nearest = fruits[1]
            if nearest and (nearest.pos - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude <= cfg.autoPickupRange then
                pcall(function() tryPickupFruit(nearest) end)
            end
        end

        -- Server hop if idle (no fruits)
        if cfg.serverHopEnabled and (os.time() - lastFruitFoundTime >= cfg.noFruitServerHopAfter) then
            lastFruitFoundTime = os.time()
            warn("[DFHelper] No fruits found for "..tostring(cfg.noFruitServerHopAfter).."s. Attempting server hop...")
            pcall(serverHop)
        end
    end
end)

print("[DFHelper] Loaded with improved menu. Use F1 to toggle GUI (configurable).")
