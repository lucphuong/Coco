-- 🔺 DEVIL HUB (FIXED + FULL Rayfield VERSION)
-- All toggles are single-click (auto deactivate logic included)
pcall(function()
    if not game:IsLoaded() then game.Loaded:Wait() end

    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local VirtualUser = game:GetService("VirtualUser")
    local LocalPlayer = Players.LocalPlayer
    local CoreGui = game:GetService("CoreGui")

    -- Cleanup old UI
    pcall(function() if CoreGui:FindFirstChild("DevilHub_UI") then CoreGui.DevilHub_UI:Destroy() end end)

    local handles, hooks = {}, {}

    local function tryCleanup(key)
        local h = handles[key]
        if not h then return end
        pcall(function()
            if typeof(h) == "RBXScriptConnection" then h:Disconnect()
            elseif typeof(h) == "Instance" and h.Destroy then h:Destroy()
            elseif type(h) == "function" then h() end
        end)
        handles[key] = nil
    end

    local function safeLoadFromUrl(key, url)
        local ok, res = pcall(function() return game:HttpGet(url, true) end)
        if not ok then warn("DevilHub Load Failed:", url) return end
        local ok2, ret = pcall(function() return loadstring(res)() end)
        if not ok2 then warn("DevilHub Exec Failed:", url) return end
        handles[key] = ret
    end

    -- Simple ESP
    local function startESP()
        if handles._ESP then return end
        local folder = Instance.new("Folder")
        folder.Name = "DevilHub_ESP"
        folder.Parent = CoreGui
        handles._ESP = folder

        local function add(plr)
            if plr == LocalPlayer then return end
            local function hl(char)
                if not char or char:FindFirstChild("DevilHubHighlight") then return end
                local h = Instance.new("Highlight")
                h.Name = "DevilHubHighlight"
                h.Adornee = char
                h.FillTransparency = 0.6
                h.OutlineTransparency = 0
                h.FillColor = Color3.fromRGB(255,50,50)
                h.Parent = folder
            end
            if plr.Character then hl(plr.Character) end
            plr.CharacterAdded:Connect(hl)
        end
        for _, p in pairs(Players:GetPlayers()) do add(p) end
        Players.PlayerAdded:Connect(add)
    end
    local function stopESP() tryCleanup("_ESP") end

    -- Hooks (features)
    hooks.Fly = function(e)
        if e then
            tryCleanup("Fly")
            local bv, bg = Instance.new("BodyVelocity"), Instance.new("BodyGyro")
            bv.MaxForce = Vector3.new(9e9,9e9,9e9)
            bg.MaxTorque = Vector3.new(9e9,9e9,9e9)
            local spd = 60
            local conn = RunService.Heartbeat:Connect(function()
                local c = LocalPlayer.Character
                if not c or not c:FindFirstChild("HumanoidRootPart") then return end
                local hrp, cam = c.HumanoidRootPart, workspace.CurrentCamera
                bv.Parent, bg.Parent = hrp, hrp
                bg.CFrame = cam.CFrame
                local v = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then v += cam.CFrame.LookVector * spd end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then v -= cam.CFrame.LookVector * spd end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then v -= cam.CFrame.RightVector * spd end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then v += cam.CFrame.RightVector * spd end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then v += Vector3.new(0,spd,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then v -= Vector3.new(0,spd,0) end
                bv.Velocity = v
            end)
            handles.Fly = function() conn:Disconnect() bv:Destroy() bg:Destroy() end
        else tryCleanup("Fly") end
    end

    hooks.Speed = function(e)
        if e then
            tryCleanup("Speed")
            local conn = RunService.Heartbeat:Connect(function()
                local c = LocalPlayer.Character
                if c and c:FindFirstChild("HumanoidRootPart") then
                    local hrp, cam = c.HumanoidRootPart, workspace.CurrentCamera
                    local d = Vector3.new()
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then d += cam.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then d -= cam.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then d -= cam.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then d += cam.CFrame.RightVector end
                    if d.Magnitude > 0 then
                        hrp.Velocity = Vector3.new(d.Unit.X*80, hrp.Velocity.Y, d.Unit.Z*80)
                    end
                end
            end)
            handles.Speed = conn
        else tryCleanup("Speed") end
    end

    hooks.InfJump = function(e)
        if e then
            tryCleanup("InfJump")
            handles.InfJump = UserInputService.JumpRequest:Connect(function()
                local c = LocalPlayer.Character
                if c and c:FindFirstChildOfClass("Humanoid") then
                    c:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
                end
            end)
        else tryCleanup("InfJump") end
    end

    hooks.XRay = function(e)
        if e then startESP() else stopESP() end
    end

    hooks.TeleportToMouse = function()
        pcall(function()
            local m = LocalPlayer:GetMouse()
            if LocalPlayer.Character and m and m.Hit then
                LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(m.Hit.p + Vector3.new(0,3,0))
            end
        end)
    end

    hooks.AntiAFK = function(e)
        if e then
            tryCleanup("AntiAFK")
            handles.AntiAFK = LocalPlayer.Idled:Connect(function()
                VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new())
            end)
        else tryCleanup("AntiAFK") end
    end

    hooks.TeleportGUI = function(e) if e then safeLoadFromUrl("TP","https://cdn.wearedevs.net/scripts/Click%20Teleport.txt") else tryCleanup("TP") end end
    hooks.TanHinh = function(e) if e then safeLoadFromUrl("Inv","https://abre.ai/invisible-v2") else tryCleanup("Inv") end end
    hooks.BatTu = function(e) workspace.FallenPartsDestroyHeight = e and 9e9 or -500 end
    hooks.Noclip = function(e)
        if e then
            tryCleanup("Noclip")
            handles.Noclip = RunService.Stepped:Connect(function()
                local c = LocalPlayer.Character
                if c then
                    for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end
                end
            end)
        else tryCleanup("Noclip") end
    end
    hooks.BeACar = function(e) if e then safeLoadFromUrl("Car","https://raw.githubusercontent.com/gumanba/Scripts/main/BeaCar") else tryCleanup("Car") end end
    hooks.Bang = function(e) if e then safeLoadFromUrl("Bang","https://raw.githubusercontent.com/4gh9/Bang-Script-Gui/main/bang%20gui.lua") else tryCleanup("Bang") end end
    hooks.JerkOff = function(e) if e then safeLoadFromUrl("Jerk","https://pastefy.app/lawnvcTT/raw") else tryCleanup("Jerk") end end
    hooks.AutoClick = function(e) if e then safeLoadFromUrl("AutoClick","https://raw.githubusercontent.com/Hosvile/The-telligence/main/MC%20KSystem%202") else tryCleanup("AutoClick") end end
    hooks.ESP = function(e) if e then startESP() else stopESP() end end
    hooks.KillAura = function(e) if e then safeLoadFromUrl("KA","https://pastebin.com/raw/0hn40Zbc") else tryCleanup("KA") end end
    hooks.Gun = function(e) if e then safeLoadFromUrl("Gun","https://pastebin.com/raw/0hn40Zbc") else tryCleanup("Gun") end end
    hooks.Sword = function(e) if e then safeLoadFromUrl("Sword","https://pastebin.com/raw/0hn40Zbc") else tryCleanup("Sword") end end
    hooks.Fighting = function(e) if e then safeLoadFromUrl("Fight","https://pastefy.app/cAQICuXo/raw") else tryCleanup("Fight") end end
    hooks.LaserGun = function(e) if e then safeLoadFromUrl("Laser","https://raw.githubusercontent.com/your-placeholder/laser/main/compiled.lua") else tryCleanup("Laser") end end
    hooks.Shader = function(e) if e then safeLoadFromUrl("Shader","https://raw.githubusercontent.com/p0e1/1/refs/heads/main/SimpleShader.lua") else tryCleanup("Shader") end end
    hooks.WallWalk = function(e) if e then safeLoadFromUrl("Wall","https://pastebin.com/raw/5T7KsEWy") else tryCleanup("Wall") end end
    hooks.LowLag = function(e) if e then safeLoadFromUrl("Lag","https://pastebin.com/raw/KiSYpej6") else tryCleanup("Lag") end end

    -- Rayfield Loader
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/shlexware/Rayfield/main/source.lua"))()
    end)
    if not ok then warn("Rayfield Load Fail") return end
    local Rayfield = lib

    -- UI
    local Window = Rayfield:CreateWindow({ Name = "🔺 DEVIL HUB", LoadingTitle = "Devil Hub", KeySystem = false })
    local Main = Window:CreateTab("🏠 Main")
    local LocalTab = Window:CreateTab("👤 Local")
    local Funny = Window:CreateTab("🎉 Funny")
    local Server = Window:CreateTab("🌐 Server")
    local Fight = Window:CreateTab("⚔️ Fight")

    -- MAIN TAB
    Main:CreateSection("Core")
    Main:CreateToggle({Name="Fly",Callback=hooks.Fly})
    Main:CreateToggle({Name="Speed",Callback=hooks.Speed})
    Main:CreateToggle({Name="Infinite Jump",Callback=hooks.InfJump})
    Main:CreateSection("Utilities")
    Main:CreateToggle({Name="X-Ray",Callback=hooks.XRay})
    Main:CreateButton({Name="Teleport To Mouse",Callback=hooks.TeleportToMouse})
    Main:CreateToggle({Name="Anti-AFK",Callback=hooks.AntiAFK})

    -- LOCAL TAB
    LocalTab:CreateSection("Player")
    LocalTab:CreateToggle({Name="Teleport GUI",Callback=hooks.TeleportGUI})
    LocalTab:CreateToggle({Name="Invisible",Callback=hooks.TanHinh})
    LocalTab:CreateToggle({Name="Bất Tử",Callback=hooks.BatTu})
    LocalTab:CreateToggle({Name="NoClip",Callback=hooks.Noclip})

    -- FUNNY TAB
    Funny:CreateSection("Fun Stuff")
    Funny:CreateToggle({Name="Be A Car",Callback=hooks.BeACar})
    Funny:CreateToggle({Name="Bang",Callback=hooks.Bang})
    Funny:CreateToggle({Name="Jerk Off",Callback=hooks.JerkOff})
    Funny:CreateToggle({Name="Shader",Callback=hooks.Shader})
    Funny:CreateToggle({Name="Auto Click",Callback=hooks.AutoClick})

    -- SERVER TAB
    Server:CreateSection("Server Tools")
    Server:CreateToggle({Name="ESP",Callback=hooks.ESP})
    Server:CreateToggle({Name="Wall Walk",Callback=hooks.WallWalk})
    Server:CreateToggle({Name="Low Lag",Callback=hooks.LowLag})

    -- FIGHT TAB
    Fight:CreateSection("Combat")
    Fight:CreateToggle({Name="Kill Aura",Callback=hooks.KillAura})
    Fight:CreateToggle({Name="Sword",Callback=hooks.Sword})
    Fight:CreateToggle({Name="Gun",Callback=hooks.Gun})
    Fight:CreateToggle({Name="Laser Gun",Callback=hooks.LaserGun})
    Fight:CreateButton({Name="Load Fighting Script",Callback=function() hooks.Fighting(true) Rayfield:Notify({Title="Loaded",Content="Fighting Script Loaded",Duration=3}) end})

    Rayfield:Notify({Title="✅ DEVIL HUB",Content="Loaded Successfully",Duration=5})
end)
