local env = (getgenv and getgenv()) or _G
local loaded = rawget(env, "__NECTAR_MODULES")

local data

if loaded and loaded.data then
	data = loaded.data
else
	data = require(script.Parent:WaitForChild("data"))
end

print("test new sys1432423412")

local farming = {}

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
	random = Random.new(),
}

--print(find.player)

local queue = {
	auto_farm = {},
	tokens = {},
}

local invc, tween, afarm, atween, track, animwalk, p, p1; local farmId = 0

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
		mod.data.actives["move"] = true
		--print(actives["move"])
		for _, v in ipairs(workspace:FindFirstChild("FlowerZones"):GetChildren()) do
			if v.Name == a[3] then
				if mod.data.actives["auto_farm"] == false then
					return
				end
				local c = v.Position -- p f
				local s = Instance.new("SelectionBox")
				s.Parent = v; s.Adornee = v; s.Color3 = Color3.new(255, 255, 255); s.SurfaceColor3 = Color3.new(255, 255, 255); s.LineThickness = .04; s.SurfaceTransparency = .9

				if tween then
					tween:Cancel()
					tween = nil
				end

				if not workspace:FindFirstChild(find.player.Name) then
					return
				end

				local root = find.player.Character:FindFirstChild("HumanoidRootPart")
				local target = v.CFrame:PointToWorldSpace(
					Vector3.new(
						0,
						v.Size.Y / 2 + 4,
						0
					)
				)

				local d1 = (root.Position - target).Magnitude
					/ math.max(a[2], .001)

				root.Anchored = true

				local root = find.player.Character:FindFirstChild("HumanoidRootPart")
				local currentFarmId = farmId

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
				b(true, root, v)

				currentTween.Completed:Once(function(state)
					if tween == currentTween then
						tween = nil
					end

					if state == Enum.PlaybackState.Cancelled
						or currentFarmId ~= farmId
					then
						if s.Parent then
							s:Destroy()
						end

						return
					end

					j(false)

					pcall(function()
						b(false, root, v)
					end)

					if s.Parent then
						s:Destroy()
					end

					-- Игрок остаётся закреплённым в центре поля.
					farming.inv(true)

					-- Ставим sprinkler и ждём его установку.
					farming.autosprinkler()
					task.wait(1)

					-- За время ожидания игрок мог сменить поле
					-- или выключить автофарм.
					if currentFarmId ~= farmId
						or mod.data.actives["auto_farm"] == false
					then
						return
					end

					root.Anchored = false
					mod.data.actives["move"] = false
				end)

				return currentTween
			end
		end
	end
end

function farming.get_pollen_from_gui()
	local player = find.player
	local pg = player:FindFirstChild("PlayerGui")
	if not pg then return nil end

	-- Путь: PlayerGui.ScreenGui.MeterHUD.PollenMeter.Bar.TextLabel
	local screenGui = pg:FindFirstChild("ScreenGui")
	local meterHud = screenGui and screenGui:FindFirstChild("MeterHUD")
	local pollenMeter = meterHud and meterHud:FindFirstChild("PollenMeter")
	local bar = pollenMeter and pollenMeter:FindFirstChild("Bar")
	local label = bar and bar:FindFirstChild("TextLabel")

	if not label or not label:IsA("TextLabel") then
		return nil
	end

	local text = label.Text
	-- Формат: "35,427/192,265,724"
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

function farming.autosprinkler()
	if mod.data.actives["auto_sprinkler"] ~= true then
		return
	end

	if mod.data.actives["move"] == true or mod.data.actives["__converting"] == true then
		return
	end

	-- Кулдаун 10 сек
	if mod.data.actives["__last_sprinkler_time"] then
		local elapsed = tick() - mod.data.actives["__last_sprinkler_time"]
		if elapsed < 10 then
			return
		end
	end

	local character = find.player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	if not root or not humanoid then return end

	-- Проверяем 3 замера по 0.15 сек = 0.45 сек — на земле ли игрок
	local groundCount = 0
	for i = 1, 3 do
		if humanoid.FloorMaterial ~= Enum.Material.Air then
			if root.AssemblyLinearVelocity.Magnitude < 8 then
				groundCount = groundCount + 1
			end
		end
		task.wait(0.15)
	end

	if groundCount < 3 then
		return
	end

	-- Не в улье
	local hivePos = farming.get_hive_position()
	if hivePos and (root.Position - hivePos).Magnitude < 30 then
		return
	end

	local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
	if not events then return end

	local pac = events:FindFirstChild("PlayerActivesCommand")
	if not pac or not pac:IsA("RemoteEvent") then
		return
	end

	local ok = pcall(function()
		pac:FireServer({Name = "Sprinkler Builder"})
	end)

	if ok then
		mod.data.actives["__last_sprinkler_time"] = tick()
		print("[AutoSprinkler] placed (grounded)")
	end
