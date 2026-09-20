local data = {}

data.zones = {
	{name = "Ant Field", image = "rbxassetid://15617807338"},
	{name = "Bamboo Field", image = "rbxassetid://15617807109"},
	{name = "Blue Flower Field", image = "rbxassetid://15617806925"},
	{name = "Cactus Field", image = "rbxassetid://15617806727"},
	{name = "Clover Field", image = "rbxassetid://15617806641"},
	{name = "Coconut Field", image = "rbxassetid://15617838168"},
	{name = "Dandelion Field", image = "rbxassetid://15617826387"},
	{name = "Mountain Top Field", image = "rbxassetid://15617806273"},
	{name = "Mushroom Field", image = "rbxassetid://15617806189"},
	{name = "Pepper Patch", image = "rbxassetid://15617806096"},
	{name = "Pine Tree Forest", image = "rbxassetid://15617805993"},
	{name = "Pineapple Patch", image = "rbxassetid://15617805930"},
	{name = "Pumpkin Patch", image = "rbxassetid://15617805864"},
	{name = "Rose Field", image = "rbxassetid://15617805712"},
	{name = "Spider Field", image = "rbxassetid://15617806534"},
	{name = "Strawberry Field", image = "rbxassetid://15617805499"},
	{name = "Stump Field", image = "rbxassetid://15617805381"},
	{name = "Sunflower Field", image = "rbxassetid://15617805255"},
}

data.other = {
	{name = "Walk", image = "rbxassetid://5704054370"},
	{name = "Tween", image = "rbxassetid://121610549642254"},
}

data.mask = {
	{name = "Diamond Mask", image = "rbxassetid://2557828875"},
	{name = "Demon Mask", image = "rbxassetid://2557829605"},
	{name = "Gummy Mask", image = "rbxassetid://2557830185"},
	{name = "Bubble Mask", image = "rbxassetid://2558166299"},
	{name = "Fire Mask", image = "rbxassetid://2558167630"},
	{name = "Honey Mask", image = "rbxassetid://2558166990"},
	{name = "None", image = "rbxassetid://1554410815"},
}

data.actives = {
	--auto_farm
	auto_farm = false, -- test
	auto_sprinkler = false,
	auto_dig = false,
	point = false,
	lines = true,
	auto_farm_speed = 80,
	style_auto_farm = "Walk",
	position_field = "center",
	selected_field = "Blue Flower Field",
	
	--convert
	balloon = false,
	honey_mask = false,
	backpack = 80,
	auto_convert = 20,
	mask = "None",
	__converting = false,
	__last_convert_time = 0,
	
	--farm settings
	collect_bubbles = false,
	wealth_clock = false,

	--options
	hide_decorations = false,
	hide_field_decorations = true,

	--move_to
	move = false,
	move_speed = 100,

	--other
	script_name = "Nectar 0.0.1",
	position_script = UDim2.new(0.22, 0, 0.5, 0),
	walkspeed = 40,
}

return data
