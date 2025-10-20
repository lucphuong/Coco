-- DEVIL HUB — Custom GUI (POLARIA style) — Full pcall/syn wrappers, draggable, right-side toggle
-- Tabs: Main | Local Player | Funny | Server | Fight
-- Buttons act as toggles (1-click to enable, click again to disable). All loading/cleanup wrapped in pcall.
-- Place this whole script into an executor and run. The script will attempt to protect GUI with syn if available.

pcall(function()
    if not game:IsLoaded() then game.Loaded:Wait() end

    -- Services
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local VirtualUser = game:GetService("VirtualUser")
    local LocalPlayer = Players.LocalPlayer
    local CoreGui = game:GetService("CoreGui")

    -- Utility: safe httpget + loadstring
    local function safeHttpGet(url)
        if not url or url == "" then return nil, "no url" end
        local ok, res = pcall(function()
            -- prefer syn.request if available for headers, else game:HttpGet
            if syn and syn.request then
                local r = syn.request({Url = url, Method = "GET"})
                return r.Body
            else
                return game:HttpGet(url, true)
            end
        end)
        if not ok then return nil, res end
        return res, nil
    end

    local function safeLoadFromUrl(key, url)
        if not url then return false, "no url" end
        local src, err = safeHttpGet(url)
        if not src then return false, err end
        local ok, res = pcall(function()
            local f, e = loadstring(src)
            if not f then error(e or "loadstring error") end
            return f()
        end)
        return ok, res
    end

    -- Handles table for cleanup
    local handles = {}
    local function tryCleanup(key)
        local h = handles[key]
        if not h then return end
        pcall(function()
            if type(h) == "function" then
                -- if stored function, call to cleanup
                pcall(h)
            elseif typeof(h) == "RBXScriptConnection" then
                h:Disconnect()
            elseif typeof(h) == "Instance" and h.Destroy then
                h:Destroy()
            elseif type(h) == "table" and h.disconnect then
                pcall(h.disconnect, h)
            end
        end)
        handles[key] = nil
    end

    -- Inline simple features (no external load) where possible
    local function startESP()
        if handles._ESP then return end
        local folder = Instance.new("Folder")
        folder.Name = "DevilHub_ESP"
        if syn and syn.protect_gui then pcall(syn.protect_gui, folder) end
        folder.Parent = CoreGui
        handles._ESP = folder

        local function apply(plr)
            if plr == LocalPlayer then return end
            local function add(c)
                pcall(function()
                    if not c or c:FindFirstChild("DevilHubHighlight") then return end
                    local hl = Instance.new("Highlight")
                    hl.Name = "DevilHubHighlight"
                    hl.Adornee = c
                    hl.FillTransparency = 0.6
                    hl.OutlineTransparency = 0
                    hl.FillColor = (plr.Team == LocalPlayer.Team) and Color3.fromRGB(0, 120, 255) or Color3.fromRGB(255, 60, 60)
                    hl.Parent = folder
                end)
            end
            if plr.Character then add(plr.Character) end
            plr.CharacterAdded:Connect(add)
        end

        for _, p in pairs(Players:GetPlayers()) do apply(p) end
        Players.PlayerAdded:Connect(apply)
    end

    local function stopESP()
        tryCleanup("_ESP")
    end

    -- Small helper to make a toggleable feature button: calls hooks[name](bool) and keeps internal state
    local states = {}
    local hooks = {}

    local function makeToggleAction(name, fn)
        hooks[name] = fn
    end

    local function toggleFeature(name, newState)
        states[name] = newState
        local ok, err = pcall(function() hooks[name](newState) end)
        return ok, err
    end

    -- Implement inline hooks and wrappers for user-provided URLs
    -- Movement & utilities
    makeToggleAction("Fly", function(enable)
        if enable then
            -- create BodyVelocity + BodyGyro controlled by heartbeat
            tryCleanup("Fly")
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(9e9, 9e9, 9e9)
            bv.Velocity = Vector3.new()
            local bg = Instance.new("BodyGyro")
            bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
            bg.P = 2500
            local speed = 60
            local conn = RunService.Heartbeat:Connect(function()
                local char = LocalPlayer.Character
                if not char or not char:FindFirstChild("HumanoidRootPart") then return end
                local hrp = char.HumanoidRootPart
                if not bv.Parent then bv.Parent = hrp end
                if not bg.Parent then bg.Parent = hrp end
                local cam = workspace.CurrentCamera
                bg.CFrame = cam.CFrame
                local vel = Vector3.new()
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + cam.CFrame.LookVector * speed end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - cam.CFrame.LookVector * speed end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - cam.CFrame.RightVector * speed end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + cam.CFrame.RightVector * speed end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.new(0, speed, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel - Vector3.new(0, speed, 0) end
                bv.Velocity = vel
            end)
            handles.Fly = function()
                pcall(function() conn:Disconnect() end)
                pcall(function() bv:Destroy() end)
                pcall(function() bg:Destroy() end)
            end
        else
            tryCleanup("Fly")
        end
    end)

    makeToggleAction("Speed", function(enable)
        if enable then
            tryCleanup("Speed")
            local conn = RunService.Heartbeat:Connect(function()
                local char = LocalPlayer.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    local hrp = char.HumanoidRootPart
                    local cam = workspace.CurrentCamera
                    local dir = Vector3.new()
                    local speed = 80
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
                    if dir.Magnitude > 0 then
                        dir = dir.Unit
                        hrp.Velocity = Vector3.new(dir.X * speed, hrp.Velocity.Y, dir.Z * speed)
                    end
                end
            end)
            handles.Speed = conn
        else
            tryCleanup("Speed")
        end
    end)

    makeToggleAction("InfJump", function(enable)
        if enable then
            tryCleanup("InfJump")
            local conn = UserInputService.JumpRequest:Connect(function()
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end) end
                end
            end)
            handles.InfJump = conn
        else
            tryCleanup("InfJump")
        end
    end)

    -- AntiAFK
    makeToggleAction("AntiAFK", function(enable)
        if enable then
            tryCleanup("AntiAFK")
            local conn = LocalPlayer.Idled:Connect(function()
                pcall(function()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton2(Vector2.new(0,0))
                end)
            end)
            handles.AntiAFK = conn
        else
            tryCleanup("AntiAFK")
        end
    end)

    -- NoClip
    makeToggleAction("Noclip", function(enable)
        if enable then
            tryCleanup("Noclip")
            local conn = RunService.Stepped:Connect(function()
                local char = LocalPlayer.Character
                if char then
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end)
            handles.Noclip = conn
        else
            tryCleanup("Noclip")
        end
    end)

    -- BatTu (prevent falling death)
    makeToggleAction("BatTu", function(enable)
        if enable then
            handles._oldFall = workspace.FallenPartsDestroyHeight
            workspace.FallenPartsDestroyHeight = 9e9
        else
            if handles._oldFall ~= nil then
                workspace.FallenPartsDestroyHeight = handles._oldFall
                handles._oldFall = nil
            else
                workspace.FallenPartsDestroyHeight = -500
            end
        end
    end)

    -- TanHinh (invisibility) — simple transparency
    makeToggleAction("TanHinh", function(enable)
        if enable then
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") or part:IsA("Decal") then
                        if not handles._TanHinhStore then handles._TanHinhStore = {} end
                        if part:IsA("BasePart") then
                            handles._TanHinhStore[part] = part.Transparency
                            part.Transparency = 1
                        elseif part:IsA("Decal") then
                            handles._TanHinhStore[part] = part.Transparency
                            part.Transparency = 1
                        end
                    end
                end
            end
        else
            if handles._TanHinhStore then
                for part, old in pairs(handles._TanHinhStore) do
                    pcall(function() part.Transparency = old end)
                end
                handles._TanHinhStore = nil
            end
        end
    end)

    -- WallWalk (load external)
    makeToggleAction("WallWalk", function(enable)
        if enable then
            safeLoadFromUrl("WallWalk", "https://pastebin.com/raw/5T7KsEWy")
        else
            tryCleanup("WallWalk")
        end
    end)

    -- LowLag (external)
    makeToggleAction("LowLag", function(enable)
        if enable then
            safeLoadFromUrl("LowLag", "https://pastebin.com/raw/KiSYpej6")
        else
            tryCleanup("LowLag")
        end
    end)

    -- FeFlip (external)
    makeToggleAction("FeFlip", function(enable)
        if enable then
            safeLoadFromUrl("FeFlip", "https://pastebin.com/raw/abcd1234") -- replace with actual feFlip raw
        else
            tryCleanup("FeFlip")
        end
    end)

    -- ESP/XRay wrappers
    makeToggleAction("ESP", function(enable)
        if enable then startESP() else stopESP() end
    end)

    makeToggleAction("XRay", function(enable)
        if enable then
            startESP()
            -- make outlines stronger
            if handles._ESP then
                for _, v in pairs(handles._ESP:GetChildren()) do
                    if v:IsA("Highlight") then
                        v.FillTransparency = 1
                        v.OutlineTransparency = 0
                        v.OutlineColor = Color3.new(1, 0, 0)
                    end
                end
            end
        else
            stopESP()
        end
    end)

    -- External load wrappers for combat/vehicles/etc (pcall safe)
    local extMap = {
        TeleportGUI = "https://cdn.wearedevs.net/scripts/Click%20Teleport.txt",
        Shader = "https://raw.githubusercontent.com/p0e1/1/refs/heads/main/SimpleShader.lua",
        KillAura = "https://pastebin.com/raw/0hn40Zbc",
        Fighting = "https://pastefy.app/cAQICuXo/raw",
        BeACar = "https://raw.githubusercontent.com/gumanba/Scripts/main/BeaCar",
        Bang = "https://raw.githubusercontent.com/4gh9/Bang-Script-Gui/main/bang%20gui.lua",
        JerkOff = "https://pastefy.app/lawnvcTT/raw",
        AutoClick = "https://raw.githubusercontent.com/Hosvile/The-telligence/main/MC%20KSystem%202",
        LaserGun = "https://raw.githubusercontent.com/lucphuong/1x1x1x1x1/refs/heads/main/Lasergun.lua?token=GHSAT0AAAAAADMAEXZDBRUBA3FMM4YW3XAC2HVZGUA",
        Gun = "https://pastebin.com/raw/0hn40Zbc",
        Sword = "https://pastebin.com/raw/0hn40Zbc"
    }

    for k, v in pairs(extMap) do
        makeToggleAction(k, function(enable)
            if enable then
                local ok, res = safeLoadFromUrl(k, v)
                if not ok then
                    warn("DevilHub: failed to load", k, "->", res)
                end
            else
                tryCleanup(k)
            end
        end)
    end

    -- Teleport to mouse (one-shot button)
    hooks.TeleportToMouse = function()
        pcall(function()
            local mouse = LocalPlayer:GetMouse()
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") and mouse and mouse.Hit then
                char.HumanoidRootPart.CFrame = CFrame.new(mouse.Hit.p + Vector3.new(0, 3, 0))
            end
        end)
    end

    -- GUI builder helpers
    local function uiNew(class, props)
        local obj = Instance.new(class)
        if type(props) == "table" then
            for k, v in pairs(props) do
                pcall(function() obj[k] = v end)
            end
        end
        return obj
    end

    -- Remove old GUI if exists
    if CoreGui:FindFirstChild("DevilHub_UI") then
        pcall(function() CoreGui.DevilHub_UI:Destroy() end)
    end

    -- Root ScreenGui
    local SG = uiNew("ScreenGui", {Name = "DevilHub_UI", ResetOnSpawn = false})
    if syn and syn.protect_gui then pcall(syn.protect_gui, SG) end
    SG.Parent = CoreGui

    -- Theme colors
    local bgColor = Color3.fromRGB(20, 20, 20)
    local panelColor = Color3.fromRGB(25, 12, 35)
    local accent = Color3.fromRGB(170, 80, 255)
    local textColor = Color3.fromRGB(240, 240, 240)

    -- Right-side toggle button (Show/Hide)
    local toggleBtn = uiNew("TextButton", {
        Name = "Devil_ShowBtn",
        Parent = SG,
        Size = UDim2.new(0, 36, 0, 120),
        Position = UDim2.new(1, -40, 0.5, -60),
        BackgroundColor3 = accent,
        AutoButtonColor = true,
        Text = "DE\nVIL",
        TextWrapped = true,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextColor3 = Color3.new(1,1,1),
        BorderSizePixel = 0,
        ZIndex = 10
    })

    -- Main window
    local winW, winH = 540, 360
    local win = uiNew("Frame", {
        Name = "Devil_Window",
        Parent = SG,
        Size = UDim2.new(0, winW, 0, winH),
        Position = UDim2.new(1, -winW - 46, 0.5, -winH/2),
        BackgroundColor3 = bgColor,
        BorderSizePixel = 0
    })

    local uistroke = uiNew("UIStroke", {Parent = win, Color = accent, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
    local titleBar = uiNew("Frame", {Parent = win, Size = UDim2.new(1,0,0,40), BackgroundColor3 = panelColor})
    uiNew("UIStroke", {Parent = titleBar, Color = accent, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border})
    local titleLabel = uiNew("TextLabel", {
        Parent = titleBar, Size = UDim2.new(0.6, -10, 1, 0), Position = UDim2.new(0, 8, 0, 0),
        BackgroundTransparency = 1, Text = "DEVIL HUB", Font = Enum.Font.GothamBold, TextSize = 20, TextColor3 = textColor, TextXAlignment = Enum.TextXAlignment.Left
    })
    local subLabel = uiNew("TextLabel", {
        Parent = titleBar, Size = UDim2.new(0.4, -8, 1, 0), Position = UDim2.new(0.6, 8, 0, 0),
        BackgroundTransparency = 1, Text = "Full | Custom GUI", Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = textColor, TextXAlignment = Enum.TextXAlignment.Right
    })

    -- Tabs row
    local tabsFrame = uiNew("Frame", {Parent = win, Size = UDim2.new(1, -12, 0, 36), Position = UDim2.new(0,6,0,46), BackgroundTransparency = 1})
    local tabNames = {"Main","Local Player","Funny","Server","Fight"}
    local tabs = {}
    local contentFrame = uiNew("Frame", {Parent = win, Size = UDim2.new(1, -12, 1, -108), Position = UDim2.new(0,6,0,86), BackgroundColor3 = Color3.fromRGB(15,15,15)})
    uiNew("UIStroke", {Parent = contentFrame, Color = Color3.fromRGB(40,40,40), Thickness = 1})

    -- create tab buttons
    do
        local btnW = (winW - 20) / #tabNames
        for i, name in ipairs(tabNames) do
            local b = uiNew("TextButton", {
                Parent = tabsFrame,
                Size = UDim2.new(0, btnW - 6, 0, 30),
                Position = UDim2.new(0, (i-1)*(btnW), 0, 0),
                BackgroundColor3 = Color3.fromRGB(18,18,18),
                Text = name,
                Font = Enum.Font.GothamBold,
                TextSize = 14,
                TextColor3 = textColor,
                BorderSizePixel = 0,
            })
            uiNew("UIStroke", {Parent = b, Color = Color3.fromRGB(60,10,120), Thickness = 2})
            tabs[name] = b
        end
    end

    -- Create a grid creator utility to layout many buttons like the screenshot (4 columns)
    local function makeGrid(parent)
        local canvas = uiNew("Frame", {Parent = parent, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1})
        local layout = uiNew("UIGridLayout", {Parent = canvas})
        layout.CellSize = UDim2.new(0, math.floor((winW - 60)/4), 0, 36)
        layout.CellPadding = UDim2.new(0,8,0,8)
        layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        return canvas, layout
    end

    -- Create content pages
    local pages = {}
    for _, name in ipairs(tabNames) do
        local p = uiNew("Frame", {Parent = contentFrame, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Visible = false})
        pages[name] = p
    end
    pages["Main"].Visible = true
    tabs["Main"].BackgroundColor3 = Color3.fromRGB(30,30,30)

    -- Tab switching
    for name, btn in pairs(tabs) do
        btn.MouseButton1Click:Connect(function()
            for n, p in pairs(pages) do p.Visible = false end
            for _, b in pairs(tabs) do b.BackgroundColor3 = Color3.fromRGB(18,18,18) end
            pages[name].Visible = true
            btn.BackgroundColor3 = Color3.fromRGB(30,30,30)
        end)
    end

    -- Build grids and populate buttons for each page
    -- Helper for creating action buttons
    local function createActionButton(parent, label, key)
        local btn = uiNew("TextButton", {
            Parent = parent,
            Text = label .. " [OFF]",
            Font = Enum.Font.GothamBold,
            TextSize = 14,
            TextColor3 = textColor,
            BackgroundColor3 = Color3.fromRGB(90,10,10),
            AutoButtonColor = true,
            BorderSizePixel = 0
        })
        uiNew("UIStroke", {Parent = btn, Color = Color3.fromRGB(120,20,200), Thickness = 1})
        btn.MouseButton1Click:Connect(function()
            local newState = not states[key]
            local ok, err = pcall(function() toggleFeature(key, newState) end)
            if not ok then
                warn("DevilHub: feature error for", key, err)
            end
            states[key] = newState
            if states[key] then
                btn.BackgroundColor3 = Color3.fromRGB(20,120,20)
                btn.Text = label .. " [ON]"
            else
                btn.BackgroundColor3 = Color3.fromRGB(90,10,10)
                btn.Text = label .. " [OFF]"
            end
        end)
        return btn
    end

    -- MAIN page
    do
        local grid, layout = makeGrid(pages["Main"])
        createActionButton(grid, "✈️ Fly", "Fly")
        createActionButton(grid, "⚡ Speed", "Speed")
        createActionButton(grid, "🦘 Infinite Jump", "InfJump")
        createActionButton(grid, "👁️ X-Ray (Highlights)", "XRay")
        -- Teleport to mouse button (one-shot)
        local tpBtn = uiNew("TextButton", {
            Parent = grid, Text = "📍 Teleport To Mouse", Font = Enum.Font.GothamBold, TextSize = 14,
            TextColor3 = textColor, BackgroundColor3 = Color3.fromRGB(70,70,70), BorderSizePixel = 0
        })
        uiNew("UIStroke", {Parent = tpBtn, Color = Color3.fromRGB(120,20,200), Thickness = 1})
        tpBtn.MouseButton1Click:Connect(function()
            pcall(function() hooks.TeleportToMouse() end)
            tpBtn.BackgroundColor3 = Color3.fromRGB(20,120,20)
            tpBtn.Text = "📍 Teleported"
            wait(0.6)
            tpBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
            tpBtn.Text = "📍 Teleport To Mouse"
        end)
        createActionButton(grid, "🛡️ Anti-AFK", "AntiAFK")
    end

    -- LOCAL PLAYER page
    do
        local grid = makeGrid(pages["Local Player"])
        createActionButton(grid, "🔫 Teleport GUI (Click TP)", "TeleportGUI")
        createActionButton(grid, "👻 Invisible (Tàng Hình)", "TanHinh")
        createActionButton(grid, "🪄 Bất Tử (Fall prevention)", "BatTu")
        createActionButton(grid, "🔧 NoClip", "Noclip")
    end

    -- FUNNY page
    do
        local grid = makeGrid(pages["Funny"])
        createActionButton(grid, "🚗 Be A Car", "BeACar")
        createActionButton(grid, "💥 Bang Script", "Bang")
        createActionButton(grid, "🍆 Jerk Off", "JerkOff")
        createActionButton(grid, "🎭 FeFlip (Roll)", "FeFlip")
        createActionButton(grid, "🧰 Shader Effects", "Shader")
    end

    -- SERVER page
    do
        local grid = makeGrid(pages["Server"])
        createActionButton(grid, "👁️ ESP (Highlight Players)", "ESP")
        createActionButton(grid, "🧭 Wall Walk", "WallWalk")
        createActionButton(grid, "🧹 Low Lag", "LowLag")
        createActionButton(grid, "🤖 Auto Click (KSystem)", "AutoClick")
    end

    -- FIGHT page
    do
        local grid = makeGrid(pages["Fight"])
        createActionButton(grid, "⚔️ Kill Aura", "KillAura")
        createActionButton(grid, "🗡️ Sword (Local)", "Sword")
        createActionButton(grid, "🔫 Gun (load)", "Gun")
        createActionButton(grid, "🔫 Laser Gun (build)", "LaserGun")
        -- Fighting load button (one-shot)
        local fightBtn = uiNew("TextButton", {
            Parent = grid, Text = "🥊 Load Fighting Script", Font = Enum.Font.GothamBold, TextSize = 14,
            TextColor3 = textColor, BackgroundColor3 = Color3.fromRGB(70,70,70), BorderSizePixel = 0
        })
        uiNew("UIStroke", {Parent = fightBtn, Color = Color3.fromRGB(120,20,200), Thickness = 1})
        fightBtn.MouseButton1Click:Connect(function()
            local ok, err = pcall(function() hooks.Fighting(true) end)
            if not ok then warn("DevilHub fight load error", err) end
            fightBtn.BackgroundColor3 = Color3.fromRGB(20,120,20)
            fightBtn.Text = "🥊 Loaded"
            wait(0.7)
            fightBtn.BackgroundColor3 = Color3.fromRGB(70,70,70)
            fightBtn.Text = "🥊 Load Fighting Script"
        end)
    end

    -- Draggable window (by titleBar)
    do
        local dragging, dragStart, startPos = false, Vector2.new(), UDim2.new()
        titleBar.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = win.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)
    end

    -- Show/hide logic
    local visible = true
    toggleBtn.MouseButton1Click:Connect(function()
        visible = not visible
        win.Visible = visible
        toggleBtn.BackgroundColor3 = visible and accent or Color3.fromRGB(60,60,60)
    end)

    -- Small footer: close all on destroy
    local closeAll = uiNew("TextButton", {
        Parent = titleBar, Size = UDim2.new(0, 60, 0, 24), Position = UDim2.new(1, -68, 0, 8),
        Text = "CLOSE", Font = Enum.Font.GothamBold, TextSize = 12, TextColor3 = textColor, BackgroundColor3 = Color3.fromRGB(40,10,40), BorderSizePixel = 0
    })
    uiNew("UIStroke", {Parent = closeAll, Color = Color3.fromRGB(120,20,200), Thickness = 1})
    closeAll.MouseButton1Click:Connect(function()
        -- cleanup handles
        for k,_ in pairs(handles) do tryCleanup(k) end
        pcall(function() SG:Destroy() end)
    end)

    -- Initial notification (small on-screen text)
    local function notify(msg, t)
        local lab = uiNew("TextLabel", {
            Parent = SG, Size = UDim2.new(0, 220, 0, 28), Position = UDim2.new(1, -280, 0.9, 0),
            BackgroundColor3 = Color3.fromRGB(30,30,30), Text = msg, TextColor3 = textColor,
            Font = Enum.Font.GothamBold, TextSize = 14, BorderSizePixel = 0
        })
        uiNew("UIStroke", {Parent = lab, Color = accent, Thickness = 1})
        delay(t or 3, function() pcall(function() lab:Destroy() end) end)
    end

    notify("DEVIL HUB loaded — custom GUI", 4)
    print("✅ DEVIL HUB (custom) initialized")
end)
```0
