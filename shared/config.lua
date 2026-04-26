Config = {}

Config.Framework = {
    auto_detect = true, -- Automatically detect framework or set manually
    manual_framework = nil, -- Options: 'qbcore', 'qbx', 'esx', 'standalone'
    debug = false
}

Config.JobLocations = {
    depot = {
        name = 'Trucking Depot',
        coords = vector3(1208.83, -3114.97, 4.54),
        heading = 0.0,
        interaction_distance = 2.0,
        blip = {
            sprite = 477,
            display = 4,
            scale = 0.7,
            color = 0,
            label = 'Trucking Depot'
        },
        ped = {
            model = 's_m_m_dockwork_01',
            scenario = 'WORLD_HUMAN_CLIPBOARD',
            enabled = true
        }
    }
}

Config.Jobs = {
    local_delivery = {
        id = 'local_delivery',
        name = 'Local Delivery',
        description = 'Short distance deliveries in the city',
        distance_range = { min = 1000, max = 5000 },
        base_pay = 500,
        multiplier = 0.08, -- per meter
        xp_reward = 2000,
        can_damage = true,
        allow_company_truck = true,
        trailer_required = true,
        time_bonus = 1.25
    },
    long_haul = {
        id = 'long_haul',
        name = 'Long Haul',
        description = 'Cross-state deliveries',
        distance_range = { min = 20000, max = 50000 },
        base_pay = 2000,
        multiplier = 0.15,
        xp_reward = 200,
        can_damage = true,
        allow_company_truck = true,
        trailer_required = true,
        time_bonus = 1.5
    },
    fragile_cargo = {
        id = 'fragile_cargo',
        name = 'Fragile Cargo',
        description = 'Delicate items - minimal damage allowed',
        distance_range = { min = 2000, max = 10000 },
        base_pay = 1500,
        multiplier = 0.12,
        xp_reward = 150,
        can_damage = false,
        allow_company_truck = true,
        trailer_required = true,
        time_bonus = 1.75,
        damage_threshold = 0.15
    },
    timed_delivery = {
        id = 'timed_delivery',
        name = 'Timed Delivery',
        description = 'Rush delivery with time limit',
        distance_range = { min = 3000, max = 8000 },
        base_pay = 1200,
        multiplier = 0.2,
        xp_reward = 175,
        can_damage = true,
        allow_company_truck = true,
        trailer_required = true,
        time_bonus = 2.0,
        time_limit = 600
    },
    construction_haul = {
        id = 'construction_haul',
        name = 'Construction Haul',
        description = 'Deliver building materials to construction sites',
        distance_range = { min = 4000, max = 12000 },
        base_pay = 1800,
        multiplier = 0.14,
        xp_reward = 220,
        can_damage = true,
        allow_company_truck = true,
        trailer_required = true,
        time_bonus = 1.4
    },
    fuel_delivery = {
        id = 'fuel_delivery',
        name = 'Fuel Tanker Delivery',
        description = 'Transport flammable fuel - drive carefully!',
        distance_range = { min = 5000, max = 15000 },
        base_pay = 2500,
        multiplier = 0.18,
        xp_reward = 300,
        can_damage = false,
        allow_company_truck = true,
        trailer_required = true,
        time_bonus = 1.6,
        damage_threshold = 0.10
    },
    refrigerated = {
        id = 'refrigerated',
        name = 'Refrigerated Cargo',
        description = 'Temperature-sensitive goods, maintain steady speed',
        distance_range = { min = 6000, max = 18000 },
        base_pay = 2200,
        multiplier = 0.16,
        xp_reward = 260,
        can_damage = true,
        allow_company_truck = true,
        trailer_required = true,
        time_bonus = 1.5
    },
    livestock = {
        id = 'livestock',
        name = 'Livestock Transport',
        description = 'Transport animals to farms and markets',
        distance_range = { min = 8000, max = 20000 },
        base_pay = 2800,
        multiplier = 0.17,
        xp_reward = 320,
        can_damage = false,
        allow_company_truck = true,
        trailer_required = true,
        time_bonus = 1.55,
        damage_threshold = 0.20
    },
    hazardous = {
        id = 'hazardous',
        name = 'Hazardous Materials',
        description = 'Dangerous goods - extreme caution required',
        distance_range = { min = 10000, max = 25000 },
        base_pay = 4000,
        multiplier = 0.22,
        xp_reward = 450,
        can_damage = false,
        allow_company_truck = true,
        trailer_required = true,
        time_bonus = 1.8,
        damage_threshold = 0.05
    },
    overnight_express = {
        id = 'overnight_express',
        name = 'Overnight Express',
        description = 'Premium high-pay, time-critical delivery',
        distance_range = { min = 15000, max = 35000 },
        base_pay = 3500,
        multiplier = 0.25,
        xp_reward = 400,
        can_damage = true,
        allow_company_truck = true,
        trailer_required = true,
        time_bonus = 2.5,
        time_limit = 900
    },
    grocery_run = {
        id = 'grocery_run',
        name = 'Grocery Run',
        description = 'Stock supermarkets with fresh goods',
        distance_range = { min = 1500, max = 4000 },
        base_pay = 700,
        multiplier = 0.10,
        xp_reward = 90,
        can_damage = true,
        allow_company_truck = true,
        trailer_required = true,
        time_bonus = 1.3
    },
    furniture_delivery = {
        id = 'furniture_delivery',
        name = 'Furniture Delivery',
        description = 'Bulky furniture - fragile assembly required',
        distance_range = { min = 3000, max = 8000 },
        base_pay = 1100,
        multiplier = 0.13,
        xp_reward = 130,
        can_damage = false,
        allow_company_truck = true,
        trailer_required = true,
        time_bonus = 1.4,
        damage_threshold = 0.20
    },
    auto_parts = {
        id = 'auto_parts',
        name = 'Auto Parts Run',
        description = 'Deliver parts to mechanics and dealerships',
        distance_range = { min = 2500, max = 6000 },
        base_pay = 950,
        multiplier = 0.11,
        xp_reward = 110,
        can_damage = true,
        allow_company_truck = true,
        trailer_required = true,
        time_bonus = 1.35
    },
    medical_supplies = {
        id = 'medical_supplies',
        name = 'Medical Supplies',
        description = 'Critical medical equipment to hospitals',
        distance_range = { min = 4000, max = 10000 },
        base_pay = 2000,
        multiplier = 0.16,
        xp_reward = 240,
        can_damage = false,
        allow_company_truck = true,
        trailer_required = true,
        time_bonus = 2.0,
        time_limit = 720,
        damage_threshold = 0.10
    },
    mail_route = {
        id = 'mail_route',
        name = 'Postal Mail Route',
        description = 'Multi-stop postal delivery route',
        distance_range = { min = 2000, max = 6000 },
        base_pay = 800,
        multiplier = 0.12,
        xp_reward = 120,
        can_damage = true,
        allow_company_truck = true,
        trailer_required = true,
        time_bonus = 1.5
    },
    farm_equipment = {
        id = 'farm_equipment',
        name = 'Farm Equipment',
        description = 'Heavy agricultural machinery transport',
        distance_range = { min = 7000, max = 18000 },
        base_pay = 2400,
        multiplier = 0.17,
        xp_reward = 280,
        can_damage = true,
        allow_company_truck = true,
        trailer_required = true,
        time_bonus = 1.45
    },
    luxury_cars = {
        id = 'luxury_cars',
        name = 'Luxury Car Transport',
        description = 'High-value vehicles - zero scratches allowed',
        distance_range = { min = 10000, max = 22000 },
        base_pay = 3200,
        multiplier = 0.20,
        xp_reward = 380,
        can_damage = false,
        allow_company_truck = true,
        trailer_required = true,
        time_bonus = 1.7,
        damage_threshold = 0.05
    },
    electronics = {
        id = 'electronics',
        name = 'Electronics Shipment',
        description = 'High-tech electronics - drive smoothly',
        distance_range = { min = 5000, max = 13000 },
        base_pay = 1800,
        multiplier = 0.15,
        xp_reward = 210,
        can_damage = false,
        allow_company_truck = true,
        trailer_required = true,
        time_bonus = 1.55,
        damage_threshold = 0.12
    },
    military_supplies = {
        id = 'military_supplies',
        name = 'Military Supplies',
        description = 'Classified defense logistics - maximum security',
        distance_range = { min = 12000, max = 28000 },
        base_pay = 4500,
        multiplier = 0.24,
        xp_reward = 500,
        can_damage = false,
        allow_company_truck = true,
        trailer_required = true,
        time_bonus = 1.9,
        damage_threshold = 0.08
    },
    quarry_haul = {
        id = 'quarry_haul',
        name = 'Quarry Haul',
        description = 'Heavy loads of stone and gravel',
        distance_range = { min = 6000, max = 15000 },
        base_pay = 1700,
        multiplier = 0.13,
        xp_reward = 200,
        can_damage = true,
        allow_company_truck = true,
        trailer_required = true,
        time_bonus = 1.3
    },
    cross_border = {
        id = 'cross_border',
        name = 'Cross-Border Run',
        description = 'Long-distance interstate transport',
        distance_range = { min = 25000, max = 60000 },
        base_pay = 5000,
        multiplier = 0.28,
        xp_reward = 600,
        can_damage = true,
        allow_company_truck = true,
        trailer_required = true,
        time_bonus = 2.2
    },
    contraband = {
        id = 'contraband',
        name = 'Contraband Run',
        description = 'High-risk illegal cargo - avoid police!',
        distance_range = { min = 18000, max = 40000 },
        base_pay = 6500,
        multiplier = 0.30,
        xp_reward = 750,
        can_damage = true,
        allow_company_truck = true,
        trailer_required = true,
        time_bonus = 2.8,
        time_limit = 1200
    }
}