end

-- Возвращает актуальную стату игрока или nil
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

function farming.honey_mask()
	local stats = getStats()
	if not stats then return false end

	-- В дампе: [EquippedMask] = "Diamond Mask" / "Honey Mask" / "None"
	local mask = stats.EquippedMask
	if type(mask) ~= "string" then return false end

	return mask == "Honey Mask"
end

function farming.get_pollen_info()
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

function farming.get_hive_position()
	local honeycombs = workspace:FindFirstChild("Honeycombs")
	if not honeycombs then
		return nil
	end

	local myName = string.lower(find.player.Name)

	for _, hive in ipairs(honeycombs:GetChildren()) do
		local display = hive:FindFirstChild("Display")
		local gui = display and display:FindFirstChild("Gui")
		local frame = gui and gui:FindFirstChild("Frame")
		local ownerName = frame and frame:FindFirstChild("OwnerName")

		if ownerName and ownerName:IsA("TextLabel") then
			local text = ownerName.Text or ""
			-- Обрезаем пробелы
			local trimmed = string.match(text, "^%s*(.-)%s*$") or ""

			if string.lower(trimmed) == myName then
				local spawnPos = hive:FindFirstChild("SpawnPos")
				if spawnPos then
					if spawnPos:IsA("BasePart") then
						return spawnPos.Position
					elseif spawnPos:IsA("CFrameValue") then
						return spawnPos.Value.Position
					elseif spawnPos:IsA("Attachment") then
						return spawnPos.WorldPosition
					elseif spawnPos:IsA("Vector3Value") then
						return spawnPos.Value
					end
				end
			end
		end
	end

	return nil
end

function farming.wait_for_balloon(hivePos, timeout)
	timeout = timeout or 300 -- максимум 5 минут

	local startTime = tick()

	while tick() - startTime < timeout do
		-- Ищем BalloonBody в радиусе 25 от SpawnPos
		local found = false

		for _, obj in ipairs(workspace:GetDescendants()) do
			if obj.Name == "BalloonBody" and obj:IsA("BasePart") then
				local dist = (obj.Position - hivePos).Magnitude
				if dist <= 25 then
					found = true
					break
				end
			end
		end

		if not found then
			print("[AutoConvert] Хайв-баллун исчез, ждём 3 секунды")
			task.wait(3)
			return true
		end

		task.wait(1)
	end

	warn("[AutoConvert] Таймаут ожидания баллуна")
	return false
end

-- Жмёт E и проверяет, уменьшился ли Pollen за 10 секунд.
-- Если уменьшился — возвращает true. Если нет — жмёт ещё раз.
function farming.press_e_until_convert(hivePos, maxAttempts)
	maxAttempts = maxAttempts or 2

	local VirtualInputManager = game:GetService("VirtualInputManager")

	-- Запоминаем Pollen ДО всего
	local initialInfo = farming.get_pollen_info()
	local initialPollen = initialInfo and initialInfo.pollen or 0

	for attempt = 1, maxAttempts do
		print("[AutoConvert] Попытка " .. attempt .. ": жмём E")

		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
		task.wait(0.1)
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)

		-- Ждём 5 секунд — быстро проверяем, сработало ли
		local quickCheck = tick()
		while tick() - quickCheck < 5 do
			task.wait(0.5)
			local now = farming.get_pollen_info()
			if now and (now.pollen < initialPollen * 0.9 or now.percent < 2) then
				print("[AutoConvert] Конвертация запущена")
				return true
			end
		end

		print("[AutoConvert] E не сработал за 5 сек — жмём ещё раз")
	end

	-- Не сработало — не выходим, просто возвращаем false
	print("[AutoConvert] E не сработал — ждём автоматическую конвертацию сервера")
	return false
end

