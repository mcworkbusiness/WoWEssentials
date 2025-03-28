-- WoW Essentials Configuration
-- Handles addon settings and configuration UI

local WE = WoWEssentials
local L = {} -- Localization table, will be expanded later

-- Default settings
local defaults = {
    profile = {
        debug = false,
        modules = {
            UI = {
                enabled = true,
                scale = 1.0,
                customFont = false,
                fontFamily = "Friz Quadrata TT",
                fontSize = 12,
                barTexture = "Blizzard",
                customColors = false,
                colors = {
                    health = {r = 0.1, g = 0.9, b = 0.1},
                    mana = {r = 0.1, g = 0.1, b = 0.9},
                    energy = {r = 0.9, g = 0.9, b = 0.1},
                    rage = {r = 0.9, g = 0.1, b = 0.1}
                }
            },
            Alerts = {
                enabled = true,
                sound = true,
                visual = true,
                text = true,
                bossOnly = false,
                threshold = 75 -- Percentage health for special alerts
            },
            Cues = {
                enabled = true,
                cooldowns = true,
                procs = true,
                resources = true
            },
            Stats = {
                enabled = true,
                showDps = true,
                showHps = true,
                combatOnly = true,
                window = 60, -- Time window in seconds
                threshold = 1000 -- Minimum value to display
            }
        }
    }
}

-- Initialize database
function WE:InitializeDB()
    -- Check for LibStub and AceDB
    if not LibStub then
        self:Print("LibStub not found. Configuration system disabled.")
        return
    end
    
    -- Create database
    local AceDB = LibStub("AceDB-3.0", true)
    if AceDB then
        self.db = AceDB:New("WoWEssentialsDB", defaults, true)
        self.db.RegisterCallback(self, "OnProfileChanged", "RefreshConfig")
        self.db.RegisterCallback(self, "OnProfileCopied", "RefreshConfig")
        self.db.RegisterCallback(self, "OnProfileReset", "RefreshConfig")
    else
        self:Print("AceDB-3.0 not found. Using basic configuration system.")
        
        -- Basic configuration system fallback
        if not WoWEssentialsDB then
            WoWEssentialsDB = defaults.profile
        end
        self.db = { profile = WoWEssentialsDB }
    end
end

-- Get a configuration value
function WE:GetConfig(path, default)
    if not self.db then return default end
    
    local value = self.db.profile
    local pathParts = {strsplit(".", path)}
    
    for _, part in ipairs(pathParts) do
        if value[part] ~= nil then
            value = value[part]
        else
            return default
        end
    end
    
    return value
end

-- Set a configuration value
function WE:SetConfig(path, value)
    if not self.db then return end
    
    local config = self.db.profile
    local pathParts = {strsplit(".", path)}
    local lastKey = table.remove(pathParts)
    
    for _, part in ipairs(pathParts) do
        if config[part] == nil then
            config[part] = {}
        end
        config = config[part]
    end
    
    config[lastKey] = value
    self:RefreshConfig()
end

-- Refresh all modules with new configuration
function WE:RefreshConfig()
    for name, module in pairs(self.modules) do
        if module.enabled and module.OnConfigChanged then
            local success, err = pcall(module.OnConfigChanged, module)
            if not success then
                self:Print("Error refreshing " .. name .. " module: " .. err)
            end
        end
    end
end

-- Configuration UI
function WE:CreateConfigPanel()
    -- Check for AceGUI
    local AceGUI = LibStub("AceGUI-3.0", true)
    if not AceGUI then
        self:Print("AceGUI-3.0 not found. Configuration UI disabled.")
        return
    end
    
    -- Create the main configuration frame
    self.configFrame = AceGUI:Create("Frame")
    local frame = self.configFrame
    frame:SetTitle("WoW Essentials Configuration")
    frame:SetLayout("Flow")
    frame:SetCallback("OnClose", function(widget) 
        AceGUI:Release(widget)
        self.configFrame = nil
    end)
    
    -- Create tab group for modules
    local tabGroup = AceGUI:Create("TabGroup")
    tabGroup:SetLayout("Flow")
    tabGroup:SetFullWidth(true)
    tabGroup:SetFullHeight(true)
    
    local tabs = {
        {text = "General", value = "general"},
        {text = "UI", value = "ui"},
        {text = "Alerts", value = "alerts"},
        {text = "Cues", value = "cues"},
        {text = "Stats", value = "stats"}
    }
    
    tabGroup:SetTabs(tabs)
    tabGroup:SetCallback("OnGroupSelected", function(container, event, group)
        container:ReleaseChildren()
        self:CreateTabContent(container, group)
    end)
    
    -- Select the initial tab
    tabGroup:SelectTab("general")
    
    frame:AddChild(tabGroup)
    return frame
end

-- Create content for each configuration tab
function WE:CreateTabContent(container, group)
    if group == "general" then
        -- General settings
        local debugCheckbox = LibStub("AceGUI-3.0"):Create("CheckBox")
        debugCheckbox:SetLabel("Enable Debug Mode")
        debugCheckbox:SetValue(self:GetConfig("debug", false))
        debugCheckbox:SetCallback("OnValueChanged", function(widget, event, value)
            self:SetConfig("debug", value)
        end)
        container:AddChild(debugCheckbox)
        
        -- Add more general settings here
    elseif group == "ui" then
        self:CreateUIConfig(container)
    elseif group == "alerts" then
        self:CreateAlertsConfig(container)
    elseif group == "cues" then
        self:CreateCuesConfig(container)
    elseif group == "stats" then
        self:CreateStatsConfig(container)
    end
end

-- Open configuration panel
function WE:OpenConfigPanel()
    if self.configFrame then
        self.configFrame:Show()
    else
        self:CreateConfigPanel()
    end
end

-- These functions will be implemented as the individual module configurations are developed
WE.CreateUIConfig = function(self, container) end
WE.CreateAlertsConfig = function(self, container) end
WE.CreateCuesConfig = function(self, container) end
WE.CreateStatsConfig = function(self, container) end 