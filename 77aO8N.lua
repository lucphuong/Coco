local 77aO8N = (getgenv or getrenv or getfenv)()
local BETA_VERSION = BETA_VERSION or 77aO8N.BETA_VERSION

local Scripts = {
	{
		GameId = 994732206, -- Blox Fruits
		UrlPath = if BETA_VERSION then "BLOX-FRUITS-BETA.lua" else "BloxFruits.luau"
	},
	{
		PlacesIds = {10260193230}, -- Meme Sea
		UrlPath = "MemeSea.luau"
	}
}

local fetcher, urls = {}, {}

-- chống spam execute
do
	local last_exec = 77aO8N.rz_execute_debounce
	if last_exec and (tick() - last_exec) <= 5 then
		return nil
	end
	77aO8N.rz_execute_debounce = tick()
end

urls.Owner = "https://raw.githubusercontent.com/tlredz/"
urls.Repository = urls.Owner .. "Scripts/refs/heads/main/"
urls.Translator = urls.Repository .. "Translator/"
urls.Utils = urls.Repository .. "Utils/"

-- hỗ trợ teleport queue
do
	local executor = syn or fluxus
	local queueteleport = queue_on_teleport or (executor and executor.queue_on_teleport)

	if not 77aO8N.rz_added_teleport_queue and type(queueteleport) == "function" then
		local ScriptSettings = {...}
		local SettingsCode = ""

		77aO8N.rz_added_teleport_queue = true

		local Success, EncodedSettings = pcall(function()
			return game:GetService("HttpService"):JSONEncode(ScriptSettings)
		end)

		if Success and EncodedSettings then
			SettingsCode = "unpack(game:GetService('HttpService'):JSONDecode('" .. EncodedSettings .. "'))"
		end

		local SourceCode = ("loadstring(game:HttpGet('%smain.luau'))(%s)"):format(urls.Repository, SettingsCode)

		if BETA_VERSION then
			SourceCode = "getgenv().BETA_VERSION=true;" .. SourceCode
		end

		pcall(queueteleport, SourceCode)
	end
end

-- ==== BẮT ĐẦU PHẦN BÁO LỖI ====
local function CreateMessageError(Text)
	if 77aO8N.rz_error_message then
		77aO8N.rz_error_message:Destroy()
	end

	local Message = Instance.new("Message", workspace)
	Message.Text = Text
	77aO8N.rz_error_message = Message

	warn("[77aO8N Error] " .. Text)
	task.delay(5, function()
		if Message and Message.Parent then
			Message:Destroy()
		end
	end)
end
-- ==== KẾT THÚC PHẦN BÁO LỖI ====

local function formatUrl(Url)
	for key, path in urls do
		if Url:find("{" .. key .. "}") then
			return Url:gsub("{" .. key .. "}", path)
		end
	end
	return Url
end

function fetcher.get(Url)
	local success, response = pcall(function()
		return game:HttpGet(formatUrl(Url))
	end)
	if not success then
		CreateMessageError("[1] Không thể tải URL: " .. tostring(Url))
	end
	return success and response or ""
end

function fetcher.load(Url: string, concat: string?)
	local raw = fetcher.get(Url) .. (if concat then concat else "")
	local runFunction, err = loadstring(raw)
	if type(runFunction) ~= "function" then
		CreateMessageError("[2] Lỗi cú pháp khi load: " .. tostring(Url) .. "\nChi tiết: " .. tostring(err))
	else
		return runFunction
	end
end

local function IsPlace(Script)
	if Script.PlacesIds and table.find(Script.PlacesIds, game.PlaceId) then
		return true
	elseif Script.GameId and Script.GameId == game.GameId then
		return true
	end
	return false
end

for _, Script in Scripts do
	if IsPlace(Script) then
		local success, err = pcall(function()
			return fetcher.load("{Repository}Games/" .. Script.UrlPath)(fetcher, ...)
		end)
		if not success then
			CreateMessageError("[3] Lỗi khi thực thi script: " .. tostring(err))
		end
	end
    end
