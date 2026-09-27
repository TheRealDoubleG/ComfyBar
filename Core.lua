local ADDON_NAME = ...

ComfyBar = ComfyBar or {}
local CB = ComfyBar

CB.name = ADDON_NAME or "ComfyBar"
CB.version = "0.11"
CB.buildDate = "27.09.2026"
CB.status = "Beta"
CB.gameVersion = "WoW Forever 1.60.1"
CB.targetBuild = "70009"
CB.interface = 16001
CB.author = "TheRealDoubleG"
CB.discord = "the.real.double.g"
CB.github = "https://github.com/TheRealDoubleG/ComfyBar"
CB.editMode = false

CB.defaultBarPositions = {
    utility = {point = "CENTER", relativePoint = "CENTER", x = 0, y = -80},
    buffs = {point = "CENTER", relativePoint = "CENTER", x = 0, y = -130},
    consumables = {point = "CENTER", relativePoint = "CENTER", x = 0, y = -180},
    professions = {point = "CENTER", relativePoint = "CENTER", x = 0, y = -230},
    racials = {point = "CENTER", relativePoint = "CENTER", x = 0, y = -280},
}

local defaults = {
    enabled = true,
    selectedProfile = "Bevorzugt",
    minimap = {
        show = true,
        locked = false,
        angle = 220,
    },
    optionsWindow = {
        point = "CENTER",
        relativePoint = "CENTER",
        x = -360,
        y = 40,
    },
    bars = {
        consumables = {
            enabled = true,
            orientation = "HORIZONTAL",
            scale = 1.00,
            spacing = 4,
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = -180,
            hideInCombat = true,
            actions = {},
        },
        buffs = {
            enabled = true,
            orientation = "HORIZONTAL",
            scale = 1.00,
            spacing = 4,
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = -130,
            hideInCombat = true,
            actions = {},
        },
        utility = {
            enabled = true,
            orientation = "HORIZONTAL",
            scale = 1.00,
            spacing = 4,
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = -80,
            hideInCombat = true,
            actions = {
                {kind = "item", itemID = 6948, label = "Hearthstone"},
            },
        },
        professions = {
            enabled = false,
            orientation = "HORIZONTAL",
            scale = 1.00,
            spacing = 4,
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = -230,
            hideInCombat = true,
            actions = {},
        },
        racials = {
            enabled = false,
            orientation = "HORIZONTAL",
            scale = 1.00,
            spacing = 4,
            point = "CENTER",
            relativePoint = "CENTER",
            x = 0,
            y = -280,
            hideInCombat = false,
            actions = {},
        },
    },
    customProfiles = {},
}

local function CopyTable(src)
    if type(src) ~= "table" then return src end
    local dst = {}
    for k, v in pairs(src) do
        dst[k] = CopyTable(v)
    end
    return dst
end

local function ApplyDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            ApplyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

CB.CopyTable = CopyTable

function CB:Print(msg)
    if DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd200ComfyBar:|r " .. tostring(msg))
    end
end

function CB:GetClientBuildInfo()
    if type(GetBuildInfo) ~= "function" then
        return "?", "?", "?", nil
    end
    local version, build, buildDate, interface = GetBuildInfo()
    return tostring(version or "?"), tostring(build or "?"), tostring(buildDate or "?"), tonumber(interface)
end

function CB:GetCompatibilityStatus()
    local _, _, _, clientInterface = self:GetClientBuildInfo()
    if clientInterface and tonumber(clientInterface) == tonumber(self.interface) then
        return true, self:T("COMPAT_MATCH")
    end
    return false, self:T("COMPAT_UPDATE_REQUIRED")
end

local legacyBarPositions = {
    utility = {point = "BOTTOMRIGHT", x = -420, y = 220},
    buffs = {point = "BOTTOMRIGHT", x = -420, y = 170},
    consumables = {point = "BOTTOMRIGHT", x = -420, y = 120},
    professions = {point = "BOTTOMRIGHT", x = -420, y = 70},
    racials = {point = "BOTTOMRIGHT", x = -420, y = 20},
}

function CB:MigrateLegacyBarAnchors()
    if not self.db or not self.db.bars then return end

    for key, oldPos in pairs(legacyBarPositions) do
        local cfg = self.db.bars[key]
        local newPos = self.defaultBarPositions[key]
        if cfg and newPos
            and cfg.point == oldPos.point
            and (cfg.relativePoint == nil or cfg.relativePoint == oldPos.point)
            and tonumber(cfg.x) == oldPos.x
            and tonumber(cfg.y) == oldPos.y then

            cfg.point = newPos.point
            cfg.relativePoint = newPos.relativePoint
            cfg.x = newPos.x
            cfg.y = newPos.y
        end
    end
