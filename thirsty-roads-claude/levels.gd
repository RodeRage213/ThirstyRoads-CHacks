class_name Levels
extends RefCounted

static func get_all_worlds() -> Array:
	return [
		{
			"world_id": 1,
			"world_name": "World 1: Grassland Riverbeds",
			"bg_color": "58c4f5",
			"theme": {
				"ground_fill": Color("e8a87c"),
				"top_grass": Color("4cd964"),
				"mountains": Color("1f4e79")
			},
			"levels": [
				{
					"name": "W1-L1: Smooth Grassland",
					"time_limit": 30.0,
					"cliffs": [PackedVector2Array([
						Vector2(-900, 0), Vector2(300, 0), Vector2(500, -30), Vector2(700, 0),
						Vector2(900, 40), Vector2(1100, 0), Vector2(1450, 0), Vector2(1800, 0), Vector2(2500, 0)])],
					"bridges": [],
					"coins": [Vector2(600, -40), Vector2(1300, -40), Vector2(1755, -40)],
					"finish": Vector2(2200, 0),
					"fact": "More than 2 billion people still lack safely managed drinking water at home.",
				},
				{
					"name": "W1-L2: Gentle Crests",
					"time_limit": 32.0,
					"cliffs": [PackedVector2Array([
						Vector2(-900, 0), Vector2(500, 0), Vector2(900, 40), Vector2(1100, 0),
						Vector2(1450, 0), Vector2(1710, -90), Vector2(1800, -90), Vector2(1920, 0),
						Vector2(2550, 0), Vector2(3100, 0)])],
					"bridges": [],
					"coins": [Vector2(900, -40), Vector2(1755, -120), Vector2(2450, -40)],
					"finish": Vector2(2800, 0),
					"fact": "Contaminated drinking water causes over 485,000 diarrheal deaths each year.",
				},
				{
					"name": "W1-L3: Swaying Bridge",
					"time_limit": 35.0,
					"cliffs": [
						PackedVector2Array([Vector2(-900, 0), Vector2(500, 0)]),
						PackedVector2Array([Vector2(1000, 0), Vector2(1850, -130)]),
						PackedVector2Array([Vector2(2500, -100), Vector2(3300, 0)]),
					],
					"bridges": [{"from": 500.0, "to": 1000.0, "y": 0.0, "flex": 45.0, "planks": 8}],
					"coins": [Vector2(750, -40), Vector2(1850, -160), Vector2(2850, -40)],
					"finish": Vector2(3100, 0),
					"fact": "Unsafe water and poor sanitation spread cholera, dysentery, and polio.",
				},
				{
					"name": "W1-L4: Double Kicker Ramps",
					"time_limit": 38.0,
					"cliffs": [
						PackedVector2Array([Vector2(-900, 0), Vector2(700, 0)]),
						PackedVector2Array([Vector2(1700, 0), Vector2(2560, -150)]),
						PackedVector2Array([Vector2(3300, -110), Vector2(4100, -20)]),
					],
					"bridges": [{"from": 700.0, "to": 1700.0, "y": 0.0, "flex": 60.0, "planks": 16}],
					"coins": [Vector2(1200, -40), Vector2(2560, -180), Vector2(3350, -130)],
					"finish": Vector2(3800, -20),
					"fact": "Women and girls spend an estimated 200 million hours every day collecting water.",
				},
				{
					"name": "W1-L5: Riverbed Grand Leap",
					"time_limit": 42.0,
					"cliffs": [
						PackedVector2Array([Vector2(-900, 0), Vector2(500, 0)]),
						PackedVector2Array([Vector2(1000, 0), Vector2(1550, -130)]),
						PackedVector2Array([Vector2(2150, -80), Vector2(2400, 0)]),
						PackedVector2Array([Vector2(3100, 0), Vector2(4700, 0)]),
					],
					"bridges": [
						{"from": 500.0, "to": 1000.0, "y": 0.0, "flex": 45.0, "planks": 8},
						{"from": 2400.0, "to": 3100.0, "y": 0.0, "flex": 55.0, "planks": 12},
					],
					"coins": [Vector2(750, -40), Vector2(1550, -160), Vector2(2750, -40), Vector2(3980, -120)],
					"finish": Vector2(4450, 0),
					"fact": "Safe water, sanitation and hygiene are a human right under UN SDG 6.",
				},
			]
		},
		{
			"world_id": 2,
			"world_name": "World 2: Sunbaked Desert Canyons",
			"bg_color": "e67e22",
			"theme": {
				"style": "desert",
				"ground_fill": Color("d35400"),
				"top_grass": Color("f39c12"),
				"mountains": Color("ba4a00")
			},
			"levels": [
				{
					"name": "W2-L1: Arid Dunes",
					"time_limit": 30.0,
					"cliffs": [PackedVector2Array([
						Vector2(-900, 0), Vector2(400, 0), Vector2(600, -60), Vector2(800, 0),
						Vector2(1200, -80), Vector2(1400, 0), Vector2(2200, 0)])],
					"bridges": [],
					"coins": [Vector2(600, -80), Vector2(1200, -100)],
					"finish": Vector2(2000, 0),
					"fact": "Over 700 children under five die every day from diseases linked to unsafe water.",
				},
				{
					"name": "W2-L2: Canyon Chasm",
					"time_limit": 32.0,
					"cliffs": [
						PackedVector2Array([Vector2(-900, 0), Vector2(600, 0), Vector2(800, -80)]),
						PackedVector2Array([Vector2(1400, -40), Vector2(2400, 0)])
					],
					"bridges": [],
					"coins": [Vector2(800, -100), Vector2(1100, -120), Vector2(1600, -60)],
					"finish": Vector2(2200, 0),
					"fact": "Droughts worsened by climate change are expanding water scarcity globally.",
				},
				{
					"name": "W2-L3: Red Rock Ridge",
					"time_limit": 35.0,
					"cliffs": [
						PackedVector2Array([Vector2(-900, 0), Vector2(500, 0)]),
						PackedVector2Array([Vector2(1200, 0), Vector2(1800, -100)]),
						PackedVector2Array([Vector2(2500, 0), Vector2(3200, 0)])
					],
					"bridges": [{"from": 500.0, "to": 1200.0, "y": 0.0, "flex": 50.0, "planks": 10}],
					"coins": [Vector2(850, -40), Vector2(1800, -120)],
					"finish": Vector2(3000, 0),
					"fact": "By 2025, half of the world's population will live in water-stressed areas.",
				},
				{
					"name": "W2-L4: Skyward Launch",
					"time_limit": 36.0,
					"cliffs": [
						PackedVector2Array([Vector2(-900, 0), Vector2(600, 0), Vector2(800, -140)]),
						PackedVector2Array([Vector2(1600, -100), Vector2(1800, -40), Vector2(2800, 0)])
					],
					"bridges": [],
					"coins": [Vector2(1100, -180), Vector2(1300, -160)],
					"finish": Vector2(2600, 0),
					"fact": "Agriculture accounts for 70 percent of all global freshwater withdrawals.",
				},
				{
					"name": "W2-L5: Mega Canyon Leap",
					"time_limit": 40.0,
					"cliffs": [
						PackedVector2Array([Vector2(-900, 0), Vector2(500, 0)]),
						PackedVector2Array([Vector2(1400, 0), Vector2(2000, -120)]),
						PackedVector2Array([Vector2(2800, -60), Vector2(3600, 0)])
					],
					"bridges": [{"from": 500.0, "to": 1400.0, "y": 0.0, "flex": 65.0, "planks": 14}],
					"coins": [Vector2(950, -40), Vector2(2400, -150)],
					"finish": Vector2(3400, 0),
					"fact": "80% of wastewater flows back into nature without treatment.",
				},
			]
		},
		{
			"world_id": 3,
			"world_name": "World 3: Urban Slums",
			"bg_color": "c9b8a6",
			"theme": {
				"style": "urban",
				"ground_fill": Color("6e6a66"),
				"top_grass": Color("4a4f55"),
				"mountains": Color("5d6d7e")
			},
			"levels": [
				{
					"name": "W3-L1: Broken Concrete",
					"time_limit": 28.0,
					"cliffs": [PackedVector2Array([
						Vector2(-900, 0), Vector2(400, 0), Vector2(450, -25), Vector2(500, 0),
						Vector2(800, 0), Vector2(850, -30), Vector2(900, 0), Vector2(1800, 0)])],
					"bridges": [],
					"coins": [Vector2(475, -50), Vector2(875, -50)],
					"finish": Vector2(1600, 0),
					"fact": "Rapid urbanization strains city water and sanitation networks.",
				},
				{
					"name": "W3-L2: Debris Drop-Offs",
					"time_limit": 32.0,
					"cliffs": [
						PackedVector2Array([Vector2(-900, 0), Vector2(600, 0)]),
						PackedVector2Array([Vector2(1000, -50), Vector2(1600, -50)]),
						PackedVector2Array([Vector2(2000, 0), Vector2(2800, 0)])
					],
					"bridges": [],
					"coins": [Vector2(800, -60), Vector2(1800, -40)],
					"finish": Vector2(2600, 0),
					"fact": "In urban slums, water can cost up to 10 times more than formal city taps.",
				},
				{
					"name": "W3-L3: Makeshift Scaffold Bridge",
					"time_limit": 35.0,
					"cliffs": [
						PackedVector2Array([Vector2(-900, 0), Vector2(500, 0)]),
						PackedVector2Array([Vector2(1300, 0), Vector2(2200, 0)])
					],
					"bridges": [{"from": 500.0, "to": 1300.0, "y": 0.0, "flex": 55.0, "planks": 12}],
					"coins": [Vector2(900, -40), Vector2(1600, -40)],
					"finish": Vector2(2000, 0),
					"fact": "Up to 50% of treated water in developing cities is lost to leaks.",
				},
				{
					"name": "W3-L4: Alleyway Incline",
					"time_limit": 36.0,
					"cliffs": [
						PackedVector2Array([Vector2(-900, 0), Vector2(600, 0), Vector2(800, -120)]),
						PackedVector2Array([Vector2(1400, -120), Vector2(2400, 0)])
					],
					"bridges": [],
					"coins": [Vector2(1100, -160), Vector2(1800, -40)],
					"finish": Vector2(2200, 0),
					"fact": "Better sanitation cuts health costs and boosts school attendance.",
				},
				{
					"name": "W3-L5: Freeway Bridge Collapse",
					"time_limit": 40.0,
					"cliffs": [
						PackedVector2Array([Vector2(-900, 0), Vector2(500, 0)]),
						PackedVector2Array([Vector2(1400, 0), Vector2(2000, 0)]),
						PackedVector2Array([Vector2(2800, 0), Vector2(3600, 0)])
					],
					"bridges": [
						{"from": 500.0, "to": 1400.0, "y": 0.0, "flex": 50.0, "planks": 12},
						{"from": 2000.0, "to": 2800.0, "y": 0.0, "flex": 60.0, "planks": 12}
					],
					"coins": [Vector2(950, -40), Vector2(2400, -40)],
					"finish": Vector2(3400, 0),
					"fact": "Every $1 invested in water and sanitation yields a return of up to $4.",
				},
			]
		},
		{
			"world_id": 4,
			"world_name": "World 4: Frozen Glaciers & Ice Peaks",
			"bg_color": "1b4f72",
			"theme": {
				"style": "glacier",
				"ground_fill": Color("5dade2"),
				"top_grass": Color("ecf0f1"),
				"mountains": Color("2e86c1")
			},
			"levels": [
				{
					"name": "W4-L1: Ice Runway",
					"time_limit": 30.0,
					"cliffs": [PackedVector2Array([
						Vector2(-900, 0), Vector2(600, 0), Vector2(900, -40), Vector2(1200, 0),
						Vector2(2000, 0)])],
					"bridges": [],
					"coins": [Vector2(900, -60), Vector2(1500, -40)],
					"finish": Vector2(1800, 0),
					"fact": "Glaciers store nearly 69% of global freshwater reserves.",
				},
				{
					"name": "W4-L2: Glacial Crevasse",
					"time_limit": 32.0,
					"cliffs": [
						PackedVector2Array([Vector2(-900, 0), Vector2(600, 0)]),
						PackedVector2Array([Vector2(1300, 0), Vector2(2200, 0)])
					],
					"bridges": [],
					"coins": [Vector2(950, -80), Vector2(1600, -40)],
					"finish": Vector2(2000, 0),
					"fact": "Glacier loss initially causes flooding, then severe long-term water deficits.",
				},
				{
					"name": "W4-L3: Slippery Ravine",
					"time_limit": 35.0,
					"cliffs": [
						PackedVector2Array([Vector2(-900, 0), Vector2(500, 0)]),
						PackedVector2Array([Vector2(1200, 0), Vector2(2000, 0)])
					],
					"bridges": [{"from": 500.0, "to": 1200.0, "y": 0.0, "flex": 40.0, "planks": 10}],
					"coins": [Vector2(850, -40), Vector2(1500, -40)],
					"finish": Vector2(1800, 0),
					"fact": "Mountain ecosystems face frontline impacts from climate-driven water loss.",
				},
				{
					"name": "W4-L4: Frozen Kicker Launch",
					"time_limit": 38.0,
					"cliffs": [
						PackedVector2Array([Vector2(-900, 0), Vector2(700, 0), Vector2(900, -150)]),
						PackedVector2Array([Vector2(1700, -100), Vector2(2600, 0)])
					],
					"bridges": [],
					"coins": [Vector2(1300, -180), Vector2(2000, -40)],
					"finish": Vector2(2400, 0),
					"fact": "Protecting water ecosystems safeguards future freshwater supply.",
				},
				{
					"name": "W4-L5: The Ultimate Glacier Rush",
					"time_limit": 42.0,
					"cliffs": [
						PackedVector2Array([Vector2(-900, 0), Vector2(500, 0)]),
						PackedVector2Array([Vector2(1400, 0), Vector2(2200, -100)]),
						PackedVector2Array([Vector2(3000, 0), Vector2(3800, 0)])
					],
					"bridges": [{"from": 500.0, "to": 1400.0, "y": 0.0, "flex": 65.0, "planks": 14}],
					"coins": [Vector2(950, -40), Vector2(2600, -120)],
					"finish": Vector2(3600, 0),
					"fact": "Achieving SDG 6 requires international cooperation and community action!",
				},
			]
		}
	]
