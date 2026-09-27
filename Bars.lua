ComfyBar = ComfyBar or {}
local CB = ComfyBar

CB.barOrder = {"consumables", "buffs", "utility", "professions", "racials"}
CB.bars = CB.bars or {}

local BUTTON_SIZE = 36
local FRAME_PADDING = 6

local function IsLockedDown()
    return InCombatLockdown and InCombatLockdown()
end

local function IsSecretValue(value)
    if type(issecretvalue) == "function" then
        local ok, secret = pcall(issecretvalue, value)
        if ok then return secret and true or false end
    end
    if type(canaccessvalue) == "function" then
        local ok, accessible = pcall(canaccessvalue, value)
        if ok then return not accessible end
    end
    return false
end

local function GetItemCountSafe(itemID)
    if C_Item and type(C_Item.GetItemCount) == "function" then
        local ok, count = pcall(C_Item.GetItemCount, itemID, false, false, false, false)
        if ok and count then return count end
    end
    if type(GetItemCount) == "function" then
        local ok, count = pcall(GetItemCount, itemID)
        if ok and count then return count end
    end
    return 0
end

local function GetItemIconSafe(itemID)
    if C_Item and type(C_Item.GetItemIconByID) == "function" then
        local ok, icon = pcall(C_Item.GetItemIconByID, itemID)
        if ok and icon then return icon end
    end
    if type(GetItemIcon) == "function" then
        local ok, icon = pcall(GetItemIcon, itemID)
        if ok and icon then return icon end
    end
    if type(GetItemInfo) == "function" then
        local ok, _, _, _, _, _, _, _, _, _, icon = pcall(GetItemInfo, itemID)
        if ok and icon then return icon end
    end
    return "Interface\\Icons\\INV_Misc_QuestionMark"
end

local function GetSpellInfoSafe(spellIDOrName)
    if C_Spell and type(C_Spell.GetSpellInfo) == "function" then
        local ok, info = pcall(C_Spell.GetSpellInfo, spellIDOrName)
        if ok and type(info) == "table" and info.name then
            return info.name, info.iconID
        end
    end
    if type(GetSpellInfo) == "function" then
        local ok, name, _, icon = pcall(GetSpellInfo, spellIDOrName)
        if ok and name then return name, icon end
    end
    return nil, nil
end

local function GetItemCooldownSafe(itemID)
    if C_Item and type(C_Item.GetItemCooldown) == "function" then
        local ok, startTime, duration, enable = pcall(C_Item.GetItemCooldown, itemID)
        if ok then return startTime or 0, duration or 0, enable or 0 end
    end
    if type(GetItemCooldown) == "function" then
        local ok, startTime, duration, enable = pcall(GetItemCooldown, itemID)
        if ok then return startTime or 0, duration or 0, enable or 0 end
    end
    return 0, 0, 0
end

local function GetSpellCooldownSafe(spellIDOrName)
    if C_Spell and type(C_Spell.GetSpellCooldown) == "function" then
        local ok, info = pcall(C_Spell.GetSpellCooldown, spellIDOrName)
        if ok and type(info) == "table" then
            return info.startTime or 0, info.duration or 0, info.isEnabled and 1 or 0
        end
    end
    if type(GetSpellCooldown) == "function" then
        local ok, startTime, duration, enable = pcall(GetSpellCooldown, spellIDOrName)
        if ok then return startTime or 0, duration or 0, enable or 0 end
    end
    return 0, 0, 0
end

local function SetCooldown(cooldown, startTime, duration, enable)
    if not cooldown then return end

    -- WoW can return protected/secret cooldown values. Addons may pass those
    -- values to the Cooldown widget, but must not compare them in Lua.
    if IsSecretValue(startTime) or IsSecretValue(duration) or IsSecretValue(enable) then
        local ok = pcall(cooldown.SetCooldown, cooldown, startTime, duration)
        if ok then
            cooldown:Show()
        else
            cooldown:Clear()
            cooldown:Hide()
        end
        return
    end

    local active = false
    local ok, result = pcall(function()
        return enable ~= 0
            and duration ~= nil and duration > 0
            and startTime ~= nil and startTime > 0
    end)
    if ok then active = result and true or false end

    if active then
        cooldown:SetCooldown(startTime, duration)
        cooldown:Show()
    else
        cooldown:Clear()
        cooldown:Hide()
    end
