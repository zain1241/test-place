local env = (getgenv and getgenv()) or _G
local loaded = rawget(env, "__NECTAR_MODULES")

local data
local farming

if loaded and loaded.data and loaded.farming then
	data = loaded.data
	farming = loaded.farming
else
	data = require(script.Parent:WaitForChild("data"))
	farming = require(script.Parent:WaitForChild("farming"))
end

local menu = {}

local mod = {
	data = data,
	farming = farming,
}

local find= {
	renderstepped = game:GetService("RunService").RenderStepped,
	prerender = game:GetService("RunService").PreRender,
	tweenservice = game:GetService("TweenService"),
	player = game:GetService("Players").LocalPlayer,
	players = game:GetService("Players"),
	httpservice = game:GetService("HttpService"),
	contextactionservice = game:GetService("ContextActionService"),
	userinputservice = game:GetService("UserInputService"),
	random = Random.new(),
}

menu.colors = {
	main = Color3.fromRGB(10, 9, 11),
	active_button = Color3.fromRGB(28, 26, 31),
	card = Color3.fromRGB(16, 15, 18),
	preview = Color3.fromRGB(28, 26, 31),
	button_off = Color3.fromRGB(34, 33, 39),
	button_on = Color3.fromRGB(255, 198, 74),
}

local sections = {}
local navigationButtons = {}
local activeSection = "Home"

function menu.main_create()
	local playerGui = find.player:WaitForChild("PlayerGui")
	local s = playerGui:FindFirstChild("ScreenGui")

	if not s then
		s = Instance.new("ScreenGui")
		s.Name = "ScreenGui"
		s.ResetOnSpawn = false
		s.IgnoreGuiInset = false
		s.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		s.Parent = playerGui
	end

	local old = s:FindFirstChild("EggHuntLayerVisualOnly")

	if old then
		old:Destroy()
	end

	local f = Instance.new("Frame")
	f.Name = "EggHuntLayerVisualOnly"
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.BackgroundTransparency = 1
	f.Position = mod.data.actives["position_script"]
		or UDim2.new(0.22, 0, 0.5, 0)
	f.Size = UDim2.new(0.351, 0, 0.435, 0)
	f.ZIndex = 1000
	f.Parent = s

	local fl = Instance.new("UIListLayout")
	fl.SortOrder = Enum.SortOrder.LayoutOrder
	fl.Padding = UDim.new(0, 0)
	fl.Parent = f
	fl.FillDirection = Enum.FillDirection.Horizontal
	fl.HorizontalAlignment = Enum.HorizontalAlignment.Left
	fl.VerticalAlignment = Enum.VerticalAlignment.Top

	local m = Instance.new("Frame")
	m.Name = "Main"
	m.AnchorPoint = Vector2.new(0.5, 0.5)
	m.BackgroundColor3 = Color3.fromRGB(10, 9, 11)
	m.BorderSizePixel = 0
	m.BackgroundTransparency = 0.04
	m.Size = UDim2.new(0.773, 0,1, 0)
	m.LayoutOrder = 1
	m.ZIndex = 1001
	m.Parent = f

	local ms = Instance.new("UIShadow")
	ms.Parent = m
	ms.BlurRadius = UDim.new(0.1, 0)
	ms.Color = Color3.fromRGB(0, 0, 0)
	ms.Transparency = 0.8

	local mc = Instance.new("UICorner")
	mc.Parent = m
	mc.BottomLeftRadius = UDim.new(0, 0)
	mc.BottomRightRadius = UDim.new(0.03, 0)
	mc.TopLeftRadius = UDim.new(0, 0)
	mc.TopRightRadius = UDim.new(0.03, 0)

	local c = Instance.new("Frame")
	c.Name = "Content"
	c.AnchorPoint = Vector2.new(0.5, 0.5)
	c.BackgroundTransparency = 1
	c.Position = UDim2.new(0.5, 0,0.5, 0)
	c.Size = UDim2.new(1, 0,1, 0)
	c.ZIndex = 1001
	c.Parent = m

	local cc = Instance.new("UICorner")
	cc.Parent = c
	cc.BottomLeftRadius = UDim.new(0, 0)
	cc.BottomRightRadius = UDim.new(0.03, 0)
	cc.TopLeftRadius = UDim.new(0, 0)
	cc.TopRightRadius = UDim.new(0.03, 0)

	local t = Instance.new("Frame")
	t.Name = "Tab"
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.BackgroundColor3 = Color3.fromRGB(10, 9, 11)
	t.BorderSizePixel = 0
	t.BackgroundTransparency = 0.04
	t.Size = UDim2.new(0.227, 0,1, 0)
	t.LayoutOrder = 0
	t.ZIndex = 1001
	t.Parent = f

	local tl = Instance.new("UIListLayout")
	tl.SortOrder = Enum.SortOrder.LayoutOrder
	tl.Padding = UDim.new(0, 0)
	tl.Parent = t
	tl.FillDirection = Enum.FillDirection.Vertical
	tl.HorizontalAlignment = Enum.HorizontalAlignment.Right
	tl.VerticalAlignment = Enum.VerticalAlignment.Top

	local ts = Instance.new("UIShadow")
	ts.Parent = t
	ts.BlurRadius = UDim.new(0.1, 0)
	ts.Color = Color3.fromRGB(0, 0, 0)
	ts.Transparency = 0.8

	local tc = Instance.new("UICorner")
	tc.Parent = t
	tc.BottomLeftRadius = UDim.new(0.08, 0)
	tc.BottomRightRadius = UDim.new(0, 0)
	tc.TopLeftRadius = UDim.new(0.08, 0)
	tc.TopRightRadius = UDim.new(0, 0)
end

