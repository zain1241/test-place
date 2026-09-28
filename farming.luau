local env = (getgenv and getgenv()) or _G
local loaded = rawget(env, "__NECTAR_MODULES")

local data

if loaded and loaded.data then
	data = loaded.data
else
	data = require(script.Parent:WaitForChild("data"))
end

local farming = {}

local mod = {
	data = data,
}

print("loaded 0.1.23")

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

local queue = {
	auto_farm = {},
	tokens = {},
}

local happenings = workspace:FindFirstChild("Happenings")
local bloomFolder = happenings and happenings:FindFirstChild("PoppablePlants")

local function getHappenings()
	return workspace:FindFirstChild("Happenings")
end

local function getPuffFolder()
	local h = getHappenings()
	return h and h:FindFirstChild("Puffshrooms")
end

local invc, tween, afarm, adig, aconvert, atween, track, animwalk, humanoid_walk_speed, p, p1;
local farmId = 0

local bubbles = {}
local staticBubbles = {}
local bubblesReady = false

local function initBubbles()
	if bubblesReady then return end
	local particles = workspace:FindFirstChild("Particles")
	if not particles then return end
	bubblesReady = true
	
	for _, v in ipairs(particles:GetChildren()) do
		if v:IsA("BasePart") and (v.Name == "Bubble" or v.Name == "GoldBubble") then
			staticBubbles[v] = true
		end
	end

	for _, v in ipairs(particles:GetChildren()) do
		if v:IsA("BasePart")
			and (v.Name == "Bubble" or v.Name == "GoldBubble")
			and not staticBubbles[v]
		then
			bubbles[v] = true
		end
	end

	particles.ChildAdded:Connect(function(v)
		if v:IsA("BasePart")
			and (v.Name == "Bubble" or v.Name == "GoldBubble")
			and not staticBubbles[v]
		then
			bubbles[v] = true
		end
	end)

	particles.ChildRemoved:Connect(function(v)
		bubbles[v] = nil
	end)
end

local __bboxCache = {}
local __bboxCacheTime = {}

local function getFieldBox(field)
	if not field then return end
	if field:IsA("BasePart") then
		return field.CFrame, field.Size
	end
	if field:IsA("Model") then
		local now = tick()
		local last = __bboxCacheTime[field]
		if __bboxCache[field] and last and now - last < 2 then
			local c = __bboxCache[field]
			return c[1], c[2]
		end
		local cf, size = field:GetBoundingBox()
		__bboxCache[field] = {cf, size}
		__bboxCacheTime[field] = now
		return cf, size
	end
end

local function isInField(pos, field)
	local cf, size = getFieldBox(field)
	if not cf then return true end
	local p = cf:PointToObjectSpace(pos)
	return math.abs(p.X) <= size.X / 2
		and math.abs(p.Z) <= size.Z / 2
end

local function getNearestBubble(field, hrp)
	initBubbles()
	if not hrp then return nil end

	local nearest, nearestDistance
	for bubble in pairs(bubbles) do
		if not bubble.Parent then
			bubbles[bubble] = nil
			continue
		end
		if isInField(bubble.Position, field) then
			local d = (bubble.Position - hrp.Position).Magnitude
			if not nearestDistance or d < nearestDistance then
				nearest = bubble
				nearestDistance = d
			end
		end
	end
	return nearest
end

local function getBloomPosition(bloom)
	local core = bloom and bloom:FindFirstChild("CorePart", true)
	if core and core:IsA("BasePart") then
		return core.Position
	end
end

local function getNearestBloom(field, hrp)
	if not bloomFolder then return nil end
	local nearest, nearestDistance
	for _, bloom in ipairs(bloomFolder:GetChildren()) do
		if bloom:IsA("Model") and bloom.Name == "Bloom" then
			local pos = getBloomPosition(bloom)
			if pos and isInField(pos, field) then
				local target = Vector3.new(pos.X, hrp.Position.Y, pos.Z)
				local d = (target - hrp.Position).Magnitude
				if not nearestDistance or d < nearestDistance then
					nearest = bloom
					nearestDistance = d
				end
			end
		end
	end
	return nearest
end

local function isPetal(v)
	return v
		and v:IsA("BasePart")
		and v.Name == "PetalPart"
		and v.Parent == workspace:FindFirstChild("Particles")
end

local function getBestPetal(tracked, hrp)
	local nearest, bestScore
	for petal in pairs(tracked) do
		if not petal.Parent then
			tracked[petal] = nil
			continue
		end
		local pos = petal.Position
		local dx = pos.X - hrp.Position.X
		local dz = pos.Z - hrp.Position.Z
		local flat = math.sqrt(dx * dx + dz * dz)
		local hDiff = math.abs(pos.Y - hrp.Position.Y)
		local score = flat + hDiff * 0.30
		if not bestScore or score < bestScore then
			bestScore = score
			nearest = petal
		end
	end
	return nearest
end

function farming.farmPetalBloom(field, id)
	local character = find.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return false end

	local bloom = getNearestBloom(field, hrp)
	if not bloom then return false end

	local origin = getBloomPosition(bloom)
	if not origin then return false end

	local particles = workspace:FindFirstChild("Particles")
	if not particles then return false end

	local oldPetals = {}
	for _, v in ipairs(particles:GetChildren()) do
		if isPetal(v) then oldPetals[v] = true end
	end

	local tool = character:FindFirstChildOfClass("Tool")
	local lastActivate = 0
	
	local phaseStart = tick()
	while id == farmId
		and mod.data.actives["auto_farm"] == true
		and mod.data.actives["petals"] == true
		and not mod.data.actives["converting"]
		and bloom.Parent == bloomFolder
		and tick() - phaseStart < 30
	do
		character = find.player.Character
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		hrp = character and character:FindFirstChild("HumanoidRootPart")

		if humanoid and hrp then
			local pos = getBloomPosition(bloom)
			if pos then
				local target = Vector3.new(pos.X, hrp.Position.Y, pos.Z)
				if (target - hrp.Position).Magnitude > 5 then
					humanoid:MoveTo(target)
				end
			end
		end

		task.wait(0.01)
	end
	
	local popTimeout = os.clock() + 4
	while id == farmId
		and mod.data.actives["auto_farm"] == true
		and mod.data.actives["petals"] == true
		and bloom.Parent == bloomFolder
		and os.clock() < popTimeout
	do
		character = find.player.Character
		if character then
			tool = character:FindFirstChildOfClass("Tool") or tool
			if tool and tool.Parent == character and os.clock() - lastActivate >= 0.08 then
				pcall(function() tool:Activate() end)
				lastActivate = os.clock()
			end
		end

		task.wait(0.01)
	end
	
	local tracked = {}
	local lastSpawn = os.clock()

	local conn
	conn = particles.ChildAdded:Connect(function(v)
		if not mod.data.actives["auto_farm"] then return end
		if not isPetal(v) then return end
		if oldPetals[v] then return end
		if (v.Position - origin).Magnitude <= 60 then
			tracked[v] = true
			lastSpawn = os.clock()
		end
	end)

	local petalStart = os.clock()
	local petalTimeout = petalStart + 7

	while id == farmId
		and mod.data.actives["auto_farm"] == true
		and mod.data.actives["petals"] == true
		and not mod.data.actives["converting"]
		and os.clock() < petalTimeout
	do
		character = find.player.Character
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		hrp = character and character:FindFirstChild("HumanoidRootPart")

		if humanoid and hrp then
			for _, v in ipairs(particles:GetChildren()) do
				if isPetal(v)
					and not oldPetals[v]
					and not tracked[v]
					and (v.Position - origin).Magnitude <= 60
				then
					tracked[v] = true
					lastSpawn = os.clock()
				end
			end

			local petal = getBestPetal(tracked, hrp)
			if petal then
				local pos = petal.Position
				local target = Vector3.new(pos.X, hrp.Position.Y, pos.Z)
				humanoid:MoveTo(target)
				if (target - hrp.Position).Magnitude <= 3.5 then
					tracked[petal] = nil
				end
			else
				if os.clock() - lastSpawn > 0.45 and os.clock() - petalStart > 0.5 then
					break
				end
			end
		end

		task.wait(0.01)
	end

	if conn then conn:Disconnect() end

	return true
end

local PUFF_RARITY = {
	["Common"] = true,
	["Rare"] = true,
	["Epic"] = true,
	["Legendary"] = true,
	["Mythic"] = true,
}

local function getPuffRarity(puff)
	for rar in pairs(PUFF_RARITY) do
		if string.find(puff.Name, rar, 1, true) then
			return rar
		end
	end
	local attr = puff:GetAttribute("Rarity") or puff:GetAttribute("rarity")
	if type(attr) == "string" then
		for rar in pairs(PUFF_RARITY) do
			if string.find(attr, rar, 1, true) then
				return rar
			end
		end
	end
	return nil
end


local function getPuffRoot(puff)
	return puff.PrimaryPart
		or puff:FindFirstChild("PuffballStem", true)
		or puff:FindFirstChildWhichIsA("BasePart", true)
end

local function getNearestPuff(field, hrp, filter)
	local pf = getPuffFolder()
	if not pf or not hrp then
		--warn("[puff] puffFolder =", pf, "hrp =", hrp)
		return nil
	end

	local nearest, nearestDist
	local total = 0
	for _, puff in ipairs(pf:GetChildren()) do
		if puff:IsA("Model") then
			total += 1
			local rarity = getPuffRarity(puff)
			local accept = (filter == "All Pushrooms") or (rarity == filter)

			if accept then
				local root = getPuffRoot(puff)
				if root then
					local d = (root.Position - hrp.Position).Magnitude
					if not nearestDist or d < nearestDist then
						nearest = puff
						nearestDist = d
					end
				end
			end
		end
	end

	--print("[puff] total models:", total, "filter:", filter, "->", nearest and nearest.Name or "nil")
	return nearest
end

local function isPuffLoot(v)
	if not v or not v:IsA("BasePart") then
		return false
	end

	if v.Name == "PuffballStem" or v.Name == "Puffball" then
		return false
	end

	-- Реальный лут гриба находится в Collectibles.
	-- Decal обычно содержит его картинку/тип.
	return v.Parent == workspace:FindFirstChild("Collectibles")
		and v:FindFirstChildWhichIsA("Decal") ~= nil
end

local function findLootNear(pos, radius)
	if not pos then
		return nil
	end

	local collectibles = workspace:FindFirstChild("Collectibles")
	if not collectibles then
		return nil
	end

	local best
	local bestDist

	for _, v in ipairs(collectibles:GetChildren()) do
		if isPuffLoot(v) then
			local d = (v.Position - pos).Magnitude

			if d <= radius and (not bestDist or d < bestDist) then
				best = v
				bestDist = d
			end
		end
	end

	return best
end

