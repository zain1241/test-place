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

print("loaded 0.2.221")

if mod.data.actives["hive_choice"] == nil then
	mod.data.actives["hive_choice"] = "Random"
end

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
local invc, tween, afarm, adig, aconvert, atween, track, animwalk, humanoid_walk_speed, p, p1;
local farmId = 0

local __noclipConn = nil; local PUFF_MAX_DISTANCE = nil; local bubblesReady = false; local lastSproutTime = 0; local MONDO_COLLECT_TIME = 40
local bubbles = {}; local staticBubbles = {}; local __bboxCache = {}; local __bboxCacheTime = {}

local PUFF_RARITY = {["Common"] = true, ["Rare"] = true, ["Epic"] = true, ["Legendary"] = true, ["Mythic"] = true}
local PUFF_PRIORITY = {["Mythic"] = 5, ["Legendary"] = 4, ["Epic"] = 3, ["Rare"] = 2, ["Common"] = 1,}

local MONSTER_SAFE_EDGE  = 80; local MONSTER_AVOID_EDGE = 18; local MONSTER_FLEE_DIST  = 22

local PETAL_COLORS = {
	Red = Color3.fromRGB(249, 34, 34),
	Blue = Color3.fromRGB(33, 66, 249),
	White = Color3.fromRGB(249, 249, 249),
	Green = Color3.fromRGB(35, 232, 5),
	Black = Color3.fromRGB(11, 11, 11),
	Yellow = Color3.fromRGB(238, 204, 79),
	Scarlet = Color3.fromRGB(171, 19, 19),
	Cyan = Color3.fromRGB(29, 196, 222),
	Grey = Color3.fromRGB(127, 127, 127),
	Violet = Color3.fromRGB(94, 38, 177),
	Pink = Color3.fromRGB(255, 130, 201),
	Merigold = Color3.fromRGB(218, 168, 28),
	Periwinkle = Color3.fromRGB(150, 156, 236),
}

local function getPetalColorName(petal)
	if not petal or not petal:IsA("BasePart") then return nil end
	
	local c = petal.Color
	for name, ref in pairs(PETAL_COLORS) do
		if math.abs(c.R - ref.R) < 0.02
			and math.abs(c.G - ref.G) < 0.02
			and math.abs(c.B - ref.B) < 0.02
		then
			return name
		end
	end
	
	for name in pairs(PETAL_COLORS) do
		if string.find(petal.Name, name, 1, true) then
			return name
		end
	end

	return nil
end

local function petalAllowed(petal)
	local filter = farming.getPetalColorFilter()
	if not filter then return true end

	local colorName = getPetalColorName(petal)
	if not colorName then return true end

	return filter[colorName] == true
end

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

function farming.getPetalColorFilter()
	local f = mod.data.actives["petal_colors"]
	if type(f) ~= "table" then return nil end
	return f
end

local function isOpaque(v)
	return v ~= nil and v:IsA("BasePart") and v.Transparency <= 0
end

local function getHappenings()
	return workspace:FindFirstChild("Happenings")
end

local function getPuffFolder()
	local h = getHappenings()
	return h and h:FindFirstChild("Puffshrooms")
end

local function getSproutFolder()
	local particles = workspace:FindFirstChild("Particles")
	return particles and particles:FindFirstChild("Folder2")
end

local function findMin(list, score)
	local best, bestScore
	for _, obj in pairs(list) do
		local s = score(obj)
		if s and (not bestScore or s < bestScore) then
			best, bestScore = obj, s
		end
	end
	return best
end

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

local function getBloomPosition(bloom)
	local core = bloom and bloom:FindFirstChild("CorePart", true)
	if core and core:IsA("BasePart") then
		return core.Position
	end
end

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
	return puff.PrimaryPart or puff:FindFirstChild("PuffballStem", true) or puff:FindFirstChildWhichIsA("BasePart", true)
end

-------------------------------------------------------------

local function getNearestSprout(field, hrp)
	if not hrp then return nil end
	local sf = workspace:FindFirstChild("Sprouts")
	if not sf then return nil end

	return findMin(sf:GetChildren(), function(obj)
		if obj.Name ~= "Sprout" or not obj:IsA("BasePart") then return nil end
		return (obj.Position - hrp.Position).Magnitude
	end)
end

local function getNearestBubble(field, hrp)
	initBubbles()
	if not hrp then return nil end
	return findMin(bubbles, function(bubble)
		if not bubble.Parent then bubbles[bubble] = nil return nil end
		if not isInField(bubble.Position, field) then return nil end
		return (bubble.Position - hrp.Position).Magnitude
	end)
end

local function getNearestBloom(field, hrp)
	if not hrp then return nil end

	local happenings = getHappenings()
	local folder = happenings and happenings:FindFirstChild("PoppablePlants")
	if not folder then return nil end

	return findMin(folder:GetChildren(), function(bloom)
		if not bloom:IsA("Model") or bloom.Name ~= "Bloom" then return nil end

		local pos = getBloomPosition(bloom)
		if not pos or not isInField(pos, field) then return nil end

		local dx = pos.X - hrp.Position.X
		local dz = pos.Z - hrp.Position.Z
		return math.sqrt(dx * dx + dz * dz)
	end)
end

local function getNearestPuff(field, hrp, filter)
	local pf = getPuffFolder()
	if not pf or not hrp then return nil end

	return findMin(pf:GetChildren(), function(puff)
		if not puff:IsA("Model") then return nil end

		local rarity = getPuffRarity(puff)
		if filter ~= "All Pushrooms" and rarity ~= filter then return nil end

		local root = getPuffRoot(puff)
		if not root then return nil end

		local d = (root.Position - hrp.Position).Magnitude
		if PUFF_MAX_DISTANCE and d > PUFF_MAX_DISTANCE then return nil end

		local priority = (rarity and PUFF_PRIORITY[rarity]) or 0
		return d - priority * 1e6
	end)
end

function farming.get_pollen_info()
	local pg = find.player:FindFirstChild("PlayerGui")
	if not pg then return nil end

	local screenGui = pg:FindFirstChild("ScreenGui")
	local meterHud = screenGui and screenGui:FindFirstChild("MeterHUD")
	local pollenMeter = meterHud and meterHud:FindFirstChild("PollenMeter")
	local bar = pollenMeter and pollenMeter:FindFirstChild("Bar")
	local label = bar and bar:FindFirstChild("TextLabel")

	if not label or not label:IsA("TextLabel") then return nil end

	local current, max = string.match(label.Text, "([%d,]+)/([%d,]+)")
	if not current or not max then return nil end

	current = tonumber((string.gsub(current, ",", ""))) or 0
	max = tonumber((string.gsub(max, ",", ""))) or 0

	if max <= 0 then return nil end

	return {
		pollen = current,
		max = max,
		percent = (current / max) * 100,
	}
end

farming.get_pollen_from_gui = farming.get_pollen_info -- deprecated

local function safeCleanup(rootPart, clearMove)
	if rootPart and rootPart.Parent then pcall(function() rootPart.Anchored = false end) end
	pcall(function() farming.inv(false) end)
	if clearMove ~= false then mod.data.actives["move"] = false end
end

local function getMondo()
	local monsters = workspace:FindFirstChild("Monsters")
	if not monsters then return nil end
	for _, m in ipairs(monsters:GetChildren()) do
		if string.find(m.Name, "Mondo", 1, true) then
			return m
		end
	end
	return nil
end

local function getMondoPosition(mondo)
	if not mondo then return nil end
	if mondo:IsA("Model") then
		if mondo.PrimaryPart then return mondo.PrimaryPart.Position end
		local part = mondo:FindFirstChildWhichIsA("BasePart", true)
		return part and part.Position
	end
	if mondo:IsA("BasePart") then return mondo.Position end
	return nil
end

local function getMonsterRadius(monster)
	if not monster then return 15 end
	local ok, _, size = pcall(function()
		return monster:GetBoundingBox()
	end)
	if ok and size then
		return math.max(size.X, size.Z) / 2
	end
	return 15
end

local function getMonsterPosition(monster)
	if not monster then return nil end
	if monster:IsA("Model") then
		if monster.PrimaryPart then return monster.PrimaryPart.Position end
		local p = monster:FindFirstChildWhichIsA("BasePart", true)
		return p and p.Position
	end
	if monster:IsA("BasePart") then return monster.Position end
	return nil
end

local function getThreateningMonster(hrp)
	if not hrp then return nil end
	local monsters = workspace:FindFirstChild("Monsters")
	if not monsters then return nil end

	local playerChar = find.player.Character
	if not playerChar then return nil end

	local best, bestEdge
	for _, monster in ipairs(monsters:GetChildren()) do
		local t = monster:FindFirstChild("Target")
		if t and t:IsA("ObjectValue") and t.Value == playerChar then
			local mp = getMonsterPosition(monster)
			if mp then
				local r = getMonsterRadius(monster)
				local d = (hrp.Position - mp).Magnitude
				local edge = d - r
				if not bestEdge or edge < bestEdge then
					bestEdge = edge
					best = {
						monster = monster,
						mp = mp,
						radius = r,
						distance = d,
						realDist = edge,
					}
				end
			end
		end
	end
	return best
end