end

function CB:GetBarLabel(key)
    local map = {
        consumables = "BAR_CONSUMABLES",
        buffs = "BAR_BUFFS",
        utility = "BAR_UTILITY",
        professions = "BAR_PROFESSIONS",
        racials = "BAR_RACIALS",
    }
    return self:T(map[key] or key)
end

function CB:GetActionLabel(action)
    if not action then return "?" end
    if action.label == "Hearthstone" then
        return self:T("HEARTHSTONE")
    end
    if action.kind == "item" and action.itemID then
        if type(GetItemInfo) == "function" then
            local name = GetItemInfo(action.itemID)
            if name then return name end
        end
        return "Item " .. tostring(action.itemID)
    elseif action.kind == "spell" then
        local name = action.spellName
        if not name and action.spellID then name = GetSpellInfoSafe(action.spellID) end
        return name or ("Spell " .. tostring(action.spellID or "?"))
    end
    return action.label or "?"
end

function CB:UpdateActionButton(button)
    if not button or not button.action then return end
    local action = button.action
    local icon = "Interface\\Icons\\INV_Misc_QuestionMark"
    local count = ""
    local startTime, duration, enable = 0, 0, 0

    if action.kind == "item" and action.itemID then
        icon = GetItemIconSafe(action.itemID)
        local itemCount = GetItemCountSafe(action.itemID)
        if not IsSecretValue(itemCount) then
            local okCount, numericCount = pcall(tonumber, itemCount)
            numericCount = okCount and numericCount or nil
            if numericCount and numericCount > 1 then count = tostring(numericCount) end
            if button.icon then
                local empty = numericCount == 0
                button.icon:SetDesaturated(empty)
                local shade = empty and 0.55 or 1
                button.icon:SetVertexColor(shade, shade, shade)
            end
        elseif button.icon then
            -- Secret counts cannot be inspected safely; leave the icon neutral.
            button.icon:SetDesaturated(false)
            button.icon:SetVertexColor(1, 1, 1)
        end
        startTime, duration, enable = GetItemCooldownSafe(action.itemID)
    elseif action.kind == "spell" then
        local _, spellIcon = GetSpellInfoSafe(action.spellID or action.spellName)
        if spellIcon then icon = spellIcon end
        startTime, duration, enable = GetSpellCooldownSafe(action.spellID or action.spellName)
        if button.icon then
            button.icon:SetDesaturated(false)
            button.icon:SetVertexColor(1, 1, 1)
        end
    end

    if button.icon then button.icon:SetTexture(icon) end
    if button.count then button.count:SetText(count) end
    SetCooldown(button.cooldown, startTime, duration, enable)
end

function CB:UpdateActionVisuals()
    for _, key in ipairs(self.barOrder) do
        local bar = self.bars[key]
        if bar and bar.actionButtons then
            for _, button in ipairs(bar.actionButtons) do
                self:UpdateActionButton(button)
            end
        end
    end
end

local function ConfigureSecureAction(button, action)
    if IsLockedDown() then return false end

    button:SetAttribute("type1", nil)
    button:SetAttribute("spell", nil)
    button:SetAttribute("item", nil)

    if not action then return true end

    if action.kind == "item" and action.itemID then
        button:SetAttribute("type1", "item")
        button:SetAttribute("item", "item:" .. tostring(action.itemID))
    elseif action.kind == "spell" then
        button:SetAttribute("type1", "spell")
        button:SetAttribute("spell", action.spellID or action.spellName)
    end
    return true
end