Config.Vehicles = {
    company_trucks = {
        {
            model = 'phantom',
            name = 'Job Phantom',
            trailer = 'trailers',
            spawn_loc = vector3(1245.35, -3135.37, 4.57),
            heading = 0.0,
            fuel = 100,
            condition = 100
        },
        {
            model = 'hauler',
            name = 'Job Hauler',
            trailer = 'trailers2',
            spawn_loc = vector3(1245.57, -3142.64, 4.59),
            heading = 0.0,
            fuel = 100,
            condition = 100
        },
        {
            model = 'packer',
            name = 'Job Packer',
            trailer = 'trailers4',
            spawn_loc = vector3(1245.59, -3148.3, 4.59),
            heading = 0.0,
            fuel = 100,
            condition = 100
        }
    },
    trailers = {
        trailers = {
            name = 'Standard Trailer',
            capacity = 5000,
            damage_multiplier = 1.0
        },
        trailers2 = {
            name = 'Box Trailer',
            capacity = 3000,
            damage_multiplier = 1.5
        },
        trailers4 = {
            name = 'Heavy Trailer',
            capacity = 6500,
            damage_multiplier = 1.25
        }
    },
    purchasable = {
        {
            id = 'phantom_custom',
            model = 'phantom',
            name = 'Phantom',
            price = 45000,
            fuel_capacity = 100,
            fuel_consumption = 0.5
        },
        {
            id = 'hauler_custom',
            model = 'hauler',
            name = 'Hauler',
            price = 55000,
            fuel_capacity = 120,
            fuel_consumption = 0.6
        },
        {
            id = 'packer_custom',
            model = 'packer',
            name = 'Packer',
            price = 40000,
            fuel_capacity = 95,
            fuel_consumption = 0.55
        }
    }
}

