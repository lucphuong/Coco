--[[ DFHelper Encoded Lite ]]
local L0=loadstring;local E0=getgenv and getgenv() or _G
E0.DFH=E0.DFH or {}
local C=E0.DFH
C.rng=C.rng or 250
C.hop=C.hop or 60
C.chk=C.chk or 2
C.spd=C.spd or 120
C.esp=C.esp or false
C.aut=C.aut or false
C.svhop=C.svhop or true
C.st=C.st or true
C.keys=C.keys or {
    gui=Enum.KeyCode.F1,
    esp=Enum.KeyCode.F2,
    au=Enum.KeyCode.F3,
    sh=Enum.KeyCode.F4
}

local S=game:GetService;local P=S("Players")
local LP=P.LocalPlayer
local RS=S("RunService")
local TS=S("TeleportService")
local HS=S("HttpService")
local UI=S("UserInputService")
local TW=S("TweenService")

local esps,noti,last=os.time(),{},os.time()
local guiRef

-- tiny util
local function call(f,...)local ok,r=pcall(f,...)return ok,r end
local function fruitFld()return workspace:FindFirstChild("Fruit")or workspace:FindFirstChild("Fruits")or workspace:FindFirstChild("DevilFruit")end

-- 🍏 ESP
local function mkESP(o)
 if esps[o]then return end
 local p=o:IsA("Model")and(o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart"))or o
 if not p then return end
 local b=Instance.new("BillboardGui")b.Name="DFe"
 b.Adornee=p b.Size=UDim2.new(0,120,0,36)b.AlwaysOnTop=true b.StudsOffset=Vector3.new(0,1.6,0)b.Parent=p
 local f=Instance.new("Frame",b)f.Size=UDim2.new(1,0,1,0)f.BackgroundTransparency=0.45
 local l=Instance.new("TextLabel",f)l.Size=UDim2.new(1,-4,1,-4)l.Position=UDim2.new(0,2,0,2)
 l.BackgroundTransparency=1 l.Text="🍏Fruit"l.TextScaled=true
 esps[o]=b
end
local function rmESP(o)if esps[o]then pcall(function()esps[o]:Destroy()end)esps[o]=nil end end

-- 🍏 SCAN
local function scan()
 local fld=fruitFld()if not fld then return{}end
 local t={}for _,o in ipairs(fld:GetChildren())do
  local p=(o:IsA("Model")and(o.PrimaryPart or o:FindFirstChildWhichIsA("BasePart")))or o
  if p and p.Position then table.insert(t,{m=o,part=p,pos=p.Position})end
 end;return t
end

-- 🍏 Pickup with smooth path
local function pick(f)
 if not f or not f.part then return end
 local ch=LP.Character;if not ch then return end
 local hrp=ch:FindFirstChild("HumanoidRootPart")
 if not hrp then return end
 local start=hrp.Position local fin=f.pos+Vector3.new(0,2,0)
 local mid=start:Lerp(fin,0.5)+Vector3.new(0,40,0)
 local sp=C.spd or 120
 local function fly(to)
  local d=(to-hrp.Position).Magnitude
  local t=math.max(0.25,d/sp)
  local tw=TW:Create(hrp,TweenInfo.new(t,Enum.EasingStyle.Linear),{CFrame=CFrame.new(to)})
  tw:Play()tw.Completed:Wait()
 end
 fly(mid)task.wait(0.05)fly(fin)
 task.wait(0.25)
 if C.st then
  call(function()
   local tool=LP.Backpack:FindFirstChildWhichIsA("Tool")or(ch and ch:FindFirstChildWhichIsA("Tool"))
   if tool then
    local r=S("ReplicatedStorage"):FindFirstChild("Remotes")
    local c=r and r:FindFirstChild("CommF_")
    if c then c:InvokeServer("StoreFruit",tool.Name)end
   end
  end)
 end
end

-- 🍏 Server hop
local function hop()
 local req=syn and syn.request or request;if not req then return end
 local url=("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100"):format(game.PlaceId)
 local ok,res=pcall(function()return req({Url=url,Method="GET"})end)
 if not ok or not res or not res.Body then return end
 local d=HS:JSONDecode(res.Body)
 for _,s in ipairs(d.data)do
  if s.id~=game.JobId and s.playing<s.maxPlayers then
   TS:TeleportToPlaceInstance(game.PlaceId,s.id,LP)return
  end
 end
end

-- 🍏 GUI mini
local function gui()
 if LP.PlayerGui:FindFirstChild("DFGui")then LP.PlayerGui.DFGui:Destroy()end
 local sc=Instance.new("ScreenGui",LP.PlayerGui)sc.Name="DFGui"
 local f=Instance.new("Frame",sc)f.Size=UDim2.new(0,220,0,160)f.Position=UDim2.new(0,12,0,80)
 local t=Instance.new("TextLabel",f)t.Text="DF Helper"t.Size=UDim2.new(1,0,0,24)
 local b=Instance.new("TextButton",f)b.Text="Toggle Auto"b.Size=UDim2.new(1,0,0,26)b.Position=UDim2.new(0,0,0,40)
 b.MouseButton1Click:Connect(function()C.aut=not C.aut end)
 return sc
end
guiRef=gui()

-- 🍏 Loop
task.spawn(function()
 while task.wait(C.chk)do
  local fs=scan()if #fs>0 then last=os.time()end
  if C.esp then for _,f in ipairs(fs)do if not esps[f.m]then mkESP(f.m)end end end
  if C.aut and #fs>0 then table.sort(fs,function(a,b)return(a.pos-LP.Character.HumanoidRootPart.Position).Magnitude<(b.pos-LP.Character.HumanoidRootPart.Position).Magnitude end)pick(fs[1])end
  if C.svhop and (os.time()-last>=C.hop)then hop()end
 end
end)

print("[DFH] Encoded Lite loaded")