function CB:CreateActionButtonFrame(barKey)
    local bar = self.bars[barKey]
    if not bar then return nil end

    local button = CreateFrame("Button", nil, bar, "SecureActionButtonTemplate")
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button.barKey = barKey

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button.icon = icon

    -- Clean icon-only look in normal use. The old Quickslot normal texture
    -- created an extra small square behind every icon.
    button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    cooldown:SetAllPoints(icon)
    button.cooldown = cooldown

    local count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    count:SetPoint("BOTTOMRIGHT", -3, 3)
    button.count = count

    button:SetScript("OnEnter", function(self)
        local a = self.action
        if not a then return end

        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if a.kind == "item" and a.itemID then
            if GameTooltip.SetItemByID then
                GameTooltip:SetItemByID(a.itemID)
            else
                GameTooltip:SetHyperlink("item:" .. tostring(a.itemID))
            end
        elseif a.kind == "spell" then
            if a.spellID and GameTooltip.SetSpellByID then
                GameTooltip:SetSpellByID(a.spellID)
            else
                GameTooltip:SetText(CB:GetActionLabel(a), 1, 0.82, 0)
            end
        else
            GameTooltip:SetText(CB:GetActionLabel(a), 1, 0.82, 0)
        end
        if CB.editMode then
            GameTooltip:AddLine(" ")
            GameTooltip:AddLine(CB:T("REMOVE_HINT"), 0.75, 0.75, 0.75)
        end
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetScript("PostClick", function(self, mouseButton)
        if mouseButton == "RightButton" and CB.editMode and not IsLockedDown() and self.actionIndex then
            CB:RemoveAction(self.barKey, self.actionIndex)
        end
    end)

    button:Hide()
    return button
end

function CB:AcquireActionButton(barKey, action, index)
    if IsLockedDown() then return nil end

    local bar = self.bars[barKey]
    if not bar then return nil end

    bar.buttonPool = bar.buttonPool or {}
    local button

    for _, candidate in ipairs(bar.buttonPool) do
        if not candidate.__ComfyInUse then
            button = candidate
            break
        end
    end

    if not button then
        button = self:CreateActionButtonFrame(barKey)
        if not button then return nil end
        table.insert(bar.buttonPool, button)
    end

    button.__ComfyInUse = true
    button.action = action
    button.actionIndex = index
    button.barKey = barKey

    ConfigureSecureAction(button, action)
    self:UpdateActionButton(button)
    button:Show()
    return button
end

function CB:ReleaseActionButtons(bar)
    if not bar then return end

    for _, button in ipairs(bar.buttonPool or {}) do
        button.__ComfyInUse = false
        button.action = nil
        button.actionIndex = nil
        button:Hide()

        if button.count then button.count:SetText("") end
        if button.cooldown then
            button.cooldown:Clear()
            button.cooldown:Hide()
        end
    end

    bar.actionButtons = {}
end

-- Compatibility wrapper for older internal integrations.
function CB:CreateActionButton(barKey, action, index)
    return self:AcquireActionButton(barKey, action, index)
end

function CB:ReadCursorAction()
    if type(GetCursorInfo) ~= "function" then return nil end

    local kind, a, b, c = GetCursorInfo()
    if kind == "item" then
        local itemID = tonumber(a)
        if not itemID and type(b) == "string" then
            itemID = tonumber(b:match("item:(%d+)"))
        end
        if itemID then
            return {kind = "item", itemID = itemID}
        end
    elseif kind == "spell" then
        local spellID = tonumber(c)
        local spellName

        if type(GetSpellBookItemName) == "function" and a then
            local ok, name = pcall(GetSpellBookItemName, a, b)
            if ok and name then spellName = name end
        end

        if not spellID and type(GetSpellBookItemInfo) == "function" and a then
            local ok, _, id = pcall(GetSpellBookItemInfo, a, b)
            if ok and tonumber(id) then spellID = tonumber(id) end
        end

        if not spellName and spellID then
            spellName = GetSpellInfoSafe(spellID)
        end

        if not spellName and tonumber(a) then
            local name = GetSpellInfoSafe(tonumber(a))
            if name then
                spellID = tonumber(a)
                spellName = name
            end
        end

        if spellID or spellName then
            return {kind = "spell", spellID = spellID, spellName = spellName}
        end
    end

    return nil
end

function CB:IsDuplicateAction(barKey, action)
    local cfg = self.db and self.db.bars and self.db.bars[barKey]
    if not cfg or type(cfg.actions) ~= "table" then return false end

    for _, existing in ipairs(cfg.actions) do
        if action.kind == existing.kind then
            if action.kind == "item" and action.itemID == existing.itemID then
                return true
            elseif action.kind == "spell" then
                if action.spellID and existing.spellID and action.spellID == existing.spellID then
                    return true
                end
                if action.spellName and existing.spellName and action.spellName == existing.spellName then
                    return true
                end
            end
        end
    end
    return false
end

function CB:AddCursorAction(barKey)
    if IsLockedDown() then
        self:Print(self:T("COMBAT_LOCK"))
        return
    end
    if not self.editMode then return end

    local action = self:ReadCursorAction()
    if not action then
        self:Print(self:T("INVALID_DROP"))
        return
    end

    local cfg = self.db.bars[barKey]
    if not cfg then return end
    cfg.actions = cfg.actions or {}

    if not self:IsDuplicateAction(barKey, action) then
        table.insert(cfg.actions, action)
        self:Print(self:T("ADDED") .. ": " .. self:GetActionLabel(action))
    end

    if type(ClearCursor) == "function" then ClearCursor() end
    self:RebuildBar(barKey)
end

function CB:RemoveAction(barKey, index)
    if IsLockedDown() or not self.editMode then return end
    local cfg = self.db and self.db.bars and self.db.bars[barKey]
    if not cfg or not cfg.actions or not cfg.actions[index] then return end

    local label = self:GetActionLabel(cfg.actions[index])
    table.remove(cfg.actions, index)
    self:Print(self:T("REMOVED") .. ": " .. label)
    self:RebuildBar(barKey)
end

function CB:CreatePlusButton(barKey)
    local bar = self.bars[barKey]
    if not bar then return nil end

    local button = CreateFrame("Button", nil, bar)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
    button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    local plus = button:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    plus:SetPoint("CENTER", 0, 1)
    plus:SetText("+")
    plus:SetTextColor(1.0, 0.82, 0.0)

    button:SetScript("OnReceiveDrag", function()
        CB:AddCursorAction(barKey)
    end)

    button:SetScript("OnMouseUp", function(_, mouseButton)
        if mouseButton == "LeftButton" and GetCursorInfo and GetCursorInfo() then
            CB:AddCursorAction(barKey)
        end
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(CB:T("PLUS_TOOLTIP"), 1, 0.82, 0)
        GameTooltip:AddLine(CB:T("PLUS_HELP"), 1, 1, 1, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)

    bar.plusButton = button
    return button
end

function CB:CreateBar(key)
    if self.bars[key] then return self.bars[key] end

    local frame = CreateFrame("Frame", "ComfyBar_" .. key, UIParent, "BackdropTemplate")
    frame:SetSize(BUTTON_SIZE + FRAME_PADDING * 2, BUTTON_SIZE + FRAME_PADDING * 2)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(5)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = {left = 3, right = 3, top = 3, bottom = 3},
    })
    frame:SetBackdropColor(0.03, 0.03, 0.03, 0)
    frame:SetBackdropBorderColor(0.65, 0.52, 0.20, 0)

    local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    title:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 2, 3)
    title:SetText(self:GetBarLabel(key))
    title:SetTextColor(1, 0.82, 0)
    title:Hide()
    frame.title = title

    frame:SetScript("OnDragStart", function(self)
        if CB.editMode and not IsLockedDown() then
            self:StartMoving()
        end
    end)

    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        if not CB.editMode or IsLockedDown() then return end
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint(1)
        if point then
            local cfg = CB.db.bars[key]
            cfg.point = point
            cfg.relativePoint = relativePoint or point
            cfg.x = xOfs or 0
            cfg.y = yOfs or 0
        end
    end)

    frame.actionButtons = {}
    frame.buttonPool = {}
    self.bars[key] = frame
    self:CreatePlusButton(key)
    return frame
