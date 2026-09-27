local env = (getgenv and getgenv()) or _G
local loaded = rawget(env, "__NECTAR_MODULES")

local data
local farming
local menu

if loaded
	and loaded.data
	and loaded.farming
	and loaded.menu
then
	data = loaded.data
	farming = loaded.farming
	menu = loaded.menu
else
	data = require(script:WaitForChild("data"))
	farming = require(script:WaitForChild("farming"))
	menu = require(script:WaitForChild("menu"))
end

assert(type(data) == "table" and type(data.actives) == "table", "client: data not loaded")
assert(type(farming) == "table", "client: farming not loaded")
assert(type(menu) == "table" and type(menu.client_menu) == "function", "client: menu.client_menu not loaded")

local CONFIG_FILE = "Nectar_config.json"

local function saveConfig()
	if not writefile then return end

	local saveData = {
		actives = data.actives,
	}

	local ok, encoded = pcall(function()
		return game:GetService("HttpService"):JSONEncode(saveData)
	end)

	if ok then
		pcall(function()
			writefile(CONFIG_FILE, encoded)
		end)
	end
end

local function loadConfig()
	if not (isfile and readfile) then return end
	if not isfile(CONFIG_FILE) then return end

	local ok, content = pcall(function()
		return readfile(CONFIG_FILE)
	end)

	if not ok or not content or content == "" then return end

	local ok2, decoded = pcall(function()
		return game:GetService("HttpService"):JSONDecode(content)
	end)

	if not ok2 or type(decoded) ~= "table" then return end

	if type(decoded.actives) == "table" then
		for key, value in pairs(decoded.actives) do
			if key ~= "position_script" then
				data.actives[key] = value
			end
		end
	end
end

loadConfig()

env.__NECTAR_SAVE = saveConfig

local find = {
	renderstepped = game:GetService("RunService").RenderStepped,
	prerender = game:GetService("RunService").PreRender,
	tweenservice = game:GetService("TweenService"),
	player = game:GetService("Players").LocalPlayer,
	players = game:GetService("Players"),
	httpservice = game:GetService("HttpService"),
	contextactionservice = game:GetService("ContextActionService"),
	random = Random.new(),
}

local mod = {
	data = data,
	farming = farming,
	menu = menu,
	save = saveConfig,
}

local function characterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	character:WaitForChild("HumanoidRootPart")
	humanoid.WalkSpeed = mod.data.actives["walkspeed"]
end

local success, result = xpcall(function()
	mod.menu.client_menu()
end, debug.traceback)

if not success then
	warn("er create menu:\n" .. tostring(result))
end

if find.player.Character then
	task.spawn(characterAdded, find.player.Character)
end

find.player.CharacterAdded:Connect(characterAdded)

if writefile then
	task.spawn(function()
		while task.wait(5) do
			saveConfig()
		end
	end)
end

return mod