-- Жмёт E и проверяет, стал ли улей нашим за 10 секунд.
-- Если стал — возвращает true. Если нет — жмёт ещё раз.
function farming.press_e_until_hive(maxAttempts)
	maxAttempts = maxAttempts or 5

	local VirtualInputManager = game:GetService("VirtualInputManager")

	for attempt = 1, maxAttempts do
		print("[Farm] Попытка занять улей " .. attempt .. ": жмём E")

		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
		task.wait(0.05)
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)

		-- Ждём до 10 секунд, проверяем каждую секунду
		local startTime = tick()
		while tick() - startTime < 10 do
			task.wait(1)

			local hivePos = farming.get_hive_position()
			if hivePos then
				print("[Farm] Улей занят!")
				return true, hivePos
			end
		end

		print("[Farm] Улей не занялся за 10 сек — жмём E ещё раз")
	end

	warn("[Farm] Не удалось занять улей")
	return false, nil
end

function farming.go_to_hive_and_convert()
	print("[AutoConvert] Начинаем...")

	-- 1. Проверяем свой улей
	local hivePos = farming.get_hive_position()

	if not hivePos then
		print("[AutoConvert] Своего улья нет — ищем свободный")

		local freeHive = farming.find_free_hive()
		if not freeHive then
			warn("[AutoConvert] Свободных ульев нет")
			return
		end

		print("[AutoConvert] Найден свободный улей:", freeHive.hive.Name,
			"| OwnerName.Text = '" .. tostring(freeHive.ownerText) .. "'")
		print("[AutoConvert] Позиция SpawnPos:", tostring(freeHive.pos))

		-- Летим к свободному
		local character = find.player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			warn("[AutoConvert] Нет HumanoidRootPart")
			return
		end

		mod.data.actives["move"] = true

		local dist = (root.Position - freeHive.pos).Magnitude
		local speed = mod.data.actives["move_speed"] or 100
		local tweenTime = dist / math.max(speed, 1)

		root.Anchored = true
		local tw = find.tweenservice:Create(
			root,
			TweenInfo.new(tweenTime, Enum.EasingStyle.Linear),
			{CFrame = CFrame.new(freeHive.pos)}
		)
		tw:Play()
		tw.Completed:Wait()
		task.wait(1.5)

		-- Эмулируем E для занятия
		print("[AutoConvert] Занимаем улей через E")
		farming.emulate_e(5)
		task.wait(2)

		-- Проверяем, занялся ли
		local newHivePos = nil
		for attempt = 1, 5 do
			newHivePos = farming.get_hive_position()
			if newHivePos then break end
			print("[AutoConvert] Попытка " .. attempt .. "/5 — улей ещё не наш")
			farming.emulate_e(2)
			task.wait(1)
		end

		if not newHivePos then
			warn("[AutoConvert] Не удалось занять улей")
			root.Anchored = false
			mod.data.actives["move"] = false
			return
		end

		hivePos = newHivePos
		print("[AutoConvert] Улей занят:", tostring(hivePos))
	end

	-- 2. Запоминаем позицию поля, откуда прилетели
	local character = find.player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local returnPos = root.Position
	local selectedField = mod.data.actives["selected_field"]
	local fields = workspace:FindFirstChild("FlowerZones")
	local field = fields and selectedField and fields:FindFirstChild(selectedField)
	if field and field:IsA("BasePart") then
		returnPos = field.Position
	end

	-- 3. ПРОБУЕМ E ДЛЯ РАЗГРУЗКИ
	print("[AutoConvert] Пробуем E для разгрузки")
	farming.press_e_until_convert(hivePos, 2)

	-- ===== 4. ЖДЁМ ЗАВЕРШЕНИЯ КОНВЕРТАЦИИ =====
	print("[AutoConvert] Ждём завершения конвертации...")

	-- Запоминаем состояние В МОМЕНТ ПРИЛЁТА
	local arrivalInfo = farming.get_pollen_info()
	local arrivalPollen = arrivalInfo and arrivalInfo.pollen or 0
	local arrivalPercent = arrivalInfo and arrivalInfo.percent or 0

	print(string.format(
		"[AutoConvert] Прилетели: pollen=%d (%.2f%%)",
		arrivalPollen, arrivalPercent))

	-- Если при прилёте Pollen УЖЕ низкий — это подозрительно, ждём 10 сек
	if arrivalPercent < 5 then
		print("[AutoConvert] Pollen уже низкий — ждём 10 сек для уверенности")
		task.wait(10)
	end

	local timeout = 300
	local startTime = tick()
	local lowCount = 0
	local requiredLow = 8
	local sawDrop = false

	while tick() - startTime < timeout do
		local info = farming.get_pollen_info()
		if not info then
			task.wait(1)
			continue
		end

		-- Отслеживаем, что Pollen РЕАЛЬНО падал (был высокий → стал низкий)
		if not sawDrop and arrivalPercent >= 5 then
			if info.pollen < arrivalPollen * 0.5 then
				sawDrop = true
				print(string.format(
					"[AutoConvert] Pollen упал вдвое: %d → %d",
					arrivalPollen, info.pollen))
			end
		end

		-- Считаем «низкий» только если Pollen < 5%
		if info.percent < 5 then
			lowCount = lowCount + 1
			print(string.format(
				"[AutoConvert] Низкий %d/%d (%.2f%%)",
				lowCount, requiredLow, info.percent))

			if lowCount >= requiredLow then
				-- Проверка: если мы прилетели с полным рюкзаком,
				-- но так и НЕ увидели падения — что-то не так
				if arrivalPercent >= 5 and not sawDrop then
					warn("[AutoConvert] Pollen низкий, но падения не было — пропускаем")
					lowCount = 0
				else
					print("[AutoConvert] Разгрузка завершена")
					break
				end
			end
		else
			lowCount = 0
		end

		task.wait(1)
	end

	-- 5. ЖДЁМ ЗАВЕРШЕНИЯ
	print("[AutoConvert] Ждём завершения конвертации...")

	local timeout = 300
	local startTime = tick()
	local lastPollen = nil
	local stableLowCount = 0

	while tick() - startTime < timeout do
		local info = farming.get_pollen_info()
		if not info then
			task.wait(1)
			continue
		end

		-- Считаем «Pollen низкий и не растёт»
		if info.percent < 5 then
			if lastPollen and info.pollen <= lastPollen + 1000 then
				-- Pollen не растёт (или растёт очень медленно)
				stableLowCount = stableLowCount + 1
				print(string.format(
					"[AutoConvert] Pollen стабильно низкий %d/%d (%.2f%%) — %d/5",
					info.pollen, info.max, info.percent, stableLowCount))

				if stableLowCount >= 5 then
					print("[AutoConvert] Разгрузка завершена")
					break
				end
			else
				-- Pollen вырос — сбрасываем счётчик
				stableLowCount = 0
			end
		else
			stableLowCount = 0
		end

		lastPollen = info.pollen
		task.wait(1)
	end

	-- 6. Ждём баллун
	if mod.data.actives["balloon"] == true then
		print("[AutoConvert] Ждём хайв-баллун...")
		farming.wait_for_balloon(hivePos, 300)
	end

	-- 7. Возвращаемся на поле
	print("[AutoConvert] Возвращаемся на поле")

	local distBack = (root.Position - returnPos).Magnitude
	if distBack > 5 then
		local speed = mod.data.actives["move_speed"] or 100
		local tweenTime = distBack / math.max(speed, 1)

		root.Anchored = true
		local twBack = find.tweenservice:Create(
			root,
			TweenInfo.new(tweenTime, Enum.EasingStyle.Linear),
			{CFrame = CFrame.new(returnPos)}
		)
		twBack:Play()
		twBack.Completed:Wait()
	end

	root.Anchored = false
	mod.data.actives["move"] = false
	mod.data.actives["__last_convert_time"] = tick()
	--mod.data.actives["__last_sprinkler_time"] = nil

	print("[AutoConvert] Готово")