end

function CB:LayoutBar(key)
    if IsLockedDown() then return end

    local bar = self.bars[key]
    local cfg = self.db and self.db.bars and self.db.bars[key]
    if not bar or not cfg then return end

    local items = {}
    for _, button in ipairs(bar.actionButtons or {}) do
        if button:IsShown() then table.insert(items, button) end
    end

    if self.editMode and bar.plusButton then
        bar.plusButton:Show()
        table.insert(items, bar.plusButton)
    elseif bar.plusButton then
        bar.plusButton:Hide()
    end

    local spacing = tonumber(cfg.spacing) or 4
    local horizontal = cfg.orientation ~= "VERTICAL"

    for i, button in ipairs(items) do
        button:ClearAllPoints()
        if i == 1 then
            button:SetPoint("TOPLEFT", bar, "TOPLEFT", FRAME_PADDING, -FRAME_PADDING)
        elseif horizontal then
            button:SetPoint("LEFT", items[i - 1], "RIGHT", spacing, 0)
        else
            button:SetPoint("TOP", items[i - 1], "BOTTOM", 0, -spacing)
        end
    end

    local n = #items
    if n == 0 then
        bar:SetSize(1, 1)
    elseif horizontal then
        bar:SetSize(FRAME_PADDING * 2 + BUTTON_SIZE * n + spacing * (n - 1), FRAME_PADDING * 2 + BUTTON_SIZE)
    else
        bar:SetSize(FRAME_PADDING * 2 + BUTTON_SIZE, FRAME_PADDING * 2 + BUTTON_SIZE * n + spacing * (n - 1))
    end
