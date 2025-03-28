-- WoW Essentials Initialization
-- Handles addon loading and module initialization

local WE = WoWEssentials

-- Initialize addon on ADDON_LOADED event
local function OnAddonLoaded(event, addonName)
    if addonName ~= "WoWEssentials" then return end
    
    -- Initialize database
    WE:InitializeDB()
    
    -- Initialize modules
    for name, module in pairs(WE.modules) do
        local success, err = pcall(module.Initialize, module)
        if not success then
            WE:Print("Error initializing " .. name .. " module: " .. err)
        elseif WE:GetConfig("modules." .. name .. ".enabled", module.enabled) then
            module:Enable()
            WE:Debug(name .. " module enabled")
        else
            WE:Debug(name .. " module disabled")
        end
    end
    
    -- Print welcome message
    WE:Print("v" .. WE.version .. " loaded. Type /we for options.")
    
    -- Unregister the load event
    WE.frame:UnregisterEvent("ADDON_LOADED")
end

-- Register for ADDON_LOADED event
WE:RegisterEvent("ADDON_LOADED", OnAddonLoaded)

-- Handle PLAYER_ENTERING_WORLD to ensure everything is initialized
WE:RegisterEvent("PLAYER_ENTERING_WORLD", function(isInitialLogin, isReloadingUi)
    if isInitialLogin or isReloadingUi then
        -- This is called when player first logs in or UI is reloaded
        WE:Debug("Player entered world, finalizing initialization")
        
        -- Call OnWorldEnter for each enabled module
        for name, module in pairs(WE.modules) do
            if module.enabled and module.OnWorldEnter then
                local success, err = pcall(module.OnWorldEnter, module, isInitialLogin, isReloadingUi)
                if not success then
                    WE:Print("Error in " .. name .. " OnWorldEnter: " .. err)
                end
            end
        end
    end
end)

-- Function to be called during logout/reload to save data
local function OnPlayerLogout()
    for name, module in pairs(WE.modules) do
        if module.enabled and module.OnLogout then
            local success, err = pcall(module.OnLogout, module)
            if not success then
                WE:Print("Error in " .. name .. " OnLogout: " .. err)
            end
        end
    end
end

-- Register for PLAYER_LOGOUT event
WE:RegisterEvent("PLAYER_LOGOUT", OnPlayerLogout) 