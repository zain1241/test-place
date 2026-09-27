local env = (getgenv and getgenv()) or _G
local loaded = rawget(env, "__NECTAR_MODULES")

local data

if loaded and loaded.data then
	data = loaded.data
else
	data = require(script.Parent:WaitForChild("data"))
end

local config = {}

local mod = {
	data = data,
}

local find= {
	renderstepped = game:GetService("RunService").RenderStepped,
	prerender = game:GetService("RunService").PreRender,
	tweenservice = game:GetService("TweenService"),
	player = game:GetService("Players").LocalPlayer,
	players = game:GetService("Players"),
	httpservice = game:GetService("HttpService"),
	contextactionservice = game:GetService("ContextActionService"),
	virtual = game:GetService("VirtualInputManager"),
	guiservice = game:GetService("GuiService"),
	random = Random.new(),
}

return config