end

function CB:ApplyBarPosition(key)
    if IsLockedDown() then return end

    local bar = self.bars[key]
    local cfg = self.db and self.db.bars and self.db.bars[key]
    if not bar or not cfg then return end

    bar:ClearAllPoints()
    local point = cfg.point or "BOTTOMRIGHT"
    local relativePoint = cfg.relativePoint or point
    bar:SetPoint(point, UIParent, relativePoint, cfg.x or 0, cfg.y or 0)
    bar:SetScale(tonumber(cfg.scale) or 1)
end

function CB:ApplyBarVisibility(key)
    if IsLockedDown() then return end

    local bar = self.bars[key]
    local cfg = self.db and self.db.bars and self.db.bars[key]
    if not bar or not cfg then return end

    if UnregisterStateDriver then
        UnregisterStateDriver(bar, "visibility")
    end

    if not self.db.enabled or not cfg.enabled then
        bar:Hide()
        return
    end

    if cfg.hideInCombat and RegisterStateDriver then
        RegisterStateDriver(bar, "visibility", "[combat] hide; show")
    else
        bar:Show()
    end
end

function CB:UpdateEditVisuals(key)
    local bar = self.bars[key]
    if not bar then return end

    if self.editMode and self.db.enabled and not IsLockedDown() then
        bar:SetBackdropColor(0.03, 0.03, 0.03, 0.72)
        bar:SetBackdropBorderColor(0.65, 0.52, 0.20, 1)
        bar.title:Show()
    else
        bar:SetBackdropColor(0.03, 0.03, 0.03, 0)
        bar:SetBackdropBorderColor(0.65, 0.52, 0.20, 0)
        bar.title:Hide()
        if bar.plusButton then bar.plusButton:Hide() end
    end
end

function CB:RebuildBar(key)
    if IsLockedDown() then
        self.pendingBarRefresh = true
        return false
    end

    local bar = self:CreateBar(key)
    local cfg = self.db.bars[key]
    self:ReleaseActionButtons(bar)

    for index, action in ipairs(cfg.actions or {}) do
        local button = self:AcquireActionButton(key, action, index)
        if button then
            table.insert(bar.actionButtons, button)
        end
    end

    self:ApplyBarPosition(key)
    self:UpdateEditVisuals(key)
    self:LayoutBar(key)
    self:ApplyBarVisibility(key)
    return true
end

function CB:RefreshBars()
    if not self.db then return false end

    if IsLockedDown() then
        self.pendingBarRefresh = true
        self:UpdateActionVisuals()
        return false
    end

    self.pendingBarRefresh = false
    for _, key in ipairs(self.barOrder) do
        self:RebuildBar(key)
    end
    return true
end

function CB:OnCombatStart()
    self.editMode = false
    for _, key in ipairs(self.barOrder) do
        local bar = self.bars[key]
        if bar then
            if bar.plusButton then bar.plusButton:Hide() end
            if bar.title then bar.title:Hide() end
            bar:SetBackdropColor(0.03, 0.03, 0.03, 0)
            bar:SetBackdropBorderColor(0.65, 0.52, 0.20, 0)
        end
    end
end

function CB:InitializeBars()
    if not self.db then return end
    for _, key in ipairs(self.barOrder) do
        self:CreateBar(key)
    end
    self:RefreshBars()
end
