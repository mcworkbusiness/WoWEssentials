-- WoW Essentials Core
-- Main addon framework and initialization

-- Create addon global table and namespace
WoWEssentials = {}
local WE = WoWEssentials
local _G = _G

-- Version info
WE.version = GetAddOnMetadata("WoWEssentials", "Version")
WE.name = "WoW Essentials"

-- Module system
WE.modules = {}

function WE:NewModule(name, enabledByDefault)
    local module = {}
    module.name = name
    module.enabled = enabledByDefault
    
    -- Default methods
    module.Initialize = function() end
    module.Enable = function() 
        module.enabled = true
        if module.OnEnable then module:OnEnable() end
    end
    module.Disable = function() 
        module.enabled = false
        if module.OnDisable then module:OnDisable() end
    end
    
    -- Register in modules table
    self.modules[name] = module
    return module
end

-- Event handling system
WE.frame = CreateFrame("Frame")
WE.events = {}

function WE:RegisterEvent(event, callback)
    if not self.events[event] then
        self.events[event] = {}
        self.frame:RegisterEvent(event)
    end
    table.insert(self.events[event], callback)
end

function WE:UnregisterEvent(event, callback)
    if self.events[event] then
        for i, func in ipairs(self.events[event]) do
            if func == callback then
                table.remove(self.events[event], i)
                break
            end
        end
        
        if #self.events[event] == 0 then
            self.events[event] = nil
            self.frame:UnregisterEvent(event)
        end
    end
end

-- Main event handler
WE.frame:SetScript("OnEvent", function(self, event, ...)
    if WE.events[event] then
        for _, callback in ipairs(WE.events[event]) do
            local success, err = pcall(callback, ...)
            if not success then
                print("|cFFFF0000WoW Essentials Error:|r " .. err)
            end
        end
    end
end)

-- Chat command handling
SLASH_WOWESSENTIALS1 = "/we"
SLASH_WOWESSENTIALS2 = "/wowessentials"

SlashCmdList["WOWESSENTIALS"] = function(msg)
    local args = {}
    for arg in string.gmatch(msg, "%S+") do
        table.insert(args, string.lower(arg))
    end
    
    local command = args[1]
    
    if command == "config" or command == "options" then
        WE:ShowConfig()
    elseif command == "version" then
        print(string.format("%s version %s", WE.name, WE.version))
    elseif command == "help" then
        print("WoW Essentials commands:")
        print("/we config - Open configuration panel")
        print("/we enable [module] - Enable a specific module")
        print("/we disable [module] - Disable a specific module")
        print("/we version - Show version information")
        print("/we help - Show this help message")
    elseif command == "enable" and args[2] then
        local module = WE.modules[args[2]]
        if module then
            module:Enable()
            print(string.format("Enabled %s module", args[2]))
        else
            print(string.format("Module '%s' not found", args[2]))
        end
    elseif command == "disable" and args[2] then
        local module = WE.modules[args[2]]
        if module then
            module:Disable()
            print(string.format("Disabled %s module", args[2]))
        else
            print(string.format("Module '%s' not found", args[2]))
        end
    else
        WE:ShowConfig()
    end
end

-- Utility functions
function WE:Print(msg)
    print("|cFF00CCFF" .. WE.name .. ":|r " .. tostring(msg))
end

function WE:Debug(msg)
    if WE.db and WE.db.debug then
        print("|cFF00CCFF" .. WE.name .. " Debug:|r " .. tostring(msg))
    end
end

function WE:ShowConfig()
    -- Will be implemented in Config.lua
    if self.OpenConfigPanel then
        self:OpenConfigPanel()
    else
        self:Print("Configuration not available.")
    end
end 