function farming.farmPuffshroom(field, id)
	local function enabled()
		return id == farmId
			and mod.data.actives["auto_farm"] == true
			and mod.data.actives["pushrooms_enabled"] == true
			and not mod.data.actives["converting"]
	end

	local character = find.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local hrp = character and character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not hrp then
		return false
	end

	local filter = mod.data.actives["pushrooms"] or "All Pushrooms"
	local puff = getNearestPuff(field, hrp, filter)

	if not puff then
		return false
	end

	local rootPart = getPuffRoot(puff)

	if not rootPart then
		return false
	end

	local pf = getPuffFolder()

	if not pf then
		return false
	end

	print("[puff] target:", puff.Name)

	-- =========================================
	-- 1. ЛЁТ К ГРИБУ
	-- =========================================

	mod.data.actives["move"] = true

	character = find.player.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	hrp = character and character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not hrp then
		mod.data.actives["move"] = false
		return false
	end

	if tween then
		tween:Cancel()
		tween = nil
	end

	local startRoot = hrp
	local target = rootPart.Position

	local distance = (startRoot.Position - target).Magnitude
	local speed = tonumber(mod.data.actives["walkspeed"]) or 40
	local duration = distance / math.max(speed, 1)

	startRoot.Anchored = true

	-- INV только на время полёта
	farming.inv(true)

	local flyTween = find.tweenservice:Create(
		startRoot,
		TweenInfo.new(
			math.max(duration, 0.05),
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out
		),
		{
			CFrame = CFrame.new(target)
		}
	)

	tween = flyTween
	flyTween:Play()

	local finished = false

	flyTween.Completed:Once(function()
		finished = true

		if tween == flyTween then
			tween = nil
		end
	end)

	while enabled()
		and puff.Parent == pf
		and not finished
	do
		task.wait()
	end

	if not enabled() then
		pcall(function()
			flyTween:Cancel()
		end)

		startRoot.Anchored = false
		farming.inv(false)
		mod.data.actives["move"] = false
		return false
	end

	startRoot.Anchored = false
	farming.inv(false)
	mod.data.actives["move"] = false

	task.wait(0.1)

	-- =========================================
	-- 2. ЛОЖИМСЯ В КРУГ
	-- =========================================

	character = find.player.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	hrp = character and character:FindFirstChild("HumanoidRootPart")

	if not humanoid or not hrp then
		return false
	end

	local circleRadius = 5
	local circleDirection = 1
	local lastActivate = 0

	local tool = character:FindFirstChildOfClass("Tool")

	local breakStart = tick()

	while enabled()
		and puff.Parent == pf
		and tick() - breakStart < 30
	do
		character = find.player.Character
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		hrp = character and character:FindFirstChild("HumanoidRootPart")

		if not humanoid or not hrp or hrp.Anchored then
			break
		end

		local centerPart = getPuffRoot(puff)

		if not centerPart then
			break
		end

		local center = centerPart.Position

		local offset = Vector3.new(
			hrp.Position.X - center.X,
			0,
			hrp.Position.Z - center.Z
		)

		local distance = offset.Magnitude

		if distance < 0.1 then
			offset = Vector3.new(1, 0, 0)
			distance = 1
		end

		local radial = offset.Unit

		-- касательная к окружности
		local tangent = Vector3.new(
			-radial.Z * circleDirection,
			0,
			radial.X * circleDirection
		)

		-- Если слишком далеко от гриба,
		-- сначала возвращаемся к радиусу.
		if distance > circleRadius + 1.5 then
			local correction = (
				Vector3.new(center.X, hrp.Position.Y, center.Z)
				- hrp.Position
			).Unit

			humanoid:Move(correction, false)
		elseif distance < circleRadius - 1.5 then
			local correction = radial

			humanoid:Move(correction, false)
		else
			humanoid:Move(tangent, false)
		end

		humanoid.WalkSpeed = speed

		-- Используем инструмент постоянно, но не спамим.
		tool = character:FindFirstChildOfClass("Tool") or tool

		if tool
			and tool.Parent == character
			and os.clock() - lastActivate >= 0.12
		then
			pcall(function()
				tool:Activate()
			end)

			lastActivate = os.clock()
		end

		task.wait(0.04)
	end

	-- Останавливаем движение
	character = find.player.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		humanoid:Move(Vector3.zero, false)
	end

	-- =========================================
	-- 3. СОБИРАЕМ ТОЛЬКО НОВЫЙ ЛУТ
	-- =========================================

	if not enabled() then
		return false
	end

	print("[puff] looting")

	local lootTimeout = tick() + 7
	local lastLootTime = tick()

	while enabled() and tick() < lootTimeout do
		character = find.player.Character
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		hrp = character and character:FindFirstChild("HumanoidRootPart")

		if not humanoid or not hrp or hrp.Anchored then
			task.wait(0.05)
			continue
		end

		local loot = findLootNear(target, 35)

		if loot and loot.Parent then
			lastLootTime = tick()

			local lootStart = tick()

			while enabled()
				and loot.Parent
				and tick() - lootStart < 2
			do
				character = find.player.Character
				humanoid = character and character:FindFirstChildOfClass("Humanoid")
				hrp = character and character:FindFirstChild("HumanoidRootPart")

				if not humanoid or not hrp then
					break
				end

				local targetPos = Vector3.new(
					loot.Position.X,
					hrp.Position.Y,
					loot.Position.Z
				)

				local distance = (
					Vector3.new(hrp.Position.X, 0, hrp.Position.Z)
					- Vector3.new(targetPos.X, 0, targetPos.Z)
				).Magnitude

				if distance <= 2 then
					break
				end

				humanoid.WalkSpeed = speed
				humanoid:MoveTo(targetPos)

				task.wait()
			end
		else
			-- Ждём ещё немного, потому что лут может появиться
			-- чуть позже самого исчезновения гриба.
			if tick() - lastLootTime > 0.7 then
				break
			end
		end

		task.wait(0.05)
	end

	character = find.player.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		humanoid:Move(Vector3.zero, false)
	end

	print("[puff] done")

	return true
end

local function clearFarmLines()
	local lines = workspace:FindFirstChild("Lines_Cub")

	if lines then
		lines:ClearAllChildren()
	end

	local character = find.player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if root then
		for _, object in ipairs(root:GetChildren()) do
			if object.Name == "Attachment" or object.Name == "Beam" then
				object:Destroy()
			end
		end
	end

	local zones = workspace:FindFirstChild("FlowerZones")

	if zones then
		for _, field in ipairs(zones:GetChildren()) do
			for _, object in ipairs(field:GetChildren()) do
				if object.Name == "Attachment" then
					object:Destroy()
				end
			end
		end
	end
end

local function findActivateButton()
	local pg = find.player.PlayerGui
	local sg = pg:FindFirstChild("ScreenGui")
	if sg then
		local b = sg:FindFirstChild("ActivateButton")
		if b then return b end
	end
	for _, gui in ipairs(pg:GetChildren()) do
		if gui:IsA("ScreenGui") or gui:IsA("Folder") then
			local b = gui:FindFirstChild("ActivateButton", true)
			if b then return b end
		end
	end
	return nil
end

--local function activateButton(...)
--	local button = findActivateButton()
--	if not button then
--		warn("ActivateButton not found")
--		return false
--	end

--	local waitStart = tick()
--	while tick() - waitStart < 3 do
--		if button.Visible and button.AbsoluteSize.X > 0 then break end
--		task.wait(0.05)
--		button = findActivateButton() or button
--	end

--	local pos = button.AbsolutePosition
--	local size = button.AbsoluteSize
--	if size.X <= 0 or size.Y <= 0 then
--		warn("ActivateButton has no size")
--		return false
--	end

--	local cx = pos.X + (size.X / 2)
--	local cy = pos.Y + (size.Y / 2)
--	local inset = find.guiservice:GetGuiInset()

--	pcall(function() find.virtual:SendMouseMoveEvent(cx, cy + inset.Y, false, game) end)
--	task.wait(0.1)
--	pcall(function()
--		local VU = game:GetService("VirtualUser")
--		VU:CaptureController()
--		VU:ClickButton1(Vector2.new(cx, cy + inset.Y))
--	end)
--	task.wait(0.1)
--	pcall(function() find.virtual:SendMouseButtonEvent(cx, cy + inset.Y, 0, true, game, 1) end)
--	task.wait(0.05)
--	pcall(function() find.virtual:SendMouseButtonEvent(cx, cy + inset.Y, 0, false, game, 1) end)

--	return true
--end

local function activateButton(...)
	local button = findActivateButton()
	if not button then
		warn("ActivateButton not found")
		return false
	end

	local waitStart = tick()
	while tick() - waitStart < 3 do
		if button.Visible and button.AbsoluteSize.X > 0 then break end
		task.wait(0.05)
		button = findActivateButton() or button
	end

	local pos = button.AbsolutePosition
	local size = button.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		warn("ActivateButton has no size")
		return false
	end

	local cx = pos.X + (size.X / 2)
	local cy = pos.Y + (size.Y / 2)
	local inset = find.guiservice:GetGuiInset()
	local clickY = cy + inset.Y

	local VU = game:GetService("VirtualUser")
	pcall(function()
		find.virtual:SendMouseButtonEvent(cx, clickY, 0, false, game, 1)
	end)
	pcall(function()
		find.virtual:SendMouseButtonEvent(cx, clickY, 1, false, game, 1)
	end)
	pcall(function()
		find.virtual:SendKeyEvent(false, Enum.KeyCode.ButtonR2, false, game)
	end)
	pcall(function()
		VU:Button1Up(Vector2.new(cx, clickY))
	end)
	
	pcall(function()
		VU:CaptureController()
	end)
	pcall(function()
		VU:ReleaseController(Vector2.new(cx, clickY))
	end)

	task.wait(0.05)
	
	pcall(function()
		find.virtual:SendMouseMoveEvent(cx, clickY, false, game)
	end)
	task.wait(0.08)
	
	pcall(function()
		VU:CaptureController()
		VU:ClickButton1(Vector2.new(cx, clickY))
	end)
	task.wait(0.05)

	pcall(function()
		find.virtual:SendMouseButtonEvent(cx, clickY, 0, true, game, 1)
	end)
	task.wait(0.05)
	pcall(function()
		find.virtual:SendMouseButtonEvent(cx, clickY, 0, false, game, 1)
	end)
	
	task.wait(0.1)
	pcall(function()
		find.virtual:SendMouseButtonEvent(cx, clickY, 0, true, game, 1)
	end)
	task.wait(0.05)
	pcall(function()
		find.virtual:SendMouseButtonEvent(cx, clickY, 0, false, game, 1)
	end)

	return true
end

function farming.conAF(...)
	local a = {...}
	local interval = 1 / a[2]
	local accumulated = 0

	return a[1]:Connect(function(delta)
		accumulated += delta
		if accumulated < interval then
			return
		end
		local elapsed = accumulated
		accumulated %= interval

		a[3](elapsed)
	end)
end

function farming.cornl(...)
	local a = {...}
	local h = find.player.Character and find.player.Character:FindFirstChildOfClass("Humanoid")
	local function block(...) return Enum.ContextActionResult.Sink end

	if a[1] == true then
		find.contextactionservice:BindActionAtPriority("BlockPlayerMovement", block, false, Enum.ContextActionPriority.High.Value + 1, Enum.PlayerActions.CharacterForward,
			Enum.PlayerActions.CharacterBackward, Enum.PlayerActions.CharacterLeft, Enum.PlayerActions.CharacterRight, Enum.PlayerActions.CharacterJump)
		if h then h.Jump = false; h:SetStateEnabled(Enum.HumanoidStateType.Jumping, false) end
	else
		find.contextactionservice:UnbindAction("BlockPlayerMovement")
		if h then h:SetStateEnabled(Enum.HumanoidStateType.Jumping, true) end
	end
end

function farming.inv(...)
	local a = {...}
	local b = workspace:FindFirstChild(find.player.Name)
	if not b then return end

	if a[1] == true then
		if invc then
			return
		end

		invc = farming.conAF(
			find.prerender, 4,
			function(delta)
				--print(delta)
				for _, v in ipairs(b:GetChildren()) do
					if v:IsA("MeshPart") then
						if v.Name ~= "HumanoidRootPart"then
							v.Transparency = 0.6
						end
						--print(v.Name)
						v.CanCollide = false
						v.CanTouch = false
						v.CanQuery = false
					end
				end
			end
		)
	else
		if invc then
			invc:Disconnect()
			invc = nil
		end

		for _, v in ipairs(b:GetChildren()) do
			if v:IsA("MeshPart") then
				if v.Name ~= "HumanoidRootPart" then
					v.Transparency = 0
				end
				v.CanCollide = false
				v.CanTouch = true
				v.CanQuery = true
			end
		end
	end
end