function menu.main_nav()
	local s = find.player.PlayerGui:FindFirstChild("ScreenGui"):FindFirstChild("EggHuntLayerVisualOnly"):FindFirstChild("Tab")
	local b1 = Instance.new("Frame")
	b1.Name = "Back"
	b1.BackgroundTransparency = 1
	b1.Size = UDim2.new(1, 0,0.106, 0)
	b1.ZIndex = 1002
	b1.Parent = s

	local n = Instance.new("Frame")
	n.Name = "Nav"
	n.BackgroundTransparency = 1
	n.Size = UDim2.new(0.961, 0,0.716, 0)
	n.ZIndex = 1002
	n.Parent = s

	local t = Instance.new("Frame")
	t.Name = "Stats"
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0,0.16, 0)
	t.ZIndex = 1002
	t.Parent = s

	local sl = Instance.new("UIListLayout")
	sl.SortOrder = Enum.SortOrder.LayoutOrder
	sl.Padding = UDim.new(0, 0)
	sl.Parent = t
	sl.FillDirection = Enum.FillDirection.Horizontal
	sl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	sl.VerticalAlignment = Enum.VerticalAlignment.Bottom

	local b = Instance.new("TextButton")
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.BackgroundColor3 = Color3.fromRGB(16, 16, 17)
	b.BackgroundTransparency = 0
	b.Parent = t
	b.Text = ""
	b.Size = UDim2.new(0.912, 0,0.664, 0)
	b.ZIndex = 1003

	local bl = Instance.new("UIListLayout")
	bl.SortOrder = Enum.SortOrder.LayoutOrder
	bl.Padding = UDim.new(0, 0)
	bl.Parent = b
	bl.FillDirection = Enum.FillDirection.Horizontal
	bl.HorizontalAlignment = Enum.HorizontalAlignment.Left
	bl.VerticalAlignment = Enum.VerticalAlignment.Center

	local bc = Instance.new("UICorner")
	bc.Parent = b
	bc.BottomLeftRadius = UDim.new(0.3, 0)
	bc.BottomRightRadius = UDim.new(0.3, 0)
	bc.TopLeftRadius = UDim.new(0.3, 0)
	bc.TopRightRadius = UDim.new(0.3, 0)

	local f1 = Instance.new("Frame")
	f1.Name = "f1"
	f1.BackgroundTransparency = 1
	f1.Size = UDim2.new(0.5, 0,1, 0)
	f1.LayoutOrder = 0
	f1.ZIndex = 1004
	f1.Parent = b

	local f1l = Instance.new("UIListLayout")
	f1l.SortOrder = Enum.SortOrder.LayoutOrder
	f1l.Padding = UDim.new(0, 0)
	f1l.Parent = f1
	f1l.FillDirection = Enum.FillDirection.Horizontal
	f1l.HorizontalAlignment = Enum.HorizontalAlignment.Center
	f1l.VerticalAlignment = Enum.VerticalAlignment.Center

	local f1i = Instance.new("ImageLabel")
	f1i.BackgroundColor3 = Color3.fromRGB(12, 12, 13)
	f1i.BackgroundTransparency = 0
	f1i.BorderSizePixel = 0
	f1i.Size = UDim2.new(0.489, 0, 0.791, 0)
	f1i.ScaleType = Enum.ScaleType.Fit
	f1i.ZIndex = 1005
	f1i.Image = "rbxthumb://type=AvatarHeadShot&id="
		.. find.player.UserId
		.. "&w=100&h=100"
	f1i.Parent = f1

	local f1c = Instance.new("UICorner")
	f1c.Parent = f1i
	f1c.BottomLeftRadius = UDim.new(1, 0)
	f1c.BottomRightRadius = UDim.new(1, 0)
	f1c.TopLeftRadius = UDim.new(1, 0)
	f1c.TopRightRadius = UDim.new(1, 0)

	local f2 = Instance.new("Frame")
	f2.Name = "f2"
	f2.BackgroundTransparency = 1
	f2.Size = UDim2.new(0.5, 0,1, 0)
	f2.LayoutOrder = 1
	f2.ZIndex = 1004
	f2.Parent = b

	local f2l = Instance.new("UIListLayout")
	f2l.SortOrder = Enum.SortOrder.LayoutOrder
	f2l.Padding = UDim.new(0, 0)
	f2l.Parent = f2
	f2l.FillDirection = Enum.FillDirection.Vertical
	f2l.HorizontalAlignment = Enum.HorizontalAlignment.Left
	f2l.VerticalAlignment = Enum.VerticalAlignment.Center

	local tp = Instance.new("TextLabel")
	tp.Name = "tp"
	tp.Parent = f2
	tp.AutomaticSize = Enum.AutomaticSize.X
	tp.BackgroundTransparency = 1
	tp.BorderSizePixel = 0
	tp.Size = UDim2.new(0.773, 0,0.323, 0)
	tp.ZIndex = 1005
	tp.Font = Enum.Font.BuilderSansMedium
	tp.Text = "#"..find.player.Name
	tp.LayoutOrder = 1
	tp.TextColor3 = Color3.fromRGB(69, 66, 72)
	tp.TextScaled = true
	tp.TextXAlignment = Enum.TextXAlignment.Left

	local tt = Instance.new("TextLabel")
	tt.Name = "tt"
	tt.Parent = f2
	tt.AutomaticSize = Enum.AutomaticSize.X
	tt.BackgroundTransparency = 1
	tt.BorderSizePixel = 0
	tt.Size = UDim2.new(0.773, 0,0.323, 0)
	tt.ZIndex = 1005
	tt.Font = Enum.Font.BuilderSansBold
	tt.Text = "" -- timer need added for key end
	task.spawn(function()
		while tt.Parent do
			tt.Text = DateTime.now():FormatLocalTime("HH:mm", "ru-ru")
			task.wait(1)
		end
	end)
	tt.LayoutOrder = 0
	tt.TextColor3 = Color3.fromRGB(255, 255, 255)
	tt.TextScaled = true
	tt.TextXAlignment = Enum.TextXAlignment.Left

	local b1l = Instance.new("UIListLayout")
	b1l.SortOrder = Enum.SortOrder.LayoutOrder
	b1l.Padding = UDim.new(0.04, 0)
	b1l.Parent = b1
	b1l.FillDirection = Enum.FillDirection.Horizontal
	b1l.HorizontalAlignment = Enum.HorizontalAlignment.Center
	b1l.VerticalAlignment = Enum.VerticalAlignment.Center

	local b1t = Instance.new("TextLabel")
	b1t.Name = "b1t"
	b1t.Parent = b1
	b1t.BackgroundTransparency = 1
	b1t.BorderSizePixel = 0
	b1t.Size = UDim2.new(0.468, 0,0.37, 0)
	b1t.ZIndex = 1004
	b1t.Font = Enum.Font.BuilderSansBold
	b1t.Text = mod.data.actives["script_name"]
	b1t.LayoutOrder = 0
	b1t.TextColor3 = Color3.fromRGB(255, 255, 255)
	b1t.TextScaled = true
	b1t.TextXAlignment = Enum.TextXAlignment.Right
	
	local f2i = Instance.new("ImageLabel")
	f2i.BackgroundTransparency = 1
	f2i.BorderSizePixel = 0
	f2i.Size = UDim2.new(0.177, 0, 0.659, 0)
	f2i.ScaleType = Enum.ScaleType.Fit
	f2i.LayoutOrder = -1
	f2i.ZIndex = 1004
	f2i.Image = "rbxassetid://15505167958"
	f2i.Parent = b1

	local b1b = Instance.new("TextButton")
	b1b.AnchorPoint = Vector2.new(0.5, 0.5)
	b1b.BackgroundColor3 = Color3.fromRGB(24, 23, 25)
	b1b.BackgroundTransparency = 0
	b1b.Parent = b1
	b1b.LayoutOrder = 1
	b1b.Font = Enum.Font.BuilderSansExtraBold
	b1b.TextScaled = true
	b1b.TextXAlignment = Enum.TextXAlignment.Center
	b1b.Text = "<"
	b1b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b1b.Size = UDim2.new(0.153, 0,0.542, 0)
	b1b.ZIndex = 1004

	local frame = find.player.PlayerGui:FindFirstChild("ScreenGui"):FindFirstChild("EggHuntLayerVisualOnly")
	local tab = find.player.PlayerGui:FindFirstChild("ScreenGui"):FindFirstChild("EggHuntLayerVisualOnly"):FindFirstChild("Tab")
	local mainsize = frame.Main.Size
	local clicked = false
	frame.Main.ClipsDescendants = true
	b1b.MouseButton1Click:Connect(function()
		if clicked == true then
			return
		end

		clicked = true

		if frame.Main.Visible == true then
			local af = s:FindFirstChild("Nav") and s.Nav:FindFirstChild("NavAutoFarm")
			if af then af.Visible = true end

			find.tweenservice:Create(frame.Main, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = UDim2.new(0, 0, mainsize.Y.Scale, mainsize.Y.Offset)
			}):Play()

			find.tweenservice:Create(frame.Main.UICorner, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				BottomLeftRadius = UDim.new(0.03, 0),
				BottomRightRadius = UDim.new(0.03, 0),
				TopLeftRadius = UDim.new(0.03, 0),
				TopRightRadius = UDim.new(0.03, 0)
			}):Play()

			tab.Back.TextButton.Text = ">"

			task.delay(0.3, function()
				frame.Main.Visible = false

				find.tweenservice:Create(tab.UICorner, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
					BottomLeftRadius = UDim.new(0.08, 0),
					BottomRightRadius = UDim.new(0.08, 0),
					TopLeftRadius = UDim.new(0.08, 0),
					TopRightRadius = UDim.new(0.08, 0)
				}):Play()
				clicked = false
			end)
		else
			local af = s:FindFirstChild("Nav") and s.Nav:FindFirstChild("NavAutoFarm")
			if af then af.Visible = false end

			frame.Main.Visible = true
			frame.Main.Size = UDim2.new(0, 0, mainsize.Y.Scale, mainsize.Y.Offset)

			find.tweenservice:Create(tab.UICorner, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				BottomLeftRadius = UDim.new(0.08, 0),
				BottomRightRadius = UDim.new(0, 0),
				TopLeftRadius = UDim.new(0.08, 0),
				TopRightRadius = UDim.new(0, 0)
			}):Play()

			find.tweenservice:Create(frame.Main.UICorner, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				BottomLeftRadius = UDim.new(0, 0),
				BottomRightRadius = UDim.new(0.03, 0),
				TopLeftRadius = UDim.new(0, 0),
				TopRightRadius = UDim.new(0.03, 0)
			}):Play()

			tab.Back.TextButton.Text = "<"

			find.tweenservice:Create(frame.Main, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
				Size = mainsize
			}):Play()

			task.delay(0.3, function()
				clicked = false
			end)
		end
	end)

	local b1c = Instance.new("UICorner")
	b1c.Parent = b1b
	b1c.BottomLeftRadius = UDim.new(0.4, 0)
	b1c.BottomRightRadius = UDim.new(0.4, 0)
	b1c.TopLeftRadius = UDim.new(0.4, 0)
	b1c.TopRightRadius = UDim.new(0.4, 0)

	local nl = Instance.new("UIListLayout")
	nl.SortOrder = Enum.SortOrder.LayoutOrder
	nl.Padding = UDim.new(0.02, 0)
	nl.Parent = n
	nl.FillDirection = Enum.FillDirection.Vertical
	nl.HorizontalAlignment = Enum.HorizontalAlignment.Left
	nl.VerticalAlignment = Enum.VerticalAlignment.Top
	
	local afButton = Instance.new("TextButton")
	afButton.Name = "NavAutoFarm"
	afButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	afButton.BackgroundTransparency = 0.85
	afButton.BorderSizePixel = 0
	afButton.Text = ""
	afButton.Size = UDim2.new(0.954, 0,0.087, 0)
	afButton.LayoutOrder = 100
	afButton.ZIndex = 1004
	afButton.Visible = false
	afButton.Parent = n
	
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(
		Color3.fromRGB(194, 49, 142), -- #E72EFF
		Color3.fromRGB(242, 96, 190)  -- #FF4294
	)
	gradient.Rotation = 0
	gradient.Parent = afButton

	gradient.Offset = Vector2.new(-1, 0)

	local shimmer = find.tweenservice:Create(
		gradient,
		TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
		{Offset = Vector2.new(1, 0)}
	)

	shimmer:Play()

	local afCorner = Instance.new("UICorner")
	afCorner.CornerRadius = UDim.new(0, 7)
	afCorner.Parent = afButton

	local afText = Instance.new("TextLabel")
	afText.Name = "TextLabel"
	afText.BackgroundTransparency = 1
	afText.BorderSizePixel = 0
	afText.Position = UDim2.new(0, 10, 0, 0)
	afText.Size = UDim2.new(0.62, -10, 1, 0)
	afText.ZIndex = 1005
	afText.Font = Enum.Font.BuilderSansBold
	afText.Text = "Auto Farm"
	afText.TextColor3 = Color3.fromRGB(255, 255, 255)
	afText.TextScaled = false
	afText.TextSize = 15
	afText.TextXAlignment = Enum.TextXAlignment.Left
	afText.Parent = afButton

	local afToggle = Instance.new("TextButton")
	afToggle.Name = "TextButton"
	afToggle.AnchorPoint = Vector2.new(1, 0.5)
	afToggle.BackgroundColor3 = Color3.fromRGB(30, 12, 26)
	afToggle.Interactable = false
	afToggle.BackgroundTransparency = 0
	afToggle.AutoButtonColor = false
	afToggle.BorderSizePixel = 0
	afToggle.Position = UDim2.new(1, -7, 0.5, 0)
	afToggle.Size = UDim2.new(0, 18, 0, 18)
	afToggle.ZIndex = 1005
	afToggle.Text = ""
	afToggle.Parent = afButton

	local afToggleCorner = Instance.new("UICorner")
	afToggleCorner.CornerRadius = UDim.new(0.3, 0)
	afToggleCorner.Parent = afToggle

	local afCheck = Instance.new("ImageLabel")
	afCheck.Name = "ImageLabel"
	afCheck.AnchorPoint = Vector2.new(0.5, 0.5)
	afCheck.BackgroundTransparency = 1
	afCheck.BorderSizePixel = 0
	afCheck.Position = UDim2.new(0.5, 0, 0.5, 0)
	afCheck.Size = UDim2.new(0.721, 0, 0.721, 0)
	afCheck.ZIndex = 1006
	afCheck.Image = "rbxassetid://3642321726"
	afCheck.ScaleType = Enum.ScaleType.Fit
	afCheck.Visible = false
	afCheck.Parent = afToggle

	local function afUpdate()
		afCheck.Visible = mod.data.actives["auto_farm"] == true
	end
	afUpdate()

	afButton.MouseButton1Click:Connect(function()
		mod.data.actives["auto_farm"] = not (mod.data.actives["auto_farm"] == true)
		afUpdate()
		if mod.farming and mod.farming.farm then
			mod.farming.farm()
		end
		if mod.farming and mod.farming.startPlanterLoop then
			if mod.data.actives["auto_farm"] == true and mod.data.actives["planter_auto"] == true then
				mod.farming.startPlanterLoop()
			else
				mod.farming.stopPlanterLoop()
			end
		end
	end)
	
	task.spawn(function()
		while afButton.Parent do
			afUpdate()
			task.wait(0.15)
		end
	end)
	
	local mainFrame = find.player.PlayerGui:FindFirstChild("ScreenGui")
		:FindFirstChild("EggHuntLayerVisualOnly")
		:FindFirstChild("Main")

	afButton.Visible = mainFrame.Visible == false
	mainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
		afButton.Visible = mainFrame.Visible == false
	end)

	local function showsel(name)
		activeSection = name
		for sectionName, page in pairs(sections) do
			page.Visible = sectionName == name
		end
		for sectionName, button in pairs(navigationButtons) do
			button.BackgroundTransparency = sectionName == name and 0 or 1
			button.textname.TextColor3 = sectionName == name and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(80, 76, 83)
			button.icon.ImageColor3 = sectionName == name and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(80, 76, 83)
		end
		--search.Text = "Search"
	end

	local function addNavigation(name, icon, order)
		local b = Instance.new("TextButton")
		b.Name = "Button-" .. name
		b.BackgroundColor3 = Color3.fromRGB(28, 26, 31)
		b.BackgroundTransparency = 1 -- not enabled
		b.BorderSizePixel = 0
		b.Size = UDim2.new(0.855, 0,0.087, 0)
		b.LayoutOrder = order
		b.ZIndex = 1004
		b.Parent = n
		b.Text = ""
		b.TextXAlignment = Enum.TextXAlignment.Left

		local u = Instance.new("UIListLayout")
		u.SortOrder = Enum.SortOrder.LayoutOrder
		u.Padding = UDim.new(0.06, 0)
		u.Parent = b
		u.FillDirection = Enum.FillDirection.Horizontal
		u.HorizontalAlignment = Enum.HorizontalAlignment.Left
		u.VerticalAlignment = Enum.VerticalAlignment.Center

		local c = Instance.new("UICorner")
		c.Parent = b
		c.BottomLeftRadius = UDim.new(0.3, 0)
		c.BottomRightRadius = UDim.new(0.3, 0)
		c.TopLeftRadius = UDim.new(0.3, 0)
		c.TopRightRadius = UDim.new(0.3, 0)

		local p = Instance.new("UIPadding")
		p.Parent = b
		p.PaddingLeft = UDim.new(0.04, 0)
		p.PaddingRight = UDim.new(0, 0)
		p.PaddingTop = UDim.new(0, 0)
		p.PaddingBottom = UDim.new(0, 0)

		local i = Instance.new("ImageLabel")
		i.Name = "icon"
		i.AnchorPoint = Vector2.new(0.5, 0.5)
		i.BackgroundTransparency = 1
		i.LayoutOrder = 0
		i.Size = UDim2.new(0.114, 0,0.489, 0)
		i.Image = icon
		i.ImageColor3 = Color3.fromRGB(255, 255, 255)
		i.ScaleType = Enum.ScaleType.Fit
		i.ZIndex = 1004
		i.Parent = b

		local t = Instance.new("TextLabel")
		t.Name = "textname"
		t.AutomaticSize = Enum.AutomaticSize.X
		t.BackgroundTransparency = 1
		t.BorderSizePixel = 0
		t.LayoutOrder = 1
		t.Size = UDim2.new(0.319, 0,0.61, 0)
		t.ZIndex = 1004
		t.Font = Enum.Font.BuilderSansMedium
		t.Text = name
		t.TextColor3 = Color3.fromRGB(255, 255, 255)
		t.TextScaled = true
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Parent = b

		b.MouseButton1Click:Connect(function()
			showsel(name)
		end)

		navigationButtons[name] = b
	end

	--addNavigation("Home", "rbxassetid://13060262529", 1)
	addNavigation("Farming", "rbxassetid://15332137726", 1)
	addNavigation("Planters", "rbxassetid://13060262529", 2)
	addNavigation("Toys", "rbxassetid://102597526078163", 3)
	--addNavigation("Combat", "rbxassetid://4391741881", 4)
	addNavigation("Config", "rbxassetid://4857706689", 4)

	showsel("Farming")
