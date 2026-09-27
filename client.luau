local env = (getgenv and getgenv()) or _G
local loaded = rawget(env, "__NECTAR_MODULES")

local data
local farming
local menu

if loaded
	and loaded.data
	and loaded.farming
	and loaded.menu
	and loaded.config
then
	data = loaded.data
	farming = loaded.farming
	menu = loaded.menu
	config = loaded.config
else
	data = require(script:WaitForChild("data"))
	farming = require(script:WaitForChild("farming"))
	menu = require(script:WaitForChild("menu"))
	config = require(script:WaitForChild("config"))
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
	config = config,
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

local function startAntiAFK()
	local env_ref = env

	if env_ref.__NECTAR_ANTI_AFK_CONN then
		pcall(function() env_ref.__NECTAR_ANTI_AFK_CONN:Disconnect() end)
		env_ref.__NECTAR_ANTI_AFK_CONN = nil
	end

	local VU = game:GetService("VirtualUser")
	local player = find.player
	
	env_ref.__NECTAR_ANTI_AFK_CONN = player.Idled:Connect(function()
		if mod.data.actives["anti_afk"] ~= true then return end
		
		pcall(function()
			VU:CaptureController()
			VU:ClickButton2(Vector2.new())
		end)
		task.wait(0.1)
		pcall(function()
			VU:SendMouseMoveEvent(math.random(-5, 5), math.random(-5, 5), true, game)
		end)
		task.wait(0.1)
		pcall(function()
			VU:SendKeyEvent(true, Enum.KeyCode.LeftShift, false, game)
			task.wait(0.05)
			VU:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
		end)
	end)
	
	task.spawn(function()
		if env_ref.__NECTAR_ANTI_AFK_WORKER then return end
		env_ref.__NECTAR_ANTI_AFK_WORKER = true

		while player.Parent do
			task.wait(45)

			if mod.data.actives["anti_afk"] == true then
				pcall(function()
					local dx = math.random(-3, 3)
					local dy = math.random(-3, 3)
					VU:SendMouseMoveEvent(dx, dy, true, game)
					task.wait(0.05)
					VU:SendMouseMoveEvent(-dx, -dy, true, game)
					task.wait(0.05)
					
					local keys = {Enum.KeyCode.LeftShift, Enum.KeyCode.LeftControl, Enum.KeyCode.Tab}
					local key = keys[math.random(#keys)]
					VU:SendKeyEvent(true, key, false, game)
					task.wait(0.05)
					VU:SendKeyEvent(false, key, false, game)
				end)
			end
		end

		env_ref.__NECTAR_ANTI_AFK_WORKER = false
	end)
end

startAntiAFK()

if writefile then
	task.spawn(function()
		while task.wait(10) do
			saveConfig()
		end
	end)
end

return mod