local function getFleeTarget(hrp)
	if mod.data.actives["save_mode"] ~= true then return nil end
	if not hrp then return nil end

	local threat = getThreateningMonster(hrp)
	if not threat then return nil end
	if threat.realDist >= MONSTER_AVOID_EDGE then return nil end
	
	local mv = Vector3.zero
	pcall(function()
		local pp = threat.monster.PrimaryPart
			or threat.monster:FindFirstChildWhichIsA("BasePart", true)
		if pp then mv = pp.AssemblyLinearVelocity end
	end)

	local toMe = hrp.Position - threat.mp
	toMe = Vector3.new(toMe.X, 0, toMe.Z)

	local chasing = false
	if mv.Magnitude > 0.5 and toMe.Magnitude > 0.1 then
		if mv.Unit:Dot(toMe.Unit) > 0.1 then
			chasing = true
		end
	end
	
	if threat.realDist > MONSTER_SAFE_EDGE and not chasing then
		return nil
	end

	local away
	if threat.distance > 0.1 then
		away = (hrp.Position - threat.mp).Unit
	else
		away = Vector3.new(1, 0, 0)
	end

	local push = math.max(MONSTER_SAFE_EDGE - threat.realDist, 0) + MONSTER_FLEE_DIST
	local raw = hrp.Position + away * push
	return Vector3.new(raw.X, hrp.Position.Y, raw.Z)
end

local function isPetal(v)
	return v and v:IsA("BasePart") and v.Name == "PetalPart" and v.Parent == workspace:FindFirstChild("Particles") and v.Transparency <= 0 and petalAllowed(v)
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
	if not isInField(hrp.Position, field) then return false end

	local origin = getBloomPosition(bloom)
	if not origin then return false end

	local particles = workspace:FindFirstChild("Particles")
	if not particles then return false end

	local oldPetals = {}
	for _, v in ipairs(particles:GetChildren()) do
		if isPetal(v) then oldPetals[v] = true end
	end

	local speed = tonumber(mod.data.actives["walkspeed"]) or 40
	
	local function phaseEnabled()
		return id == farmId and mod.data.actives["auto_farm"] == true and mod.data.actives["petals"] == true and not mod.data.actives["converting"]
	end
	
	local function bloomAlive()
		local happenings = getHappenings()
		local folder = happenings and happenings:FindFirstChild("PoppablePlants")
		
		return phaseEnabled() and folder ~= nil and bloom.Parent == folder
	end
	
	local approachStart = tick()
	while bloomAlive() and tick() - approachStart < 10 do
		character = find.player.Character
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not hrp or hrp.Anchored then break end

		local pos = getBloomPosition(bloom)
		if not pos then break end

		local target = Vector3.new(pos.X, hrp.Position.Y, pos.Z)
		local dist = (target - hrp.Position).Magnitude
		if dist <= 8 then break end

		humanoid.WalkSpeed = speed
		humanoid:MoveTo(target)
		task.wait(0.01)
	end
	
	local circleRadius = 7; local circleStart = tick(); local breakTimeout = 30; local spin = 1; local lastActivate = 0

	while bloomAlive() and (tick() - circleStart) < breakTimeout do
		character = find.player.Character
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		hrp = character and character:FindFirstChild("HumanoidRootPart")

		if not humanoid or not hrp or hrp.Anchored then break end

		local pos = getBloomPosition(bloom)
		if not pos then break end

		local center = Vector3.new(pos.X, hrp.Position.Y, pos.Z)
		local offset = Vector3.new(hrp.Position.X - center.X, 0, hrp.Position.Z - center.Z)
		local dist = offset.Magnitude

		if dist < 0.1 then offset = Vector3.new(1, 0, 0) dist = 1 end

		local radial = offset.Unit
		local tangent = Vector3.new(-radial.Z * spin, 0, radial.X * spin)

		local moveDir

		if dist > circleRadius + 1.5 then
			moveDir = -radial
		elseif dist < circleRadius - 1.5 then
			moveDir = radial
		else
			moveDir = tangent
		end

		local waypoint = hrp.Position + moveDir * 8
		waypoint = Vector3.new(waypoint.X, hrp.Position.Y, waypoint.Z)
		humanoid.WalkSpeed = speed

		pcall(function()
			humanoid:MoveTo(waypoint)
		end)

		task.wait(0.08)
	end

	pcall(function()
		if humanoid then
			humanoid:Move(Vector3.zero, false)
		end
	end)
	
	local tracked = {}; local handled = {}; local lastSpawn = os.clock()

	local conn
	conn = particles.ChildAdded:Connect(function(v)
		if not phaseEnabled() then return end
		if not isPetal(v) then return end
		if oldPetals[v] then return end
		if handled[v] then return end
		if (v.Position - origin).Magnitude <= 60 then
			tracked[v] = true
			lastSpawn = os.clock()
		end
	end)

	local petalStart = os.clock(); local petalTimeout = petalStart + 4

	while phaseEnabled() and os.clock() < petalTimeout do
		character = find.player.Character
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		hrp = character and character:FindFirstChild("HumanoidRootPart")

		if humanoid and hrp and not hrp.Anchored then
			for petal in pairs(tracked) do
				if not petal.Parent then
					tracked[petal] = nil
				end
			end
			for petal in pairs(handled) do
				if not petal.Parent then
					handled[petal] = nil
				end
			end
			
			for _, v in ipairs(particles:GetChildren()) do
				if isPetal(v)
					and not oldPetals[v]
					and not tracked[v]
					and not handled[v]
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
				local d = (target - hrp.Position).Magnitude

				if d <= 3.5 then
					tracked[petal] = nil
					handled[petal] = true
					task.wait(0.01)
				else
					humanoid.WalkSpeed = speed
					humanoid:MoveTo(target)
					task.wait(0.01)
				end
			else
				if os.clock() - lastSpawn > 0.45 and os.clock() - petalStart > 0.5 then
					break
				end
				task.wait(0.01)
			end
		else
			task.wait(0.01)
		end
	end

	if conn then conn:Disconnect() end

	return true
end

local function getMondoRadius(mondo)
	if not mondo then return 15 end
	local ok, _, size = pcall(function()
		return mondo:GetBoundingBox()
	end)
	if ok and size then
		return math.max(size.X, size.Z) / 2
	end
	return 15
end

local function getMondoField()
	local zones = workspace:FindFirstChild("FlowerZones")
	if not zones then return nil end
	for _, z in ipairs(zones:GetChildren()) do
		if string.find(z.Name, "Mountain Top Field", 1, true) then
			return z
		end
	end
	return nil
end