end

function CB:InitializeDB()
    if type(ComfyBarDB) ~= "table" then
        ComfyBarDB = CopyTable(defaults)
    else
        ApplyDefaults(ComfyBarDB, defaults)
    end
    self.db = ComfyBarDB
    self:MigrateLegacyBarAnchors()
    self.editMode = false
end

function CB:ResetBarPosition(key)
    if not self.db or not self.db.bars[key] then return end
    local pos = self.defaultBarPositions[key]
    if not pos then return end
    self.db.bars[key].point = pos.point or "CENTER"
    self.db.bars[key].relativePoint = pos.relativePoint or pos.point or "CENTER"
    self.db.bars[key].x = pos.x
    self.db.bars[key].y = pos.y
    if self.RefreshBars then self:RefreshBars() end
end

function CB:ApplyLayoutToAllBars(sourceKey)
    if InCombatLockdown and InCombatLockdown() then
        self:Print(self:T("COMBAT_LOCK"))
        return false
    end
    if not self.db or not self.db.bars then return false end

    local source = self.db.bars[sourceKey]
    if not source then return false end

    for key, cfg in pairs(self.db.bars) do
        if key ~= sourceKey and type(cfg) == "table" then
            cfg.orientation = source.orientation
            cfg.scale = source.scale
            cfg.spacing = source.spacing
        end
    end

    if self.RefreshBars then self:RefreshBars() end
    if self.RefreshOptions then self:RefreshOptions() end
    self:Print(self:T("LAYOUT_APPLIED"))
    return true
end

function CB:SetEnabled(value)
    if InCombatLockdown and InCombatLockdown() then
        self:Print(self:T("COMBAT_LOCK"))
        return false
    end
    self.db.enabled = value and true or false
    if self.RefreshBars then self:RefreshBars() end
    if self.UpdateMinimapAppearance then self:UpdateMinimapAppearance() end
    if self.RefreshOptions then self:RefreshOptions() end
    self:Print(self.db.enabled and self:T("ENABLED_MSG") or self:T("DISABLED_MSG"))
    return true
end

function CB:ToggleEnabled()
    return self:SetEnabled(not self.db.enabled)
end

function CB:SetEditMode(value)
    if InCombatLockdown and InCombatLockdown() then
        self:Print(self:T("COMBAT_LOCK"))
        return false
    end
    self.editMode = value and true or false
    if self.RefreshBars then self:RefreshBars() end
    return true
end

function CB:OpenOptions()
    if self.ShowOptions then
        self:ShowOptions()
    end
end

SLASH_COMFYBAR1 = "/comfybar"
SLASH_COMFYBAR2 = "/cb"
SlashCmdList.COMFYBAR = function(msg)
    msg = tostring(msg or ""):lower():match("^%s*(.-)%s*$")
    if msg == "unlock" then
        CB:SetEditMode(true)
        return
    elseif msg == "lock" then
        CB:SetEditMode(false)
        return
    elseif msg == "on" then
        CB:SetEnabled(true)
        return
    elseif msg == "off" then
        CB:SetEnabled(false)
        return
    end
    CB:OpenOptions()
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("BAG_UPDATE_DELAYED")
eventFrame:RegisterEvent("BAG_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
eventFrame:RegisterEvent("SPELLS_CHANGED")

eventFrame:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= CB.name then return end
        CB:InitializeDB()
        if CB.InitializeBars then CB:InitializeBars() end
        if CB.InitializeMinimap then CB:InitializeMinimap() end
        if CB.InitializeOptions then CB:InitializeOptions() end
        if CB.RefreshBars then CB:RefreshBars() end
    elseif event == "PLAYER_LOGIN" then
        if CB.RefreshBars then CB:RefreshBars() end
    elseif event == "PLAYER_REGEN_DISABLED" then
        CB.editMode = false
        if CB.OnCombatStart then CB:OnCombatStart() end
        if CB.RefreshOptions then CB:RefreshOptions() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        if CB.RefreshBars then CB:RefreshBars() end
        if CB.RefreshOptions then CB:RefreshOptions() end
    elseif event == "BAG_UPDATE_DELAYED" or event == "BAG_UPDATE_COOLDOWN" or event == "SPELL_UPDATE_COOLDOWN" then
        if CB.UpdateActionVisuals then CB:UpdateActionVisuals() end
    elseif event == "SPELLS_CHANGED" then
        if not (InCombatLockdown and InCombatLockdown()) and CB.RefreshBars then
            CB:RefreshBars()
        end
    end
end)
