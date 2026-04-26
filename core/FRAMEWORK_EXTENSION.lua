-- ============================================================================
-- FRAMEWORK EXTENSION EXAMPLE
-- ============================================================================
-- This file shows how to extend the system for custom frameworks

-- IMPORTANT: Copy this file and modify it for your framework
-- Then include it in fxmanifest.lua

-- Example: Adding support for a custom framework named "MyFramework"

local function GetFramework_MyFramework()
    -- Get your framework object
    -- Example: local MyFW = exports['myframework']:GetObject()
    return exports['myframework']:GetObject()
end

local function GetPlayer_MyFramework(source)
    local MyFW = GetFramework_MyFramework()
    if not MyFW then return nil end
    
    -- Return player object in standard format
    return {
        source = source,
        identifier = MyFW.GetPlayerIdentifier(source),
        money = MyFW.GetPlayerMoney(source),
        bank = MyFW.GetPlayerBank(source),
        getName = function() return MyFW.GetPlayerName(source) end,
        getMoney = function() return MyFW.GetPlayerMoney(source) end,
        getBank = function() return MyFW.GetPlayerBank(source) end,
        addMoney = function(amount) MyFW.AddMoney(source, amount) end,
        removeMoney = function(amount) MyFW.RemoveMoney(source, amount) end
    }
end

local function AddMoney_MyFramework(source, amount, moneyType, reason)
    local MyFW = GetFramework_MyFramework()
    if not MyFW then return false end
    
    if moneyType == 'bank' then
        MyFW.AddBank(source, amount)
    else
        MyFW.AddCash(source, amount)
    end
    return true
end

local function RemoveMoney_MyFramework(source, amount, moneyType, reason)
    local MyFW = GetFramework_MyFramework()
    if not MyFW then return false end
    
    if moneyType == 'bank' then
        MyFW.RemoveBank(source, amount)
    else
        MyFW.RemoveCash(source, amount)
    end
    return true
end

local function GetIdentifier_MyFramework(source)
    local MyFW = GetFramework_MyFramework()
    if not MyFW then return nil end
    
    return MyFW.GetPlayerIdentifier(source)
end

-- ============================================================================
-- INTEGRATION STEPS
-- ============================================================================
--[=[

1. Copy this file to /core/server/framework_custom.lua

2. Modify the function implementations to match your framework:
   - GetFramework_MyFramework()
   - GetPlayer_MyFramework(source)
   - AddMoney_MyFramework()
   - RemoveMoney_MyFramework()
   - GetIdentifier_MyFramework()

3. Edit /core/server/framework.lua and add your framework detection:

   function FrameworkBridge.Initialize()
       if Config.Framework.manual_framework then
           FrameworkBridge.Framework = Config.Framework.manual_framework
       else
           -- Add this check
           if GetResourceState('myframework') == 'started' then
               FrameworkBridge.Framework = 'myframework'
               Utils.DebugLog("Detected My Custom Framework")
               FrameworkBridge.CustomInit = true
           elseif ... (other frameworks)
       end
   end

4. Then add cases for your framework in the bridge functions:

   function FrameworkBridge.GetPlayer(source)
       if FrameworkBridge.Framework == 'myframework' then
           return GetPlayer_MyFramework(source)
       elseif ...
   end

5. Test by starting the resource and checking logs:
   - You should see "Detected My Custom Framework"
   - Jobs should work normally
   - Payments should be processed

]=]

-- ============================================================================
-- EXAMPLE: Adding MySkyrim Framework
-- ============================================================================

-- Hypothetical custom framework implementation:

local function GetFramework_MySkyrim()
    return exports['my-skyrim-framework']:GetObject()
end

local function GetPlayer_MySkyrim(source)
    local MySkyrim = GetFramework_MySkyrim()
    if not MySkyrim then return nil end
    
    local playerData = MySkyrim.GetPlayer(source)
    return {
        source = source,
        identifier = playerData.steam_id,
        money = playerData.gold,
        bank = playerData.bank_gold,
        getName = function() return playerData.first_name .. ' ' .. playerData.last_name end,
        getMoney = function() return playerData.gold end,
        getBank = function() return playerData.bank_gold end,
        addMoney = function(amount) MySkyrim.GiveMoney(source, amount) end,
        removeMoney = function(amount) MySkyrim.TakeMoney(source, amount) end
    }
end

local function AddMoney_MySkyrim(source, amount, moneyType, reason)
    local MySkyrim = GetFramework_MySkyrim()
    if not MySkyrim then return false end
    
    if moneyType == 'bank' then
        MySkyrim.GiveBank(source, amount)
    else
        MySkyrim.GiveMoney(source, amount)
    end
    return true
end

local function RemoveMoney_MySkyrim(source, amount, moneyType, reason)
    local MySkyrim = GetFramework_MySkyrim()
    if not MySkyrim then return false end
    
    if moneyType == 'bank' then
        MySkyrim.TakeBank(source, amount)
    else
        MySkyrim.TakeMoney(source, amount)
    end
    return true
end

local function GetIdentifier_MySkyrim(source)
    local MySkyrim = GetFramework_MySkyrim()
    if not MySkyrim then return nil end
    
    local player = MySkyrim.GetPlayer(source)
    return player.steam_id
end

-- ============================================================================
-- CLIENT SIDE EXTENSION EXAMPLE
-- ============================================================================

-- For client-side, follow similar pattern:

-- local function GetPlayerMoney_MyFramework(moneyType)
--     local MyFW = exports['myframework']:GetObject()
--     if moneyType == 'bank' then
--         return MyFW.GetPlayerBank()
--     else
--         return MyFW.GetPlayerCash()
--     end
-- end

-- local function RequestModel_MyFramework(model)
--     if type(model) == 'string' then
--         model = GetHashKey(model)
--     end
--     
--     RequestModel(model)
--     local timeout = 0
--     while not HasModelLoaded(model) and timeout < 1000 do
--         Wait(10)
--         timeout = timeout + 1
--     end
--     return HasModelLoaded(model)
-- end

-- ============================================================================
-- NOTES FOR CUSTOM FRAMEWORKS
-- ============================================================================
--
-- 1. Key functions that MUST be implemented:
--    - GetPlayer(source) - Returns player data
--    - AddMoney(source, amount, type) - Adds money to player
--    - RemoveMoney(source, amount, type) - Removes money from player
--    - GetIdentifier(source) - Gets unique player identifier
--
-- 2. Money types:
--    - 'cash' - Pocket/portable money
--    - 'bank' - Bank/account money
--
-- 3. Player data must include at minimum:
--    - source: player server ID
--    - identifier: unique player identifier
--    - money/cash: pocket money
--    - bank: bank money
--
-- 4. Use Try-Catch or validation to prevent crashes:
--    if not MyFramework then return nil end
--
-- 5. Test thoroughly:
--    - Job creation
--    - Job completion and payment
--    - Player progression saving
--    - Database entries
--
-- 6. For support, provide:
--    - Framework name and version
--    - Export function names
--    - Example implementation
--    - Error logs if any
--

return {
    MySkyrim = {
        GetFramework = GetFramework_MySkyrim,
        GetPlayer = GetPlayer_MySkyrim,
        AddMoney = AddMoney_MySkyrim,
        RemoveMoney = RemoveMoney_MySkyrim,
        GetIdentifier = GetIdentifier_MySkyrim
    }
}
