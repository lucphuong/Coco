-- Simple Devil Fruit Helper (ESP + Auto Pickup + Server Hop)
-- Author: assistant (example)
-- NOTE: Use at your own risk. Test on alt account.

-- ========== CONFIG ==========
getgenv().DFHelper = getgenv().DFHelper or {}
local cfg = getgenv().DFHelper

cfg.fruitNamePatterns = cfg.fruitNamePatterns or { "Fruit", "DevilFruit", "Devil" } -- patterns to search in object.Name
cfg.autoPickupRange = cfg.autoPickupRange or 300           -- max distance to try pick up (studs)
cfg.pickupMoveSpeed = cfg.pickupMoveSpeed or 80            -- walkspeed while moving to fruit (restore after)
cfg.checkInterval = cfg.checkInterval or 1.0              -- how often to scan for fruits (seconds)
cfg.noFruitServerHopAfter = cfg.noFruitServerHopAfter or 40 -- seconds with no fruits before server hop
-- ============================

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")

-- Safe guards
if not LocalPlayer then
    warn("[DFHelper] LocalPlayer not found. Run this as a LocalScript / executor in-game.")
    return
end

-- State toggles
cfg.espEnabled = cfg.espEnabled or false
cfg.autoPickupEnabled = cfg.autoPickupEnabled or false
cfg.serverHopEnabled = cfg.serverHopEnabled or true

-- Keep track
local createdEsp = {} -- model -> BillboardGui
local lastFruitFoundTime = os.time()

-- Utility: pattern match for fruit name
local function isFruitModel(obj)
    if not obj or not obj.Name then return false end
    local nm = tostring(obj.Name)
    for _, pat in ipairs(cfg.fruitNamePatterns) do
        if string.find(string.lower(nm), string.lower(pat)) then
            return true
        end
    end
    return false
end

-- Create simple BillboardGui ESP on a Model or Part
local function createESP(target)
    if not target or not target.Parent then return end
    if createdEsp[target] then return end

    local primary = nil
    if target:IsA("Model") then
        primary = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")
    elseif target:IsA("BasePart") then
        primary = target
    else
        primary = target:FindFirstChildWhichIsA("BasePart")
    end
    if not primary then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DFHelper_ESP"
    billboard.Adornee = primary
    billboard.AlwaysOnTop = true
    billboard.Size = UDim2.new(0, 120, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 1.4, 0)
    billboard.Parent = primary

    local frame = Instance.new("Frame", billboard)
    frame.BackgroundTransparency = 0.4
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BorderSizePixel = 0

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -4, 1, -4)
    label.Position = UDim2.new(0, 2, 0, 2)
    label.BackgroundTransparency = 1
    label.Text = "Devil Fruit"
    label.TextScaled = true
    label.TextWrapped = false
    label.Font = Enum.Font.SourceSansBold
    label.TextStrokeTransparency = 0.6

    createdEsp[target] = billboard
end

local function removeESP(target)
    if not target then return end
    local g = createdEsp[target]
    if g and g.Parent then
        pcall(function() g:Destroy() end)
    end
    createdEsp[target] = nil
end

-- Scan workspace for fruits (returns table of models/parts)
local function scanForFruits()
    local res = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj and obj.Parent then
            -- Heuristics: a Model whose name contains "Fruit", or a Part named "Fruit"
            if isFruitModel(obj) then
                -- ensure there's a primary part to go to
                local primary
                if obj:IsA("Model") then
                    primary = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")
                elseif obj:IsA("BasePart") then
                    primary = obj
                end
                if primary and primary.Position then
                    table.insert(res, {model = obj, part = primary, pos = primary.Position})
                end
            end
        end
    end
    return res
end

-- Move player to fruit (naive method: set HumanoidRootPart CFrame near fruit)
local function tryPickupFruit(fruitEntry)
    if not fruitEntry or not fruitEntry.part then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not humanoid then return false end

    local originalWalkSpeed = humanoid.WalkSpeed
    -- Move near the fruit and touch
    pcall(function() humanoid.WalkSpeed = cfg.pickupMoveSpeed end)
    local targetPos = fruitEntry.pos
    local safeOffset = Vector3.new(0, 2, 0)
    -- Teleport/Move in small steps (less suspicious than instant teleport)
    local steps = 10
    for i = 1, steps do
        if not cfg.autoPickupEnabled then break end
        local alpha = i / steps
        local newPos = hrp.Position:Lerp(targetPos + safeOffset, alpha)
        pcall(function() hrp.CFrame = CFrame.new(newPos) end)
        task.wait(0.06)
    end
    -- final push
    pcall(function() hrp.CFrame = CFrame.new(targetPos + safeOffset) end)
    task.wait(0.25)

    -- restore speed
    pcall(function() humanoid.WalkSpeed = originalWalkSpeed end)
    return true
end