function farming.farmMondo(field, id)
	local function enabled()
		return id == farmId and mod.data.actives["auto_farm"] == true and mod.data.actives["mondo"] == true and not mod.data.actives["converting"]
	end

	local character = find.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return false end

	local mondo = getMondo()
	if not mondo then return false end

	local mondoPos = getMondoPosition(mondo)
	if not mondoPos then return false end
	
	local mondoField = getMondoField()
	local fieldCF, fieldSize
	if mondoField then
		if mondoField:IsA("BasePart") then
			fieldCF = mondoField.CFrame
			fieldSize = mondoField.Size
		elseif mondoField:IsA("Model") then
			local ok, cf, sz = pcall(function() return mondoField:GetBoundingBox() end)
			if ok then fieldCF, fieldSize = cf, sz end
		end
	end

	local FIELD_MARGIN = 8

	local function inMondoField(pos)
		if not fieldCF or not fieldSize then return true end
		local p = fieldCF:PointToObjectSpace(pos)
		return math.abs(p.X) <= fieldSize.X / 2 - FIELD_MARGIN and math.abs(p.Z) <= fieldSize.Z / 2 - FIELD_MARGIN
	end

	local function clampToMondoField(pos)
		if not fieldCF or not fieldSize then return pos end
		local p = fieldCF:PointToObjectSpace(pos)
		local limX = fieldSize.X / 2 - FIELD_MARGIN
		local limZ = fieldSize.Z / 2 - FIELD_MARGIN
		p = Vector3.new(math.clamp(p.X, -limX, limX), p.Y, math.clamp(p.Z, -limZ, limZ))
		return fieldCF:PointToWorldSpace(p)
	end

	mod.data.actives["move"] = true

	character = find.player.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then
		safeCleanup(hrp)
		return false
	end

	if tween then pcall(function() tween:Cancel() end) tween = nil end

	local startRoot = hrp
	local startPosition = startRoot.Position
	local angle = find.random:NextNumber(0, math.pi * 2)
	local r = find.random:NextNumber(30, 45)
	local rawTarget = Vector3.new(mondoPos.X + math.cos(angle) * r, mondoPos.Y + 5, mondoPos.Z + math.sin(angle) * r)
	local clampedTarget = clampToMondoField(rawTarget)
	local target = Vector3.new(clampedTarget.X, rawTarget.Y, clampedTarget.Z)

	local distance = (startRoot.Position - target).Magnitude
	local speed = tonumber(mod.data.actives["walkspeed"]) or 40
	local duration = distance / math.max(speed, 1)

	local anchorOk = pcall(function() startRoot.Anchored = true end)
	if not anchorOk then
		safeCleanup(startRoot)
		return false
	end

	pcall(function() farming.inv(true) end)

	local flyTween
	local tweenOk = pcall(function()
		flyTween = find.tweenservice:Create(
			startRoot,
			TweenInfo.new(math.max(duration, 0.05), Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
			{ CFrame = CFrame.new(target) }
		)
		tween = flyTween
		flyTween:Play()
	end)

	if not tweenOk or not flyTween then
		if tween then pcall(function() tween:Cancel() end) tween = nil end
		safeCleanup(startRoot)
		return false
	end

	local finished = false
	flyTween.Completed:Once(function()
		finished = true
		if tween == flyTween then tween = nil end
	end)

	local flyStart = tick()
	local flyTimeout = duration + 3

	while enabled() and mondo.Parent ~= nil and not finished and (tick() - flyStart) < flyTimeout do
		task.wait()
	end

	if not finished then pcall(function() flyTween:Cancel() end) end
	if tween == flyTween then tween = nil end

	if not finished and startRoot and startRoot.Parent then
		pcall(function() startRoot.CFrame = CFrame.new(startPosition) end)
	end

	pcall(function() startRoot.Anchored = false end)
	safeCleanup(startRoot)
	mod.data.actives["move"] = true

	if not enabled() then return false end
	task.wait(0.05)
	
	-- ===== Основной цикл =====
	local farmStart = tick()
	local farmTimeout = 400
	local lastRandom = 0
	local randomInterval = 0.6
	local currentTarget = nil
	
	local SAFE_EDGE = 10   -- ближе этого — срочно отбегаем
	local AVOID_EDGE = 16   -- ближе этого + чикен движется к нам — тоже отбегаем
	local FARM_MIN_EDGE = 18   -- минимальный отступ от края во время бега
	local FARM_MAX_EDGE = 32   -- максимальный отступ от края во время бега

	while enabled() and mondo.Parent ~= nil and (tick() - farmStart) < farmTimeout do
		character = find.player.Character
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		hrp = character and character:FindFirstChild("HumanoidRootPart")
		if not humanoid or not hrp or hrp.Anchored then break end

		local mp = getMondoPosition(mondo)
		if not mp then break end
		
		local mondoR = getMondoRadius(mondo)
		local dist = (hrp.Position - mp).Magnitude
		local realDist = dist - mondoR
		local mv = Vector3.zero
		pcall(function()
			if mondo:IsA("Model") then
				local pp = mondo.PrimaryPart or mondo:FindFirstChildWhichIsA("BasePart", true)
				if pp then mv = pp.AssemblyLinearVelocity end
			elseif mondo:IsA("BasePart") then
				mv = mondo.AssemblyLinearVelocity
			end
		end)
		
		local chickenChasing = false
		if mv.Magnitude > 0.5 and realDist < AVOID_EDGE then
			local toMe = (hrp.Position - mp)
			toMe = Vector3.new(toMe.X, 0, toMe.Z)
			if toMe.Magnitude > 0.1 and mv.Unit:Dot(toMe.Unit) > 0.1 then
				chickenChasing = true
			end
		end
		
		if realDist < SAFE_EDGE or chickenChasing then
			local away
			if dist > 0.1 then
				away = (hrp.Position - mp).Unit
			else
				away = Vector3.new(1, 0, 0)
			end
			
			local pushStrength = math.max(SAFE_EDGE - realDist, 0) + 18
			local rawTarget2 = hrp.Position + away * pushStrength
			local safeTarget2 = clampToMondoField(rawTarget2)
			
			if (safeTarget2 - hrp.Position).Magnitude < 5 then
				local tangent = Vector3.new(-away.Z, 0, away.X)
				local toCenter = (mp - hrp.Position)
				toCenter = Vector3.new(toCenter.X, 0, toCenter.Z)
				if toCenter.Magnitude > 0.1 and tangent:Dot(toCenter.Unit) < 0 then
					tangent = -tangent
				end
				rawTarget2 = hrp.Position + tangent * 22
				safeTarget2 = clampToMondoField(rawTarget2)
			end

			humanoid.WalkSpeed = speed
			humanoid:MoveTo(Vector3.new(
				safeTarget2.X,
				hrp.Position.Y,
				safeTarget2.Z
				))
			currentTarget = nil
			lastRandom = tick()
			task.wait(0.05)
			continue
		end
		
		local needNew = (not currentTarget)
			or (tick() - lastRandom > randomInterval)
			or ((Vector3.new(currentTarget.X, hrp.Position.Y, currentTarget.Z) - hrp.Position).Magnitude < 3)

		if needNew then
			local a2 = find.random:NextNumber(0, math.pi * 2)
			local rr = find.random:NextNumber(mondoR + FARM_MIN_EDGE, mondoR + FARM_MAX_EDGE)
			local rawTarget4 = Vector3.new(mp.X + math.cos(a2) * rr, hrp.Position.Y, mp.Z + math.sin(a2) * rr )
			local safeTarget4 = clampToMondoField(rawTarget4)
			currentTarget = Vector3.new(safeTarget4.X, hrp.Position.Y, safeTarget4.Z)
			lastRandom = tick()
		end

		local distToCurrentCenter = (Vector3.new(currentTarget.X, 0, currentTarget.Z) - Vector3.new(mp.X, 0, mp.Z)).Magnitude
		local currentEdge = distToCurrentCenter - mondoR
		if currentEdge < FARM_MIN_EDGE - 4 or currentEdge > FARM_MAX_EDGE + 10 then
			currentTarget = nil
			task.wait(0.05)
			continue
		end

		humanoid.WalkSpeed = speed
		humanoid:MoveTo(currentTarget)
		task.wait(0.05)
	end

	safeCleanup(nil)
	mod.data.actives["move"] = true
	
	--collect tokens
	local collectStart = tick()
	local handled = {}

	local collectTime = tonumber(mod.data.actives["mondo_collect_time"]) or MONDO_COLLECT_TIME
	local collectDrop = mod.data.actives["mondo_collect_drop"] ~= false

	while collectDrop and enabled() and (tick() - collectStart) < collectTime do
		character = find.player.Character
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		hrp = character and character:FindFirstChild("HumanoidRootPart")

		if not humanoid or not hrp or hrp.Anchored then
			task.wait(0.01)
			continue
		end

		for obj in pairs(handled) do
			if not obj.Parent then handled[obj] = nil end
		end

		local collectibles = workspace:FindFirstChild("Collectibles")
		local target2, targetDist2

		if collectibles then
			for _, v in ipairs(collectibles:GetChildren()) do
				if v:IsA("BasePart") and v.Parent and not handled[v] and v.Transparency <= 0 then
					local d = (v.Position - hrp.Position).Magnitude
					if d <= 120 and (not targetDist2 or d < targetDist2) then
						target2 = v
						targetDist2 = d
					end
				end
			end
		end

		if not target2 then
			task.wait(0.05)
			continue
		end

		local tp = Vector3.new(target2.Position.X, hrp.Position.Y, target2.Position.Z)
		local d = (tp - hrp.Position).Magnitude

		if d <= 3.5 then
			handled[target2] = true
			task.wait(0.01)
			continue
		end

		humanoid.WalkSpeed = speed
		humanoid:MoveTo(tp)
		task.wait(0.01)
	end

	mod.data.actives["move"] = false

	--return to field
	local returnField = field

	if not returnField then
		local zones = workspace:FindFirstChild("FlowerZones")
		local sel = mod.data.actives["selected_field"]

		if zones and sel and sel ~= "" then
			returnField = zones:FindFirstChild(sel)
		end
	elseif not returnField.Parent then
		local zones = workspace:FindFirstChild("FlowerZones")
		local sel = mod.data.actives["selected_field"]

		if zones and sel and sel ~= "" then
			returnField = zones:FindFirstChild(sel)
		end
	end

	if returnField and returnField.Parent then
		farming.move("flowerzones", speed, returnField.Name)

		local retStart = tick()

		while id == farmId and mod.data.actives["auto_farm"] == true and not mod.data.actives["converting"] and mod.data.actives["move"] == true and (tick() - retStart) < 30 do
			task.wait()
		end

		mod.data.actives["move"] = false
	end
	
	return true
end

function farming.farmSprout(field, id)
	local function enabled()
		return id == farmId and mod.data.actives["auto_farm"] == true and mod.data.actives["sprouts"] == true and not mod.data.actives["converting"]
	end

	local function safeCancelTween()
		if tween then
			pcall(function() tween:Cancel() end)
			tween = nil
		end
	end

	local character = find.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return false end

	local sprout = getNearestSprout(field, hrp)
	if not sprout then return false end
	if not sprout.Parent then return false end

	mod.data.actives["move"] = true

	character = find.player.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then
		safeCleanup(hrp)
		return false
	end

	safeCancelTween()

	local startRoot = hrp
	local startPosition = startRoot.Position
	local target = sprout.Position + Vector3.new(find.random:NextNumber(-3, 3), 2, find.random:NextNumber(-3, 3))

	local distance = (startRoot.Position - target).Magnitude
	local speed = tonumber(mod.data.actives["walkspeed"]) or 40
	local duration = distance / math.max(speed, 1)

	local anchorOk = pcall(function() startRoot.Anchored = true end)
	if not anchorOk then
		safeCleanup(startRoot)
		return false
	end

	pcall(function() farming.inv(true) end)
	
	local flyTween
	local tweenOk = pcall(function()
		flyTween = find.tweenservice:Create(
			startRoot,
			TweenInfo.new(
				math.max(duration, 0.05),
				Enum.EasingStyle.Linear,
				Enum.EasingDirection.Out
			),
			{ CFrame = CFrame.new(target) }
		)
		tween = flyTween
		flyTween:Play()
	end)

	if not tweenOk or not flyTween then
		safeCancelTween()
		safeCleanup(startRoot)
		return false
	end

	local finished = false
	flyTween.Completed:Once(function()
		finished = true
		if tween == flyTween then tween = nil end
	end)

	local flyStart = tick()
	local flyTimeout = duration + 3

	while enabled()
		and sprout.Parent ~= nil
		and not finished
		and (tick() - flyStart) < flyTimeout
	do
		task.wait()
	end

	if not finished then
		pcall(function() flyTween:Cancel() end)
	end
	if tween == flyTween then tween = nil end

	if not finished and startRoot and startRoot.Parent then
		pcall(function()
			startRoot.CFrame = CFrame.new(startPosition)
		end)
	end

	pcall(function()
		startRoot.Anchored = false
	end)
	safeCleanup(startRoot, false)
	mod.data.actives["move"] = true

	if not enabled() then
		return false
	end

	task.wait(0.05)

	character = find.player.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return false end

	local pp = hrp.Position
	if pp.X ~= pp.X or pp.Y ~= pp.Y or pp.Z ~= pp.Z or math.abs(pp.X) == math.huge or math.abs(pp.Y) == math.huge or math.abs(pp.Z) == math.huge then
		pcall(function() hrp.CFrame = CFrame.new(startPosition) end)
		safeCleanup(nil)
		return false
	end
	
	local circleRadius = 7
	local circleStart = tick()
	local breakTimeout = 30
	local spin = 1
	
	task.wait(.4)
	farming.autosprinkler(true)
	local currentAngle = nil

	while enabled() and sprout.Parent ~= nil and (tick() - circleStart) < breakTimeout do
		character = find.player.Character
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		hrp = character and character:FindFirstChild("HumanoidRootPart")

		if not humanoid or not hrp or hrp.Anchored then
			break
		end

		local center = Vector3.new(sprout.Position.X, hrp.Position.Y, sprout.Position.Z)

		local dx = hrp.Position.X - center.X
		local dz = hrp.Position.Z - center.Z
		local dist = math.sqrt(dx * dx + dz * dz)
		
		if not currentAngle then
			if dist > 0.5 then
				currentAngle = math.atan2(dz, dx)
			else
				currentAngle = find.random:NextNumber(0, math.pi * 2)
			end
		end
		
		currentAngle = currentAngle + 0.35 * spin
		
		if dist > circleRadius + 2 then
			currentAngle = math.atan2(dz, dx)
		elseif dist < circleRadius - 2 then
			currentAngle = math.atan2(dz, dx)
		end

		local target = Vector3.new(center.X + math.cos(currentAngle) * circleRadius, hrp.Position.Y, center.Z + math.sin(currentAngle) * circleRadius)
		humanoid.WalkSpeed = speed

		pcall(function()
			humanoid:MoveTo(target)
		end)

		task.wait(0.08)
	end

	pcall(function()
		if humanoid then
			humanoid:Move(Vector3.zero, false)
		end
	end)

	--pcall(function()
	--	if humanoid then
	--		humanoid:Move(Vector3.zero, false)
	--	end
	--end)

	character = find.player.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		pcall(function() humanoid:Move(Vector3.zero, false) end)
	end

	safeCleanup(nil)
	mod.data.actives["move"] = true
	
	local collectStart = tick()
	local collectTimeout = 15
	local handled = {}
	
	--farming.autosprinkler(true)

	while enabled() and (tick() - collectStart) < collectTimeout do
		character = find.player.Character
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		hrp = character and character:FindFirstChild("HumanoidRootPart")

		if not humanoid or not hrp or hrp.Anchored then
			task.wait(0.01)
			continue
		end
		
		for obj in pairs(handled) do
			if not obj.Parent then handled[obj] = nil end
		end

		local collectibles = workspace:FindFirstChild("Collectibles")
		local target, targetDist

		if collectibles then
			for _, v in ipairs(collectibles:GetChildren()) do
				if v:IsA("BasePart")
					and v.Parent
					and not handled[v]
					and v.Transparency <= 0
				then
					local d = (v.Position - hrp.Position).Magnitude
					if d <= 100 and (not targetDist or d < targetDist) then
						target = v
						targetDist = d
					end
				end
			end
		end

		if not target then
			task.wait(0.05)
			continue
		end

		local tp = Vector3.new(target.Position.X, hrp.Position.Y, target.Position.Z)
		local d = (tp - hrp.Position).Magnitude

		if d <= 3.5 then
			handled[target] = true
			task.wait(0.01)
			continue
		end

		humanoid.WalkSpeed = speed
		humanoid:MoveTo(tp)
		task.wait(0.01)
	end

	mod.data.actives["move"] = false

	if field and field.Parent then
		farming.move("flowerzones", speed, field.Name)
		while id == farmId and mod.data.actives["auto_farm"] == true and not mod.data.actives["converting"] and mod.data.actives["move"] == true do
			task.wait()
		end
	end

	lastSproutTime = tick()
	return true
end

local function isPuffLoot(v)
	if not v or not v:IsA("BasePart") then return false end
	if v.Name == "PuffballStem" or v.Name == "Puffball" then return false end
	if v.Transparency > 0 then return false end

	return v.Parent == workspace:FindFirstChild("Collectibles") and v:FindFirstChildWhichIsA("Decal") ~= nil
end

local function findLootNear(pos, radius, ignored)
	if not pos then return nil end

	local collectibles = workspace:FindFirstChild("Collectibles")
	if not collectibles then return nil end
	local best; local bestDist

	for _, v in ipairs(collectibles:GetChildren()) do
		if isPuffLoot(v) and not (ignored and ignored[v]) and v.Parent then
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
		return id == farmId and mod.data.actives["auto_farm"] == true and mod.data.actives["pushrooms_enabled"] == true and not mod.data.actives["converting"]
	end
	
	local function safeCleanup(rootPart)
		if rootPart then
			pcall(function()
				if rootPart.Parent then rootPart.Anchored = false end
			end)
		end
		pcall(function() farming.inv(false) end)
		mod.data.actives["move"] = false
	end
	
	local function safeCancelTween()
		if tween then
			pcall(function() tween:Cancel() end)
			tween = nil
		end
	end

	local character = find.player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return false end

	local filter = mod.data.actives["pushrooms"] or "All Pushrooms"
	local puff = getNearestPuff(field, hrp, filter)
	if not puff then return false end

	local rootPart = getPuffRoot(puff)
	if not rootPart then return false end

	local pf = getPuffFolder()
	if not pf then return false end

	mod.data.actives["move"] = true

	character = find.player.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then
		safeCleanup(hrp)
		return false
	end

	safeCancelTween()

	local startRoot = hrp
	local startPosition = startRoot.Position
	local target = rootPart.Position + Vector3.new(find.random:NextNumber(-3, 3), 2, find.random:NextNumber(-3, 3))

	local distance = (startRoot.Position - target).Magnitude
	local speed = tonumber(mod.data.actives["walkspeed"]) or 40
	local duration = distance / math.max(speed, 1)
	local anchorOk = pcall(function() startRoot.Anchored = true end)
	if not anchorOk then
		safeCleanup(startRoot)
		return false
	end

	pcall(function() farming.inv(true) end)
	
	local flyTween
	local tweenOk = pcall(function()
		flyTween = find.tweenservice:Create(
			startRoot,
			TweenInfo.new(
				math.max(duration, 0.05),
				Enum.EasingStyle.Linear,
				Enum.EasingDirection.Out
			),
			{ CFrame = CFrame.new(target) }
		)
		tween = flyTween
		flyTween:Play()
	end)

	if not tweenOk or not flyTween then
		safeCancelTween()
		safeCleanup(startRoot)
		return false
	end

	local finished = false
	flyTween.Completed:Once(function()
		finished = true
		if tween == flyTween then tween = nil end
	end)
	
	local flyStart = tick(); local flyTimeout = duration + 3

	while enabled() and puff.Parent == pf and not finished and (tick() - flyStart) < flyTimeout do
		task.wait()
	end
	
	if not finished then
		pcall(function() flyTween:Cancel() end)
	end
	if tween == flyTween then tween = nil end
	
	if not finished and startRoot and startRoot.Parent then
		pcall(function()
			startRoot.CFrame = CFrame.new(startPosition)
		end)
	end
	
	pcall(function()
		startRoot.Anchored = false
	end)
	safeCleanup(startRoot, false)
	mod.data.actives["move"] = true

	if not enabled() then
		return false
	end

	task.wait(0.05)

	character = find.player.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not hrp then return false end
	
	local p = hrp.Position
	if p.X ~= p.X or p.Y ~= p.Y or p.Z ~= p.Z or math.abs(p.X) == math.huge or math.abs(p.Y) == math.huge or math.abs(p.Z) == math.huge then
		pcall(function()
			hrp.CFrame = CFrame.new(startPosition)
		end)
		safeCleanup(nil)
		return false
	end
	
	local circleRadius = 5; local circleDirection = 1; local breakStart = tick(); local breakTimeout = 30
	
	task.wait(.4)
	farming.autosprinkler(true)

	local currentAngle = nil

	while enabled() and puff.Parent == pf and (tick() - breakStart) < breakTimeout do
		character = find.player.Character
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		hrp = character and character:FindFirstChild("HumanoidRootPart")

		if not humanoid or not hrp or hrp.Anchored then break end

		local centerPart = getPuffRoot(puff)
		if not centerPart then break end

		local center = centerPart.Position
		local dx = hrp.Position.X - center.X
		local dz = hrp.Position.Z - center.Z
		local dist = math.sqrt(dx * dx + dz * dz)

		if not currentAngle then
			if dist > 0.5 then
				currentAngle = math.atan2(dz, dx)
			else
				currentAngle = find.random:NextNumber(0, math.pi * 2)
			end
		end

		currentAngle = currentAngle + 0.35 * circleDirection

		if dist > circleRadius + 2 or dist < circleRadius - 2 then
			currentAngle = math.atan2(dz, dx)
		end

		local target = Vector3.new(center.X + math.cos(currentAngle) * circleRadius, hrp.Position.Y, center.Z + math.sin(currentAngle) * circleRadius)

		humanoid.WalkSpeed = speed
		pcall(function()
			humanoid:MoveTo(target)
		end)
		task.wait(0.08)
	end

	character = find.player.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		pcall(function() humanoid:Move(Vector3.zero, false) end)
	end

	if not enabled() then
		safeCleanup(nil)
		return false
	end
	
	local lootTimeout = tick() + 7; local lastLootTime = tick(); local handledLoot = {}

	while enabled() and tick() < lootTimeout do
		character = find.player.Character
		humanoid = character and character:FindFirstChildOfClass("Humanoid")
		hrp = character and character:FindFirstChild("HumanoidRootPart")

		if not humanoid or not hrp or hrp.Anchored then
			task.wait(0.01)
			continue
		end
		for obj in pairs(handledLoot) do
			if not obj.Parent then handledLoot[obj] = nil end
		end

		local loot = findLootNear(hrp.Position, 35, handledLoot)

		if not loot then
			if tick() - lastLootTime > 0.45 then
				break
			end
			task.wait(0.05)
			continue
		end

		lastLootTime = tick()

		local targetPos = Vector3.new(loot.Position.X, hrp.Position.Y, loot.Position.Z)
		local d = (targetPos - hrp.Position).Magnitude
		
		if d <= 3.5 then
			handledLoot[loot] = true
			task.wait(0.01)
			continue
		end

		humanoid.WalkSpeed = speed
		pcall(function()
			humanoid:MoveTo(targetPos)
		end)
		task.wait(0.01)
	end
	
	character = find.player.Character
	humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		pcall(function() humanoid:Move(Vector3.zero, false) end)
	end

	safeCleanup(nil)

	return true
end

local function returnToField(field, id)
	if not field then
		return false
	end

	if id ~= farmId or mod.data.actives["auto_farm"] ~= true or mod.data.actives["converting"] then
		return false
	end
	
	mod.data.actives["move"] = false
	local speed = tonumber(mod.data.actives["walkspeed"]) or 40
	local currentTween = farming.move(
		"flowerzones",
		speed,
		field.Name
	)

	if not currentTween then
		return false
	end
	
	while id == farmId and mod.data.actives["auto_farm"] == true and not mod.data.actives["converting"] and mod.data.actives["move"] == true do
		task.wait(0.001)
	end

	return true
end

local function clearFarmLines()
	local lines = workspace:FindFirstChild("Lines_Cub")
	if lines then lines:ClearAllChildren() end

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

function farming.hardUninv()
	if invc then
		pcall(function() invc:Disconnect() end)
		invc = nil
	end

	local b = workspace:FindFirstChild(find.player.Name)
	if not b then return end

	for _, v in ipairs(b:GetChildren()) do
		if v:IsA("MeshPart") and v.Name ~= "HumanoidRootPart" then
			v.Transparency = 0
			v.CanTouch = true
			v.CanQuery = true
			if not __noclipConn then
				v.CanCollide = true
			else
				v.CanCollide = false
			end
		end
	end
end

function farming.noclip(on)
	if on then
		if __noclipConn then return end
		__noclipConn = farming.conAF(
			find.prerender, 4,
			function()
				local c = find.player.Character
				if not c then return end
				for _, v in ipairs(c:GetChildren()) do
					if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
						v.CanCollide = false
						v.CanTouch = true
						v.CanQuery = true
					end
				end
			end
		)
	else
		if __noclipConn then
			__noclipConn:Disconnect()
			__noclipConn = nil
		end

		local c = find.player.Character
		if c then
			for _, v in ipairs(c:GetChildren()) do
				if v:IsA("BasePart") and v.Name ~= "HumanoidRootPart" then
					v.CanCollide = true
				end
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
		local a = {...}
		local part = a[1]

		if part == nil then return end

		if typeof(part) == "string" then
			local f = workspace:FindFirstChild("FlowerZones")
			part = f and f:FindFirstChild(part)
		end

		if not part then
			warn("field not found")
			return
		end

		local cf, size
		if part:IsA("BasePart") then
			cf, size = part.CFrame, part.Size
		elseif part:IsA("Model") then
			cf, size = part:GetBoundingBox()
		else
			warn("r: field is not BasePart/Model")
			return
		end

		local h = .4
		local marginX = math.min(6, size.X * .15)
		local marginZ = math.min(6, size.Z * .15)
		local x = size.X / 2 - marginX
		local z = size.Z / 2 - marginZ

		local position = string.lower(mod.data.actives["position_field"] or "center")
		local ix, ax

		if position == "left" then
			ix = -x; ax = 0
		elseif position == "right" then
			ix = 0; ax = x
		else
			ix = -x / 3; ax = x / 3
		end

		local l = Vector3.new(
			find.random:NextNumber(ix, ax),
			size.Y / 2 + h,
			find.random:NextNumber(-z, z)
		)

		return cf:PointToWorldSpace(l)
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
				
				if tween then pcall(function() tween:Cancel() end) tween = nil end
				if atween then pcall(function() atween:Cancel() end) atween = nil end
				
				local char = find.player.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local humanoid = char and char:FindFirstChildOfClass("Humanoid")
				if not root or not humanoid then
					if s.Parent then s:Destroy() end
					return
				end

				local target = r(v)
				if not target then return end

				humanoid:MoveTo(root.Position)
				humanoid:Move(Vector3.zero)
				humanoid.WalkSpeed = 0
				root.AssemblyLinearVelocity = Vector3.zero
				root.AssemblyAngularVelocity = Vector3.zero

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
						pcall(function()
							root.Anchored = false
						end)

						pcall(function()
							farming.inv(false)
						end)

						mod.data.actives["converting"] = false
						mod.data.actives["move"] = false
						return
					end

					--if state == Enum.PlaybackState.Cancelled or currentFarmId ~= farmId then
					--	if s.Parent then
					--		s:Destroy()
					--	end

					--	pcall(function()
					--		root.Anchored = false
					--	end)

					--	pcall(function()
					--		farming.inv(false)
					--	end)

					--	if humanoid and humanoid.Parent then
					--		humanoid.WalkSpeed = mod.data.actives["walkspeed"] or 16
					--	end

					--	mod.data.actives["move"] = false
					--	return
					--end

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
					mod.data.actives["point"] = false
					
					--farming.autosprinkler()
					task.wait(.2)
					farming.autosprinkler(true)
					
					--task.wait(1)
					--farming.autosprinkler()
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
			
			local hiveRes = farming.getHive()
			if type(hiveRes) ~= "Vector3" then
				task.wait(0.8)
				
				for _try = 1, 5 do
					local clicked = activateButton()
					task.wait(0.6)
					if type(farming.getHive()) == "Vector3" then break end
					if not clicked then
						pcall(function()
							find.virtual:SendKeyEvent(true, Enum.KeyCode.E, false, game)
							task.wait(0.1)
							find.virtual:SendKeyEvent(false, Enum.KeyCode.E, false, game)
						end)
						task.wait(0.4)
					end
				end

				if type(farming.getHive()) ~= "Vector3" then
					warn("hive failed to occupy hive retrying autoHive in 3s")
					mod.data.actives["move"] = false
					mod.data.actives["converting"] = false
					
					task.delay(3, function()
						if mod.data.actives["auto_farm"] == true
							and mod.data.actives["autohive"] ~= false
						then
							pcall(farming.autoHive)
						end
					end)
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
		--print(target)
		if typeof(target) ~= "Vector3" then return end
		if tween then pcall(function() tween:Cancel() end) tween = nil end
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

		if tween then pcall(function() tween:Cancel() end) tween = nil end
		if atween then pcall(function() atween:Cancel() end) atween = nil end

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
		j(true)

		currentTween.Completed:Once(function(state)
			if tween == currentTween then tween = nil end

			if state == Enum.PlaybackState.Cancelled or currentFarmId ~= farmId then
				pcall(function() j(false) end)
				root.Anchored = false
				mod.data.actives["move"] = false
				return
			end

			pcall(function() j(false) end)
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
		warn("playerHiveCommand not found")
		mod.data.actives["converting"] = false
		mod.data.actives["move"] = false
		return
	end
	
	local spawnPos = player:FindFirstChild("SpawnPos")
	local convertPos

	if spawnPos and spawnPos:IsA("CFrameValue") then
		convertPos = spawnPos.Value.Position + Vector3.new(0, 0, 6)
	end
	
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
	
	local beforePollen = getPollen()
	local started = isMakingHoney()

	if not started then
		if not beforePollen or beforePollen <= 0 then
			mod.data.actives["converting"] = false
			mod.data.actives["move"] = false
			mod.data.actives["last_time_convert"] = tick()
			task.defer(function()
				task.wait(1)
				if mod.data.actives["auto_farm"] then
					farming.farm()
				end
			end)
			return
		end

		pcall(function()
			hiveCommand:FireServer("ToggleHoneyMaking")
		end)
	end
	
	local verifyStart = tick()

	while tick() - verifyStart < 3 do
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
	
	if not started then
		local nowPollen = getPollen()
		if not nowPollen or nowPollen <= 0 then
			mod.data.actives["converting"] = false
			mod.data.actives["move"] = false
			mod.data.actives["last_time_convert"] = tick()
			task.defer(function()
				task.wait(1)
				if mod.data.actives["auto_farm"] then
					farming.farm()
				end
			end)
			return
		end

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
		warn("make honey not started")

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

	--print("make honey started")

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

			--print("convert completed")

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
					while tick() - appearStart < 3 do
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
						local popStart = tick()
						local POP_TIMEOUT = 600
						while balloon.Parent
							and mod.data.actives["auto_farm"]
							and (tick() - popStart) < POP_TIMEOUT
						do
							task.wait(0.25)
						end

						if balloon.Parent then
							warn("convert balloon did not pop in " .. POP_TIMEOUT .. "s (timeout)")
						else
							task.wait(3)
						end
					else
						warn("convert balloon not found in 3s")
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

function farming.autosprinkler(force)
	if mod.data.actives["auto_sprinkler"] ~= true then return end
	if not force and mod.data.actives["move"] == true then return end

	local Events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
	if not Events then return end

	local pac = Events:FindFirstChild("PlayerActivesCommand")
	if not pac or not pac:IsA("RemoteEvent") then return end

	pcall(function()
		pac:FireServer({Name = "Sprinkler Builder"})
	end)
end

function farming.wealthClock()
	if farming.__wealthRunning then
		return
	end
	farming.__wealthRunning = true

	task.spawn(function()
		local nextTrigger = tick() + 3602

		while true do
			task.wait(1)
			if tick() < nextTrigger then
				continue
			end
			
			if mod.data.actives["auto_farm"] ~= true or mod.data.actives["weatlh_clock"] ~= true then
				nextTrigger = nextTrigger + 3602
				continue
			end
			
			local toys = workspace:FindFirstChild("Toys")
			local wc = toys and toys:FindFirstChild("Wealth Clock")
			local platform = wc and wc:FindFirstChild("Platform")
			local alert = platform and platform:FindFirstChild("AlertPos")

			if not (alert and alert:IsA("Attachment")) then
				task.wait(60)
				continue
			end
			
			local waitStart = tick()
			while tick() - waitStart < 120 and mod.data.actives["auto_farm"] == true and mod.data.actives["weatlh_clock"] == true and mod.data.actives["move"] == true do
				task.wait(0.2)
			end

			if mod.data.actives["auto_farm"] ~= true or mod.data.actives["weatlh_clock"] ~= true or mod.data.actives["move"] == true then
				nextTrigger = nextTrigger + 3602
				continue
			end

			local speed = tonumber(mod.data.actives["walkspeed"]) or 40
			local targetPos = alert.WorldPosition
			local returnPos = farming.getHive()

			local ok = farming.move("goto", speed, targetPos)
			if not ok then
				nextTrigger = nextTrigger + 3602
				continue
			end
			
			local flyStart = tick()
			while mod.data.actives["move"] == true and mod.data.actives["auto_farm"] == true and tick() - flyStart < 90 do
				task.wait()
			end

			if mod.data.actives["auto_farm"] ~= true then
				nextTrigger = nextTrigger + 3602
				continue
			end
			
			mod.data.actives["move"] = true
			mod.data.actives["point"] = true

			do
				local ch = find.player.Character
				local rt = ch and ch:FindFirstChild("HumanoidRootPart")
				local hum = ch and ch:FindFirstChildOfClass("Humanoid")

				if rt then
					pcall(function() rt.Anchored = false end)
					pcall(function()
						rt.AssemblyLinearVelocity = Vector3.zero
						rt.AssemblyAngularVelocity = Vector3.zero
					end)
				end

				if hum then
					pcall(function() hum:Move(Vector3.zero, false) end)
				end
			end

			task.wait(1)
			local c1 = activateButton()
			task.wait(1)
			local c2 = activateButton()

			if not c1 and not c2 then
				warn("wealth clock failed")
			end

			task.wait(0.5)

			mod.data.actives["move"] = false
			mod.data.actives["point"] = false
			
			if mod.data.actives["auto_farm"] == true and mod.data.actives["weatlh_clock"] == true and returnPos then
				local backOk = farming.move("goto", speed, returnPos)
				if backOk then
					local backStart = tick()
					while mod.data.actives["move"] == true and tick() - backStart < 90 do
						task.wait()
					end
				end
			end
			
			nextTrigger = nextTrigger + 3602
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

function farming.getHiveList()
	local honeycombs = workspace:FindFirstChild("Honeycombs")
	local list = { "Random" }

	if not honeycombs then return list end
	for _, hive in ipairs(honeycombs:GetChildren()) do
		table.insert(list, hive.Name)
	end

	return list
end

function farming.installAutoRejoin()
	if env.__nectar_autorejoin_installed then return end
	env.__nectar_autorejoin_installed = true

	local LP = find.player
	local TS = game:GetService("TeleportService")
	local queued = false

	local function parsePrivateLink(link)
		if type(link) ~= "string" or link == "" then return nil, nil end
		link = link:match("^%s*(.-)%s*$")

		local placeId = link:match("games/(%d+)") or link:match("places/(%d+)")
		local code = link:match("privateServerLinkCode=([%w%-_]+)")
			or link:match("[?&]code=([%w%-_]+)")

		return tonumber(placeId), code
	end

	local REJOIN_LOADER = "https://raw.githubusercontent.com/zain1241/test-place/main/loader.luau"

	local function doRejoin()
		if queued then return end
		queued = true
		
		if queue_on_teleport then
			local code = string.format([[
local url = "%s"
local src
if request then
    local ok, res = pcall(function()
        return request({ Url = url, Method = "GET" }).Body
    end)
    if ok then src = res end
elseif http_request then
    local ok, res = pcall(function()
        return http_request({ Url = url, Method = "GET" }).Body
    end)
    if ok then src = res end
elseif game.HttpGet then
    local ok, res = pcall(function()
        return game:HttpGet(url)
    end)
    if ok then src = res end
end
if src then
    local fn = loadstring and loadstring(src) or load
    if fn then pcall(fn) end
end
]], REJOIN_LOADER)
			pcall(function() queue_on_teleport(code) end)
		else
			warn("queue_on_teleport not available — script won't auto-load")
		end
		
		local mode = mod.data.actives["server_mode"]

		if mode == "private" then
			local pid, code = parsePrivateLink(mod.data.actives["private_server_link"])
			if pid and code then
				pcall(function()
					TS:TeleportToPrivateServer(pid, code, { LP })
				end)
				return
			end
			warn("private link invalid, fallback to free server")
		end

		pcall(function()
			TS:Teleport(game.PlaceId, LP)
		end)
	end
	
	if hookfunction then
		pcall(function()
			local oldKick = LP.Kick
			hookfunction(LP.Kick, function(self, ...)
				if self == LP and mod.data.actives["auto_rejoin"] == true then
					doRejoin()
				end
				return oldKick(self, ...)
			end)
		end)
	end
	
	LP.AncestryChanged:Connect(function(_, parent)
		if not parent and mod.data.actives["auto_rejoin"] == true then
			doRejoin()
		end
	end)
end

function farming.getHive(...)
	local honeycombs = workspace:FindFirstChild("Honeycombs")

	if not honeycombs then
		return nil
	end

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

	farming.cornl(false)
	farming.inv(false)

	local activeNames = {}

	for _, p in ipairs(find.players:GetPlayers()) do
		activeNames[string.lower(p.Name)] = true
	end

	local myName = string.lower(find.player.Name)

	--local myHivePos = nil
	--local freeHivePos = nil

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
	
	local function extractSpawnPos(container)
		local sp = container:FindFirstChild("SpawnPos")
		if not sp then return nil end
		if sp:IsA("BasePart") then return sp.Position end
		if sp:IsA("CFrameValue") then return sp.Value.Position end
		if sp:IsA("Attachment") then return sp.WorldPosition end
		if sp:IsA("Vector3Value") then return sp.Value end
		return nil
	end

	local myHivePos = nil
	local freeHives = {}   -- { { hive = Instance, name = "Hive1", pos = Vector3 }, ... }

	for _, hive in ipairs(honeycombs:GetChildren()) do
		local display = hive:FindFirstChild("Display")
		local gui = display and display:FindFirstChild("Gui")
		local frame = gui and gui:FindFirstChild("Frame")
		local name = frame and frame:FindFirstChild("OwnerName")

		if name and name:IsA("TextLabel") then
			local trimmed = string.match(name.Text, "^%s*(.-)%s*$") or ""
			local lower = string.lower(trimmed)
			
			if lower == myName then
				myHivePos = extractSpawnPos(hive)
				if myHivePos then break end
			end
			
			local isFree = EMPTY[lower] == true or not activeNames[lower]
			if isFree and lower ~= myName then
				local pos = extractSpawnPos(hive)
				if pos then
					table.insert(freeHives, {
						hive = hive,
						name = hive.Name,
						pos = pos,
					})
				end
			end
		end
	end

	local hiveChoice = mod.data.actives["hive_choice"] or "Random"
	local targetPos = myHivePos

	if not targetPos then
		if #freeHives > 0 then
			if hiveChoice ~= "Random" then
				for _, entry in ipairs(freeHives) do
					if entry.name == hiveChoice then
						targetPos = entry.pos
						break
					end
				end
			end

			if not targetPos then
				local pick = freeHives[find.random:NextInteger(1, #freeHives)]
				targetPos = pick.pos
			end
		end
	end

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

	lastSproutTime = 0

	farming.cornl(enabled)
	--farming.inv(enabled)
	farming.noclip(false)
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
		find.prerender, 2,
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
	
	lastSproutTime = 0

	if not farming.__retrying then
		resetFarmMovement(enabled)
	end

	if not enabled then
		farming.noclip(false)
		return
	end

	farming.noclip(true)
	
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
	--print(pos)

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
	
	if mod.data.actives["selected_field"] == "" then
		mod.data.actives["auto_farm"] = false
		resetFarmMovement(false)
		return
	end
	
	if not find.player.Character
		or not find.player.Character:FindFirstChild("HumanoidRootPart")
	then
		task.wait(0.5)
		if mod.data.actives["auto_farm"] == true then
			task.defer(farming.farm)
		end
		return
	end
	
	local ok = farming.move(
		"flowerzones",
		mod.data.actives["walkspeed"],
		selected
	)

	if not ok then
		farming.__farmFlyRetry = (farming.__farmFlyRetry or 0) + 1
		if farming.__farmFlyRetry >= 5 then
			warn("[farm] initial fly failed 5x — disabling auto_farm to avoid kick")
			farming.__farmFlyRetry = 0
			mod.data.actives["auto_farm"] = false
			resetFarmMovement(false)
			return
		end
		local delay = math.min(2 ^ (farming.__farmFlyRetry - 1), 15)
		warn("initial fly failed, retry " .. farming.__farmFlyRetry .. "/5 in " .. delay .. "s")
		task.delay(delay, function()
			if mod.data.actives["auto_farm"] == true then
				farming.__retrying = true
				local okRetry, errRetry = pcall(farming.farm)
				farming.__retrying = nil
				if not okRetry then
					warn("farm retry error: " .. tostring(errRetry))
				end
			end
		end)
		return
	end
	
	farming.__farmFlyRetry = 0
	farming.__retrying = nil
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
		local part = a[1]

		if part == nil then return end

		if typeof(part) == "string" then
			local f = workspace:FindFirstChild("FlowerZones")
			part = f and f:FindFirstChild(part)
		end

		if not part then
			warn("field not found")
			return
		end

		local cf, size
		if part:IsA("BasePart") then
			cf, size = part.CFrame, part.Size
		elseif part:IsA("Model") then
			cf, size = part:GetBoundingBox()
		else
			warn("r: field is not BasePart/Model")
			return
		end

		local h = .4
		local marginX = math.min(6, size.X * .15)
		local marginZ = math.min(6, size.Z * .15)
		local x = size.X / 2 - marginX
		local z = size.Z / 2 - marginZ

		local position = string.lower(mod.data.actives["position_field"] or "center")
		local ix, ax

		if position == "left" then
			ix = -x; ax = 0
		elseif position == "right" then
			ix = 0; ax = x
		else
			ix = -x / 3; ax = x / 3
		end

		local l = Vector3.new(
			find.random:NextNumber(ix, ax),
			size.Y / 2 + h,
			find.random:NextNumber(-z, z)
		)

		return cf:PointToWorldSpace(l)
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
			if mod.data.actives["selected_field"] == false then
				field = nil
			else
				field = f and f:FindFirstChild(mod.data.actives["selected_field"])
			end

			if mod.data.actives["mondo"] == true then
				local mondoFound = getMondo()
				if mondoFound then
					farming.farmMondo(field, id)
				end
			end
			
			if mod.data.actives["sprouts"] == true
				and field
				and (tick() - lastSproutTime) >= mod.data.actives["sprout_cooldown"]
			then
				local sproutFound = getNearestSprout(
					field,
					find.player.Character
						and find.player.Character:FindFirstChild("HumanoidRootPart")
				)

				if sproutFound then
					--print("found:", sproutFound:GetFullName(), sproutFound.Position)
					farming.farmSprout(field, id)
					continue
				end
			end
			
			if mod.data.actives["petals"] == true and field then
				farming.farmPetalBloom(field, id)
			end
			
			if mod.data.actives["pushrooms_enabled"] == true and field then
				local rt = find.player.Character
					and find.player.Character:FindFirstChild("HumanoidRootPart")

				local puffFound = getNearestPuff(
					field,
					rt,
					mod.data.actives["pushrooms"] or "All Pushrooms"
				)

				if puffFound then
					farming.farmPuffshroom(field, id)

					if id ~= farmId
						or mod.data.actives["auto_farm"] ~= true
						or mod.data.actives["converting"]
					then
						continue
					end

					rt = find.player.Character
						and find.player.Character:FindFirstChild("HumanoidRootPart")

					local nextPuff = getNearestPuff(
						field,
						rt,
						mod.data.actives["pushrooms"] or "All Pushrooms"
					)

					if not nextPuff then
						mod.data.actives["move"] = false
						returnToField(field, id)
					end

					continue
				end
			end

			table.clear(queue["tokens"])
			
			if c and field then
				local rt = find.player.Character and find.player.Character:FindFirstChild("HumanoidRootPart")
				if rt then
					for _, v in ipairs(c:GetChildren()) do
						if v:IsA("BasePart")
							and v.Transparency <= 0
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
				local rt0 = find.player.Character
					and find.player.Character:FindFirstChild("HumanoidRootPart")
				if not rt0 then
					mod.data.actives["point"] = false
					return
				end

				local refPos = rt0.Position
				table.sort(queue["tokens"], function(x, y)
					local pa = getTokenPriority(x)
					local pb = getTokenPriority(y)
					if pa ~= pb then return pa > pb end
					return (refPos - x.Position).Magnitude
						< (refPos - y.Position).Magnitude
				end)

				local speed = a.Speed
				local function getNextToken()
					while #queue["tokens"] > 0 do
						local t = queue["tokens"][1]
						if t and t.Parent and t.Transparency <= 0 then return t end
						table.remove(queue["tokens"], 1)
					end
					return nil
				end

				local target = getNextToken()

				while id == farmId and mod.data.actives["auto_farm"] == true and not mod.data.actives["converting"] and target do
					local char = find.player.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					local rt = char and char:FindFirstChild("HumanoidRootPart")
					if not hum or not rt or rt.Anchored then break end

					local fled = false

					local lp = field.CFrame:PointToObjectSpace(target.Position)
					local hip = hum.HipHeight
					local p = field.CFrame:PointToWorldSpace(
						Vector3.new(lp.X, field.Size.Y / 2 + hip, lp.Z)
					)

					local d = Vector3.new(p.X - rt.Position.X, 0, p.Z - rt.Position.Z)
					local cf = d.Magnitude > .001
						and CFrame.lookAt(p, p + d.Unit)
						or CFrame.new(p) * rt.CFrame.Rotation
					local t = math.max(d.Magnitude / math.max(speed, .001), 0.01)
					
					if char:FindFirstChild("Animate")
						and char.Animate:FindFirstChild("run")
						and char.Animate.run:FindFirstChildWhichIsA("Animation")
					then
						local an = hum:FindFirstChildOfClass("Animator")
						if not track or animwalk ~= an then
							if track then track:Destroy() end
							animwalk = an
							track = an:LoadAnimation(
								char.Animate.run:FindFirstChildWhichIsA("Animation")
							)
							track.Looped = true
						end
						if not track.IsPlaying then track:Play() end
						track:AdjustSpeed(math.clamp(speed / 16, .25, 3))
					end

					local currentTween = find.tweenservice:Create(
						rt,
						TweenInfo.new(t, Enum.EasingStyle.Linear),
						{CFrame = cf}
					)
					atween = currentTween
					currentTween:Play()
					
					local targetFlat = Vector3.new(p.X, 0, p.Z)

					while currentTween.PlaybackState == Enum.PlaybackState.Playing do
						if id ~= farmId
							or mod.data.actives["auto_farm"] ~= true
							or mod.data.actives["converting"]
						then
							pcall(function() currentTween:Cancel() end)
							if atween == currentTween then atween = nil end
							if track and track.IsPlaying then track:Stop(.1) end
							mod.data.actives["point"] = false
							return
						end

						local rt2 = find.player.Character and find.player.Character:FindFirstChild("HumanoidRootPart")
						if not rt2 then break end

						local flee3 = getFleeTarget(rt2)
						if flee3 then
							pcall(function() currentTween:Cancel() end)
							local c2 = find.player.Character
							local h2 = c2 and c2:FindFirstChildOfClass("Humanoid")
							if h2 then
								h2.WalkSpeed = speed
								h2:MoveTo(flee3)
							end
							fled = true
							break
						end

						local curFlat = Vector3.new(rt2.Position.X, 0, rt2.Position.Z)
						if (targetFlat - curFlat).Magnitude <= 2.5 then
							pcall(function() currentTween:Cancel() end)
							break
						end

						task.wait()
					end

					if atween == currentTween then atween = nil end
					if id ~= farmId then break end

					if fled then
						task.wait()
						target = getNextToken()
						continue
					end

					table.remove(queue["tokens"], 1)
					target = getNextToken()
				end

				if atween then
					pcall(function() atween:Cancel() end)
					atween = nil
				end
				if track and track.IsPlaying then track:Stop(.1) end
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
		mod.data.actives["move"] = true

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
				task.wait()
			end

			local c3 = find.player.Character
			local h3 = c3 and c3:FindFirstChildOfClass("Humanoid")
			if h3 then h3:Move(Vector3.zero, false) end
		end

		while id == farmId and mod.data.actives["auto_farm"] == true and #queue["auto_farm"] > 0 and not mod.data.actives["converting"] do
			local a = table.remove(queue["auto_farm"], 1)
			local c = workspace:FindFirstChild("Collectibles")
			local f = workspace:FindFirstChild("FlowerZones")
			local field
			if mod.data.actives["selected_field"] == false then
				field = nil
			else
				field = f and f:FindFirstChild(mod.data.actives["selected_field"])
			end

			if mod.data.actives["mondo"] == true then
				local mondoFound = getMondo()
				if mondoFound then
					farming.farmMondo(field, id)
					if id ~= farmId
						or mod.data.actives["auto_farm"] ~= true
						or mod.data.actives["converting"]
					then
						continue
					end
				end
			end
			
			if mod.data.actives["sprouts"] == true and field and (tick() - lastSproutTime) >= mod.data.actives["sprout_cooldown"] then
				local sproutFound = getNearestSprout(
					field,
					find.player.Character
						and find.player.Character:FindFirstChild("HumanoidRootPart")
				)

				if sproutFound then
					--print("found:", sproutFound:GetFullName(), sproutFound.Position)
					farming.farmSprout(field, id)
					continue
				end
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
				local rt = find.player.Character
					and find.player.Character:FindFirstChild("HumanoidRootPart")

				local puffFound = getNearestPuff(
					field,
					rt,
					mod.data.actives["pushrooms"] or "All Pushrooms"
				)

				if puffFound then
					farming.farmPuffshroom(field, id)

					if id ~= farmId
						or mod.data.actives["auto_farm"] ~= true
						or mod.data.actives["converting"]
					then
						continue
					end

					rt = find.player.Character
						and find.player.Character:FindFirstChild("HumanoidRootPart")

					local nextPuff = getNearestPuff(
						field,
						rt,
						mod.data.actives["pushrooms"] or "All Pushrooms"
					)

					if not nextPuff then
						returnToField(field, id)
					end

					continue
				end
			end

			table.clear(queue["tokens"])
			
			if c and field then
				local rt = find.player.Character and find.player.Character:FindFirstChild("HumanoidRootPart")
				if rt then
					for _, v in ipairs(c:GetChildren()) do
						if v:IsA("BasePart")
							and v.Transparency <= 0
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
				local rt0 = find.player.Character
					and find.player.Character:FindFirstChild("HumanoidRootPart")
				if not rt0 then
					mod.data.actives["point"] = false
					return
				end

				local refPos = rt0.Position
				table.sort(queue["tokens"], function(x, y)
					local pa = getTokenPriority(x)
					local pb = getTokenPriority(y)
					if pa ~= pb then return pa > pb end
					return (refPos - x.Position).Magnitude
						< (refPos - y.Position).Magnitude
				end)
				
				local speed = a.Speed

				local lastPos = rt0.Position
				local stuckCount = 0

				while id == farmId and mod.data.actives["auto_farm"] == true and #queue["tokens"] > 0 and not mod.data.actives["converting"] do
					while #queue["tokens"] > 0 do
						local first = queue["tokens"][1]
						if first and first.Parent and first.Transparency <= 0 then break end
						table.remove(queue["tokens"], 1)
					end
					if #queue["tokens"] == 0 then break end

					local target = queue["tokens"][1]
					local char = find.player.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					local rt = char and char:FindFirstChild("HumanoidRootPart")
					if not hum or not rt or rt.Anchored then break end

					local flee = getFleeTarget(rt)
					if flee then
						hum.WalkSpeed = speed
						hum:MoveTo(flee)
						task.wait()
						continue
					end

					local tp = Vector3.new(target.Position.X, rt.Position.Y, target.Position.Z)
					local dist = (tp - rt.Position).Magnitude

					if dist <= 2 then
						table.remove(queue["tokens"], 1)
						lastPos = rt.Position
						stuckCount = 0
						continue
					end

					hum.WalkSpeed = speed
					hum:MoveTo(tp)
					task.wait()
				end
			else
				if a.TargetPosition and a.Speed then
					local char = find.player.Character
					local hum = char and char:FindFirstChildOfClass("Humanoid")
					local rt = char and char:FindFirstChild("HumanoidRootPart")

					if hum and rt and not rt.Anchored then
						local walkStart = tick()
						local targetPos = a.TargetPosition

						while tick() - walkStart < 15 do
							if id ~= farmId
								or mod.data.actives["auto_farm"] ~= true
								or mod.data.actives["converting"]
							then
								break
							end
							
							local hasToken = false
							if c and field then
								for _, v in ipairs(c:GetChildren()) do
									if v:IsA("BasePart") and isTokenInField(v, field) then
										hasToken = true
										break
									end
								end
							end
							if hasToken then break end

							local char2 = find.player.Character
							local hum2 = char2 and char2:FindFirstChildOfClass("Humanoid")
							local rt2 = char2 and char2:FindFirstChild("HumanoidRootPart")
							if not hum2 or not rt2 or rt2.Anchored then break end

							local flee2 = getFleeTarget(rt2)
							if flee2 then
								hum2.WalkSpeed = a.Speed
								hum2:MoveTo(flee2)
								task.wait()
								continue
							end

							local flat = Vector3.new(targetPos.X, rt2.Position.Y, targetPos.Z)
							if (flat - rt2.Position).Magnitude <= 1.5 then break end

							hum2.WalkSpeed = a.Speed
							hum2:MoveTo(flat)
							task.wait()
						end
					end
				end
			end

			task.wait()
		end

		mod.data.actives["move"] = false
		mod.data.actives["point"] = false
	end

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

		-- Флаг: первая проверка после прилёта на поле
		local didArrivalCheck = false

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
					farming.hardUninv()
					farming.noclip(false)
					mod.data.actives["move"] = false
					return
				end
				if mod.data.actives["auto_farm"] == true then
					if mod.data.actives["converting"] then return end
					local info = farming.get_pollen_info()
					local threshold = mod.data.actives["backpack"] or 80

					-- === Прилёт на поле: решает ТОЛЬКО процент рюкзака ===
					if not didArrivalCheck and mod.data.actives["move"] == false then
						didArrivalCheck = true
						if not (info and info.percent >= threshold) then
							-- Рюкзак пустой/неполный — сбрасываем таймер,
							-- чтобы он не сработал сразу после прилёта
							mod.data.actives["last_time_convert"] = tick()
						end
					end

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
						local hasPollen = false
						local coreStats = find.player:FindFirstChild("CoreStats")
						local pv = coreStats and coreStats:FindFirstChild("Pollen")
						if pv and pv:IsA("NumberValue") then
							hasPollen = pv.Value > 0
						else
							local pInfo = farming.get_pollen_info()
							hasPollen = pInfo and pInfo.pollen and pInfo.pollen > 0
						end

						if not hasPollen then
							mod.data.actives["last_time_convert"] = tick()
						else
							local targetPos = farming.getHive()
							if targetPos then
								mod.data.actives["move"] = false
								mod.data.actives["point"] = false
								local ok = farming.move("convert", mod.data.actives["walkspeed"], targetPos)
								if ok then
									mod.data.actives["converting"] = true
								end
							end
						end
						return
					end
					
					--if shouldConvert and mod.data.actives["move"] == false then
					--	local targetPos = farming.getHive()
					--	if targetPos then
					--		local ok = farming.move("convert", mod.data.actives["walkspeed"], targetPos)
					--		if ok then
					--			mod.data.actives["converting"] = true
					--		end
					--	end
					--	return
					--end
				end
				
				if mod.data.actives["move"] == false then
					if invc then
						farming.inv(false)
						farming.hardUninv()
					end
					local hasTokens = false
					local collectibles = workspace:FindFirstChild("Collectibles")
					local flowerZones = workspace:FindFirstChild("FlowerZones")
					local selField = mod.data.actives["selected_field"]
					local checkField = flowerZones and selField and flowerZones:FindFirstChild(selField)

					if collectibles and checkField then
						local rt = find.player.Character
							and find.player.Character:FindFirstChild("HumanoidRootPart")
						if rt then
							for _, v in ipairs(collectibles:GetChildren()) do
								if v:IsA("BasePart") and v.Transparency <= 0 then
									local p = checkField.CFrame:PointToObjectSpace(v.Position)
									local s = checkField.Size / 2
									if math.abs(p.X) <= s.X
										and math.abs(p.Z) <= s.Z
										and p.Y >= -3 and p.Y <= 15
									then
										hasTokens = true
										break
									end
								end
							end
						end
					end

					if not hasTokens and mod.data.actives["collect_bubbles"] == true and checkField then
						initBubbles()
						local rt = find.player.Character
							and find.player.Character:FindFirstChild("HumanoidRootPart")
						if rt then
							for bubble in pairs(bubbles) do
								if bubble.Parent and isInField(bubble.Position, checkField) then
									hasTokens = true
									break
								end
							end
						end
					end
					
					if hasTokens then
						if #queue["auto_farm"] == 0 then
							table.insert(queue["auto_farm"], {TargetPosition = nil, Speed = mod.data.actives["walkspeed"]})
							if not mod.data.actives["move"] then
								task.spawn(q1)
							end
						end
					else
						if mod.data.actives["style_auto_farm"] == "Walk" then
							farming.cornl(true)
							m1(b, mod.data.actives["walkspeed"])
						elseif mod.data.actives["style_auto_farm"] == "Tween" then
							farming.cornl(true)
							m(b, mod.data.actives["walkspeed"])
						end
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
		farming.hardUninv()
		farming.noclip(false)
	end
end

task.spawn(function()
	task.wait(2)

	if mod.data.actives["auto_dig"] == true then
		farming.autoDig(true)
	end
	
	farming.forceWalkSpeed(mod.data.actives["walkspeed"] or 16)
	farming.wealthClock()
	farming.installAutoRejoin()
	
	if mod.data.actives["auto_farm"] == true then
		farming.farm()
	end
	farming.__initialFarmStarted = true
end)

local function onCharacterRespawn(character)
	task.wait(0.8)

	if adig then
		pcall(function() adig:Disconnect() end)
		adig = nil
	end

	pcall(function()
		resetFarmMovement(false)
	end)
	
	if mod.data.actives["auto_dig"] == true then
		task.spawn(function()
			task.wait(1)
			pcall(function() farming.autoDig(true) end)
		end)
	end
	
	mod.data.actives["point"] = false
	mod.data.actives["move"] = false
	mod.data.actives["converting"] = false
	
	local humanoid = character:WaitForChild("Humanoid", 10)
	local hrp = character:WaitForChild("HumanoidRootPart", 10)

	if not humanoid or not hrp then
		return
	end
	
	local ws = tonumber(mod.data.actives["walkspeed"]) or 16
	humanoid.WalkSpeed = ws
	
	pcall(function()
		hrp.Massless = false
		local p = hrp.CurrentPhysicalProperties
		hrp.CustomPhysicalProperties = PhysicalProperties.new(
			20, p.Friction, p.Elasticity, p.FrictionWeight, p.ElasticityWeight
		)
	end)
	
	pcall(function()
		farming.forceWalkSpeed(ws)
	end)
	
	if mod.data.actives["auto_farm"] == true and farming.__initialFarmStarted then
		task.wait(0.5)

		mod.data.actives["move"] = false
		mod.data.actives["point"] = false
		mod.data.actives["converting"] = false

		pcall(function()
			farming.farm()
		end)
	end
end

find.player.CharacterAdded:Connect(onCharacterRespawn)

if find.player.Character then
	task.spawn(function()
		task.wait(0.5)
		onCharacterRespawn(find.player.Character)
	end)
end

return farming