Config.Progression = {
    xp_per_level = 1000,
    max_level = 50,
    skill_categories = {
        'distance_driving',
        'fragile_handling',
        'speed_efficiency'
    },
    unlocks = {
        [2] = 'grocery_run',
        [3] = 'mail_route',
        [4] = 'auto_parts',
        [5] = 'construction_haul',
        [6] = 'furniture_delivery',
        [7] = 'long_haul',
        [8] = 'quarry_haul',
        [9] = 'refrigerated',
        [10] = 'fragile_cargo',
        [12] = 'electronics',
        [13] = 'medical_supplies',
        [15] = 'livestock',
        [16] = 'farm_equipment',
        [18] = 'timed_delivery',
        [20] = 'luxury_cars',
        [22] = 'fuel_delivery',
        [25] = 'overnight_express',
        [28] = 'cross_border',
        [32] = 'hazardous',
        [38] = 'military_supplies',
        [45] = 'contraband'
    }
}

Config.Payment = {
    damage_reduction = 0.1,
    late_delivery_penalty = 0.15,
    cash_payment = true,
    bank_payment = true,
    min_payment = 100,
    max_payment = 10000
}

Config.UI = {
    theme = 'dark',
    language = 'en',
    animations = true,
    show_radar = true,
    interaction = {
        enable_command = false,
        command_name = 'trucking',
        keybind_enabled = false,
        keybind = 'T',
        prompt = 'Press ~INPUT_CONTEXT~ to open Trucking Depot'
    }
}