end

function farming.find_free_hive()
	local honeycombs = workspace:FindFirstChild("Honeycombs")
	if not honeycombs then return nil end

	local Players = game:GetService("Players")

	-- Собираем имена всех игроков на сервере (lowercase)
	local activeNames = {}
	for _, p in ipairs(Players:GetPlayers()) do
		activeNames[string.lower(p.Name)] = true
	end

	local root = find.player.Character and find.player.Character:FindFirstChild("HumanoidRootPart")
	local myPos = root and root.Position

	local bestHive = nil
	local bestDist = math.huge

	for _, hive in ipairs(honeycombs:GetChildren()) do
		local display = hive:FindFirstChild("Display")
		local gui = display and display:FindFirstChild("Gui")
		local frame = gui and gui:FindFirstChild("Frame")
		local ownerName = frame and frame:FindFirstChild("OwnerName")

		if ownerName and ownerName:IsA("TextLabel") then
			local text = ownerName.Text or ""
			local trimmed = string.match(text, "^%s*(.-)%s*$") or ""

			local isFree = false

			-- Пустая строка = свободен
			if trimmed == "" then
				isFree = true
			else
				-- Если имя не принадлежит ни одному игроку на сервере
				local lower = string.lower(trimmed)
				if not activeNames[lower] then
					isFree = true
				end
			end

			if isFree then
				local spawnPos = hive:FindFirstChild("SpawnPos")
				if spawnPos then
					local pos = nil
					if spawnPos:IsA("BasePart") then
						pos = spawnPos.Position
					elseif spawnPos:IsA("CFrameValue") then
						pos = spawnPos.Value.Position
					elseif spawnPos:IsA("Attachment") then
						pos = spawnPos.WorldPosition
					elseif spawnPos:IsA("Vector3Value") then
						pos = spawnPos.Value
					end

					if pos then
						local dist = myPos and (myPos - pos).Magnitude or 0
						if dist < bestDist then
							bestDist = dist
							bestHive = {
								hive = hive,
								pos = pos,
								ownerText = trimmed,
							}
						end
					end
				end
			end
		end
	end

	return bestHive
