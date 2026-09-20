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
	b1l.Padding = UDim.new(0.08, 0)
	b1l.Parent = b1
	b1l.FillDirection = Enum.FillDirection.Horizontal
	b1l.HorizontalAlignment = Enum.HorizontalAlignment.Center
	b1l.VerticalAlignment = Enum.VerticalAlignment.Center

	local b1t = Instance.new("TextLabel")
	b1t.Name = "b1t"
	b1t.Parent = b1
	b1t.BackgroundTransparency = 1
	b1t.BorderSizePixel = 0
	b1t.Size = UDim2.new(0.678, 0,0.37, 0)
	b1t.ZIndex = 1004
	b1t.Font = Enum.Font.BuilderSansBold
	b1t.Text = mod.data.actives["script_name"]
	b1t.LayoutOrder = 0
	b1t.TextColor3 = Color3.fromRGB(255, 255, 255)
	b1t.TextScaled = true
	b1t.TextXAlignment = Enum.TextXAlignment.Right

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

	addNavigation("Home", "rbxassetid://13060262529", 1)
	addNavigation("Farming", "rbxassetid://15332137726", 2)
	addNavigation("Combat", "rbxassetid://4391741881", 3)
	addNavigation("Config", "rbxassetid://4857706689", 4)

	showsel("Home")
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
			--print(mod.data.actives[a[1].key])
		end

		if a[1].callback ~= nil then
			a[1].callback(a[2], a[3], a[4])
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
				save(d, value, b, r)
				update()

				print(d.key, "=", mod.data.actives[d.key])
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
			Color3.fromRGB(231, 46, 255), -- #E72EFF
			Color3.fromRGB(255, 66, 148)  -- #FF4294
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
		if parent == nil or type(d) ~= "table" then
			return
		end

		local list = d.list or mod.data.zones
		local key = d.key or "selected_field"
		local opened = d.opened == true

		local selected = d.value

		if selected == nil then
			selected = mod.data.actives[key]
		end

		if selected == false or selected == "" then
			selected = nil
		end

		local fields = table.create(#list)
		local cards = {}
		local valid = {}
		local search = {
			tostring(d.text or "Field"),
		}

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

			if type(name) == "string" and name ~= ""then
				if name == "Ant Field" then
					print(name)
				else
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

		if selected ~= nil and valid[selected] ~= true then
			selected = nil
		end

		mod.data.actives[key] = selected or false

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

		local h = Instance.new("TextButton")
		h.Name = "Header"
		h.BackgroundTransparency = 1
		h.BorderSizePixel = 0
		h.AutoButtonColor = true
		h.Size = d.header_size or UDim2.new(0.96, 0, 0, 32)
		h.LayoutOrder = 0
		h.ZIndex = 1004
		h.Font = Enum.Font.BuilderSansBold
		h.TextColor3 = Color3.fromRGB(255, 255, 255)
		h.TextSize = 15
		h.TextTruncate = Enum.TextTruncate.AtEnd
		h.TextXAlignment = Enum.TextXAlignment.Left
		h.Parent = r

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
		h2.Position = UDim2.new(0.941, 0,0.107, 0)
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

		local function updateHeader()
			h.Text = tostring(d.text or "Field")
				.. ": "
				.. tostring(selected or "NONE")
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
			local old = selected
			local new = name

			if selected == name and d.allow_none ~= false then
				new = nil
			end

			if old == new then
				return
			end

			selected = new
			mod.data.actives[key] = selected or false

			if old ~= nil then
				updateCard(cards[old], false)
			end

			if selected ~= nil then
				updateCard(cards[selected], true)
			end

			updateHeader()

			if type(d.changed) == "function" then
				d.changed(selected)
			end
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

			local icon = Instance.new("ImageLabel")
			icon.Name = "Icon"
			icon.AnchorPoint = Vector2.new(0, 0.5)
			icon.BackgroundTransparency = 1
			icon.BorderSizePixel = 0
			icon.Position = UDim2.new(0, 6, 0.5, 0)
			icon.Size = UDim2.fromOffset(21, 21)
			icon.ZIndex = 1006
			icon.Image = field.image
			icon.ScaleType = Enum.ScaleType.Fit
			icon.Visible = field.image ~= ""
				and field.image ~= "rbxassetid://0"
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
				selected == field.name
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

		updateHeader()
		updateOpened()

		return r1
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
							callback = mod.farming.autosprinkler,
						},
						{ type = "button", text = "Auto Dig", key = "auto_dig", callback = mod.farming.autoDig},
						{
							type = "addlistchose",
							text = "Field",
							key = "selected_field",
							allow_none = false,
							changed = function()
								if mod.data.actives.auto_farm then
									mod.farming.farm()
								end
							end,
						},
						{
							type = "slider",
							text = "WalkSpeed",
							key = "walkspeed",
							min = 16,
							max = 100,
							step = 1,

							callback = function(value)
								local character = find.player.Character
								local humanoid = character
									and character:FindFirstChildOfClass("Humanoid")

								local root = character
									and character:FindFirstChild("HumanoidRootPart")

								if humanoid then
									humanoid.WalkSpeed = value
								end

								if root then
									local p = root.CurrentPhysicalProperties

									root.Massless = false
									root.CustomPhysicalProperties = PhysicalProperties.new(
										20,
										p.Friction,
										p.Elasticity,
										p.FrictionWeight,
										p.ElasticityWeight
									)
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
						{ type = "button", text = "Wealth Clock", key = "weatlh_clock"},
					},
				},
			},
		},
		{
			name = "Config",
			lists = {
				{
					name = "Config",
					opened = true,
					items = {
						{
							type = "addlistchose",
							text = "Movement Method",
							key = "style_auto_farm",
							list = mod.data.other,
							allow_none = false,
						}
					},
				},
			},
		},
	}

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

	activeSection = "Home"

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