Config.Inventory = {
    use_ox_inventory = true,
    cargo_item = 'cargo_package'
}

Config.Logging = {
    enabled = true,
    webhook_url = 'https://discord.com/api/webhooks/YOUR_WEBHOOK_URL_HERE',
    log_job_completion = true,
    log_payments = true,
    log_exploits = true,
    embed_color = 0x00FF00 
}

Config.Fuel = {
    enabled = true,
    fuel_loss_per_meter = 0.0002,
    engine_damage_per_meter = 0.0001,
    damage_threshold = 100 
}

Config.GPS = {
    enabled = true,
    show_waypoint = true,
    distance_check = 50 
}

Config.DeliveryZones = {
    { id = 1,  name = 'LSIA Cargo Terminal',     coords = vector3(1537.35, -2155.01, 76.6), radius = 100 },
    { id = 2,  name = 'Port of Los Santos',      coords = vector3(1719.54, -1657.6, 111.51),    radius = 100 },
    { id = 3,  name = 'Cypress Flats Warehouse', coords = vector3(1366.16, -580.59, 73.38),     radius = 100 },
    { id = 4,  name = 'La Mesa Industrial',      coords = vector3(379.9, 293.17, 102.18),   radius = 100 },
    { id = 5,  name = 'El Burro Heights Depot',  coords = vector3(-1417.38, -282.61, 45.24),     radius = 100 },
    { id = 6,  name = 'Murrieta Heights Yard',   coords = vector3(-1178.11, -1482.03, 3.38),  radius = 100 },
    { id = 7,  name = 'Rancho Industrial',       coords = vector3(-3034.33, 126.81, 10.61),    radius = 100 },
    { id = 8,  name = 'Davis Construction Site', coords = vector3(-2538.54, 2327.18, 32.06),     radius = 100 },
    { id = 9,  name = 'Strawberry Logistics',    coords = vector3(-802.35, 5409.23, 32.86),  radius = 100 },
    { id = 10, name = 'Vespucci Beach Storage',  coords = vector3(-749.95, 5544.45, 32.49),  radius = 100 },
    { id = 11, name = 'Banham Canyon Garage',    coords = vector3(-731.22, 5809.36, 16.46),  radius = 100 },
    { id = 12, name = 'Great Ocean Highway',     coords = vector3(1537.35, -2155.01, 76.6), radius = 100 },
    { id = 13, name = 'Paleto Bay Docks',        coords = vector3(-447.97, 6348.79, 11.61),   radius = 100 },
    { id = 14, name = 'Mount Chiliad Outpost',   coords = vector3(-140.77, 6494.06, 28.71),   radius = 100 },
    { id = 15, name = 'Grapeseed Farm',          coords = vector3(-76.96, 6491.69, 30.49),   radius = 100 },
    { id = 16, name = 'Sandy Shores Truck Stop', coords = vector3(145.39, 6625.48, 30.72),   radius = 100 },
    { id = 17, name = 'Harmony Repair Shop',     coords = vector3(145.39, 6625.48, 30.72),    radius = 100 },
    { id = 18, name = 'Ron Alternates Wind Farm',coords = vector3(-2538.54, 2327.18, 32.06),   radius = 100 },
    { id = 19, name = 'McKenzie Airfield',       coords = vector3(1537.35, -2155.01, 76.6),   radius = 100 },
    { id = 20, name = 'Davis Quartz Quarry',     coords = vector3(-2538.54, 2327.18, 32.06),   radius = 100 },
    { id = 21, name = 'Humane Labs Loading',     coords = vector3(1537.35, -2155.01, 76.6),   radius = 100 },
    { id = 22, name = 'Cape Catfish Pier',       coords = vector3(1366.16, -580.59, 73.38),    radius = 100 },
    { id = 23, name = 'Land Act Reservoir',      coords = vector3(145.39, 6625.48, 30.72),  radius = 100 },
    { id = 24, name = 'Galileo Observatory',     coords = vector3(1366.16, -580.59, 73.38),   radius = 100 },
    { id = 25, name = 'Lago Zancudo Border',     coords = vector3(1366.16, -580.59, 73.38),   radius = 100 },
    { id = 26, name = 'Fort Zancudo Gate',       coords = vector3(1537.35, -2155.01, 76.6),   radius = 100 },
    { id = 27, name = 'Paleto Forest Sawmill',   coords = vector3(2538.54, 2327.18, 32.06),   radius = 100 },
    { id = 28, name = 'Procopio Beach Storage',  coords = vector3(1537.35, -2155.01, 76.6),   radius = 100 },
    { id = 29, name = 'Senora Desert Gas Stop',  coords = vector3(145.39, 6625.48, 30.72),   radius = 100 },
    { id = 30, name = 'Tataviam Mountains Site', coords = vector3(1537.35, -2155.01, 76.6),   radius = 100 }
}