end

function farming.emulate_e(times)
	times = times or 3

	local VirtualInputManager = game:GetService("VirtualInputManager")
	if not VirtualInputManager then
		warn("[emulate_e] VirtualInputManager недоступен")
		return false
	end

	for i = 1, times do
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
		task.wait(0.05)
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
		task.wait(0.2)
	end

	print("[emulate_e] Нажал E x" .. times)
	return true
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

	farming.cornl(enabled)
	farming.inv(enabled)
end

local autoDigId = 0
function farming.autoDig(enabled)
	autoDigId += 1
	local id = autoDigId

	if enabled ~= true then
		return
	end

	local events = game:GetService("ReplicatedStorage"):FindFirstChild("Events")
	local collect = events and events:FindFirstChild("ToolCollect")

	if not collect or not collect:IsA("RemoteEvent") then
		warn("ToolCollect не найден")
		return
	end

	task.spawn(function()
		while mod.data.actives["auto_dig"] == true and autoDigId == id do
			collect:FireServer()
			task.wait(.1)
		end
	end)
end

function farming.farm(...)
	farmId += 1
	local id = farmId
	local enabled = mod.data.actives["auto_farm"] == true

	resetFarmMovement(enabled)

	if not enabled then return end

	-- ===== ПРОВЕРКА УЛЬЯ ПЕРЕД СТАРТОМ ФАРМА =====
	local hivePos = farming.get_hive_position()

	if not hivePos then
		print("[Farm] Своего улья нет — ищем свободный")

		local freeHive = farming.find_free_hive()
		if not freeHive then
			warn("[Farm] Свободных ульев нет — стоп автофарм")
			mod.data.actives["auto_farm"] = false
			resetFarmMovement(false)
			return
		end

		print("[Farm] Найден свободный улей:", freeHive.hive.Name)

		local character = find.player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not root then
			mod.data.actives["auto_farm"] = false
			resetFarmMovement(false)
			return
		end

		-- Летим к свободному улью
		mod.data.actives["move"] = true
		local dist = (root.Position - freeHive.pos).Magnitude
		local speed = mod.data.actives["move_speed"] or 100
		local tweenTime = dist / math.max(speed, 1)

		root.Anchored = true
		local tw = find.tweenservice:Create(
			root,
			TweenInfo.new(tweenTime, Enum.EasingStyle.Linear),
			{CFrame = CFrame.new(freeHive.pos)}
		)
		tw:Play()
		tw.Completed:Wait()
		task.wait(1.5)

		-- Умная эмуляция E для занятия улья
		local occupied, newHivePos = farming.press_e_until_hive(5)

		if not occupied or not newHivePos then
			warn("[Farm] Не удалось занять улей — стоп автофарм")
			root.Anchored = false
			mod.data.actives["move"] = false
			mod.data.actives["auto_farm"] = false
			resetFarmMovement(false)
			return
		end

		hivePos = newHivePos
		print("[Farm] Улей занят, начинаем фарм")
		root.Anchored = false
		mod.data.actives["move"] = false
		task.wait(0.5)
	end

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
		mod.data.actives["move_speed"],
		selected
	)
	
	mod.data.actives["__last_convert_time"] = tick()

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
		--print(x, z)

		local l = Vector3.new(find.random:NextNumber(ix, ax), a[1].Size.Y / 2 + h, find.random:NextNumber(-z, z))
		--print(l)
		return a[1].CFrame:PointToWorldSpace(l)
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
			--print(a[1],a[2],a[3])

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
				local a = {...}
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

			if typeof(a[1]) == "CFrame" then
				p = a[1].Position
			elseif typeof(a[1]) == "Instance" and a[1]:IsA("BasePart") then
				local lp = a[3].CFrame:PointToObjectSpace(a[1].Position)
				p = a[3].CFrame:PointToWorldSpace(Vector3.new(lp.X, a[3].Size.Y / 2, lp.Z ))
			else
				return
			end

			--print(a[3].Position.Y)
			--print(a[3])

			--find.player.Character:FindFirstChild("HumanoidRootPart").Anchored = true
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

			if atween == tween then
				atween = nil
			end

			if id ~= farmId then
				return
			end
			if mod.data.actives["lines"] == true then
				tween:Play()
				b(true, find.player.Character:FindFirstChild("HumanoidRootPart"), p)
				tween.Completed:Wait()
				b(false, find.player.Character:FindFirstChild("HumanoidRootPart"), p)
				if track and track.IsPlaying then track:Stop(.1) end
				--if track then track:Stop() end
			elseif mod.data.actives["lines"] == false then
				tween:Play()
				tween.Completed:Wait()
				if track and track.IsPlaying then track:Stop(.1) end
				--if track then track:Stop() end
			end
		end

		while id == farmId and mod.data.actives["auto_farm"] == true and #queue["auto_farm"] > 0 do
			local a = table.remove(queue["auto_farm"], 1)
			local c = workspace:FindFirstChild("Collectibles")
			local f = workspace:FindFirstChild("FlowerZones")
			local d = mod.data.actives["selected_field"]
			local field

			if mod.data.actives["selected_field"] == false then field = nil else field = f:FindFirstChild(mod.data.actives["selected_field"]) end

			table.clear(queue["tokens"])

			if c and field then
				local root = find.player.Character
					and find.player.Character:FindFirstChild("HumanoidRootPart")

				if root then
					for _, v in ipairs(c:GetChildren()) do
						if v:IsA("BasePart")
							and i(v, field)
							and (root.Position - v.Position).Magnitude > 4
						then
							table.insert(queue["tokens"], v)
						end
					end
				end
			end

			if #queue["tokens"] > 0 then
				while id == farmId and mod.data.actives["auto_farm"] == true and #queue["tokens"] > 0 do
					table.sort(queue["tokens"], function(a, b)
						return (find.player.Character:FindFirstChild("HumanoidRootPart").Position - a.Position).Magnitude < (find.player.Character:FindFirstChild("HumanoidRootPart").Position - b.Position).Magnitude
					end)

					local v = table.remove(queue["tokens"], 1)
					if v and v.Parent and a.Speed then
						m(v, a.Speed, field)
					end
				end
			else
				--print(1)
				--print(a.TargetCFrame, a.Speed)
				if a.TargetCFrame and a.Speed then
					m(a.TargetCFrame, a.Speed, field)
				end
			end
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

		local function i(token, field)
			local p = field.CFrame:PointToObjectSpace(token.Position)
			local s = field.Size / 2

			return math.abs(p.X) <= s.X and math.abs(p.Z) <= s.Z and p.Y >= -3 and p.Y <= 15
		end

		local function b(...)
			local a = {...}
			--print(a[1],a[2],a[3])

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
				local a = {...}
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

		while id == farmId and mod.data.actives["auto_farm"] == true and #queue["auto_farm"] > 0 do
			local a = table.remove(queue["auto_farm"], 1)
			local c = workspace:FindFirstChild("Collectibles")
			local f = workspace:FindFirstChild("FlowerZones")
			local d = mod.data.actives["selected_field"]
			local field

			if mod.data.actives["selected_field"] == false then field = nil else field = f:FindFirstChild(mod.data.actives["selected_field"]) end

			table.clear(queue["tokens"])

			if c and field then
				local root = find.player.Character
					and find.player.Character:FindFirstChild("HumanoidRootPart")

				if root then
					for _, v in ipairs(c:GetChildren()) do
						if v:IsA("BasePart")
							and i(v, field)
							and (root.Position - v.Position).Magnitude > 4
						then
							table.insert(queue["tokens"], v)
						end
					end
				end
			end

			local function m(...)
				local a = {...}
				if not find.player.Character:FindFirstChildOfClass("Humanoid") or not find.player.Character:FindFirstChild("HumanoidRootPart") or not a[1] or not a[2] then
					return
				end

				if typeof(a[1]) == "Instance" and a[1]:IsA("BasePart") then
					p1 = Vector3.new(a[1].Position.X, find.player.Character:FindFirstChild("HumanoidRootPart").Position.Y, a[1].Position.Z)
				else
					p1 = a[1]
				end

				find.player.Character:FindFirstChild("HumanoidRootPart").Anchored = false
				find.player.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = a[2]
				find.player.Character:FindFirstChildOfClass("Humanoid"):MoveTo(p1)
				b(true, find.player.Character:FindFirstChild("HumanoidRootPart"), p1)
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
				find.player.Character:FindFirstChildOfClass("Humanoid").MoveToFinished:Wait()
				if id ~= farmId then return end
				b(false, find.player.Character:FindFirstChild("HumanoidRootPart"), p1)
			end

			if #queue["tokens"] > 0 then
				while id == farmId and mod.data.actives["auto_farm"] == true and #queue["tokens"] > 0 do
					if not find.player.Character:FindFirstChild("HumanoidRootPart") then
						break
					end

					table.sort(queue["tokens"], function(a, b)
						return (find.player.Character:FindFirstChild("HumanoidRootPart").Position - a.Position).Magnitude < (find.player.Character:FindFirstChild("HumanoidRootPart").Position - b.Position).Magnitude
					end)

					local v = table.remove(queue["tokens"], 1)

					if v and v.Parent and a.Speed then
						m(v, a.Speed)
					end
				end
			else
				if a.TargetPosition and a.Speed then
					m(a.TargetPosition, a.Speed)
				end
			end
		end

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
		--print(a)

		if a == false then b = nil else b = f:FindFirstChild(a) end

		if not a then return end
		if not f then return end
		if afarm then afarm:Disconnect() afarm = nil end

		--print(1)
		--mod.data.actives["move"] = false
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

				-- Пока идёт конвертация — ничего не делаем
				if mod.data.actives["__converting"] then
					return
				end

				-- ===== AUTO CONVERT CHECK =====
				if mod.data.actives["auto_farm"] == true
					and mod.data.actives["move"] == false
				then
					local shouldConvert = false
					local reason = ""

					-- 1) Проверка по проценту рюкзака
					local info = farming.get_pollen_info()
					local threshold = mod.data.actives["backpack"] or 80

					if info and info.percent >= threshold then
						shouldConvert = true
						reason = "backpack " .. math.floor(info.percent) .. "% >= " .. threshold .. "%"
					end

					-- 2) Проверка по таймеру auto_convert (минуты)
					if not shouldConvert then
						local autoMin = mod.data.actives["auto_convert"] or 20
						local lastTime = mod.data.actives["__last_convert_time"] or tick()
						local elapsed = (tick() - lastTime) / 60

						if elapsed >= autoMin then
							shouldConvert = true
							reason = "timer " .. math.floor(elapsed) .. "m >= " .. autoMin .. "m"
						end
					end

					if shouldConvert then
						print("[AutoConvert] Запуск:", reason)
						mod.data.actives["__converting"] = true

						task.spawn(function()
							farming.go_to_hive_and_convert()
							mod.data.actives["__converting"] = false
						end)

						return
					end
				end
				-- =============================

				if mod.data.actives["move"] == false then
					farming.inv(true)

					-- Ставим спринклер, только если его ещё нет и мы реально на поле
					if mod.data.actives["auto_sprinkler"] == true then
						farming.autosprinkler()
					end

					if mod.data.actives["style_auto_farm"] == "Walk" then
						farming.cornl(true)
						m1(b, mod.data.actives["move_speed"])
					elseif mod.data.actives["style_auto_farm"] == "Tween" then
						farming.cornl(true)
						m(b, mod.data.actives["move_speed"])
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

return farming
