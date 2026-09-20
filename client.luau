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
	-- load github loaded
	data = loaded.data
	farming = loaded.farming
	menu = loaded.menu
else
	-- load roblox studio
	data = require(script:WaitForChild("data"))
	farming = require(script:WaitForChild("farming"))
	menu = require(script:WaitForChild("menu"))
end

assert(
	type(data) == "table"
		and type(data.actives) == "table",
	"client: data not loaded"
)

assert(
	type(farming) == "table",
	"client: farming not loaded"
)

assert(
	type(menu) == "table"
		and type(menu.client_menu) == "function",
	"client: menu.client_menu not loaded"
)

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

return mod