Config.DirtyMoneyType = 'black_money'

Config.DirtyMoneyItem = 'black_money'

Config.DirtyDepot = {
    name = 'Underground Depot',
    coords = vector3(708.21, -966.07, 30.41),
    heading = 90.0,
    interaction_distance = 2.0,
    blip = {
        sprite = 51,
        display = 4,
        scale = 0.7,
        color = 1,
        label = 'Underground Depot'
    },
    ped = {
        model = 'g_m_y_lost_01',
        scenario = 'WORLD_HUMAN_SMOKING',
        enabled = true
    }
}

Config.DirtyJobs = {
    drug_transport = {
        id = 'drug_transport',
        name = 'Narcotics Transport',
        description = 'Move product across the city - avoid cops!',
        distance_range = { min = 3000, max = 8000 },
        base_pay = 1500,
        multiplier = 0.18,
        xp_reward = 180,
        can_damage = true,
        is_dirty = true,
        cop_threshold = 0,
        time_bonus = 1.4
    },
    stolen_goods = {
        id = 'stolen_goods',
        name = 'Stolen Goods Run',
        description = 'Hot merchandise - keep moving',
        distance_range = { min = 2000, max = 6000 },
        base_pay = 1200,
        multiplier = 0.15,
        xp_reward = 140,
        can_damage = true,
        is_dirty = true,
        time_bonus = 1.35
    },
    illegal_weapons = {
        id = 'illegal_weapons',
        name = 'Weapons Trafficking',
        description = 'Black market firearms - high risk, high reward',
        distance_range = { min = 5000, max = 12000 },
        base_pay = 2800,
        multiplier = 0.22,
        xp_reward = 320,
        can_damage = false,
        is_dirty = true,
        time_bonus = 1.6,
        damage_threshold = 0.10
    },
    counterfeit_money = {
        id = 'counterfeit_money',
        name = 'Counterfeit Cash Drop',
        description = 'Distribute forged bills - drive normal',
        distance_range = { min = 4000, max = 10000 },
        base_pay = 2200,
        multiplier = 0.20,
        xp_reward = 250,
        can_damage = true,
        is_dirty = true,
        time_bonus = 1.5
    },
    bootleg_alcohol = {
        id = 'bootleg_alcohol',
        name = 'Bootleg Alcohol',
        description = 'Untaxed liquor delivery to speakeasies',
        distance_range = { min = 2500, max = 7000 },
        base_pay = 1100,
        multiplier = 0.13,
        xp_reward = 130,
        can_damage = false,
        is_dirty = true,
        time_bonus = 1.3,
        damage_threshold = 0.15
    },
    chop_shop_parts = {
        id = 'chop_shop_parts',
        name = 'Chop Shop Parts',
        description = 'VIN-removed vehicle parts to chop shops',
        distance_range = { min = 3000, max = 8000 },
        base_pay = 1600,
        multiplier = 0.16,
        xp_reward = 190,
        can_damage = true,
        is_dirty = true,
        time_bonus = 1.4
    },
    blood_money = {
        id = 'blood_money',
        name = 'Blood Money Pickup',
        description = 'Collect cash from gang affiliates',
        distance_range = { min = 6000, max = 14000 },
        base_pay = 3200,
        multiplier = 0.25,
        xp_reward = 380,
        can_damage = true,
        is_dirty = true,
        time_bonus = 1.7
    },
    smuggled_electronics = {
        id = 'smuggled_electronics',
        name = 'Smuggled Tech',
        description = 'Stolen high-end electronics',
        distance_range = { min = 4000, max = 11000 },
        base_pay = 2000,
        multiplier = 0.18,
        xp_reward = 230,
        can_damage = false,
        is_dirty = true,
        time_bonus = 1.5,
        damage_threshold = 0.12
    },
    organ_transport = {
        id = 'organ_transport',
        name = 'Organ Transport',
        description = 'Black market medical cargo - drive smooth',
        distance_range = { min = 8000, max = 18000 },
        base_pay = 4500,
        multiplier = 0.28,
        xp_reward = 480,
        can_damage = false,
        is_dirty = true,
        time_bonus = 1.9,
        damage_threshold = 0.05
    },
    cartel_supply = {
        id = 'cartel_supply',
        name = 'Cartel Supply Run',
        description = 'Cross-border cartel logistics - extreme danger',
        distance_range = { min = 15000, max = 35000 },
        base_pay = 7500,
        multiplier = 0.35,
        xp_reward = 800,
        can_damage = true,
        is_dirty = true,
        time_bonus = 2.5,
        time_limit = 1500
    }
}