function farming.move(...)
	local a = {...}
	if mod.data.actives["move"] == true then
		return
	end

	if not workspace:FindFirstChild(find.player.Name) then
		return
	end

	local function j(a)
		if a then
			find.player.Character:FindFirstChildOfClass("Humanoid").Jump = true
			find.player.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.None)
			task.wait(.01)
			find.player.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Freefall)
		else
			find.player.Character:FindFirstChildOfClass("Humanoid").Jump = false
			find.player.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.None)
		end
	end

	local function r(...)
		if mod.data.actives["auto_farm"] == false then
			return
		end

		local a = {...}
		local part = a[1]

		if typeof(part) == "string" then
			local f = workspace:FindFirstChild("FlowerZones")
			part = f and f:FindFirstChild(part)
		end

		if not part or not part:IsA("BasePart") then
			warn("r: поле не найдено или не BasePart:", part)
			return
		end

		local h = .4

		local marginX = math.min(6, part.Size.X * .15)
		local marginZ = math.min(6, part.Size.Z * .15)
		local x = part.Size.X / 2 - marginX
		local z = part.Size.Z / 2 - marginZ

		local position = string.lower(mod.data.actives["position_field"] or "center")
		local ix, ax

		if position == "left" then
			ix = -x
			ax = 0
		elseif position == "right" then
			ix = 0
			ax = x
		else
			ix = -x / 3
			ax = x / 3
		end

		local l = Vector3.new(
			find.random:NextNumber(ix, ax),
			part.Size.Y / 2 + h,
			find.random:NextNumber(-z, z)
		)

		return part.CFrame:PointToWorldSpace(l)
	end

	local function b(...)
		local a = {...}
		--print(a[1],a[2],a[3])

		local p = r(a[3])
		--print(p)

		if a[1] == true then
			local m = Instance.new("Attachment"); m.Name = "Attachment"; m.Parent = a[2];
			local m1 = Instance.new("Attachment"); m1.Name = "Attachment"; m1.Parent = a[3]; m1.Position = a[3].CFrame:PointToObjectSpace(p + Vector3.new(0, 4, 0))

			local b = Instance.new("Beam"); b.Parent = a[2]; b.Width0 = .2; b.Width1 = .2; b.Attachment0 = m; b.Attachment1 = m1; b.FaceCamera = true; b.TextureLength = 1; b.LightEmission = 1; b.Transparency = NumberSequence.new(0, 0)
		elseif a[1] == false then
			a[2].Attachment:Destroy(); a[3].Attachment:Destroy(); a[2].Beam:Destroy()
		end
	end

	--print(a[1])

	if a[1] == "flowerzones" then
		for _, v in ipairs(workspace:FindFirstChild("FlowerZones"):GetChildren()) do
			if v.Name == a[3] then
				if mod.data.actives["auto_farm"] == false then
					return
				end

				local s = Instance.new("SelectionBox")
				s.Parent = v
				s.Adornee = v
				s.Color3 = Color3.new(255, 255, 255)
				s.SurfaceColor3 = Color3.new(255, 255, 255)
				s.LineThickness = .04
				s.SurfaceTransparency = .9
				
				if tween then tween:Cancel() tween = nil end
				if atween then atween:Cancel() atween = nil end
				
				local char = find.player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local humanoid = char and char:FindFirstChildOfClass("Humanoid")
				if not root or not humanoid then return end

				humanoid:MoveTo(root.Position)
				humanoid:Move(Vector3.zero)
				humanoid.WalkSpeed = 0
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero

				if not workspace:FindFirstChild(find.player.Name) then
					return
				end
				
				local target = v.CFrame:PointToWorldSpace(
					Vector3.new(0, v.Size.Y / 2 + 4, 0)
				)
				local d1 = (root.Position - target).Magnitude / math.max(a[2], .001)
				root.Anchored = true

				local currentFarmId = farmId
				local t = TweenInfo.new(d1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
				local currentTween = find.tweenservice:Create(root, t, {CFrame = CFrame.new(target)})
				tween = currentTween
				mod.data.actives["move"] = true

				currentTween:Play()
				farming.inv(true)
				j(true)

				currentTween.Completed:Once(function(state)
					if tween == currentTween then
						tween = nil
					end

					if state == Enum.PlaybackState.Cancelled or currentFarmId ~= farmId then
						if s.Parent then s:Destroy() end
						return
					end

					j(false)
					if s.Parent then s:Destroy() end
					farming.inv(false)

					if currentFarmId ~= farmId or mod.data.actives["auto_farm"] == false then
						root.Anchored = false
						if humanoid and humanoid.Parent then
							humanoid.WalkSpeed = mod.data.actives["walkspeed"] or 16
						end
						return
					end

					root.Anchored = false
					
					if humanoid and humanoid.Parent then
						humanoid.WalkSpeed = mod.data.actives["walkspeed"] or 16
					end

					mod.data.actives["move"] = false
					task.wait(.4)
					farming.autosprinkler()
					task.wait(1)
				end)
				
				task.wait(1)

				return currentTween
			end
		end
	elseif a[1] == "hive" then
		if mod.data.actives["autohive"] == false then
			return
		end

		local target = a[3]

		if typeof(target) ~= "Vector3" then
			return
		end

		if not workspace:FindFirstChild(find.player.Name) then
			return
		end

		if tween then
			tween:Cancel()
			tween = nil
		end

		if atween then
			atween:Cancel()
			atween = nil
		end

		local character = find.player.Character
		if not character then
			return
		end

		local root = character:FindFirstChild("HumanoidRootPart")
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if not root or not humanoid then
			return
		end
		
		humanoid:MoveTo(root.Position)
		humanoid:Move(Vector3.zero, false)
		
		mod.data.actives["point"] = false
		mod.data.actives["move"] = true
		mod.data.actives["converting"] = false

		local currentFarmId = farmId

		local d1 =
			(root.Position - target).Magnitude
			/ math.max(a[2], 0.001)

		root.Anchored = true

		local currentTween = find.tweenservice:Create(
			root,
			TweenInfo.new(
				d1,
				Enum.EasingStyle.Linear,
				Enum.EasingDirection.Out
			),
			{
				CFrame = CFrame.new(target)
			}
		)

		tween = currentTween

		currentTween:Play()
		farming.inv(true)

		currentTween.Completed:Once(function(state)
			if tween == currentTween then
				tween = nil
			end

			if state == Enum.PlaybackState.Cancelled
				or currentFarmId ~= farmId
			then
				root.Anchored = false
				mod.data.actives["move"] = false
				return
			end

			farming.inv(false)

			root.Anchored = false

			if currentFarmId ~= farmId
				or mod.data.actives["auto_farm"] ~= true
			then
				mod.data.actives["move"] = false
				return
			end
			
			if not farming.getHive() then
				task.wait(0.6)

				local clicked = false
				for try = 1, 3 do
					clicked = activateButton()
					task.wait(0.5)
					if farming.getHive() then break end
				end

				if not farming.getHive() then
					warn("[hive] не занялся после 3 попыток")
					mod.data.actives["move"] = false
					mod.data.actives["converting"] = false
					return
				end
			end

			mod.data.actives["converting"] = true
			mod.data.actives["move"] = true

			farming.convert()
		end)

		return currentTween
	elseif a[1] == "convert" then
		--mod.data.actives["move"] = true
		--print(actives["move"])

		local target = a[3]
		print(target)
		if typeof(target) ~= "Vector3" then return end
		if tween then tween:Cancel() tween = nil end
		if not workspace:FindFirstChild(find.player.Name) then return end

		local character = find.player.Character
		if not character then return end

		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return end
		mod.data.actives["move"] = true
		local currentFarmId = farmId

		local d1 = (root.Position - target).Magnitude
			/ math.max(a[2], .001)

		root.Anchored = true

		local t = TweenInfo.new(
			d1,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.Out
		)

		local currentTween = find.tweenservice:Create(
			root,
			t,
			{
				CFrame = CFrame.new(target)
			}
		)

		tween = currentTween

		currentTween:Play()
		farming.inv(true)
		j(true)

		currentTween.Completed:Once(function(state)
			if tween == currentTween then tween = nil end
			if state == Enum.PlaybackState.Cancelled or currentFarmId ~= farmId then
				mod.data.actives["converting"] = false
				mod.data.actives["move"] = false
				return
			end

			j(false)
			farming.inv(false)
			root.Anchored = false
			task.wait(1)

			--if currentFarmId ~= farmId or mod.data.actives["auto_farm"] ~= true then
			--	mod.data.actives["move"] = false
			--	mod.data.actives["converting"] = false
			--	return
			--end
			
			--mod.data.actives["move"] = false
			farming.convert()
		end)
		return currentTween
	elseif a[1] == "goto" then
		local target = a[3]
		if typeof(target) ~= "Vector3" then return end
		if not workspace:FindFirstChild(find.player.Name) then return end

		local character = find.player.Character
		if not character then return end

		local root = character:FindFirstChild("HumanoidRootPart")
		if not root then return end

		if tween then tween:Cancel() tween = nil end
		if atween then atween:Cancel() atween = nil end

		mod.data.actives["move"] = true
		local currentFarmId = farmId

		local d1 = (root.Position - target).Magnitude / math.max(a[2], .001)

		root.Anchored = true

		local currentTween = find.tweenservice:Create(
			root,
			TweenInfo.new(d1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
			{CFrame = CFrame.new(target)}
		)

		tween = currentTween
		currentTween:Play()
		farming.inv(true)

		currentTween.Completed:Once(function(state)
			if tween == currentTween then tween = nil end

			if state == Enum.PlaybackState.Cancelled or currentFarmId ~= farmId then
				root.Anchored = false
				mod.data.actives["move"] = false
				return
			end

			farming.inv(false)
			root.Anchored = false
			mod.data.actives["move"] = false
		end)

		return currentTween
	end
	return false
end

function farming.forceWalkSpeed(speed)
	if farming.__speedConn then
		farming.__speedConn:Disconnect()
		farming.__speedConn = nil
	end

	farming.__forcedSpeed = speed

	local function applyMass()
		local char = find.player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		if not root then return end
		root.Massless = false
		local p = root.CurrentPhysicalProperties
		root.CustomPhysicalProperties = PhysicalProperties.new(
			20, p.Friction, p.Elasticity, p.FrictionWeight, p.ElasticityWeight
		)
	end

	local function applySpeed()
		local targetSpeed = tonumber(mod.data.actives["walkspeed"]) or farming.__forcedSpeed
		if not targetSpeed or targetSpeed <= 0 then return end
		
		if mod.data.actives["move_speed"] ~= targetSpeed then
			mod.data.actives["move_speed"] = targetSpeed
		end

		if mod.data.actives["converting"] then return end
		local char = find.player.Character
		local humanoid = char and char:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.WalkSpeed ~= targetSpeed then
			humanoid.WalkSpeed = targetSpeed
		end
	end

	applyMass()

	farming.__speedConn = find.renderstepped:Connect(applySpeed)

	applySpeed()

	if farming.__charConn then
		farming.__charConn:Disconnect()
	end
	farming.__charConn = find.player.CharacterAdded:Connect(function()
		task.wait(1)
		applyMass()
		applySpeed()
	end)
end

function farming.convert(...)
	if aconvert then
		aconvert:Disconnect()
		aconvert = nil
	end

	if mod.data.actives["honey_mask"] == true then
		farming.honey_mask()
		task.wait(0.5)
	end

	local player = find.player
	local char = player.Character
	local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")

	if not humanoid or not root then
		mod.data.actives["converting"] = false
		mod.data.actives["move"] = false
		return
	end

	local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
	local hiveCommand = events and events:FindFirstChild("PlayerHiveCommand")

	if not hiveCommand or not hiveCommand:IsA("RemoteEvent") then
		warn("[convert] PlayerHiveCommand not found")
		mod.data.actives["converting"] = false
		mod.data.actives["move"] = false
		return
	end

	-- Точка, где обычно активируется Make Honey.
	local spawnPos = player:FindFirstChild("SpawnPos")
	local convertPos

	if spawnPos and spawnPos:IsA("CFrameValue") then
		convertPos = spawnPos.Value.Position + Vector3.new(0, 0, 6)
	end

	-- Подходим ближе к кнопке/падду.
	if convertPos and (root.Position - convertPos).Magnitude > 8 then
		humanoid:MoveTo(convertPos)

		local moveStart = tick()

		while tick() - moveStart < 5 do
			if not mod.data.actives["auto_farm"] then
				mod.data.actives["converting"] = false
				mod.data.actives["move"] = false
				return
			end

			char = player.Character
			humanoid = char and char:FindFirstChildOfClass("Humanoid")
			root = char and char:FindFirstChild("HumanoidRootPart")

			if not humanoid or not root then
				mod.data.actives["converting"] = false
				mod.data.actives["move"] = false
				return
			end

			if (root.Position - convertPos).Magnitude <= 7 then
				break
			end

			humanoid:MoveTo(convertPos)
			task.wait(0.1)
		end
	end

	local function isMakingHoney()
		local button = findActivateButton()
		if not button then
			return false
		end

		local textBox = button:FindFirstChild("TextBox", true)

		if textBox and textBox:IsA("TextLabel") then
			return textBox.Text == "Stop Making Honey"
		end

		return false
	end

	local function getPollen()
		local coreStats = player:FindFirstChild("CoreStats")
		local pollen = coreStats and coreStats:FindFirstChild("Pollen")

		if pollen and pollen:IsA("NumberValue") then
			return pollen.Value
		end

		local info = farming.get_pollen_info()
		return info and info.pollen
	end

	-- Если уже конвертация включена, второй Toggle НЕ отправляем.
	local beforePollen = getPollen()
	local started = isMakingHoney()

	if not started then
		pcall(function()
			hiveCommand:FireServer("ToggleHoneyMaking")
		end)
	end

	-- Проверяем, что реально начало конвертировать.
	local verifyStart = tick()

	while tick() - verifyStart < 10 do
		if not mod.data.actives["auto_farm"] then
			mod.data.actives["converting"] = false
			mod.data.actives["move"] = false
			return
		end

		if isMakingHoney() then
			started = true
			break
		end

		local pollen = getPollen()

		if beforePollen and pollen and pollen < beforePollen then
			started = true
			break
		end

		task.wait(0.2)
	end

	-- Fallback: если UI/remote не дал видимого состояния, один раз E.
	if not started then
		pcall(function()
			find.virtual:SendKeyEvent(true, Enum.KeyCode.E, false, game)
			task.wait(0.1)
			find.virtual:SendKeyEvent(false, Enum.KeyCode.E, false, game)
		end)

		local fallbackStart = tick()

		while tick() - fallbackStart < 5 do
			if isMakingHoney() then
				started = true
				break
			end

			local pollen = getPollen()

			if beforePollen and pollen and pollen < beforePollen then
				started = true
				break
			end

			task.wait(0.2)
		end
	end

	if not started then
		warn("[convert] Make Honey не запустился")

		mod.data.actives["converting"] = false
		mod.data.actives["move"] = false

		task.defer(function()
			task.wait(2)

			if mod.data.actives["auto_farm"] then
				farming.farm()
			end
		end)

		return
	end

	print("[convert] Make Honey started")

	local startTime = tick()
	local pollenZeroSince = nil

	aconvert = farming.conAF(
		find.prerender,
		4,
		function(delta)
			if not mod.data.actives["auto_farm"] then
				if aconvert then
					aconvert:Disconnect()
					aconvert = nil
				end

				mod.data.actives["converting"] = false
				mod.data.actives["move"] = false
				return
			end

			if tick() - startTime > 600 then
				if aconvert then
					aconvert:Disconnect()
					aconvert = nil
				end

				mod.data.actives["last_time_convert"] = tick()
				mod.data.actives["converting"] = false
				mod.data.actives["move"] = false

				task.defer(function()
					task.wait(2)

					if mod.data.actives["auto_farm"] then
						farming.farm()
					end
				end)

				return
			end

			local pollen = getPollen()

			if pollen == nil then
				return
			end

			if pollen <= 0 then
				pollenZeroSince = pollenZeroSince or tick()
			else
				pollenZeroSince = nil
			end

			if not pollenZeroSince then
				return
			end

			if tick() - pollenZeroSince < 2 then
				return
			end

			print("convert completed")

			if aconvert then
				aconvert:Disconnect()
				aconvert = nil
			end

			task.spawn(function()
				if mod.data.actives["balloon"] == true then
					local function findBalloonNear(pos)
						if not pos then return nil end
						local containers = {
							workspace:FindFirstChild("Balloons"),
							workspace:FindFirstChild("Effects"),
							workspace:FindFirstChild("FX"),
							workspace:FindFirstChild("Balloon"),
						}
						for _, container in ipairs(containers) do
							if container then
								for _, obj in ipairs(container:GetDescendants()) do
									if obj:IsA("BasePart")
										and obj.Name == "BalloonBody"
										and (obj.Position - pos).Magnitude <= 25
									then
										return obj
									end
								end
							end
						end
						return nil
					end
					
					local balloon = nil
					local appearStart = tick()
					while tick() - appearStart < 10 do
						if not mod.data.actives["auto_farm"] then return end

						local c2 = player.Character
						local r2 = c2 and c2:FindFirstChild("HumanoidRootPart")
						if r2 then
							balloon = findBalloonNear(r2.Position)
							if balloon then break end
						end
						task.wait(1)
					end

					if balloon then
						print("balloon found, waiting pop")
						local popStart = tick()
						while balloon.Parent and tick() - popStart < 300 do
							if not mod.data.actives["auto_farm"] then return end
							task.wait(1)
						end
						if not balloon.Parent then
							print("balloon converted")
						else
							print("balloon timeout")
						end
					else
						print("balloon not found 10s")
					end
				end

				local target_mask = mod.data.actives["mask"]

				if target_mask and target_mask ~= "None" then
					farming.equip_mask(target_mask)
					task.wait(0.4)
				end

				mod.data.actives["last_time_convert"] = tick()
				mod.data.actives["converting"] = false
				mod.data.actives["move"] = false

				if mod.data.actives["auto_farm"] then
					farming.farm()
				end
			end)
		end
	)
end

--function farming.convert(...)
--	if aconvert then
--		aconvert:Disconnect()
--		aconvert = nil
--	end

--	if mod.data.actives["honey_mask"] == true then
--		farming.honey_mask()
--	end

--	local eSucceeded = false
--	task.wait(1.5)
	
--	local btnWait = tick()
--	while tick() - btnWait < 15 do
--		if not mod.data.actives["auto_farm"] then
--			if aconvert then aconvert:Disconnect() aconvert = nil end
--			mod.data.actives["converting"] = false
--			mod.data.actives["move"] = false
--			return
--		end
--		local b = findActivateButton()
--		if b and b.Visible and b.AbsoluteSize.X > 0 then break end
--		task.wait(0.2)
--	end
	
--	local infoWait = tick()
--	while tick() - infoWait < 5 do
--		local info = farming.get_pollen_info()
--		if info and info.pollen ~= nil then break end
--		task.wait(0.2)
--	end
	
--	local before = farming.get_pollen_info()
--	local before_pollen = (before and before.pollen) or 0
	
--	local attempt = 0
--	local maxAttempts = 20

--	while not eSucceeded and attempt < maxAttempts do
--		attempt += 1

--		if not mod.data.actives["auto_farm"] then
--			if aconvert then aconvert:Disconnect() aconvert = nil end
--			mod.data.actives["converting"] = false
--			mod.data.actives["move"] = false
--			return
--		end
		
--		local nowBefore = farming.get_pollen_info()
--		if nowBefore and nowBefore.pollen then
--			before_pollen = nowBefore.pollen
--		end

--		activateButton()

--		local checkStart = tick()
--		local dropped = false

--		while tick() - checkStart < 8 do
--			task.wait(0.4)

--			local now = farming.get_pollen_info()
--			if now and now.pollen then
--				if now.pollen <= 0 then
--					dropped = true
--					break
--				end
--				if before_pollen > 0 and now.pollen < before_pollen then
--					dropped = true
--					break
--				end
--				if before_pollen <= 0 and now.pollen > 0 then
--					before_pollen = now.pollen
--				end
--			end
--		end

--		if dropped then
--			eSucceeded = true
--			print("convert started (try "..attempt..")")
--			break
--		end

--		task.wait(0.3)
--	end

--	if not eSucceeded then
--		warn("convert not a "..maxAttempts.." try")
--		if aconvert then aconvert:Disconnect() aconvert = nil end
--		mod.data.actives["converting"] = false
--		mod.data.actives["move"] = false

--		task.defer(function()
--			task.wait(2)
--			if mod.data.actives["auto_farm"] then
--				farming.farm()
--			end
--		end)
--		return
--	end
	
--	--for attempt = 1, 10 do
--	--	local before = farming.get_pollen_info()
--	--	local before_pollen = before and before.pollen or 0

--	--	activateButton()

--	--	local checkStart = tick()
--	--	while tick() - checkStart < 10 do
--	--		task.wait(1)

--	--		local now = farming.get_pollen_info()
--	--		if now then
--	--			if now.pollen <= 0 then
--	--				eSucceeded = true
--	--				break
--	--			end
--	--			if before_pollen > 0 and now.pollen < before_pollen - 50 then
--	--				eSucceeded = true
--	--				break
--	--			end
--	--		end
--	--	end

--	--	if eSucceeded then break end
--	--end

--	--if not eSucceeded then
--	--	if aconvert then aconvert:Disconnect() aconvert = nil end
--	--	mod.data.actives["converting"] = false
--	--	mod.data.actives["move"] = false

--	--	task.defer(function()
--	--		task.wait(2)
--	--		if mod.data.actives["auto_farm"] then
--	--			farming.farm()
--	--		end
--	--	end)
--	--	return
--	--end

--	local startTime = tick()
--	local pollenZeroSince = nil

--	aconvert = farming.conAF(
--		find.prerender,
--		4,
--		function(delta)

--			local info = farming.get_pollen_info()
--			if tick() - startTime > 600 then
--				if aconvert then
--					aconvert:Disconnect()
--					aconvert = nil
--				end

--				mod.data.actives["last_time_convert"] = tick()
--				mod.data.actives["converting"] = false
--				mod.data.actives["move"] = false

--				task.defer(function()
--					task.wait(3)

--					if mod.data.actives["auto_farm"] then
--						farming.farm()
--					end
--				end)

--				return
--			end

--			if not info then
--				return
--			end

--			if info.pollen <= 0 then
--				pollenZeroSince = pollenZeroSince or tick()
--			else
--				pollenZeroSince = nil
--			end

--			if not pollenZeroSince then
--				return
--			end

--			if tick() - pollenZeroSince < 2 then
--				return
--			end
--			print("completed autoconvert")

--			if aconvert then
--				aconvert:Disconnect()
--				aconvert = nil
--			end
			
--			task.spawn(function()
--				if mod.data.actives["balloon"] == true then
--					local char = find.player.Character
--					local root = char and char:FindFirstChild("HumanoidRootPart")
--					local playerPos = root and root.Position
					
--					local function findBalloonNear(pos)
--						if not pos then return nil end
						
--						local containers = {
--							workspace:FindFirstChild("Balloons"),
--							workspace:FindFirstChild("Effects"),
--							workspace:FindFirstChild("FX"),
--							workspace:FindFirstChild("Balloon"),
--						}

--						for _, container in ipairs(containers) do
--							if container then
--								for _, obj in ipairs(container:GetChildren()) do
--									if obj:IsA("BasePart")
--										and obj.Name == "BalloonBody"
--										and (obj.Position - pos).Magnitude <= 25
--									then
--										return obj
--									end
--								end
--							end
--						end
						
--						for _, obj in ipairs(workspace:GetChildren()) do
--							if obj:IsA("BasePart")
--								and obj.Name == "BalloonBody"
--								and (obj.Position - pos).Magnitude <= 25
--							then
--								return obj
--							end
--						end

--						return nil
--					end

--					local balloon = findBalloonNear(playerPos)

--					if balloon then
--						local balloonStart = tick()
--						while balloon.Parent do
--							if not mod.data.actives["auto_farm"] then return end
--							if tick() - balloonStart > 600 then break end
--							task.wait(3)
--						end
--						if not balloon.Parent then
--							print("balloon converted")
--						end
--					end
--				end

--				local target_mask = mod.data.actives["mask"]
--				if target_mask and target_mask ~= "None" then
--					farming.equip_mask(target_mask)
--					task.wait(0.4)
--				end

--				mod.data.actives["last_time_convert"] = tick()
--				mod.data.actives["converting"] = false
--				mod.data.actives["move"] = false

--				if mod.data.actives["auto_farm"] then
--					farming.farm()
--				end
--			end)

--			--task.spawn(function()
--			--	if mod.data.actives["balloon"] == true then
--			--		local hivePos = farming.getHive()

--			--		if hivePos then
--			--			local function findBalloonAt(hivePos)
--			--				if not hivePos then return nil end

--			--				local candidates = {
--			--					workspace,
--			--					workspace:FindFirstChild("Balloons"),
--			--					workspace:FindFirstChild("Effects"),
--			--					workspace:FindFirstChild("FX"),
--			--					workspace:FindFirstChild("Balloon"),
--			--				}

--			--				for _, container in ipairs(candidates) do
--			--					if container then
--			--						for _, obj in ipairs(container:GetChildren()) do
--			--							if obj.Name == "BalloonBody" and obj:IsA("BasePart") then
--			--								if (obj.Position - hivePos).Magnitude <= 25 then
--			--									return obj
--			--								end
--			--							end
--			--						end
--			--						for _, child in ipairs(container:GetChildren()) do
--			--							for _, obj in ipairs(child:GetChildren()) do
--			--								if obj.Name == "BalloonBody" and obj:IsA("BasePart") then
--			--									if (obj.Position - hivePos).Magnitude <= 25 then
--			--										return obj
--			--									end
--			--								end
--			--							end
--			--						end
--			--					end
--			--				end

--			--				return nil
--			--			end
						
--			--			local balloon = nil
--			--			local searchStart = tick()
--			--			while tick() - searchStart < 10 do
--			--				balloon = findBalloonAt(hivePos)
--			--				if balloon then break end
--			--				if not mod.data.actives["auto_farm"] then return end
--			--				task.wait(1)
--			--			end

--			--			if mod.data.actives["balloon"] == true then
--			--				local char = find.player.Character
--			--				local root = char and char:FindFirstChild("HumanoidRootPart")
--			--				local playerPos = root and root.Position

--			--				local balloon = nil
--			--				if playerPos then
--			--					for _, o in ipairs(workspace:GetDescendants()) do
--			--						if o.Name == "BalloonBody" and o:IsA("BasePart") then
--			--							if (o.Position - playerPos).Magnitude <= 25 then
--			--								balloon = o
--			--								break
--			--							end
--			--						end
--			--					end
--			--				end

--			--				if balloon then
--			--					--print("balloon found, waiting up to 10 min...")
--			--					local balloonStart = tick()
--			--					while balloon.Parent do
--			--						if not mod.data.actives["auto_farm"] then return end
--			--						if tick() - balloonStart > 600 then
--			--							--print("balloon timeout 10 min")
--			--							break
--			--						end
--			--						task.wait(3)
--			--					end
--			--					if not balloon.Parent then
--			--						print("balloon converted")
--			--					end
--			--				end
--			--			end
--			--		else
--			--			warn("not hive")
--			--		end
--			--	end

--			--	local target_mask = mod.data.actives["mask"]
--			--	if target_mask and target_mask ~= "None" then
--			--		farming.equip_mask(target_mask)
--			--		task.wait(0.4)
--			--	end

--			--	mod.data.actives["last_time_convert"] = tick()
--			--	mod.data.actives["converting"] = false
--			--	mod.data.actives["move"] = false

--			--	--task.wait(.4)

--			--	if mod.data.actives["auto_farm"] then
--			--		farming.farm()
--			--	end
--			--end)
--		end
--	)
--end

function farming.get_pollen_from_gui() -- ai
	local player = find.player
	local pg = player:FindFirstChild("PlayerGui")
	if not pg then return nil end

	local screenGui = pg:FindFirstChild("ScreenGui")
	local meterHud = screenGui and screenGui:FindFirstChild("MeterHUD")
	local pollenMeter = meterHud and meterHud:FindFirstChild("PollenMeter")
	local bar = pollenMeter and pollenMeter:FindFirstChild("Bar")
	local label = bar and bar:FindFirstChild("TextLabel")

	if not label or not label:IsA("TextLabel") then
		return nil
	end

	local text = label.Text
	local current, max = string.match(text, "([%d,]+)/([%d,]+)")
	if not current or not max then
		return nil
	end

	current = tonumber(string.gsub(current, ",", "")) or 0
	max = tonumber(string.gsub(max, ",", "")) or 0

	if max <= 0 then
		return nil
	end

	return {
		pollen = current,
		max = max,
		percent = (current / max) * 100,
	}
end

--function farming.autosprinkler()
--	if mod.data.actives["auto_sprinkler"] ~= true then return end
--	if mod.data.actives["move"] == true then return end

--	local character = find.player.Character
--	local root = character and character:FindFirstChild("HumanoidRootPart")
--	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

--	local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
--	if not events then return end

--	local pac = events:FindFirstChild("PlayerActivesCommand")
--	if not pac or not pac:IsA("RemoteEvent") then return end

--	pac:FireServer({Name = "Sprinkler Builder"})
--	print("autosprinkler point")
--end

function farming.autosprinkler()
	if mod.data.actives["auto_sprinkler"] ~= true then return end
	if mod.data.actives["move"] == true then return end

	local Events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
	if not Events then return end

	local pac = Events:FindFirstChild("PlayerActivesCommand")
	if not pac or not pac:IsA("RemoteEvent") then return end

	pac:FireServer({Name = "Sprinkler Builder"})
	--print("autosprinkler fired")
end

function farming.wealthClock()
	if farming.__wealthConn then
		farming.__wealthConn = nil
	end

	local startTime = tick()
	local nextTrigger = startTime + 3600

	task.spawn(function()
		while mod.data.actives["auto_farm"] == true do
			task.wait(1)
			if mod.data.actives["weatlh_clock"] ~= true then
				startTime = tick()
				nextTrigger = startTime + 3600
				continue
			end

			if tick() < nextTrigger then
				continue
			end
			
			local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
			local toyEvent = events and events:FindFirstChild("ToyEvent")

			if toyEvent and toyEvent:IsA("RemoteEvent") then
				for i = 1, 3 do
					pcall(function()
						toyEvent:FireServer("Wealth Clock")
					end)
					--print("[wealth clock] attempt", i)
					task.wait(3)
				end
			end

			nextTrigger = tick() + 3600
		end
	end)
end

local function getStats()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local events = ReplicatedStorage:FindFirstChild("Events")
	if not events then return nil end

	local ok, result = pcall(function()
		return events:WaitForChild("RetrievePlayerStats"):InvokeServer()
	end)

	if ok and type(result) == "table" then
		return result
	end
	return nil
end

function farming.equip_mask(name)
	if type(name) ~= "string" or name == "" or name == "None" then
		return false
	end

	local Events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
	if not Events then return false end

	local ItemPackageEvent = Events:FindFirstChild("ItemPackageEvent")
	if not ItemPackageEvent then return false end
	ItemPackageEvent:InvokeServer("Equip", {
		Mute = false,
		Type = name,
		Category = "Accessory"
	})

	return true
end

function farming.honey_mask()	
	return farming.equip_mask("Honey Mask")
end

function farming.get_pollen_info() -- ai
	local player = find.player
	local pg = player:FindFirstChild("PlayerGui")
	if not pg then return nil end

	local screenGui = pg:FindFirstChild("ScreenGui")
	local meterHud = screenGui and screenGui:FindFirstChild("MeterHUD")
	local pollenMeter = meterHud and meterHud:FindFirstChild("PollenMeter")
	local bar = pollenMeter and pollenMeter:FindFirstChild("Bar")
	local label = bar and bar:FindFirstChild("TextLabel")

	if not label or not label:IsA("TextLabel") then
		return nil
	end

	local text = label.Text
	local current, max = string.match(text, "([%d,]+)/([%d,]+)")
	if not current or not max then
		return nil
	end

	current = tonumber((string.gsub(current, ",", ""))) or 0
	max = tonumber((string.gsub(max, ",", ""))) or 0

	if max <= 0 then
		return nil
	end

	return {
		pollen = current,
		max = max,
		percent = (current / max) * 100,
	}
end

function farming.getHive(...)
	local honeycombs = workspace:FindFirstChild("Honeycombs")
	if not honeycombs then return end

	local pos = nil

	for _, hive in ipairs(honeycombs:GetChildren()) do
		local display = hive:FindFirstChild("Display")
		local gui = display and display:FindFirstChild("Gui")
		local frame = gui and gui:FindFirstChild("Frame")
		local name = frame and frame:FindFirstChild("OwnerName")

		if name and name:IsA("TextLabel") then
			local trimmed = string.match(name.Text, "^%s*(.-)%s*$") or ""
			if string.lower(trimmed) == string.lower(find.player.Name) then
				local spawnPos = hive:FindFirstChild("SpawnPos")
				if spawnPos then
					if spawnPos:IsA("BasePart") then pos = spawnPos.Position
					elseif spawnPos:IsA("CFrameValue") then pos = spawnPos.Value.Position
					elseif spawnPos:IsA("Attachment") then pos = spawnPos.WorldPosition
					elseif spawnPos:IsA("Vector3Value") then pos = spawnPos.Value end
				end
			end
		end
	end

	return pos
end

function farming.autoHive(...)
	if mod.data.actives["autohive"] == false then
		return
	end

	local honeycombs = workspace:FindFirstChild("Honeycombs")
	if not honeycombs then
		return
	end

	if afarm then
		afarm:Disconnect()
		afarm = nil
	end

	if tween then
		tween:Cancel()
		tween = nil
	end

	if atween then
		atween:Cancel()
		atween = nil
	end

	table.clear(queue["auto_farm"])
	table.clear(queue["tokens"])
	farmId += 1

	local character = find.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if humanoid and root then
		humanoid:MoveTo(root.Position)
		humanoid:Move(Vector3.zero, false)

		root.Anchored = false
	end

	mod.data.actives["point"] = false
	mod.data.actives["converting"] = false
	-- mod.data.actives["move"] = true   <-- УБРАНО: иначе farming.move("hive", ...) отсекается guard'ом

	farming.cornl(false)
	farming.inv(false)

	local activeNames = {}

	for _, p in ipairs(find.players:GetPlayers()) do
		activeNames[string.lower(p.Name)] = true
	end

	local myName = string.lower(find.player.Name)

	local myHivePos = nil
	local freeHivePos = nil

	local EMPTY = {
		[""] = true,
		[" "] = true,
		["-"] = true,
		["--"] = true,
		["—"] = true,
		["none"] = true,
		["empty"] = true,
		["free"] = true,
		["n/a"] = true,
	}

	for _, hive in ipairs(honeycombs:GetChildren()) do
		local display = hive:FindFirstChild("Display")
		local gui = display and display:FindFirstChild("Gui")
		local frame = gui and gui:FindFirstChild("Frame")
		local name = frame and frame:FindFirstChild("OwnerName")

		if name and name:IsA("TextLabel") then
			local trimmed =
				string.match(name.Text, "^%s*(.-)%s*$") or ""

			local lower = string.lower(trimmed)

			if lower == myName then
				local spawnPos = hive:FindFirstChild("SpawnPos")

				if spawnPos then
					if spawnPos:IsA("BasePart") then
						myHivePos = spawnPos.Position
					elseif spawnPos:IsA("CFrameValue") then
						myHivePos = spawnPos.Value.Position
					elseif spawnPos:IsA("Attachment") then
						myHivePos = spawnPos.WorldPosition
					elseif spawnPos:IsA("Vector3Value") then
						myHivePos = spawnPos.Value
					end
				end

				if myHivePos then
					break
				end
			end

			if not freeHivePos and lower ~= myName then
				local isFree =
					EMPTY[lower] == true
					or not activeNames[lower]

				if isFree then
					local spawnPos = hive:FindFirstChild("SpawnPos")

					if spawnPos then
						if spawnPos:IsA("BasePart") then
							freeHivePos = spawnPos.Position
						elseif spawnPos:IsA("CFrameValue") then
							freeHivePos = spawnPos.Value.Position
						elseif spawnPos:IsA("Attachment") then
							freeHivePos = spawnPos.WorldPosition
						elseif spawnPos:IsA("Vector3Value") then
							freeHivePos = spawnPos.Value
						end
					end
				end
			end
		end
	end

	local targetPos = myHivePos or freeHivePos

	if not targetPos then
		mod.data.actives["move"] = false
		return
	end

	farming.move(
		"hive",
		mod.data.actives["walkspeed"],
		targetPos
	)
end

local function stopTweenWalkAnimation()
	if track then
		pcall(function()
			if track.IsPlaying then
				track:Stop(0.1)
			end
		end)
	end

	track = nil
	animwalk = nil
end

local function resetFarmMovement(enabled)
	if afarm then
		afarm:Disconnect()
		afarm = nil
	end

	if tween then
		tween:Cancel()
		tween = nil
	end

	if atween then
		atween:Cancel()
		atween = nil
	end
	
	stopTweenWalkAnimation()
	
	if aconvert then
		aconvert:Disconnect()
		aconvert = nil
	end

	clearFarmLines()

	table.clear(queue["auto_farm"])
	table.clear(queue["tokens"])

	local character = find.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if humanoid and root then
		humanoid:MoveTo(root.Position)
		humanoid:Move(Vector3.zero)
		root.Anchored = false
	end

	mod.data.actives["point"] = false
	mod.data.actives["move"] = false
	mod.data.actives["converting"] = false

	farming.cornl(enabled)
	farming.inv(enabled)
end

local autoDigId = 0
function farming.autoDig(enabled)
	autoDigId += 1
	local id = autoDigId
	if adig then
		adig:Disconnect()
		adig = nil
	end

	if enabled ~= true then return end
	local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
	local collect = events and events:FindFirstChild("ToolCollect")
	if not collect or not collect:IsA("RemoteEvent") then
		warn("tool is not find")
		return
	end

	adig = farming.conAF(
		find.prerender, 4,
		function(delta)
			if mod.data.actives["auto_dig"] == true and autoDigId == id then
				collect:FireServer()
			else
				if adig then
					adig:Disconnect()
					adig = nil
				end
			end
		end
	)
end

function farming.farm(...)
	farmId += 1
	local id = farmId
	local enabled = mod.data.actives["auto_farm"] == true

	resetFarmMovement(enabled)

	if not enabled then return end
	
	local hivePos = farming.getHive()
	if not hivePos then
		--mod.data.actives["auto_farm"] = false
		resetFarmMovement(false)
		farming.autoHive()
		return
	end
	
	local target_mask = mod.data.actives["mask"]
	if target_mask and target_mask ~= "None" then
		farming.equip_mask(target_mask)
		task.wait(0.4)
	end
	
	local pos = hivePos
	print(pos)

	local selected = mod.data.actives["selected_field"]
	local fields = workspace:FindFirstChild("FlowerZones")
	local field = fields and selected and fields:FindFirstChild(selected)

	if not field then
		warn(
			"not field:",
			"field: ", selected,
			"zone: ", fields
		)

		mod.data.actives.auto_farm = false
		resetFarmMovement(false)
		return
	end
	
	farming.move(
		"flowerzones",
		mod.data.actives["walkspeed"],
		selected
	)
	
	--farming.move(
	--	"flowerzones",
	--	mod.data.actives["move_speed"],
	--	selected
	--)

	--mod.data.actives["__last_convert_time"] = tick()

	if mod.data.actives["selected_field"] == "" then
		mod.data.actives["auto_farm"] = false
		return
	end

	local function j(a)
		if a then
			find.player.Character:FindFirstChildOfClass("Humanoid").Jump = true
			find.player.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.None)
			task.wait(.01)
			find.player.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.Freefall)
		else
			find.player.Character:FindFirstChildOfClass("Humanoid").Jump = false
			find.player.Character:FindFirstChildOfClass("Humanoid"):ChangeState(Enum.HumanoidStateType.None)
		end
	end

	local function r(...)
		local a = {...}

		if a[1] == nil then
			return
		end

		local h = .4

		local marginX = math.min(6, a[1].Size.X * .15)
		local marginZ = math.min(6, a[1].Size.Z * .15)
		local x = a[1].Size.X / 2 - marginX
		local z = a[1].Size.Z / 2 - marginZ

		mod.data.actives["position_field"] = string.lower(mod.data.actives["position_field"] or "center")
		local ix, ax

		if mod.data.actives["position_field"] == "left" then
			ix = -x
			ax = 0
		elseif mod.data.actives["position_field"] == "right" then
			ix = 0
			ax = x
		else
			ix = -x / 3
			ax = x / 3
		end

		local l = Vector3.new(find.random:NextNumber(ix, ax), a[1].Size.Y / 2 + h, find.random:NextNumber(-z, z))
		return a[1].CFrame:PointToWorldSpace(l)
	end
	
	local textureToPriority = {}

	local function buildTextureMap()
		textureToPriority = {}

		local prios = mod.data.actives["token_priorities"] or {}

		local function addFrom(list)
			for _, v in ipairs(list or {}) do
				local p = prios[v.name]
				if p then
					textureToPriority[v.image] = tonumber(p) or 0
				end
			end
		end

		addFrom(mod.data.token_resources)
		addFrom(mod.data.tokens)
	end

	buildTextureMap()
	function farming.rebuildTextureMap()
		buildTextureMap()
	end
	
	local function getTokenPriority(token)
		for _, child in ipairs(token:GetChildren()) do
			if child:IsA("Decal") then
				return textureToPriority[child.Texture] or 0
			end
		end
		if token.Name == "Bubble" or token.Name == "GoldBubble" then
			return tonumber(mod.data.actives["bubble_priority"]) or 0
		end
		return 0
	end

	local function q(...)
		if mod.data.actives["point"] then
			return
		end

		mod.data.actives["point"] = true

		local function i(token, field)
			local p = field.CFrame:PointToObjectSpace(token.Position)
			local s = field.Size / 2

			return math.abs(p.X) <= s.X and math.abs(p.Z) <= s.Z and p.Y >= -3 and p.Y <= 15
		end

		local function b(...)
			local a = {...}

			local l = workspace:FindFirstChild("Lines_Cub")

			if not l then
				l = Instance.new("Folder")
				l.Name = "Lines_Cub"
				l.Parent = workspace
			end
			local p = Instance.new("Part"); p.Name = "Attach_"..find.httpservice:GenerateGUID(false); p.Position = a[3]; p.Size = Vector3.new(1, 1, 1); p.CanCollide = false; p.Anchored = true; p.Transparency = 1; p.Parent = l
			local m1 = Instance.new("Attachment"); m1.Name = "Attachment"; m1.Parent = p;

			local s = Instance.new("SelectionBox")
			s.Parent = p; s.Adornee = p; s.Color3 = Color3.new(255, 255, 255); s.SurfaceColor3 = Color3.new(255, 255, 255); s.LineThickness = .04; s.SurfaceTransparency = .9

			local function d(...)
				if p then
					for _, v in pairs(l:GetChildren()) do
						v:Destroy()
					end
				end
			end

			if a[1] == true then
				local m = Instance.new("Attachment"); m.Name = "Attachment"; m.Parent = a[2];
				local b = Instance.new("Beam"); b.Parent = a[2]; b.Width0 = .2; b.Width1 = .2; b.Attachment0 = m; b.Attachment1 = m1; b.FaceCamera = true; b.TextureLength = 1; b.LightEmission = 1; b.Transparency = NumberSequence.new(0, 0)
			elseif a[1] == false then
				a[2].Attachment:Destroy(); a[2].Beam:Destroy();
				d(...)
			end
		end

		local function m(...)
			local a = {...}
			
			--if mod.data.actives["converting"] then return end

			---- НЕ двигаем, если идёт конвертация или игрок анкорен
			--if mod.data.actives["__converting"] then
			--	return
			--end

			if mod.data.actives["auto_farm"] == false then
				return
			end

			if not find.player.Character:FindFirstChild("HumanoidRootPart") then return end

			local checkRoot = find.player.Character:FindFirstChild("HumanoidRootPart")
			if checkRoot.Anchored then return end

			if typeof(a[1]) == "CFrame" then
				p = a[1].Position
			elseif typeof(a[1]) == "Instance" and a[1]:IsA("BasePart") then
				local lp = a[3].CFrame:PointToObjectSpace(a[1].Position)
				--p = a[3].CFrame:PointToWorldSpace(Vector3.new(lp.X, a[3].Size.Y / 2, lp.Z ))
				local hip = find.player.Character:FindFirstChildOfClass("Humanoid").HipHeight
				p = a[3].CFrame:PointToWorldSpace(Vector3.new(lp.X, a[3].Size.Y / 2 + hip, lp.Z))
			else
				return
			end

			local d = Vector3.new(p.X - find.player.Character:FindFirstChild("HumanoidRootPart").Position.X, 0, p.Z - find.player.Character:FindFirstChild("HumanoidRootPart").Position.Z)
			local cf = d.Magnitude > .001 and CFrame.lookAt(p, p + d.Unit) or CFrame.new(p) * find.player.Character:FindFirstChild("HumanoidRootPart").CFrame.Rotation
			local t = Vector3.new(find.player.Character:FindFirstChild("HumanoidRootPart").Position.X - p.X, 0, find.player.Character:FindFirstChild("HumanoidRootPart").Position.Z - p.Z).Magnitude / math.max(a[2], .001)

			if find.player.Character:FindFirstChild("Animate").run:FindFirstChildWhichIsA("Animation") then
				local an = find.player.Character:FindFirstChildOfClass("Humanoid").Animator

				if not track or animwalk ~= an then
					if track then track:Destroy()end
					animwalk = an
					track = animwalk:LoadAnimation(find.player.Character:FindFirstChild("Animate").run:FindFirstChildWhichIsA("Animation"))
					track.Looped = true
				end

				if not track.IsPlaying then track:Play() end
				track:AdjustSpeed(math.clamp(a[2] / 16, .25, 3))
			end

			local tween = find.tweenservice:Create(find.player.Character:FindFirstChild("HumanoidRootPart"), TweenInfo.new(t, Enum.EasingStyle.Linear), {CFrame = cf})
			atween = tween
			tween:Play()
			tween.Completed:Wait()

			--if mod.data.actives["__converting"] then
			--	if track and track.IsPlaying then track:Stop(0) end
			--	return
			--end

			--if atween == tween then
			--	atween = nil
			--end

			--if id ~= farmId then
			--	return
			--end
			--if mod.data.actives["lines"] == true then
			--	tween:Play()
			--	--b(true, find.player.Character:FindFirstChild("HumanoidRootPart"), p)
			--	tween.Completed:Wait()
			--	--b(false, find.player.Character:FindFirstChild("HumanoidRootPart"), p)
			--	if track and track.IsPlaying then track:Stop(.1) end
			--elseif mod.data.actives["lines"] == false then
			--	tween:Play()
			--	tween.Completed:Wait()
			--	if track and track.IsPlaying then track:Stop(.1) end
			--end

			if atween == tween then atween = nil end
			if id ~= farmId then return end
			
			if mod.data.actives["converting"] then
				if track and track.IsPlaying then track:Stop(.1) end
			end

			--if track and track.IsPlaying then track:Stop(.1) end
		end

		while id == farmId and mod.data.actives["auto_farm"] == true and #queue["auto_farm"] > 0 and not mod.data.actives["converting"] do
			local a = table.remove(queue["auto_farm"], 1)
			local c = workspace:FindFirstChild("Collectibles")
			local f = workspace:FindFirstChild("FlowerZones")
			local d = mod.data.actives["selected_field"]
			--local root = find.player.Character
			local ch = find.player.Character
			local root = ch and ch:FindFirstChild("HumanoidRootPart")
			local field

			if mod.data.actives["selected_field"] == false then field = nil else field = f:FindFirstChild(mod.data.actives["selected_field"]) end
			
			if mod.data.actives["petals"] == true and field then
				farming.farmPetalBloom(field, id)
			end
			
			if mod.data.actives["pushrooms_enabled"] == true and field then
				farming.farmPuffshroom(field, id)
			end

			table.clear(queue["tokens"])
			
			if c and field then
				local rt = find.player.Character and find.player.Character:FindFirstChild("HumanoidRootPart")
				if rt then
					for _, v in ipairs(c:GetChildren()) do
						if v:IsA("BasePart")
							and i(v, field)
							and (rt.Position - v.Position).Magnitude > 4
						then
							table.insert(queue["tokens"], v)
						end
					end
				end
			end
			
			if mod.data.actives["collect_bubbles"] == true and field then
				initBubbles()
				local rt = find.player.Character and find.player.Character:FindFirstChild("HumanoidRootPart")
				if rt then
					for bubble in pairs(bubbles) do
						if bubble.Parent
							and isInField(bubble.Position, field)
							and (rt.Position - bubble.Position).Magnitude > 4
						then
							table.insert(queue["tokens"], bubble)
						end
					end
				end
			end

			if #queue["tokens"] > 0 then
				while id == farmId and mod.data.actives["auto_farm"] == true and #queue["tokens"] > 0 do
					local rt = find.player.Character and find.player.Character:FindFirstChild("HumanoidRootPart")
					if not rt then break end

					table.sort(queue["tokens"], function(x, y)
						local pa = getTokenPriority(x)
						local pb = getTokenPriority(y)
						if pa ~= pb then
							return pa > pb
						end
						return (rt.Position - x.Position).Magnitude
							< (rt.Position - y.Position).Magnitude
					end)

					local v = table.remove(queue["tokens"], 1)
					if v and v.Parent and a.Speed then
						m(v, a.Speed, field)
					end

					task.wait(0.1)
				end
			else
				if a.TargetCFrame and a.Speed then
					m(a.TargetCFrame, a.Speed, field)
				end
			end
			
			task.wait()
		end

		mod.data.actives["point"] = false
	end

	local function m(...)
		local a = {...}
		if not find.player.Character:FindFirstChild("HumanoidRootPart") then
			return
		end

		local tg = r(a[1])
		local tgc = CFrame.new(tg) * find.player.Character:FindFirstChild("HumanoidRootPart").CFrame.Rotation

		table.insert(queue["auto_farm"], {TargetCFrame = tgc, Speed = a[2]})

		if not mod.data.actives["move"] then
			task.spawn(q)
		end
	end
	
	local function q1(...)
		if mod.data.actives["point"] then
			return
		end

		mod.data.actives["point"] = true

		local function isTokenInField(token, field)
			local p = field.CFrame:PointToObjectSpace(token.Position)
			local s = field.Size / 2

			return math.abs(p.X) <= s.X
				and math.abs(p.Z) <= s.Z
				and p.Y >= -3
				and p.Y <= 15
		end

		local function walkTo(targetPos, speed)
			local char = find.player.Character
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			local root = char and char:FindFirstChild("HumanoidRootPart")

			if not hum or not root or root.Anchored then
				return
			end

			hum.WalkSpeed = speed

			local startTime = tick()
			local lastPos = root.Position
			local stuckCount = 0
			local flatTarget = Vector3.new(targetPos.X, root.Position.Y, targetPos.Z)

			while tick() - startTime < 10 do
				if id ~= farmId
					or mod.data.actives["auto_farm"] ~= true
					or mod.data.actives["converting"]
				then
					local c2 = find.player.Character
					local h2 = c2 and c2:FindFirstChildOfClass("Humanoid")
					if h2 then h2:Move(Vector3.zero, false) end
					return
				end

				char = find.player.Character
				hum = char and char:FindFirstChildOfClass("Humanoid")
				root = char and char:FindFirstChild("HumanoidRootPart")

				if not hum or not root or root.Anchored then
					return
				end

				local dx = targetPos.X - root.Position.X
				local dz = targetPos.Z - root.Position.Z
				local distance = math.sqrt(dx * dx + dz * dz)
				
				if distance <= 1.5 then
					hum:Move(Vector3.zero, false)
					return
				end

				hum.WalkSpeed = speed
				flatTarget = Vector3.new(targetPos.X, root.Position.Y, targetPos.Z)
				hum:MoveTo(flatTarget)

				if (root.Position - lastPos).Magnitude < 0.1 then
					stuckCount += 1
					if stuckCount > 45 then
						hum.Jump = true
						task.wait(0.1)
						hum.Jump = false
						stuckCount = 0
					end
				else
					stuckCount = 0
				end
				lastPos = root.Position

				task.wait()
			end

			local c3 = find.player.Character
			local h3 = c3 and c3:FindFirstChildOfClass("Humanoid")
			if h3 then h3:Move(Vector3.zero, false) end
		end

		while id == farmId
			and mod.data.actives["auto_farm"] == true
			and #queue["auto_farm"] > 0
			and not mod.data.actives["converting"]
		do
			local a = table.remove(queue["auto_farm"], 1)
			local c = workspace:FindFirstChild("Collectibles")
			local f = workspace:FindFirstChild("FlowerZones")
			local field

			if mod.data.actives["selected_field"] == false then
				field = nil
			else
				field = f and f:FindFirstChild(mod.data.actives["selected_field"])
			end
			
			if mod.data.actives["petals"] == true and field then
				local bloomFound = getNearestBloom(
					field,
					find.player.Character
						and find.player.Character:FindFirstChild("HumanoidRootPart")
				)

				if bloomFound then
					farming.farmPetalBloom(field, id)
					continue
				end
			end

			if mod.data.actives["pushrooms_enabled"] == true and field then
				local puffFound = getNearestPuff(
					field,
					find.player.Character
						and find.player.Character:FindFirstChild("HumanoidRootPart"),
					mod.data.actives["pushrooms"] or "All Pushrooms"
				)

				if puffFound then
					farming.farmPuffshroom(field, id)

					-- После гриба НЕ идём в случайную точку.
					-- Следующий цикл сразу снова ищет гриб.
					continue
				end
			end

			table.clear(queue["tokens"])
			
			if c and field then
				local rt = find.player.Character and find.player.Character:FindFirstChild("HumanoidRootPart")
				if rt then
					for _, v in ipairs(c:GetChildren()) do
						if v:IsA("BasePart")
							and isTokenInField(v, field)
							and (rt.Position - v.Position).Magnitude > 2
						then
							table.insert(queue["tokens"], v)
						end
					end
				end
			end
			
			if mod.data.actives["collect_bubbles"] == true and field then
				initBubbles()
				local rt = find.player.Character and find.player.Character:FindFirstChild("HumanoidRootPart")
				if rt then
					for bubble in pairs(bubbles) do
						if bubble.Parent
							and isInField(bubble.Position, field)
							and (rt.Position - bubble.Position).Magnitude > 2
						then
							table.insert(queue["tokens"], bubble)
						end
					end
				end
			end

			if #queue["tokens"] > 0 then
				while id == farmId
					and mod.data.actives["auto_farm"] == true
					and #queue["tokens"] > 0
				do
					local rt = find.player.Character and find.player.Character:FindFirstChild("HumanoidRootPart")
					if not rt then break end

					table.sort(queue["tokens"], function(x, y)
						local pa = getTokenPriority(x)
						local pb = getTokenPriority(y)
						if pa ~= pb then
							return pa > pb
						end
						return (rt.Position - x.Position).Magnitude
							< (rt.Position - y.Position).Magnitude
					end)

					local v = table.remove(queue["tokens"], 1)
					if v and v.Parent and a.Speed then
						walkTo(v.Position, a.Speed)
					end

					task.wait()
				end
			else
				if a.TargetPosition and a.Speed then
					walkTo(a.TargetPosition, a.Speed)
				end
			end

			task.wait()
		end

		mod.data.actives["point"] = false
	end
	
	--local function q1(...)
	--	if mod.data.actives["point"] then
	--		return
	--	end

	--	mod.data.actives["point"] = true

	--	local function i(token, field)
	--		local p = field.CFrame:PointToObjectSpace(token.Position)
	--		local s = field.Size / 2

	--		return math.abs(p.X) <= s.X and math.abs(p.Z) <= s.Z and p.Y >= -3 and p.Y <= 15
	--	end

	--	local function b(...)
	--		local a = {...}

	--		local l = workspace:FindFirstChild("Lines_Cub")

	--		if not l then
	--			l = Instance.new("Folder")
	--			l.Name = "Lines_Cub"
	--			l.Parent = workspace
	--		end
	--		local p = Instance.new("Part"); p.Name = "Attach_"..find.httpservice:GenerateGUID(false); p.Position = a[3]; p.Size = Vector3.new(1, 1, 1); p.CanCollide = false; p.Anchored = true; p.Transparency = 1; p.Parent = l
	--		local m1 = Instance.new("Attachment"); m1.Name = "Attachment"; m1.Parent = p;

	--		local s = Instance.new("SelectionBox")
	--		s.Parent = p; s.Adornee = p; s.Color3 = Color3.new(255, 255, 255); s.SurfaceColor3 = Color3.new(255, 255, 255); s.LineThickness = .04; s.SurfaceTransparency = .9

	--		local function d(...)
	--			if p then
	--				for _, v in pairs(l:GetChildren()) do
	--					v:Destroy()
	--				end
	--			end
	--		end

	--		if a[1] == true then
	--			local m = Instance.new("Attachment"); m.Name = "Attachment"; m.Parent = a[2];
	--			local b = Instance.new("Beam"); b.Parent = a[2]; b.Width0 = .2; b.Width1 = .2; b.Attachment0 = m; b.Attachment1 = m1; b.FaceCamera = true; b.TextureLength = 1; b.LightEmission = 1; b.Transparency = NumberSequence.new(0, 0)
	--		elseif a[1] == false then
	--			a[2].Attachment:Destroy(); a[2].Beam:Destroy();
	--			d(...)
	--		end
	--	end

	--	while id == farmId and mod.data.actives["auto_farm"] == true and #queue["auto_farm"] > 0 and not mod.data.actives["converting"] do
	--		local a = table.remove(queue["auto_farm"], 1)
	--		local c = workspace:FindFirstChild("Collectibles")
	--		local f = workspace:FindFirstChild("FlowerZones")
	--		local d = mod.data.actives["selected_field"]
	--		local field

	--		if mod.data.actives["selected_field"] == false then field = nil else field = f:FindFirstChild(mod.data.actives["selected_field"]) end

	--		table.clear(queue["tokens"])

	--		if c and field then
	--			local root = find.player.Character
	--				and find.player.Character:FindFirstChild("HumanoidRootPart")

	--			if root then
	--				for _, v in ipairs(c:GetChildren()) do
	--					if v:IsA("BasePart")
	--						and i(v, field)
	--						and (root.Position - v.Position).Magnitude > 4
	--					then
	--						table.insert(queue["tokens"], v)
	--					end
	--				end
	--			end
	--		end
			
	--		local function m(...)
	--			local a = {...}

	--			if mod.data.actives["converting"] then return false end

	--			local char = find.player.Character
	--			local humanoid = char and char:FindFirstChildOfClass("Humanoid")
	--			local root = char and char:FindFirstChild("HumanoidRootPart")
	--			if not humanoid or not root or not a[1] or not a[2] then return false end

	--			if root.Anchored then return false end

	--			local targetPos
	--			if typeof(a[1]) == "Instance" and a[1]:IsA("BasePart") then
	--				if not a[1].Parent then return true end
	--				targetPos = Vector3.new(a[1].Position.X, root.Position.Y, a[1].Position.Z)
	--			else
	--				targetPos = Vector3.new(a[1].X, root.Position.Y, a[1].Z)
	--			end

	--			humanoid.WalkSpeed = a[2]
	--			humanoid:MoveTo(targetPos)

	--			local startMove = tick()
	--			local lastPos = root.Position
	--			local stuckCount = 0

	--			while tick() - startMove < 15 do
	--				if mod.data.actives["converting"] then
	--					humanoid:MoveTo(root.Position)
	--					humanoid:Move(Vector3.zero)
	--					return false
	--				end
	--				if id ~= farmId then
	--					humanoid:MoveTo(root.Position)
	--					humanoid:Move(Vector3.zero)
	--					return false
	--				end
					
	--				if typeof(a[1]) == "Instance" then
	--					if not a[1].Parent then return true end
	--					targetPos = Vector3.new(a[1].Position.X, root.Position.Y, a[1].Position.Z)
	--				end

	--				local dist = (Vector3.new(root.Position.X, 0, root.Position.Z)
	--					- Vector3.new(targetPos.X, 0, targetPos.Z)).Magnitude

	--				--if dist <= 4 then
	--				--	humanoid:MoveTo(root.Position)
	--				--	humanoid:Move(Vector3.zero)
	--				--	return true
	--				--end
					
	--				if dist <= 5 then
	--					return true
	--				end
					
	--				if (root.Position - lastPos).Magnitude < 0.1 then
	--					stuckCount += 1
	--					if stuckCount > 30 then
	--						humanoid:MoveTo(root.Position)
	--						humanoid:Move(Vector3.zero)
	--						return false
	--					end
	--				else
	--					stuckCount = 0
	--				end
	--				lastPos = root.Position
	--				--task.wait(0.05)
	--			end

	--			humanoid:MoveTo(root.Position)
	--			humanoid:Move(Vector3.zero)
	--			return false
	--		end

	--		--local function m(...)
	--		--	local a = {...}
				
	--		--	--if mod.data.actives["__converting"] then
	--		--	--	return
	--		--	--end
				
	--		--	if mod.data.actives["converting"] then
	--		--		return
	--		--	end

	--		--	if not find.player.Character:FindFirstChildOfClass("Humanoid") or not find.player.Character:FindFirstChild("HumanoidRootPart") or not a[1] or not a[2] then
	--		--		return
	--		--	end

	--		--	local checkRoot = find.player.Character:FindFirstChild("HumanoidRootPart")
	--		--	if checkRoot.Anchored then return end

	--		--	if typeof(a[1]) == "Instance" and a[1]:IsA("BasePart") then
	--		--		p1 = Vector3.new(a[1].Position.X, find.player.Character:FindFirstChild("HumanoidRootPart").Position.Y, a[1].Position.Z)
	--		--	else
	--		--		p1 = a[1]
	--		--	end

	--		--	find.player.Character:FindFirstChild("HumanoidRootPart").Anchored = false
	--		--	find.player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = a[2]
	--		--	find.player.Character:FindFirstChildOfClass("Humanoid"):MoveTo(p1)
	--		--	--b(true, find.player.Character:FindFirstChild("HumanoidRootPart"), p1)
	--		--	local r = find.player.Character:FindFirstChild("HumanoidRootPart")
	--		--	local p = r.CurrentPhysicalProperties

	--		--	r.Massless = false
	--		--	r.CustomPhysicalProperties = PhysicalProperties.new(
	--		--		20,
	--		--		p.Friction,
	--		--		p.Elasticity,
	--		--		p.FrictionWeight,
	--		--		p.ElasticityWeight
	--		--	)
	--		--	--find.player.Character:FindFirstChildOfClass("Humanoid").MoveToFinished:Wait()
	--		--	--if mod.data.actives["converting"] then
	--		--	--	return
	--		--	--end
	--		--	--if id ~= farmId then return end
				
	--		--	find.player.Character:FindFirstChildOfClass("Humanoid").MoveToFinished:Wait()
	--		--	if mod.data.actives["converting"] then
	--		--		find.player.Character:FindFirstChildOfClass("Humanoid"):MoveTo(
	--		--			find.player.Character:FindFirstChild("HumanoidRootPart").Position
	--		--		)
	--		--		find.player.Character:FindFirstChildOfClass("Humanoid"):Move(Vector3.zero)
	--		--		return
	--		--	end
	--		--	if id ~= farmId then
	--		--		find.player.Character:FindFirstChildOfClass("Humanoid"):MoveTo(
	--		--			find.player.Character:FindFirstChild("HumanoidRootPart").Position
	--		--		)
	--		--		return
	--		--	end
				
	--		--	--b(false, find.player.Character:FindFirstChild("HumanoidRootPart"), p1)
	--		--end

	--		if #queue["tokens"] > 0 or (a and a.TargetPosition) then
	--			humanoid_walk_speed = a and a.Speed or mod.data.actives["move_speed"] or 50

	--			local startMove = tick()
	--			local lastPos = find.player.Character:FindFirstChild("HumanoidRootPart").Position
	--			local stuckCount = 0

	--			while id == farmId 
	--				and mod.data.actives["auto_farm"] == true 
	--				and not mod.data.actives["converting"] 
	--			do
	--				local char = find.player.Character
	--				local hum = char and char:FindFirstChildOfClass("Humanoid")
	--				local rt = char and char:FindFirstChild("HumanoidRootPart")
	--				if not hum or not rt then break end
	--				if rt.Anchored then task.wait() continue end
					
	--				table.clear(queue["auto_farm"])

	--				if c and field then
	--					table.clear(queue["tokens"])
	--					for _, v in ipairs(c:GetChildren()) do
	--						if v:IsA("BasePart")
	--							and i(v, field)
	--							and (rt.Position - v.Position).Magnitude > 4
	--						then
	--							table.insert(queue["tokens"], v)
	--						end
	--					end
	--				end

	--				local target = nil
	--				local bestDist = math.huge
	--				for _, v in ipairs(queue["tokens"]) do
	--					if v and v.Parent then
	--						local d = (rt.Position - v.Position).Magnitude
	--						if d < bestDist then
	--							bestDist = d
	--							target = v
	--						end
	--					end
	--				end

	--				if not target then
	--					if a and a.TargetPosition then
	--						target = { Position = a.TargetPosition, Parent = true }
	--					else
	--						hum:MoveTo(rt.Position)
	--						hum:Move(Vector3.zero)
	--						break
	--					end
	--				end

	--				hum.WalkSpeed = humanoid_walk_speed
	--				hum:MoveTo(Vector3.new(target.Position.X, rt.Position.Y, target.Position.Z))

	--				if (rt.Position - lastPos).Magnitude < 0.1 then
	--					stuckCount += 1
	--					if stuckCount > 30 then
	--						local rnd = Vector3.new(
	--							math.random(-3, 3), 0, math.random(-3, 3)
	--						)
	--						hum:MoveTo(rt.Position + rnd)
	--						stuckCount = 0
	--					end
	--				else
	--					stuckCount = 0
	--				end
	--				lastPos = rt.Position

	--				task.wait()
					
					
	--				--local v = table.remove(queue["tokens"], 1)

	--				--if v and v.Parent and a.Speed then
	--				--	m(v, a.Speed)
	--				--end

	--				--task.wait()

	--				--local v = table.remove(queue["tokens"], 1)

	--				--if v and v.Parent and a.Speed then
	--				--	local reached = m(v, a.Speed)
	--				--	if not reached and v.Parent then
	--				--		table.insert(queue["tokens"], v)
	--				--	end
	--				--end

	--				--task.wait()

	--				--local v = table.remove(queue["tokens"], 1)

	--				--if v and v.Parent and a.Speed then
	--				--	local reached = m(v, a.Speed)

	--				--	if not reached and v.Parent then
	--				--		table.insert(queue["tokens"], v)
	--				--	end
	--				--end
	--			end
				
	--			local char = find.player.Character
	--			local hum = char and char:FindFirstChildOfClass("Humanoid")
	--			local rt = char and char:FindFirstChild("HumanoidRootPart")
	--			if hum and rt then
	--				hum:MoveTo(rt.Position)
	--				hum:Move(Vector3.zero)
	--			end
	--		else
	--			if a and a.TargetPosition and a.Speed then
	--				local char = find.player.Character
	--				local hum = char and char:FindFirstChildOfClass("Humanoid")
	--				if hum then
	--					hum.WalkSpeed = a.Speed
	--					hum:MoveTo(a.TargetPosition)
	--				end
	--			end
	--		end
			
	--		task.wait()
	--	end

	--	mod.data.actives["point"] = false
	--end

	local function m1(...)
		local a = {...}
		if not find.player.Character:FindFirstChild("HumanoidRootPart") then
			return
		end

		local tg = r(a[1])

		table.insert(queue["auto_farm"], {TargetPosition = tg, Speed = a[2]})

		if not mod.data.actives["move"] then
			task.spawn(q1)
		end
	end

	if mod.data.actives["auto_farm"] == true then
		local a = mod.data.actives["selected_field"]
		local f = workspace:FindFirstChild("FlowerZones")
		local b

		if a == false then b = nil else b = f:FindFirstChild(a) end

		if not a then return end
		if not f then return end
		if afarm then afarm:Disconnect() afarm = nil end

		afarm = farming.conAF(
			find.prerender, 4,
			function(delta)
				if mod.data.actives["auto_farm"] == false then
					if afarm then
						afarm:Disconnect()
						afarm = nil
					end
					find.player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = mod.data.actives["walkspeed"]
					farming.cornl(false)
					farming.inv(false)
					mod.data.actives["move"] = false
					return
				end
				
				if mod.data.actives["auto_farm"] == true then
					if mod.data.actives["converting"] then return end
					local info = farming.get_pollen_info()
					local threshold = mod.data.actives["backpack"] or 80
					
					local shouldConvert = false
					local reason = ""
					
					if info and info.percent >= threshold then
						shouldConvert = true
						reason = "backpack " .. math.floor(info.percent) .. "% >= " .. threshold .. "%"
					end
					
					if not shouldConvert then
						local autoMin = mod.data.actives["auto_convert"] or 20
						local lastTime = mod.data.actives["last_time_convert"] or tick()
						local elapsed = (tick() - lastTime) / 60

						if elapsed >= autoMin then
							shouldConvert = true
							reason = "timer " .. math.floor(elapsed) .. "m >= " .. autoMin .. "m"
						end
					end
					
					if shouldConvert and mod.data.actives["move"] == false then
						local targetPos = farming.getHive()
						if targetPos then
							local ok = farming.move("convert", mod.data.actives["walkspeed"], targetPos)
							if ok then
								mod.data.actives["converting"] = true
							end
						end
						return
					end
				end

				if mod.data.actives["move"] == false then
					farming.inv(false)
					if mod.data.actives["style_auto_farm"] == "Walk" then
						farming.cornl(true)
						m1(b, mod.data.actives["walkspeed"])
					elseif mod.data.actives["style_auto_farm"] == "Tween" then
						farming.cornl(true)
						m(b, mod.data.actives["walkspeed"])
					end
				end
			end
		)
	elseif mod.data.actives["auto_farm"] == false then
		if afarm then
			afarm:Disconnect()
			afarm = nil
		end

		table.clear(queue["auto_farm"])
		table.clear(queue["tokens"])

		local character = find.player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")

		if humanoid and root then
			humanoid:MoveTo(root.Position)
			humanoid:Move(Vector3.zero)
			humanoid.WalkSpeed = mod.data.actives["walkspeed"]
			root.Anchored = false

			local r = find.player.Character:FindFirstChild("HumanoidRootPart")
			local p = r.CurrentPhysicalProperties

			r.Massless = false
			r.CustomPhysicalProperties = PhysicalProperties.new(
				20,
				p.Friction,
				p.Elasticity,
				p.FrictionWeight,
				p.ElasticityWeight
			)
		end

		if tween then
			tween:Cancel()
			tween = nil
		end

		mod.data.actives["move"] = false

		farming.cornl(false)
		farming.inv(false)
	end
end

task.spawn(function()
	task.wait(2)

	if mod.data.actives["auto_dig"] == true then
		farming.autoDig(true)
	end

	farming.forceWalkSpeed(mod.data.actives["walkspeed"] or 16)
	farming.wealthClock()

	if mod.data.actives["auto_farm"] == true then
		farming.farm()
	end
	
	--local lastSprinklerTime = 0

	--while true do
	--	task.wait(1)

	--	if mod.data.actives["auto_sprinkler"] == true
	--		and mod.data.actives["auto_farm"] == true
	--		and mod.data.actives["move"] == false
	--		and mod.data.actives["converting"] ~= true
	--		and tick() - lastSprinklerTime > 60
	--	then
	--		farming.autosprinkler()
	--		lastSprinklerTime = tick()
	--	end
	--end
end)

return farming