-- Server hop: tries to get list of public servers and teleport to one that's not current.
local function serverHop()
    -- This method uses Roblox public API, may fail due to rate limits or HttpService restrictions.
    local placeId = tostring(game.PlaceId)
    local success, body = pcall(function()
        return HttpService:GetAsync("https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?sortOrder=Asc&limit=100")
    end)
    if not success or not body then
        warn("[DFHelper] serverHop: couldn't get server list.")
        return
    end

    local ok, data = pcall(function() return HttpService:JSONDecode(body) end)
    if not ok or not data or not data.data then
        warn("[DFHelper] serverHop: invalid server data.")
        return
    end

    for _, server in ipairs(data.data) do
        local id = server.id or server.id -- some fields differ
        local maxPlayers = server.maxPlayers or server.maxPlayers
        local playing = server.playing or server.playing
        if id and tonumber(playing) < tonumber(maxPlayers) and id ~= tostring(game.JobId) then
            -- Teleport to this server
            pcall(function()
                TeleportService:TeleportToPlaceInstance(game.PlaceId, id, LocalPlayer)
            end)
            return
        end
    end
    warn("[DFHelper] serverHop: no suitable server found in list.")
end

-- GUI (very simple)
local function createGUI()
    if LocalPlayer.PlayerGui:FindFirstChild("DFHelperGui") then
        LocalPlayer.PlayerGui:FindFirstChild("DFHelperGui"):Destroy()
    end

    local screen = Instance.new("ScreenGui")
    screen.Name = "DFHelperGui"
    screen.ResetOnSpawn = false
    screen.Parent = LocalPlayer:WaitForChild("PlayerGui")

    local frame = Instance.new("Frame", screen)
    frame.Size = UDim2.new(0, 220, 0, 120)
    frame.Position = UDim2.new(0, 10, 0, 50)
    frame.BackgroundTransparency = 0.25
    frame.Active = true
    frame.Draggable = true

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1, 0, 0, 24)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.Text = "DF Helper"
    title.TextScaled = true
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.SourceSansBold

    local function makeButton(name, ypos, initial, callback)
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0, 200, 0, 28)
        btn.Position = UDim2.new(0, 10, 0, ypos)
        btn.Text = name .. ": " .. (initial and "ON" or "OFF")
        btn.TextScaled = true
        btn.BackgroundTransparency = 0.15

        btn.MouseButton1Click:Connect(function()
            callback(not initial)
            initial = not initial
            btn.Text = name .. ": " .. (initial and "ON" or "OFF")
        end)
        return btn
    end

    -- ESP button
    makeButton("ESP Fruits", 30, cfg.espEnabled, function(v) cfg.espEnabled = v end)
    -- Auto pickup
    makeButton("Auto Pickup", 64, cfg.autoPickupEnabled, function(v) cfg.autoPickupEnabled = v end)
    -- Server hop toggle
    makeButton("ServerHop", 98, cfg.serverHopEnabled, function(v) cfg.serverHopEnabled = v end)
end

-- Start GUI
createGUI()

-- Main loop: scanning, ESP management, auto pickup
spawn(function()
    while true do
        local fruits = scanForFruits()
        if #fruits > 0 then
            lastFruitFoundTime = os.time()
        end

        -- ESP handling
        if cfg.espEnabled then
            -- create ESP for found fruits
            local existingTargets = {}
            for _, fe in ipairs(fruits) do
                existingTargets[fe.model] = true
                if not createdEsp[fe.model] then
                    createESP(fe.model)
                end
            end
            -- remove ESP for disappeared fruits
            for k, _ in pairs(createdEsp) do
                if not existingTargets[k] then
                    removeESP(k)
                end
            end
        else
            -- remove all ESPs if disabled
            for k, _ in pairs(createdEsp) do removeESP(k) end
        end

        -- Auto pickup: go to the nearest fruit within range
        if cfg.autoPickupEnabled and #fruits > 0 then
            -- sort by distance
            table.sort(fruits, function(a,b)
                local lp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if not lp then return false end
                return (a.pos - lp.Position).Magnitude < (b.pos - lp.Position).Magnitude
            end)
            local nearest = fruits[1]
            if nearest then
                local lp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if lp and (nearest.pos - lp.Position).Magnitude <= cfg.autoPickupRange then
                    pcall(function() tryPickupFruit(nearest) end)
                end
            end
        end

        -- Server hop if enabled and no fruits for a while
        if cfg.serverHopEnabled then
            if os.time() - lastFruitFoundTime >= cfg.noFruitServerHopAfter then
                warn("[DFHelper] No fruits found for " .. tostring(cfg.noFruitServerHopAfter) .. "s - attempting server hop.")
                -- reset timer to avoid spamming
                lastFruitFoundTime = os.time()
                pcall(serverHop)
            end
        end

        task.wait(cfg.checkInterval)
    end
end)

-- Cleanup on unload (optional)
local function cleanup()
    for k, _ in pairs(createdEsp) do removeESP(k) end
    if LocalPlayer and LocalPlayer.PlayerGui and LocalPlayer.PlayerGui:FindFirstChild("DFHelperGui") then
        LocalPlayer.PlayerGui:FindFirstChild("DFHelperGui"):Destroy()
    end
end

-- Expose cleaning and config in getgenv for manual control
getgenv().DFHelper.cleanup = cleanup
getgenv().DFHelper.config = cfg

print("[DFHelper] Loaded. Use GUI to toggle features. cfg available at getgenv().DFHelper.config")