Config.DirtyDeliveryZones = {
    { id = 1,  name = 'Abandoned Warehouse',     coords = vector3(410.92, 6472.08, 27.81),   radius = 100 },
    { id = 2,  name = 'Strawberry Back Alley',   coords = vector3(1492.85, 6416.27, 21.25),    radius = 100 },
    { id = 3,  name = 'Vespucci Canals',         coords = vector3(2842.97, 4447.93, 47.58),   radius = 100 },
    { id = 4,  name = 'Cypress Industrial',      coords = vector3(410.92, 6472.08, 27.81),    radius = 100 },
    { id = 5,  name = 'Davis Drug Den',          coords = vector3(1688.51, 6423.05, 31.5),     radius = 100 },
    { id = 6,  name = 'Sandy Shores Trailer',    coords = vector3(1492.85, 6416.27, 21.25),   radius = 100 },
    { id = 7,  name = 'Grapeseed Meth Lab',      coords = vector3(2842.97, 4447.93, 47.58),   radius = 100 },
    { id = 8,  name = 'Paleto Smuggler Cove',    coords = vector3(410.92, 6472.08, 27.81),   radius = 100 },
    { id = 9,  name = 'Chumash Boat Ramp',       coords = vector3(1688.51, 6423.05, 31.5),    radius = 100 },
    { id = 10, name = 'Cassidy Creek Hideout',   coords = vector3(2842.97, 4447.93, 47.58),   radius = 100 },
    { id = 11, name = 'Stab City',               coords = vector3(1492.85, 6416.27, 21.25),    radius = 100 },
    { id = 12, name = 'Mount Josiah Cabin',      coords = vector3(410.92, 6472.08, 27.81),  radius = 100 },
    { id = 13, name = 'El Burro Industrial',     coords = vector3(1688.51, 6423.05, 31.5),   radius = 100 },
    { id = 14, name = 'Pacific Bluffs Drop',     coords = vector3(1492.85, 6416.27, 21.25),     radius = 100 },
    { id = 15, name = 'Cluckin Bell Slaughter',  coords = vector3(410.92, 6472.08, 27.81),     radius = 100 }
}

Config.DirtySpawn = {
    coords = vector3(728.19, -983.52, 23.18),
    heading = 90.0
}