end

function menu.dop_create()
	local a = {
		find.player.PlayerGui:FindFirstChild("ScreenGui"),
	}

	if a[1] == nil then
		return
	end

	local f = a[1]:FindFirstChild("EggHuntLayerVisualOnly")
	if f == nil then
		return
	end

	local m = f:FindFirstChild("Main")
	if m == nil then
		return
	end

	sections = {}
	menu.dop_objects = {}
	mod.data.actives = mod.data.actives or {}

	local active_slider

	local function corner(...)
		local a = {...}

		if a[1] == nil then
			return
		end

		local r = a[2] or UDim.new(0.08, 0)
		local c = Instance.new("UICorner")
		c.BottomLeftRadius = a[3] or r
		c.BottomRightRadius = a[4] or r
		c.TopLeftRadius = a[5] or r
		c.TopRightRadius = a[6] or r
		c.Parent = a[1]
		return c
	end

	local function save(...)
		local a = {...}

		if a[1] == nil then
			return
		end

		if a[1].key ~= nil then
			mod.data.actives[a[1].key] = a[2]
		end

		if a[1].callback ~= nil then
			local cb = a[1].callback
			local v1, v2, v3 = a[2], a[3], a[4]
			task.spawn(function()
				cb(v1, v2, v3)
			end)
		end
	end

	local function addtext(...)
		local a = {...}

		if a[1] == nil or a[2] == nil then
			return
		end

		local t = Instance.new("TextLabel")
		t.Name = a[2].name or "Text"
		t.BackgroundColor3 = menu.colors.preview
		t.BackgroundTransparency = a[2].background_transparency or 0
		t.BorderSizePixel = 0
		t.Size = a[2].size or UDim2.new(1, 0,0, 30)
		t.LayoutOrder = a[3] or 0
		t.ZIndex = 1004
		t.Font = a[2].font or Enum.Font.BuilderSansMedium
		t.Text = tostring(a[2].text or "Text")
		t.TextColor3 = a[2].text_color or Color3.fromRGB(255, 255, 255)
		t.TextScaled = a[2].text_scaled ~= false
		t.TextWrapped = true
		t.TextXAlignment = a[2].text_x_alignment or Enum.TextXAlignment.Left
		t.Parent = a[1]

		t:SetAttribute("search_text", string.lower(tostring(a[2].text or "")))

		corner(t, a[2].corner)

		local p = Instance.new("UIPadding")
		p.PaddingLeft = UDim.new(0.03, 0)
		p.PaddingRight = UDim.new(0.03, 0)
		p.Parent = t

		local o = {
			frame = t,
			text = t,
		}

		function o.set(...)
			local a = {...}
			t.Text = tostring(a[1] or "")
		end

		if a[2].id ~= nil then
			menu.dop_objects[a[2].id] = o
		end

		return o
	end

	local function addbutton(...)
		local a = {...}

		if a[1] == nil or a[2] == nil then
			return
		end

		local d = a[2]
		local toggle = d.toggle ~= false
		local value = d.value

		if d.key ~= nil and mod.data.actives[d.key] ~= nil then
			value = mod.data.actives[d.key]
			--print(value)
		end

		if toggle == true then
			value = value == true
			if d.key ~= nil and mod.data.actives[d.key] == nil then
				mod.data.actives[d.key] = value
			end
		end

		local r = Instance.new("TextButton")
		r.Name = d.name or "Preview"
		r.BackgroundColor3 = Color3.fromRGB(26, 24, 29)
		r.BackgroundTransparency = 0.2
		r.BorderSizePixel = 0
		r.Text = ""
		r.Size = UDim2.new(0.351, -12,0, 30)
		r.LayoutOrder = a[3] or 0
		r.ZIndex = 1004
		r.Parent = a[1]

		r:SetAttribute("search_text", string.lower(tostring(d.text or "")))

		corner(r, UDim.new(0, 7))

		local t = Instance.new("TextLabel")
		t.Name = "TextLabel"
		t.BackgroundTransparency = 1
		t.BorderSizePixel = 0
		t.Position = UDim2.new(0, 10,0, 0)
		t.Size = UDim2.new(0.62, -10,1, 0)
		t.ZIndex = 1005
		t.Font = Enum.Font.BuilderSansBold
		t.Text = tostring(d.text or "er")
		--print(d.text)
		t.TextColor3 = Color3.fromRGB(255, 255, 255)
		t.TextScaled = false
		t.TextSize = 15
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Parent = r

		local b = Instance.new("TextButton")
		b.Name = "TextButton"
		b.AnchorPoint = Vector2.new(1, 0.5)
		b.BackgroundColor3 = Color3.fromRGB(42, 40, 45)
		b.Interactable = false
		b.BackgroundTransparency = 0
		b.AutoButtonColor = false
		b.BorderSizePixel = 0
		b.Position = UDim2.new(1, -7,0.5, 0)
		b.Size = UDim2.new(0, 23,0, 23)
		b.ZIndex = 1005
		b.Font = Enum.Font.BuilderSansBold
		b.TextColor3 = Color3.fromRGB(92, 92, 98)
		b.TextScaled = true
		b.Text = ""
		b.Parent = r

		local c = Instance.new("ImageLabel")
		c.Name = "ImageLabel"
		c.AnchorPoint = Vector2.new(0.5, 0.5)
		c.BackgroundTransparency = 1
		c.BorderSizePixel = 0
		c.Position = UDim2.new(0.5, 0,0.5, 0)
		c.Size = UDim2.new(0.721, 0,0.721, 0)
		c.ZIndex = 1006
		c.Image = "rbxassetid://3642321726"
		c.ScaleType = Enum.ScaleType.Fit
		c.Visible = false
		c.Parent = b

		corner(b, UDim.new(0.3, 0))

		local function update()
			if toggle ~= true then
				return
			end

			if d.key ~= nil then
				value = mod.data.actives[d.key] == true
			end

			c.Visible = value == true
		end

		local o = {
			frame = r,
			text = t,
			button = b,
		}

		function o.set(...)
			local a = {...}

			if toggle == true then
				value = a[1] == true
				save(d, value, b, r)
				update()
			else
				b.Text = tostring(a[1] or "")
			end
		end

		function o.get()
			return value
		end

		r.MouseButton1Click:Connect(function()
			if toggle == true then
				value = not value
				update()
				save(d, value, b, r)

				--print(d.key, "=", mod.data.actives[d.key])
			else
				if d.key ~= nil and d.value ~= nil then
					mod.data.actives[d.key] = d.value
				end

				if d.callback ~= nil then
					d.callback(d.value, b, r)
				end
			end
		end)

		update()
		
		if toggle == true and d.key ~= nil then
			task.spawn(function()
				while r.Parent do
					update()
					task.wait(0.15)
				end
			end)
		end

		if d.id ~= nil then
			menu.dop_objects[d.id] = o
		end

		return o
	end
	
	local function addinput(parent, d, order)
		if parent == nil or type(d) ~= "table" then return end

		local key = d.key or "input"
		local value = mod.data.actives[key]
		if value == nil then
			value = d.value or ""
			mod.data.actives[key] = value
		end

		local r = Instance.new("Frame")
		r.Name = d.name or "Input"
		r.BackgroundColor3 = Color3.fromRGB(26, 24, 29)
		r.BackgroundTransparency = 0.2
		r.BorderSizePixel = 0
		r.Size = UDim2.new(1.025, -12, 0, 30)
		r.LayoutOrder = order or 0
		r.ZIndex = 1004
		r.Parent = parent

		r:SetAttribute("search_text", string.lower(tostring(d.text or "")))

		corner(r, UDim.new(0, 7))

		local t = Instance.new("TextLabel")
		t.Name = "Label"
		t.BackgroundTransparency = 1
		t.Position = UDim2.new(0.02, 0, 0, 0)
		t.Size = UDim2.new(0.4, 0, 1, 0)
		t.ZIndex = 1005
		t.Font = Enum.Font.BuilderSansBold
		t.Text = tostring(d.text or "Input")
		t.TextColor3 = Color3.fromRGB(255, 255, 255)
		t.TextSize = 14
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Parent = r

		local box = Instance.new("TextBox")
		box.Name = "TextBox"
		box.AnchorPoint = Vector2.new(1, 0.5)
		box.BackgroundColor3 = Color3.fromRGB(42, 40, 45)
		box.BorderSizePixel = 0
		box.Position = UDim2.new(1, -8, 0.5, 0)
		box.Size = UDim2.new(0.55, 0, 0.7, 0)
		box.ZIndex = 1005
		box.ClipsDescendants = true
		box.Font = Enum.Font.BuilderSansMedium
		box.Text = tostring(value)
		box.PlaceholderText = tostring(d.placeholder or "")
		box.PlaceholderColor3 = Color3.fromRGB(120, 120, 125)
		box.TextColor3 = Color3.fromRGB(255, 255, 255)
		box.TextSize = 13
		box.TextXAlignment = Enum.TextXAlignment.Center
		box.ClearTextOnFocus = false
		box.Parent = r

		corner(box, UDim.new(0, 6))

		local o = { frame = r, text = t, box = box }

		function o.set(...)
			local a = {...}
			box.Text = tostring(a[1] or "")
			mod.data.actives[key] = box.Text
		end

		function o.get()
			return box.Text
		end

		box:GetPropertyChangedSignal("Text"):Connect(function()
			mod.data.actives[key] = box.Text
		end)

		if d.id ~= nil then
			menu.dop_objects[d.id] = o
		end

		return o
	end

	local function addslider(...)
		local a = {...}

		if a[1] == nil or a[2] == nil then
			return
		end

		local d = a[2]
		local min = tonumber(d.min) or 0
		local max = tonumber(d.max) or 100
		local step = tonumber(d.step) or 1
		local value = tonumber(d.value) or min

		if max <= min then
			max = min + 1
		end

		if d.key ~= nil and tonumber(mod.data.actives[d.key]) ~= nil then
			value = tonumber(mod.data.actives[d.key])
		end

		local r = Instance.new("Frame")
		r.Name = d.name or "Slider"
		r.BackgroundTransparency = 0.2
		r.BorderSizePixel = 0
		r.BackgroundColor3 = Color3.fromRGB(26, 24, 29)
		r.Size = UDim2.new(1.025, -12, 0, 30)
		r.LayoutOrder = a[3] or 0
		r.ZIndex = 1004
		r.Parent = a[1]

		r:SetAttribute("search_text", string.lower(tostring(d.text or "")))

		corner(r, UDim.new(0, 7))

		local t = Instance.new("TextLabel")
		t.Name = "Text"
		t.BackgroundTransparency = 1
		t.BorderSizePixel = 0
		t.Position = UDim2.new(0.02, 0,0.26, 0)
		t.Size = UDim2.new(0.24, 0,0.5, 0)
		t.ZIndex = 1005
		t.Font = d.font or Enum.Font.BuilderSansBold
		t.Text = tostring(d.text or "Slider")
		t.TextColor3 = d.text_color or Color3.fromRGB(255, 255, 255)
		t.TextScaled = d.text_scaled ~= false
		t.TextXAlignment = Enum.TextXAlignment.Left
		t.Parent = r

		local v = Instance.new("TextLabel")
		v.Name = "Value"
		v.AnchorPoint = Vector2.new(1, 0.5)
		v.BackgroundTransparency = 1
		v.BorderSizePixel = 0
		v.Position = UDim2.new(0.97, 0,0.5, 0)
		v.Size = UDim2.new(0.12, 0,0.6, 0)
		v.ZIndex = 1005
		v.Font = d.value_font or Enum.Font.BuilderSansBold
		v.TextColor3 = d.value_color or Color3.fromRGB(255, 255, 255)
		v.TextScaled = true
		v.TextXAlignment = Enum.TextXAlignment.Right
		v.Parent = r

		local b = Instance.new("Frame")
		b.Name = "Back"
		b.AnchorPoint = Vector2.new(1, 0.5)
		b.BackgroundColor3 = d.back_color or menu.colors.button_off
		b.BorderSizePixel = 0
		b.Position = UDim2.new(0.87, 0,0.52, 0)
		b.Size = d.slider_size or UDim2.new(0.6, 0,0.24, 0)
		b.ZIndex = 1005
		b.Active = true
		b.Parent = r

		corner(b, UDim.new(1, 0))

		local fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		fill.BorderSizePixel = 0
		fill.Size = UDim2.new(0, 0, 1, 0)
		fill.ZIndex = 1006
		fill.Parent = b

		local gradient = Instance.new("UIGradient")
		gradient.Color = ColorSequence.new(
			Color3.fromRGB(194, 49, 142), -- #E72EFF
			Color3.fromRGB(242, 96, 190)  -- #FF4294
		)
		gradient.Rotation = 0
		gradient.Parent = fill

		gradient.Offset = Vector2.new(-1, 0)

		local shimmer = find.tweenservice:Create(
			gradient,
			TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
			{Offset = Vector2.new(1, 0)}
		)

		shimmer:Play()

		corner(fill, UDim.new(1, 0))

		local function setvalue(...)
			local a = {...}
			local n = math.clamp(tonumber(a[1]) or min, min, max)

			if step > 0 then
				n = math.round(n / step) * step
				n = math.clamp(n, min, max)
			end

			value = n

			local alpha = (value - min) / (max - min)
			fill.Size = UDim2.new(alpha, 0,1, 0)

			if d.format ~= nil then
				v.Text = tostring(d.format(value))
			else
				v.Text = tostring(value)
			end

			if d.key ~= nil then
				mod.data.actives[d.key] = value
			end

			if a[2] == true and d.callback ~= nil then
				d.callback(value, b, r)
			end
		end

		local function move(...)
			local a = {...}

			if b.AbsoluteSize.X <= 0 then
				return
			end

			local alpha = math.clamp((a[1] - b.AbsolutePosition.X) / b.AbsoluteSize.X, 0, 1)
			setvalue(min + ((max - min) * alpha), true)
		end

		local o = {
			frame = r,
			text = t,
			value = v,
			back = b,
			fill = fill,
		}

		function o.set(...)
			local a = {...}
			setvalue(a[1], a[2] ~= false)
		end

		function o.get()
			return value
		end

		b.InputBegan:Connect(function(input)
			if input.UserInputType ~= Enum.UserInputType.MouseButton1
				and input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end

			active_slider = move
			move(input.Position.X)
		end)

		setvalue(value, false)

		if d.id ~= nil then
			menu.dop_objects[d.id] = o
		end

		return o
	end

	local function addlistChose(parent, d, order)
		local list = d.list or mod.data.zones
		local key = d.key or "selected_field"
		local opened = d.opened == true
		local multi = d.multi == true
		
		local fields = table.create(#list)
		local cards = {}
		local valid = {}
		local search = { tostring(d.text or "Field") }

		for _, v in ipairs(list) do
			local name
			local image

			if type(v) == "table" then
				name = v.name
				image = v.image
			else
				name = v
				image = ""
			end

			if type(name) == "string" and name ~= "" then
				if name ~= "Ant Field" then
					local field = {
						name = name,
						image = tostring(image or ""),
					}
					fields[#fields + 1] = field
					valid[name] = true
					search[#search + 1] = name
				end
			end
		end
		
		local selected
		local selectedSet = nil

		if multi then
			if type(mod.data.actives[key]) ~= "table" then
				mod.data.actives[key] = {}
			end
			selectedSet = mod.data.actives[key]

			if selectedSet.__init ~= true then
				for _, field in ipairs(fields) do
					selectedSet[field.name] = true
				end
				selectedSet.__init = true
			end
		else
			selected = d.value
			if selected == nil then
				selected = mod.data.actives[key]
			end
			if selected == false or selected == "" then
				selected = nil
			end

			if selected ~= nil and valid[selected] ~= true then
				selected = nil
			end

			mod.data.actives[key] = selected or false
		end

		local r = Instance.new("Frame")
		r.Name = d.name or "Preview"
		r.BackgroundColor3 = Color3.fromRGB(26, 24, 29)
		r.AutomaticSize = Enum.AutomaticSize.Y
		r.BackgroundTransparency = 0.2
		r.BorderSizePixel = 0
		r.Size = UDim2.new(1.025, -12, 0, 30)
		r.LayoutOrder = order or 0
		r.ZIndex = 1004
		r.Parent = parent

		r:SetAttribute(
			"search_text",
			string.lower(table.concat(search, " "))
		)

		corner(r, UDim.new(0, 7))

		local ll = Instance.new("UIListLayout")
		ll.SortOrder = Enum.SortOrder.LayoutOrder
		ll.Padding = UDim.new(0, 5)
		ll.FillDirection = Enum.FillDirection.Vertical
		ll.HorizontalAlignment = Enum.HorizontalAlignment.Center
		ll.VerticalAlignment = Enum.VerticalAlignment.Top
		ll.Parent = r

		local ms = Instance.new("UIShadow")
		ms.BlurRadius = UDim.new(0.1, 0)
		ms.Color = Color3.fromRGB(0, 0, 0)
		ms.Transparency = 0.8
		ms.Parent = r

		--local h = Instance.new("TextButton")
		--h.Name = "Header"
		--h.BackgroundTransparency = 1
		--h.BorderSizePixel = 0
		--h.AutoButtonColor = true
		--h.Size = d.header_size or UDim2.new(0.96, 0, 0, 32)
		--h.LayoutOrder = 0
		--h.ZIndex = 1004
		--h.Font = Enum.Font.BuilderSansBold
		--h.TextColor3 = Color3.fromRGB(255, 255, 255)
		--h.TextSize = 15
		--h.TextTruncate = Enum.TextTruncate.AtEnd
		--h.TextXAlignment = Enum.TextXAlignment.Left
		--h.Parent = r
		
		local useHeaderIcon = d.header_icon == true
		local headerSize = d.header_size

		if headerSize == nil then
			if useHeaderIcon then
				headerSize = UDim2.new(0.962, 0,0, 32) -- icon
			else
				headerSize = UDim2.new(0.962, 0,0, 32)
			end
		end

		local h = Instance.new("TextButton")
		h.Name = "Header"
		h.BackgroundTransparency = 1
		h.BorderSizePixel = 0
		h.AutoButtonColor = true
		h.Size = headerSize
		h.LayoutOrder = 0
		h.ZIndex = 1004
		h.Font = Enum.Font.BuilderSansBold
		h.TextColor3 = Color3.fromRGB(255, 255, 255)
		h.TextSize = 15
		h.TextTruncate = Enum.TextTruncate.AtEnd
		h.TextXAlignment = Enum.TextXAlignment.Left
		h.Parent = r

		local headerIcon
		if useHeaderIcon then
			headerIcon = Instance.new("ImageLabel")
			headerIcon.Name = "HeaderIcon"
			headerIcon.AnchorPoint = Vector2.new(0, 0.5)
			headerIcon.BackgroundTransparency = 1
			headerIcon.BorderSizePixel = 0
			headerIcon.Position = UDim2.new(-0.012, 6,0.5, 0)
			headerIcon.Size = UDim2.fromOffset(21, 21)
			headerIcon.Image = ""
			headerIcon.ImageColor3 = Color3.fromRGB(255, 255, 255)
			headerIcon.ScaleType = Enum.ScaleType.Fit
			headerIcon.Visible = false
			headerIcon.ZIndex = 1006
			headerIcon.Parent = h
		end

		--local hp = Instance.new("UIPadding")
		--hp.PaddingRight = UDim.new(0, 34)
		--hp.Parent = h

		local h2 = Instance.new("TextButton")
		h2.Name = "Arrow"
		h2.BackgroundColor3 = Color3.fromRGB(24, 23, 25)
		h2.BackgroundTransparency = 0
		h2.AnchorPoint = Vector2.new(0, 0)
		h2.Interactable = false
		h2.BorderSizePixel = 0
		h2.Position = UDim2.new(0.967, 0,0.138, 0)
		h2.Size = UDim2.new(0.05, 0,0.723, 0)
		h2.ZIndex = 1005
		h2.Font = Enum.Font.BuilderSansExtraBold
		h2.Text = "<"
		h2.TextColor3 = Color3.fromRGB(255, 255, 255)
		h2.TextScaled = true
		h2.Parent = h

		corner(h2, d.radius or UDim.new(0.4, 0))

		local r1 = Instance.new("Frame")
		r1.Name = "Rows"
		r1.AutomaticSize = Enum.AutomaticSize.Y
		r1.BackgroundTransparency = 1
		r1.Size = UDim2.new(1, 0, 0, 0)
		r1.LayoutOrder = 1
		r1.ZIndex = 1004
		r1.Visible = opened
		r1.Parent = r

		local rl = Instance.new("UIListLayout")
		rl.SortOrder = Enum.SortOrder.LayoutOrder
		rl.Padding = UDim.new(0, 5)
		rl.Wraps = true
		rl.FillDirection = Enum.FillDirection.Horizontal
		rl.HorizontalAlignment = Enum.HorizontalAlignment.Left
		rl.VerticalAlignment = Enum.VerticalAlignment.Top
		rl.Parent = r1

		local rp = Instance.new("UIPadding")
		rp.PaddingLeft = UDim.new(0, 6)
		rp.PaddingRight = UDim.new(0, 6)
		rp.PaddingBottom = UDim.new(0, 7)
		rp.Parent = r1

		--local function updateHeader()
		--	h.Text = tostring(d.text or "Field")
		--		.. ": "
		--		.. tostring(selected or "NONE")
		--end
		
		local function updateHeader()
			local label

			if multi then
				local total = #fields
				local count = 0
				for _, f in ipairs(fields) do
					if selectedSet[f.name] then count = count + 1 end
				end
				label = tostring(d.text or "Field") .. ": " .. count .. "/" .. total
			else
				label = tostring(d.text or "Field") .. ": " .. tostring(selected or "Not Selected")
			end

			h.TextXAlignment = Enum.TextXAlignment.Left
			h.Size = UDim2.new(0.962, 0, 0, 32)

			if headerIcon then
				h.Text = "          " .. label
			else
				h.Text = label
			end

			if not useHeaderIcon or not headerIcon then return end

			local selectedImage = ""
			if selected ~= nil then
				for _, v in ipairs(list) do
					local vname = type(v) == "table" and v.name or v
					if vname == selected then
						selectedImage = type(v) == "table"
							and tostring(v.image or "") or ""
						break
					end
				end
			end

			local hasRealImage = selectedImage ~= ""
				and selectedImage ~= "rbxassetid://0"

			headerIcon.Image = hasRealImage
				and selectedImage
				or "rbxassetid://1554410815"

			headerIcon.ImageColor3 = hasRealImage
				and Color3.fromRGB(255, 255, 255)
				or Color3.fromRGB(120, 120, 125)

			headerIcon.Visible = true

			h.TextXAlignment = Enum.TextXAlignment.Left
			h.Size = UDim2.new(0.962, 0,0, 32)
		end

		local function updateOpened()
			h2.Text = opened == true and "<" or ">"
			r1.Visible = opened
		end

		local function updateCard(card, state)
			if card == nil then
				return
			end

			card.root.BackgroundColor3 = state == true
				and Color3.fromRGB(37, 35, 39)
				or Color3.fromRGB(26, 24, 29)

			card.root.BackgroundTransparency = state == true and 0 or 0.2

			card.button.BackgroundColor3 = state == true
				and Color3.fromRGB(68, 63, 75)
				or Color3.fromRGB(42, 40, 45)

			card.check.Visible = state == true
		end

		local function selectField(name)
			if multi then
				selectedSet[name] = not selectedSet[name]
				updateCard(cards[name], selectedSet[name] == true)
				updateHeader()
				if type(d.changed) == "function" then d.changed(selectedSet) end
				return
			end
			
			local old = selected
			local new = name
			if selected == name and d.allow_none ~= false then new = nil end
			if old == new then return end

			selected = new
			mod.data.actives[key] = selected or false
			if old ~= nil then updateCard(cards[old], false) end
			if selected ~= nil then updateCard(cards[selected], true) end
			updateHeader()
			if type(d.changed) == "function" then d.changed(selected) end
		end

		local function create(field, layout)
			local b = Instance.new("TextButton")
			b.Name = field.name
			b.BackgroundColor3 = Color3.fromRGB(26, 24, 29)
			b.BackgroundTransparency = 0.2
			b.BorderSizePixel = 0
			b.Size = UDim2.new(0.333, -8, 0, 32)
			b.LayoutOrder = layout
			b.AutoButtonColor = true
			b.ZIndex = 1004
			b.Text = ""
			b.Parent = r1

			b:SetAttribute(
				"search_text",
				string.lower(field.name)
			)

			corner(b, UDim.new(0, 7))

			local hasRealFieldImage = field.image ~= ""
				and field.image ~= "rbxassetid://0"

			local icon = Instance.new("ImageLabel")
			icon.Name = "Icon"
			icon.AnchorPoint = Vector2.new(0, 0.5)
			icon.BackgroundTransparency = 1
			icon.BorderSizePixel = 0
			icon.Position = UDim2.new(0, 6, 0.5, 0)
			icon.Size = UDim2.fromOffset(21, 21)
			icon.ZIndex = 1006
			icon.Image = hasRealFieldImage
				and field.image
				or "rbxassetid://1554410815"
			icon.ImageColor3 = hasRealFieldImage
				and Color3.fromRGB(255, 255, 255)
				or Color3.fromRGB(120, 120, 125)
			icon.ScaleType = Enum.ScaleType.Fit
			icon.Visible = true
			icon.Parent = b

			local t = Instance.new("TextLabel")
			t.Name = "TextLabel"
			t.BackgroundTransparency = 1
			t.BorderSizePixel = 0
			t.Position = UDim2.new(0, 32, 0, 0)
			t.Size = UDim2.new(1, -62, 1, 0)
			t.ZIndex = 1005
			t.Font = Enum.Font.BuilderSansMedium
			t.Text = field.name
			t.TextColor3 = Color3.fromRGB(255, 255, 255)
			t.TextSize = 13
			t.TextTruncate = Enum.TextTruncate.AtEnd
			t.TextXAlignment = Enum.TextXAlignment.Left
			t.Parent = b

			local h3 = Instance.new("Frame")
			h3.Name = "Selected"
			h3.AnchorPoint = Vector2.new(1, 0.5)
			h3.BackgroundColor3 = Color3.fromRGB(42, 40, 45)
			h3.BorderSizePixel = 0
			h3.Position = UDim2.new(1, -5, 0.5, 0)
			h3.Size = UDim2.fromOffset(23, 23)
			h3.ZIndex = 1005
			h3.Parent = b

			corner(h3, UDim.new(0.3, 0))

			local check = Instance.new("ImageLabel")
			check.Name = "Check"
			check.AnchorPoint = Vector2.new(0.5, 0.5)
			check.BackgroundTransparency = 1
			check.BorderSizePixel = 0
			check.Position = UDim2.fromScale(0.5, 0.5)
			check.Size = UDim2.fromScale(0.72, 0.72)
			check.ZIndex = 1006
			check.Image = "rbxassetid://3642321726"
			check.ScaleType = Enum.ScaleType.Fit
			check.Visible = false
			check.Parent = h3

			local card = {
				root = b,
				button = h3,
				check = check,
			}

			cards[field.name] = card

			updateCard(
				card,
				(multi and selectedSet[field.name] == true) or (not multi and selected == field.name)
			)

			b.MouseButton1Click:Connect(function()
				selectField(field.name)
			end)
		end

		for i, field in ipairs(fields) do
			create(field, i)
		end

		h.MouseButton1Click:Connect(function()
			opened = not opened
			--print(opened)
			updateOpened()
		end)
		
		h2.MouseButton1Click:Connect(function()
			opened = not opened
			--print(opened)
			updateOpened()
		end)

		updateHeader()
		updateOpened()

		return r1
	end
	
	local function addtokenpriority(parent, d, order)
		if parent == nil or type(d) ~= "table" then
			return
		end

		local list = d.list or mod.data.tokens or {}
		local key = d.key or "token_priorities"
		local defaultPriority = d.default_priority or 0

		local priorities = mod.data.actives[key]
		if type(priorities) ~= "table" then
			priorities = {}
			mod.data.actives[key] = priorities
		end

		for _, v in ipairs(list) do
			local name = type(v) == "table" and v.name or v
			if type(name) == "string" and name ~= "" and priorities[name] == nil then
				priorities[name] = defaultPriority
			end
		end

		local r = Instance.new("Frame")
		r.Name = d.name or "TokenPriority"
		r.BackgroundColor3 = Color3.fromRGB(26, 24, 29)
		r.BackgroundTransparency = 0.2
		r.AutomaticSize = Enum.AutomaticSize.Y
		r.BorderSizePixel = 0
		r.Size = UDim2.new(1.025, -12, 0, 30)
		r.LayoutOrder = order or 0
		r.ZIndex = 1004
		r.Parent = parent

		r:SetAttribute("search_text", string.lower(tostring(d.text or "")))

		corner(r, UDim.new(0, 7))

		local ll = Instance.new("UIListLayout")
		ll.SortOrder = Enum.SortOrder.LayoutOrder
		ll.Padding = UDim.new(0, 5)
		ll.FillDirection = Enum.FillDirection.Vertical
		ll.HorizontalAlignment = Enum.HorizontalAlignment.Center
		ll.VerticalAlignment = Enum.VerticalAlignment.Top
		ll.Parent = r

		local ms = Instance.new("UIShadow")
		ms.BlurRadius = UDim.new(0.1, 0)
		ms.Color = Color3.fromRGB(0, 0, 0)
		ms.Transparency = 0.8
		ms.Parent = r

		local h = Instance.new("TextButton")
		h.Name = "Header"
		h.BackgroundTransparency = 1
		h.BorderSizePixel = 0
		h.Size = d.header_size or UDim2.new(0.96, 0, 0, 32)
		h.LayoutOrder = 0
		h.ZIndex = 1004
		h.Font = Enum.Font.BuilderSansBold
		h.Text = tostring(d.text or "Token Priority")
		h.TextColor3 = Color3.fromRGB(255, 255, 255)
		h.TextSize = 15
		h.TextXAlignment = Enum.TextXAlignment.Left
		h.Parent = r

		local h2 = Instance.new("TextButton")
		h2.Name = "Arrow"
		h2.BackgroundColor3 = Color3.fromRGB(24, 23, 25)
		h2.AnchorPoint = Vector2.new(0, 0)
		h2.Interactable = false
		h2.BorderSizePixel = 0
		h2.Position = UDim2.new(0.967, 0,0.138, 0)
		h2.Size = UDim2.new(0.05, 0, 0.723, 0)
		h2.ZIndex = 1005
		h2.Font = Enum.Font.BuilderSansExtraBold
		h2.Text = "<"
		h2.TextColor3 = Color3.fromRGB(255, 255, 255)
		h2.TextScaled = true
		h2.Parent = h

		corner(h2, UDim.new(0.4, 0))

		local r1 = Instance.new("Frame")
		r1.Name = "Rows"
		r1.AutomaticSize = Enum.AutomaticSize.Y
		r1.BackgroundTransparency = 1
		r1.Size = UDim2.new(1, 0, 0, 0)
		r1.LayoutOrder = 1
		r1.ZIndex = 1004
		r1.Visible = d.opened ~= false
		r1.Parent = r

		local rl = Instance.new("UIListLayout")
		rl.SortOrder = Enum.SortOrder.LayoutOrder
		rl.Padding = UDim.new(0, 5)
		rl.Wraps = true
		rl.FillDirection = Enum.FillDirection.Horizontal
		rl.HorizontalAlignment = Enum.HorizontalAlignment.Left
		rl.VerticalAlignment = Enum.VerticalAlignment.Top
		rl.Parent = r1

		local rp = Instance.new("UIPadding")
		rp.PaddingLeft = UDim.new(0, 6)
		rp.PaddingRight = UDim.new(0, 6)
		rp.PaddingBottom = UDim.new(0, 7)
		rp.Parent = r1

		h.MouseButton1Click:Connect(function()
			r1.Visible = not r1.Visible
			h2.Text = r1.Visible and "<" or ">"
		end)

		h2.MouseButton1Click:Connect(function()
			r1.Visible = not r1.Visible
			h2.Text = r1.Visible and "<" or ">"
		end)

		local function rebuild()
			local items = {}
			for _, v in ipairs(list) do
				local name = type(v) == "table" and v.name or v
				local image = type(v) == "table" and (v.image or "") or ""
				if type(name) == "string" and name ~= "" then
					items[#items + 1] = {
						name = name,
						image = image,
						priority = tonumber(priorities[name]) or 0,
					}
				end
			end

			table.sort(items, function(a, b)
				if a.priority ~= b.priority then
					return a.priority > b.priority
				end
				return a.name < b.name
			end)

			for _, child in ipairs(r1:GetChildren()) do
				if child:IsA("Frame") then
					child:Destroy()
				end
			end

			for i, item in ipairs(items) do
				local row = Instance.new("Frame")
				row.Name = item.name
				row.BackgroundColor3 = Color3.fromRGB(26, 24, 29)
				row.BackgroundTransparency = 0.2
				row.BorderSizePixel = 0
				row.Size = UDim2.new(0.333, -8,0, 32)
				row.LayoutOrder = i
				row.ZIndex = 1004
				row.Parent = r1

				corner(row, UDim.new(0, 7))

				local rp2 = Instance.new("UIPadding")
				rp2.PaddingLeft = UDim.new(0, 8)
				rp2.PaddingRight = UDim.new(0, 6)
				rp2.Parent = row

				if item.image ~= "" then
					local icon = Instance.new("ImageLabel")
					icon.Name = "Icon"
					icon.BackgroundTransparency = 1
					icon.BorderSizePixel = 0
					icon.Position = UDim2.new(0, 0, 0.5, -9)
					icon.Size = UDim2.fromOffset(18, 18)
					icon.Image = item.image
					icon.ScaleType = Enum.ScaleType.Fit
					icon.ZIndex = 1006
					icon.Parent = row
				end

				local nameLabel = Instance.new("TextLabel")
				nameLabel.Name = "NameLabel"
				nameLabel.BackgroundTransparency = 1
				nameLabel.BorderSizePixel = 0
				nameLabel.Position = UDim2.new(0, item.image ~= "" and 24 or 0, 0, 0)
				nameLabel.Size = UDim2.new(1, item.image ~= "" and -66 or -42, 1, 0)
				nameLabel.ZIndex = 1005
				nameLabel.Font = Enum.Font.BuilderSansMedium
				nameLabel.Text = item.name
				nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				nameLabel.TextSize = 14
				nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
				nameLabel.TextXAlignment = Enum.TextXAlignment.Left
				nameLabel.Parent = row

				local pbox = Instance.new("TextBox")
				pbox.Name = "PriorityBox"
				pbox.AnchorPoint = Vector2.new(1, 0.5)
				pbox.BackgroundColor3 = Color3.fromRGB(42, 40, 45)
				pbox.BorderSizePixel = 0
				pbox.Position = UDim2.new(1, 0, 0.5, 0)
				pbox.Size = UDim2.fromOffset(36, 22)
				pbox.ZIndex = 1005
				pbox.Font = Enum.Font.BuilderSansBold
				pbox.Text = tostring(item.priority)
				pbox.TextColor3 = Color3.fromRGB(255, 255, 255)
				pbox.TextSize = 13
				pbox.TextXAlignment = Enum.TextXAlignment.Center
				pbox.ClearTextOnFocus = false
				pbox.Parent = row

				corner(pbox, UDim.new(0.3, 0))

				pbox:GetPropertyChangedSignal("Text"):Connect(function()
					local txt = pbox.Text
					local filtered = string.gsub(txt, "[^%d%-]", "")
					if filtered ~= txt then
						pbox.Text = filtered
					end
				end)

				pbox.FocusLost:Connect(function()
					local num = tonumber(pbox.Text)
					if num == nil then num = 0 end
					num = math.floor(num)

					priorities[item.name] = num

					if type(d.changed) == "function" then
						d.changed(priorities)
					end

					rebuild()
				end)
			end
		end

		rebuild()
		return r
	end

	local function additem(...)
		local a = {...}

		if a[1] == nil or a[2] == nil then
			return
		end

		local type = string.lower(tostring(a[2].type or "text"))

		if type == "button" then
			return addbutton(a[1], a[2], a[3])
		elseif type == "slider" then
			return addslider(a[1], a[2], a[3])
		elseif type == "addlistchose" then
			return addlistChose(a[1], a[2], a[3])
		elseif type == "tokenpriority" then
			return addtokenpriority(a[1], a[2], a[3])
		elseif type == "input" then
			return addinput(a[1], a[2], a[3])
		else
			return addtext(a[1], a[2], a[3])
		end
	end

	local function addlist(...)
		local a = {...}

		if a[1] == nil or a[2] == nil then
			return
		end

		local d = a[2]
		local opened = d.opened ~= false

		local l = Instance.new("Frame")
		l.Name = "List-" .. tostring(d.name or a[3] or "List")
		l.AutomaticSize = Enum.AutomaticSize.Y
		l.BackgroundColor3 = Color3.fromRGB(28, 26, 31)
		l.BackgroundTransparency = 0.6
		l.BorderSizePixel = 0
		l.Size = d.size or UDim2.new(1, -12,0, 36)
		l.LayoutOrder = a[3] or 0
		l.ZIndex = 1003
		l.ClipsDescendants = false
		l.Parent = a[1]

		local c = Instance.new("UICorner")
		c.CornerRadius = d.radius or UDim.new(0, 9)
		c.Parent = l

		local ll = Instance.new("UIListLayout")
		ll.SortOrder = Enum.SortOrder.LayoutOrder
		ll.Padding = UDim.new(0, 5)
		ll.FillDirection = Enum.FillDirection.Vertical
		ll.HorizontalAlignment = Enum.HorizontalAlignment.Center
		ll.VerticalAlignment = Enum.VerticalAlignment.Top
		ll.Parent = l

		local ms = Instance.new("UIShadow")
		ms.Parent = l
		ms.BlurRadius = UDim.new(0.1, 0)
		ms.Color = Color3.fromRGB(0, 0, 0)
		ms.Transparency = 0.8

		local h = Instance.new("TextButton")
		h.Name = "Header"
		h.BackgroundTransparency = 1
		h.BorderSizePixel = 0
		h.Size = d.header_size or UDim2.new(0.976, 0,0, 32)
		h.LayoutOrder = 0
		h.ZIndex = 1004
		h.Text = tostring(d.name or a[3] or "List")
		h.Font = Enum.Font.BuilderSansBold
		h.TextColor3 = Color3.fromRGB(255, 255, 255)
		h.TextScaled = false
		h.TextSize = 18
		h.TextXAlignment = Enum.TextXAlignment.Left
		h.Parent = l

		local h2 = Instance.new("TextButton")
		h2.Name = "TextButton"
		h2.BackgroundColor3 = Color3.fromRGB(24, 23, 25)
		h2.BackgroundTransparency = 0
		h2.BorderSizePixel = 0
		h2.Position = UDim2.new(0.949, 0,0.138, 0)
		h2.Size = UDim2.new(0.05, 0,0.723, 0)
		h2.ZIndex = 1005
		h2.Font = Enum.Font.BuilderSansExtraBold
		h2.Text = "<"
		h2.TextColor3 = Color3.fromRGB(255, 255, 255)
		h2.TextScaled = true
		h2.Parent = h

		local c1 = Instance.new("UICorner")
		c1.CornerRadius = d.radius or UDim.new(0.4, 0)
		c1.Parent = h2
		
		-- Dynamic header (icons + text)
		if d.header_dynamic then
			h.Text = ""

			local dynHolder = Instance.new("Frame")
			dynHolder.Name = "DynHolder"
			dynHolder.BackgroundTransparency = 1
			dynHolder.Position = UDim2.new(0, 8, 0, 0)
			dynHolder.Size = UDim2.new(0.9, -8, 1, 0)
			dynHolder.ZIndex = 1005
			dynHolder.ClipsDescendants = true
			dynHolder.Parent = h

			local dhl = Instance.new("UIListLayout")
			dhl.SortOrder = Enum.SortOrder.LayoutOrder
			dhl.Padding = UDim.new(0, 6)
			dhl.FillDirection = Enum.FillDirection.Horizontal
			dhl.VerticalAlignment = Enum.VerticalAlignment.Center
			dhl.HorizontalAlignment = Enum.HorizontalAlignment.Left
			dhl.Parent = dynHolder

			local function refreshHeader()
				for _, c in ipairs(dynHolder:GetChildren()) do
					if c:IsA("ImageLabel") or c:IsA("TextLabel") then
						c:Destroy()
					end
				end

				local info = d.header_dynamic()
				if type(info) ~= "table" or type(info.elements) ~= "table" then return end

				for idx, el in ipairs(info.elements) do
					if el.type == "text" and el.value and tostring(el.value) ~= "" then
						local t = Instance.new("TextLabel")
						t.BackgroundTransparency = 1
						t.AutomaticSize = Enum.AutomaticSize.X
						t.Size = UDim2.new(0, 0, 1, 0)
						t.Font = Enum.Font.BuilderSansBold
						t.Text = tostring(el.value)
						t.TextColor3 = el.color or Color3.fromRGB(255, 255, 255)
						t.TextSize = 16
						t.TextXAlignment = Enum.TextXAlignment.Left
						t.ZIndex = 1005
						t.LayoutOrder = idx
						t.Parent = dynHolder
					elseif el.type == "icon" then
						local img = el.value
						local isReal = img and img ~= "" and img ~= "rbxassetid://0"

						local i = Instance.new("ImageLabel")
						i.BackgroundTransparency = 1
						i.Size = UDim2.fromOffset(21, 21)
						i.Image = isReal and img or "rbxassetid://1554410815"
						i.ImageColor3 = isReal
							and Color3.fromRGB(255, 255, 255)
							or Color3.fromRGB(120, 120, 125)
						i.ScaleType = Enum.ScaleType.Fit
						i.ZIndex = 1006
						i.LayoutOrder = idx
						i.Parent = dynHolder
					end
				end
			end

			refreshHeader()

			if d._ref then
				d._ref.refresh = refreshHeader
			end
		end

		local r = Instance.new("Frame")
		r.Name = "Rows"
		r.AutomaticSize = Enum.AutomaticSize.Y
		r.BackgroundTransparency = 1
		r.Size = UDim2.new(1, 0,0, 0)
		r.LayoutOrder = 1
		r.ZIndex = 1004
		r.Visible = opened
		r.Parent = l

		local rl = Instance.new("UIListLayout")
		rl.SortOrder = Enum.SortOrder.LayoutOrder
		rl.Padding = UDim.new(0, 5)
		rl.Wraps = true
		rl.FillDirection = Enum.FillDirection.Horizontal
		rl.HorizontalAlignment = Enum.HorizontalAlignment.Left
		rl.VerticalAlignment = Enum.VerticalAlignment.Top
		rl.Parent = r

		local rp = Instance.new("UIPadding")
		rp.PaddingLeft = UDim.new(0, 6)
		rp.PaddingRight = UDim.new(0, 6)
		rp.PaddingBottom = UDim.new(0, 7)
		rp.PaddingTop = UDim.new(0, 0)
		rp.Parent = r

		local function update()
			h2.Text = opened == true and "<" or ">"
			r.Visible = opened
		end

		h.MouseButton1Click:Connect(function()
			opened = not opened
			update()
		end)

		h2.MouseButton1Click:Connect(function()
			opened = not opened
			update()
		end)

		for i, v in ipairs(d.items or {}) do
			additem(r, v, i)
		end

		update()
		return l
	end

	local function addsection(...)
		local a = {...}

		if a[1] == nil then
			return
		end

		local p = Instance.new("ScrollingFrame")
		p.Name = "Section-" .. tostring(a[1])
		p.BackgroundTransparency = 1
		p.BorderSizePixel = 0
		p.Position = UDim2.new(0, 6,0, 8)
		p.Size = UDim2.new(1, -12,1, -16)
		p.ZIndex = 1002
		p.Visible = false
		p.ClipsDescendants = true
		p.AutomaticCanvasSize = Enum.AutomaticSize.Y
		p.CanvasSize = UDim2.new()
		p.ScrollBarImageColor3 = Color3.fromRGB(30, 30, 33)
		p.ScrollBarThickness = 5
		p.ScrollingDirection = Enum.ScrollingDirection.Y
		p.Parent = m

		local pl = Instance.new("UIListLayout")
		pl.SortOrder = Enum.SortOrder.LayoutOrder
		pl.Padding = UDim.new(0, 8)
		pl.FillDirection = Enum.FillDirection.Vertical
		pl.HorizontalAlignment = Enum.HorizontalAlignment.Center
		pl.VerticalAlignment = Enum.VerticalAlignment.Top
		pl.Parent = p

		sections[a[1]] = p
		return p
	end

	local setting = {
		{
			name = "Farming",
			lists = {
				{
					name = "Farming",
					opened = true,
					items = {
						--{ type = "button", text = "Field", toggle = false, button_text = "SELECT", callback = function() end },
						--{ type = "button", text = "Movement Method", toggle = false, button_text = "WALK", callback = function() end },
						{ type = "button", text = "Auto Farm", key = "auto_farm", callback = mod.farming.farm},
						{
							type = "button",
							text = "Auto Sprinkler",
							key = "auto_sprinkler",
							--callback = mod.farming.autosprinkler,
						},
						{ type = "button", text = "Auto Dig", key = "auto_dig", callback = mod.farming.autoDig},
						{
							type = "addlistchose",
							text = "Field",
							key = "selected_field",
							allow_none = false,
							header_icon = true,
							changed = function()
								if mod.data.actives.auto_farm then
									mod.farming.farm()
								end
							end,
						},
						{
							type = "addlistchose",
							text = "Farm In",
							key = "position_field",
							list = mod.data.positions,
							allow_none = false,
							header_icon = true,
							changed = function()
								if mod.data.actives.auto_farm then
									mod.farming.farm()
								end
							end,
						},
						{
							type = "tokenpriority",
							text = "Token Priority",
							key = "token_priorities",
							list = mod.data.all_tokens,
							opened = false,
							header_icon = false,
							changed = function()
								if mod.data.actives.auto_farm then
									mod.farming.farm()
								end
							end,
						},
					},
				},
				{
					name = "Convert Honey",
					opened = true,
					items = {
						{ type = "button", text = "Convert Balloon", key = "balloon"},
						{ type = "button", text = "Honey Mask", key = "honey_mask"},
						{
							type = "addlistchose",
							text = "Standart Mask",
							key = "mask",
							list = mod.data.mask,
							allow_none = false,
							header_icon = true,
						},
						{
							type = "slider",
							text = "Backpack %(MAX)",
							key = "backpack",
							min = 10,
							max = 100,
							step = 1,
						},
						{
							type = "slider",
							text = "Auto Convert(Minutes)",
							key = "auto_convert",
							min = 1,
							max = 120,
							step = 1,
						},
					},
				},
				{
					name = "Farm Settings",
					opened = true,
					items = {
						{ type = "button", text = "Collect Bubbles", key = "collect_bubbles"},
						{ type = "button", text = "Hide Decorations", key = "hide_decorations", callback = farming.hideDecorations },
						{ type = "button", text = "Lines", key = "lines" },
					},
				},
				--{
				--	name = "Planters",
				--	opened = true,
				--	items = {
						
				--	},
				--},
				{
					name = "More AUTO",
					opened = true,
					items = {
						{ type = "button", text = "Pushrooms", key = "pushrooms_enabled"},
						{ type = "button", text = "Petals", key = "petals"},
						{ type = "button", text = "Sprouts", key = "sprouts"},
						{
							type = "addlistchose",
							text = "Pushrooms List",
							key = "pushrooms",
							list = mod.data.pushrooms,
							allow_none = false,
						},
						{
							type = "addlistchose",
							text = "Petal Colors",
							key = "petal_colors",
							multi = true,
							allow_none = true,
							header_icon = false,
							list = {
								{ name = "Red" }, { name = "Blue" }, { name = "White" }, { name = "Green" },
								{ name = "Black" }, { name = "Yellow" }, { name = "Scarlet" }, { name = "Cyan" },
								{ name = "Grey" }, { name = "Violet" }, { name = "Pink" }, { name = "Merigold" },
								{ name = "Periwinkle" },
							},
						},
					},
				},
			},
		},
		{
			name = "Config",
			lists = {
				{
					name = "Server Settings",
					opened = true,
					items = {
						{ type = "button", text = "Auto Rejoin", key = "auto_rejoin" },
						{
							type = "button",
							text = "Free Server",
							key = "server_free",
							id = "server_free",
							callback = function(v)
								if v == true then
									local other = menu.dop_objects and menu.dop_objects["server_private"]
									if other and other.get() then other.set(false) end
									mod.data.actives["server_mode"] = "free"
								else
									if mod.data.actives["server_mode"] == "free" then
										mod.data.actives["server_mode"] = nil
									end
								end
							end,
						},
						{
							type = "button",
							text = "Private Server",
							key = "server_private",
							id = "server_private",
							callback = function(v)
								if v == true then
									local other = menu.dop_objects and menu.dop_objects["server_free"]
									if other and other.get() then other.set(false) end
									mod.data.actives["server_mode"] = "private"
								else
									if mod.data.actives["server_mode"] == "private" then
										mod.data.actives["server_mode"] = nil
									end
								end
							end,
						},
						{
							type = "input",
							text = "Private URL",
							key = "private_server_link",
							placeholder = "your URL private server",
						},
					},
				},
				{
					name = "Hive Settings",
					opened = true,
					items = {
						{ type = "button", text = "Auto Hive", key = "autohive", callback = mod.farming.autoHive},
						{ type = "button", text = "Anti AFK", key = "anti_afk" },
						{
							type = "addlistchose",
							text = "Hive Target",
							key = "hive_choice",
							list = mod.farming.getHiveList(),
							allow_none = false,
							header_icon = false,
							changed = function()
								if mod.data.actives["auto_farm"] == true
									and mod.farming.getHive() == nil
								then
									mod.farming.autoHive()
								end
							end,
						},
					},
				},
				{
					name = "Farm",
					opened = true,
					items = {
						{
							type = "addlistchose",
							text = "Movement Method",
							key = "style_auto_farm",
							list = mod.data.other,
							allow_none = false,
							header_icon = true,
						},
						{
							type = "slider",
							text = "WalkSpeed",
							key = "walkspeed",
							min = 16,
							max = 100,
							step = 1,

							callback = function(value)
								if mod.farming and mod.farming.forceWalkSpeed then
									mod.farming.forceWalkSpeed(value)
								end
							end,
						},
					},
				},
				--{
				--	name = "Plus",
				--	opened = true,
				--	items = {
				--		{ type = "button", text = "Anti AFK", key = "anti_afk" },
				--	},
				--},
			},
		},
		{
			name = "Toys",
			lists = {
				{
					name = "Mondo Chicken",
					opened = true,
					items = {
						{ type = "button", text = "Kill Mondo", key = "mondo" },
						{ type = "button", text = "Collect Drop", key = "mondo_collect_drop", value = true },
						{
							type = "slider",
							text = "Drop Time Collect(s)",
							key = "mondo_collect_time",
							value = 40,
							min = 1,
							max = 60,
							step = 1,
						},
					},
				},
				{
					name = "Other",
					opened = true,
					items = {
						{ type = "button", text = "Wealth Clock", key = "weatlh_clock", callback = farming.wealthClock},
						{ type = "button", text = "Save Mode", key = "save_mode"},
					},
				},
			},
		},
		--{
		--	name = "Home",
		--	lists = {
		--		{
		--			name = "Home",
		--			opened = true,
		--			items = {
		--				{ type = "text", text = "Honey"},
		--			},
		--		},
		--	},
		--},
	}
	
	-- Плантеры
	local planterOptions = {
		{ name = "Paper Planter",         image = "rbxassetid://8310368347" },
		{ name = "Ticket Planter",        image = "rbxassetid://8346910600" },
		{ name = "Sticker Planter",       image = "rbxassetid://15742519363" },
		{ name = "Festive Planter",       image = "rbxassetid://8310370747" },
		{ name = "Plastic Planter",       image = "rbxassetid://8284592873" },
		{ name = "Candy Planter",         image = "rbxassetid://8284643507" },
		{ name = "Red Clay Planter",      image = "rbxassetid://8284644329" },
		{ name = "Blue Clay Planter",     image = "rbxassetid://8284645953" },
		{ name = "Tacky Planter",         image = "rbxassetid://8284648621" },
		{ name = "Pesticide Planter",     image = "rbxassetid://8284650236" },
		{ name = "Heat-Treated Planter",  image = "rbxassetid://8284652694" },
		{ name = "Hydroponic Planter",    image = "rbxassetid://8284655951" },
		{ name = "Petal Planter",         image = "rbxassetid://8284657454" },
		{ name = "The Planter Of Plenty", image = "rbxassetid://8310373847" },
	}

	local planterTimeMap = {
		["Paper Planter"]         = 1,
		["Ticket Planter"]        = 2,
		["Sticker Planter"]       = 3,
		["Festive Planter"]       = 4,
		["Plastic Planter"]       = 2,
		["Candy Planter"]         = 4,
		["Red Clay Planter"]      = 6,
		["Blue Clay Planter"]     = 6,
		["Tacky Planter"]         = 8,
		["Pesticide Planter"]     = 10,
		["Heat-Treated Planter"]  = 12,
		["Hydroponic Planter"]    = 12,
		["Petal Planter"]         = 14,
		["The Planter Of Plenty"] = 16,
	}

	local planterFieldList = mod.data.planter_fields or mod.data.zones
	local slotRefs = {}

	local function findPlanterImageByName(name)
		for _, p in ipairs(planterOptions) do
			if p.name == name then return p.image end
		end
		return ""
	end

	local function findFieldImageByName(name)
		for _, p in ipairs(planterFieldList) do
			local pn = type(p) == "table" and p.name or p
			if pn == name then
				return type(p) == "table" and (p.image or "") or ""
			end
		end
		return ""
	end

	local planterLists = {
		{
			name = "Planter Settings",
			opened = true,
			items = {
				{
					type = "button",
					text = "Enabled",
					key = "planter_enabled",
					callback = function(v)
						if v == true
							and mod.data.actives["auto_farm"] == true
							and mod.farming.startPlanterLoop
						then
							mod.farming.startPlanterLoop()
						elseif mod.farming.stopPlanterLoop then
							mod.farming.stopPlanterLoop()
						end
					end,
				},
				{
					type = "button",
					text = "Collect Drop",
					key = "planter_collect_drop",
					value = true,
				},
			},
		},
	}

	for i = 1, 5 do
		slotRefs[i] = {}

		table.insert(planterLists, {
			name = "Slot " .. i,
			opened = false,
			_ref = slotRefs[i],
			header_dynamic = function()
				local t = mod.data.actives["planter_slot" .. i .. "_type"]
				local f = mod.data.actives["planter_slot" .. i .. "_field"]

				local hasPlanter = type(t) == "string" and t ~= ""
				local hasField = hasPlanter and type(f) == "string" and f ~= ""
				local dim = Color3.fromRGB(120, 120, 125)
				local muted = Color3.fromRGB(160, 160, 165)

				local els = {}
				els[#els + 1] = { type = "text", value = "Slot " .. i }
				els[#els + 1] = { type = "text", value = "-", color = dim }

				if not hasPlanter then
					els[#els + 1] = { type = "text", value = "Not Planter", color = muted }
				else
					local pImg = findPlanterImageByName(t)
					if pImg ~= "" and pImg ~= "rbxassetid://0" then
						els[#els + 1] = { type = "icon", value = pImg }
					end
					els[#els + 1] = { type = "text", value = t }

					els[#els + 1] = { type = "text", value = "-", color = dim }

					if not hasField then
						els[#els + 1] = { type = "text", value = "Not field", color = muted }
					else
						local fImg = findFieldImageByName(f)
						if fImg ~= "" and fImg ~= "rbxassetid://0" then
							els[#els + 1] = { type = "icon", value = fImg }
						end
						els[#els + 1] = { type = "text", value = f }
					end
				end

				return { elements = els }
			end,
			items = {
				{
					type = "button",
					text = "Enabled",
					key = "planter_slot" .. i .. "_enabled",
				},
				{
					type = "addlistchose",
					text = "Planter",
					key = "planter_slot" .. i .. "_type",
					allow_none = true,
					header_icon = true,
					list = planterOptions,
					changed = function(selected)
						if selected then
							local hrs = planterTimeMap[selected]
							if hrs then
								local timeObj = menu.dop_objects["planter_slot" .. i .. "_time_slider"]
								if timeObj and timeObj.set then
									timeObj.set(hrs, false)
								end
							end
						end
						if slotRefs[i] and slotRefs[i].refresh then
							slotRefs[i].refresh()
						end
					end,
				},
				{
					type = "addlistchose",
					text = "Field",
					key = "planter_slot" .. i .. "_field",
					allow_none = true,
					header_icon = true,
					list = planterFieldList,
					changed = function()
						if slotRefs[i] and slotRefs[i].refresh then
							slotRefs[i].refresh()
						end
					end,
				},
				{
					type = "slider",
					text = "Time (h)",
					key = "planter_slot" .. i .. "_time",
					id = "planter_slot" .. i .. "_time_slider",
					min = 1,
					max = 24,
					step = 1,
					value = 1,
				},
			},
		})
	end

	table.insert(setting, {
		name = "Planters",
		lists = planterLists,
	})

	local b1 = Instance.new("TextButton")
	b1.Name = "button_search"
	b1.BackgroundTransparency = 1
	b1.BorderSizePixel = 0
	b1.Size = UDim2.new(0.675, 0,0.068, 0)
	b1.Text = ""
	b1.ZIndex = 1002
	b1.Parent = f.Tab.Nav
	b1.LayoutOrder = -1

	local bu = Instance.new("UICorner")
	bu.CornerRadius = UDim.new(0.3, 0)
	bu.Parent = b1

	local bl = Instance.new("UIListLayout")
	bl.SortOrder = Enum.SortOrder.LayoutOrder
	bl.Padding = UDim.new(0.06, 0)
	bl.FillDirection = Enum.FillDirection.Horizontal
	bl.VerticalAlignment = Enum.VerticalAlignment.Center
	bl.HorizontalAlignment = Enum.HorizontalAlignment.Center
	bl.Parent = b1

	local image = Instance.new("ImageLabel")
	image.Name = "image"
	image.BackgroundTransparency = 1
	image.Size = UDim2.new(0.14, 0,0.78, 0)
	image.ZIndex = 1002
	image.LayoutOrder = 0
	image.Image = "rbxassetid://4359655183"
	image.ImageColor3 = Color3.fromRGB(51, 48, 53)
	image.ScaleType = Enum.ScaleType.Fit
	image.Parent = b1

	local bt = Instance.new("TextBox")
	bt.Name = "TextBox"
	bt.AutomaticSize = Enum.AutomaticSize.X
	bt.BackgroundTransparency = 1
	bt.BorderSizePixel = 0
	bt.LayoutOrder = 1
	bt.Size = UDim2.new(0.712, 0,0.831, 0)
	bt.ShowNativeInput = true
	bt.Text = ""
	bt.PlaceholderText = "Search"
	bt.ZIndex = 1003
	bt.Font = Enum.Font.BuilderSansMedium
	bt.PlaceholderColor3 = Color3.fromRGB(51, 48, 53)
	bt.TextColor3 = Color3.fromRGB(179, 175, 184)
	bt.TextScaled = true
	bt.TextWrapped = true
	bt.TextXAlignment = Enum.TextXAlignment.Left
	bt.Parent = b1

	for i, v in ipairs(setting) do
		local p = addsection(v.name)

		for ii, vv in ipairs(v.lists or {}) do
			addlist(p, vv, ii)
		end
	end

	local search_page = addsection("Search")

	local search = f.Tab.Nav.button_search:FindFirstChild("TextBox")

	if search ~= nil and search:IsA("TextBox") then
		local function clear_search()
			for _, v in ipairs(search_page:GetChildren()) do
				if v:IsA("Frame") and string.sub(v.Name, 1, 5) == "List-" then
					v:Destroy()
				end
			end
		end

		local function update_search(...)
			local a = {...}
			local text = string.lower(tostring(a[1] or ""))

			text = string.gsub(text, "^%s+", "")
			text = string.gsub(text, "%s+$", "")

			clear_search()

			if text == "" then
				search_page.Visible = false

				for name, page in pairs(sections) do
					page.Visible = name == activeSection
				end

				return
			end

			for name, page in pairs(sections) do
				page.Visible = false
			end

			local order = 0

			for _, section in ipairs(setting) do
				for _, list in ipairs(section.lists or {}) do
					local items = {}

					for _, item in ipairs(list.items or {}) do
						local item_text = string.lower(tostring(item.text or ""))
						local list_text = string.lower(tostring(list.name or ""))
						local section_text = string.lower(tostring(section.name or ""))

						if string.find(item_text, text, 1, true) ~= nil
							or string.find(list_text, text, 1, true) ~= nil
							or string.find(section_text, text, 1, true) ~= nil then
							table.insert(items, item)
						end
					end

					if #items > 0 then
						order += 1

						addlist(search_page, {
							name = tostring(section.name) .. " / " .. tostring(list.name),
							opened = true,
							items = items,
						}, order)
					end
				end
			end

			search_page.Visible = true
		end

		search:GetPropertyChangedSignal("Text"):Connect(function()
			update_search(search.Text)
		end)
	end

	find.userinputservice.InputChanged:Connect(function(input)
		if active_slider == nil then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseMovement
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		active_slider(input.Position.X)
	end)

	find.userinputservice.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			active_slider = nil
		end
	end)

	--activeSection = "Farming"

	for name, page in pairs(sections) do
		page.Visible = name == activeSection
	end

	for name, button in pairs(navigationButtons) do
		button.BackgroundTransparency = name == activeSection and 0 or 1
		button.textname.TextColor3 = name == activeSection and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(80, 76, 83)
		button.icon.ImageColor3 = name == activeSection and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(80, 76, 83)
	end
end


function menu.input(window, dragObject)
	local dragging = false
	local dragStart
	local startPosition
	local dragInput

	dragObject = dragObject or window

	dragObject.Active = true

	dragObject.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
			and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end

		dragging = true
		dragStart = input.Position
		startPosition = window.Position

		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end)

	dragObject.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	find.userinputservice.InputChanged:Connect(function(input)
		if not dragging or input ~= dragInput then
			return
		end

		local delta = input.Position - dragStart

		window.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end)
end

function menu.client_menu()
	menu.main_create()
	menu.main_nav()
	menu.dop_create()

	menu.input(find.player.PlayerGui:FindFirstChild("ScreenGui"):FindFirstChild("EggHuntLayerVisualOnly"), find.player.PlayerGui:FindFirstChild("ScreenGui"):FindFirstChild("EggHuntLayerVisualOnly").Tab)
end

return menu