Config.Achievements = {
    {
        id = 'first_job', name = 'Rookie Trucker', icon = '🚚',
        description = 'Complete your first delivery.',
        reward = { xp = 100, cash = 500 },
        check = function(s) return (s.jobs_completed or 0) >= 1 end
    },
    {
        id = 'jobs_50', name = 'Veteran Driver', icon = '🛣️',
        description = 'Complete 50 deliveries.',
        reward = { xp = 750, cash = 3000 },
        check = function(s) return (s.jobs_completed or 0) >= 50 end
    },
    {
        id = 'jobs_250', name = 'Road Warrior', icon = '🏆',
        description = 'Complete 250 deliveries.',
        reward = { xp = 3000, cash = 15000 },
        check = function(s) return (s.jobs_completed or 0) >= 250 end
    },
    {
        id = 'jobs_1000', name = 'Living Legend', icon = '👑',
        description = 'Complete 1000 deliveries.',
        reward = { xp = 15000, cash = 75000 },
        check = function(s) return (s.jobs_completed or 0) >= 1000 end
    },
    {
        id = 'distance_100km', name = 'Long Hauler', icon = '🛻',
        description = 'Drive a total of 100 km on the job.',
        reward = { xp = 500, cash = 2500 },
        check = function(s) return (s.distance_traveled or 0) >= 100000 end
    },
    {
        id = 'distance_1000km', name = 'Cross-Country Trucker', icon = '🌎',
        description = 'Drive a total of 1000 km on the job.',
        reward = { xp = 5000, cash = 25000 },
        check = function(s) return (s.distance_traveled or 0) >= 1000000 end
    },
    {
        id = 'earn_100k', name = 'Six Figures', icon = '💵',
        description = 'Earn $100,000 in total from legit jobs.',
        reward = { xp = 1000, cash = 5000 },
        check = function(s) return (s.money_earned or 0) >= 100000 end
    },
    {
        id = 'first_dirty', name = 'Going Underground', icon = '💀',
        description = 'Complete your first dirty job.',
        reward = { xp = 0, cash = 0 },
        check = function(s) return (s.dirty_jobs_completed or 0) >= 1 end
    },
    {
        id = 'dirty_50', name = 'Career Criminal', icon = '🕶️',
        description = 'Complete 50 dirty jobs.',
        reward = { xp = 0, cash = 0 },
        check = function(s) return (s.dirty_jobs_completed or 0) >= 50 end
    },
    {
        id = 'dirty_money_500k', name = 'Off the Books', icon = '💰',
        description = 'Earn $500,000 in dirty money.',
        reward = { xp = 0, cash = 0 },
        check = function(s) return (s.dirty_money_earned or 0) >= 500000 end
    },
    {
        id = 'level_25', name = 'Master Trucker', icon = '⭐',
        description = 'Reach level 25.',
        reward = { xp = 0, cash = 10000 },
        check = function(s) return (s.level or 1) >= 25 end
    },
    {
        id = 'criminal_15', name = 'Underboss', icon = '🎩',
        description = 'Reach criminal level 15.',
        reward = { xp = 0, cash = 0 },
        check = function(s) return (s.criminal_level or 1) >= 15 end
    }
}

Config.PerkSettings = {
    points_per_level = 1,
    points_per_criminal_level = 1,
    cost_per_rank = 1
}

Config.Perks = {
    { id = 'better_negotiator', icon = '💼', name = 'Better Negotiator',
      desc = 'Increases legit job pay.',
      max_rank = 5, effect = { type = 'pay_bonus', value = 0.03 } },
    { id = 'fast_learner',      icon = '📚', name = 'Fast Learner',
      desc = 'Earn more XP per delivery.',
      max_rank = 5, effect = { type = 'xp_bonus', value = 0.04 } },
    { id = 'eco_driver',        icon = '⛽', name = 'Eco Driver',
      desc = 'Trucks consume less fuel.',
      max_rank = 3, effect = { type = 'fuel_efficiency', value = 0.05 } },
    { id = 'connected',         icon = '🤝', name = 'Connected',
      desc = 'Increases dirty job pay.',
      max_rank = 5, effect = { type = 'dirty_pay_bonus', value = 0.04 } },
    { id = 'shadow_runner',     icon = '🌑', name = 'Shadow Runner',
      desc = 'Earn more criminal rep per dirty job.',
      max_rank = 5, effect = { type = 'rep_bonus', value = 0.05 } },
    { id = 'iron_grip',         icon = '🛡️', name = 'Iron Grip',
      desc = 'Reduce damage taken to your truck (placeholder).',
      max_rank = 3, effect = { type = 'damage_resist', value = 0.10 } }
}

Config.CriminalProgression = {
    rep_per_level = 750,
    max_level = 30,
    rep_multiplier = 1.0,
    pay_per_level = 0.04,
    heat_chance_base = 0.10,
    heat_chance_per_level = 0.01,
    rank_titles = {
        [1]  = 'Street Runner',
        [3]  = 'Mule',
        [6]  = 'Hustler',
        [10] = 'Lieutenant',
        [15] = 'Underboss',
        [20] = 'Capo',
        [25] = 'Made Man',
        [30] = 'Kingpin'
    }
}

Config.DirtyUnlocks = {
    [1]  = 'bootleg_alcohol',
    [2]  = 'stolen_goods',
    [4]  = 'drug_transport',
    [6]  = 'chop_shop_parts',
    [8]  = 'counterfeit_money',
    [12] = 'smuggled_electronics',
    [16] = 'illegal_weapons',
    [22] = 'blood_money',
    [30] = 'organ_transport',
    [40] = 'cartel_supply'
}

Config.AntiExploit = {
    check_server_distance = true,
    max_speed = 150,
    prevent_job_spam = true,
    job_cooldown = 2000
}

Config.Notifications = {
    position = 'top-center',
    duration = 5000,
    animations = true
}

Config.Database = {
    connection_type = 'auto',
    debug = false
}

return Config
