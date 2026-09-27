ComfyBar = ComfyBar or {}
local CB = ComfyBar

local controls = {}
local selectedBar = "consumables"
local sliderIndex = 0

local function SetLabel(check, text)
    local label = check.Text or check.text
    if not label then
        label = check:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        label:SetPoint("LEFT", check, "RIGHT", 3, 1)
        check.Text = label
    end
    label:SetText(text)
end

local function CreateCheck(parent, text, x, y, getter, setter)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    SetLabel(cb, text)
    cb:SetScript("OnClick", function(self)
        setter(self:GetChecked() and true or false)
        CB:RefreshOptions()
    end)
    cb._getter = getter
    table.insert(controls, cb)
    return cb
end

local function CreateButton(parent, text, x, y, width, func)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width or 120, 24)
    button:SetPoint("TOPLEFT", x, y)
    button:SetText(text)
    button:SetScript("OnClick", func)
    return button
end

local function CreateSlider(parent, label, minValue, maxValue, step, x, y, getter, setter, formatter)
    sliderIndex = sliderIndex + 1
    local name = "ComfyBarSlider" .. sliderIndex
    local slider = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", x, y)
    slider:SetWidth(250)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    _G[name .. "Low"]:SetText(tostring(minValue))
    _G[name .. "High"]:SetText(tostring(maxValue))
    _G[name .. "Text"]:SetText(label)

    slider.valueText = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    slider.valueText:SetPoint("LEFT", slider, "RIGHT", 12, 0)

    slider:SetScript("OnValueChanged", function(self, value)
        if self._refreshing then return end
        setter(value)
        self.valueText:SetText(formatter and formatter(value) or tostring(value))
    end)

    slider._getter = getter
    slider._format = formatter
    table.insert(controls, slider)
    return slider
end

local function DropdownSetText(dropdown, text)
    if UIDropDownMenu_SetText then UIDropDownMenu_SetText(dropdown, text or "") end
end

local function CreateDropdown(parent, x, y, width, getItems, getCurrent, onSelect)
    local dd = CreateFrame("Frame", nil, parent, "UIDropDownMenuTemplate")
    dd:SetPoint("TOPLEFT", x, y)
    if UIDropDownMenu_SetWidth then UIDropDownMenu_SetWidth(dd, width or 180) end

    UIDropDownMenu_Initialize(dd, function(_, level)
        local current = getCurrent()
        for _, entry in ipairs(getItems()) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = entry.text
            info.value = entry.value
            info.checked = entry.value == current
            info.func = function()
                onSelect(entry.value)
                CloseDropDownMenus()
                CB:RefreshOptions()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    dd._refresh = function()
        local current = getCurrent()
        local label = tostring(current or "")
        for _, entry in ipairs(getItems()) do
            if entry.value == current then label = entry.text end
        end
        DropdownSetText(dd, label)
    end

    return dd
end

local function SelectTab(index)
    local frame = CB.optionsFrame
    if not frame then return end
    for i, tab in ipairs(frame.tabs) do
        tab:SetEnabled(i ~= index)
        frame.pages[i]:SetShown(i == index)
    end
end

function CB:RefreshOptions()
    if not self.optionsFrame or not self.db then return end

    for _, control in ipairs(controls) do
        if control._getter then
            local value = control._getter()
            if control:GetObjectType() == "CheckButton" then
                control:SetChecked(value and true or false)
            elseif control:GetObjectType() == "Slider" then
                control._refreshing = true
                control:SetValue(value)
                control._refreshing = false
                if control.valueText then
                    control.valueText:SetText(control._format and control._format(value) or tostring(value))
                end
            end
        end
    end

    if self.barDropdown and self.barDropdown._refresh then self.barDropdown._refresh() end
    if self.orientationDropdown and self.orientationDropdown._refresh then self.orientationDropdown._refresh() end

    if self.profileStatus then
        self.profileStatus:SetText(self.db.selectedProfile or "Bevorzugt")
    end
end

function CB:InitializeOptions()
    if self.optionsFrame then return end

    local frame = CreateFrame("Frame", "ComfyBarOptions", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(760, 620)
    local savedPos = self.db and self.db.optionsWindow or nil
    local point = savedPos and savedPos.point or "CENTER"
    local relativePoint = savedPos and savedPos.relativePoint or point
    frame:SetPoint(point, UIParent, relativePoint, savedPos and savedPos.x or -360, savedPos and savedPos.y or 40)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("HIGH")
    frame:SetFrameLevel(20)
    if frame.SetToplevel then frame:SetToplevel(true) end
    frame:Hide()
    frame.TitleText:SetText("ComfyBar")
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnMouseDown", function(self) self:Raise() end)
    frame:SetScript("OnDragStart", function(self)
        self:Raise()
        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local p, _, rp, x, y = self:GetPoint(1)
        if CB.db and p then
            CB.db.optionsWindow = CB.db.optionsWindow or {}
            CB.db.optionsWindow.point = p
            CB.db.optionsWindow.relativePoint = rp or p
            CB.db.optionsWindow.x = x or 0
            CB.db.optionsWindow.y = y or 0
        end
    end)
    table.insert(UISpecialFrames, frame:GetName())
    self.optionsFrame = frame

    frame.tabs = {}
    frame.pages = {}

    local tabNames = {self:T("TAB_GENERAL"), self:T("TAB_BARS"), self:T("TAB_PROFILES"), self:T("TAB_INFO")}
    for i, label in ipairs(tabNames) do
        local tab = CreateButton(frame, label, 18 + (i - 1) * 120, -35, 110, function() SelectTab(i) end)
        frame.tabs[i] = tab

        local page = CreateFrame("Frame", nil, frame)
        page:SetPoint("TOPLEFT", 12, -70)
        page:SetPoint("BOTTOMRIGHT", -12, 12)
        frame.pages[i] = page
    end

    local general = frame.pages[1]
    local gtitle = general:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    gtitle:SetPoint("TOPLEFT", 20, -10)
    gtitle:SetText(self:T("TAB_GENERAL"))

    CreateCheck(general, self:T("ADDON_ENABLED"), 20, -50,
        function() return CB.db.enabled end,
        function(v) CB:SetEnabled(v) end)

    CreateCheck(general, self:T("EDIT_MODE"), 20, -85,
        function() return CB.editMode end,
        function(v) CB:SetEditMode(v) end)

    local editHelp = general:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    editHelp:SetPoint("TOPLEFT", 45, -120)
    editHelp:SetWidth(630)
    editHelp:SetJustifyH("LEFT")
    editHelp:SetText(self:T("EDIT_HINT"))

    CreateCheck(general, self:T("MINIMAP_SHOW"), 20, -180,
        function() return CB.db.minimap.show end,
        function(v) CB.db.minimap.show = v CB:UpdateMinimapPosition() end)

    CreateCheck(general, self:T("MINIMAP_LOCK"), 20, -215,
        function() return CB.db.minimap.locked end,
        function(v) CB.db.minimap.locked = v end)

    local commands = general:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    commands:SetPoint("TOPLEFT", 20, -280)
    commands:SetText("/comfybar  ·  /cb  ·  /cb unlock  ·  /cb lock")

    local bars = frame.pages[2]
    local btitle = bars:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    btitle:SetPoint("TOPLEFT", 20, -10)
    btitle:SetText(self:T("TAB_BARS"))

    local barLabel = bars:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    barLabel:SetPoint("TOPLEFT", 20, -52)
    barLabel:SetText(self:T("TAB_BARS"))

    self.barDropdown = CreateDropdown(bars, 5, -65, 210,
        function()
            local items = {}
            for _, key in ipairs(CB.barOrder) do
                table.insert(items, {value = key, text = CB:GetBarLabel(key)})
            end
            return items
        end,
        function() return selectedBar end,
        function(value) selectedBar = value end)

    CreateCheck(bars, self:T("BAR_ENABLED"), 20, -125,
        function() return CB.db.bars[selectedBar].enabled end,
        function(v)
            if InCombatLockdown and InCombatLockdown() then CB:Print(CB:T("COMBAT_LOCK")) return end
            CB.db.bars[selectedBar].enabled = v
            CB:RefreshBars()
        end)

    CreateCheck(bars, self:T("BAR_HIDE_COMBAT"), 20, -160,
        function() return CB.db.bars[selectedBar].hideInCombat end,
        function(v)
            if InCombatLockdown and InCombatLockdown() then CB:Print(CB:T("COMBAT_LOCK")) return end
            CB.db.bars[selectedBar].hideInCombat = v
            CB:RefreshBars()
        end)

    local orientLabel = bars:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    orientLabel:SetPoint("TOPLEFT", 20, -210)
    orientLabel:SetText(self:T("BAR_ORIENTATION"))

    self.orientationDropdown = CreateDropdown(bars, 5, -223, 170,
        function()
            return {
                {value = "HORIZONTAL", text = CB:T("HORIZONTAL")},
                {value = "VERTICAL", text = CB:T("VERTICAL")},
            }
        end,
        function() return CB.db.bars[selectedBar].orientation end,
        function(value)
            if InCombatLockdown and InCombatLockdown() then CB:Print(CB:T("COMBAT_LOCK")) return end
            CB.db.bars[selectedBar].orientation = value
            CB:RefreshBars()
        end)

    CreateSlider(bars, self:T("SCALE"), 60, 150, 5, 35, -310,
        function() return math.floor((CB.db.bars[selectedBar].scale or 1) * 100 + 0.5) end,
        function(v)
            if InCombatLockdown and InCombatLockdown() then return end
            CB.db.bars[selectedBar].scale = v / 100
            CB:RefreshBars()
        end,
        function(v) return string.format("%d%%", v) end)

    CreateSlider(bars, self:T("SPACING"), 0, 30, 1, 35, -385,
        function() return CB.db.bars[selectedBar].spacing or 4 end,
        function(v)
            if InCombatLockdown and InCombatLockdown() then return end
            CB.db.bars[selectedBar].spacing = math.floor(v + 0.5)
            CB:RefreshBars()
        end,
        function(v) return tostring(math.floor(v + 0.5)) end)

    CreateButton(bars, self:T("RESET_POSITION"), 20, -455, 170, function()
        if InCombatLockdown and InCombatLockdown() then CB:Print(CB:T("COMBAT_LOCK")) return end
        CB:ResetBarPosition(selectedBar)
        CB:RefreshOptions()
    end)

    local profiles = frame.pages[3]
    local ptitle = profiles:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    ptitle:SetPoint("TOPLEFT", 20, -10)
    ptitle:SetText(self:T("TAB_PROFILES"))

    local ptext = profiles:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    ptext:SetPoint("TOPLEFT", 20, -50)
    ptext:SetWidth(650)
    ptext:SetJustifyH("LEFT")
    ptext:SetText(self:T("PROFILE_TEXT"))

    CreateButton(profiles, self:T("PROFILE_MINIMAL"), 20, -115, 140, function() CB:ApplyProfile("Minimal") end)
    CreateButton(profiles, self:T("PROFILE_PREFERRED"), 175, -115, 140, function() CB:ApplyProfile("Bevorzugt") end)
    CreateButton(profiles, self:T("PROFILE_COMPLETE"), 330, -115, 140, function() CB:ApplyProfile("Komplett") end)

    local currentLabel = profiles:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    currentLabel:SetPoint("TOPLEFT", 20, -175)
    currentLabel:SetText("Aktuell:")

    self.profileStatus = profiles:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    self.profileStatus:SetPoint("LEFT", currentLabel, "RIGHT", 8, 0)

    local infoPage = frame.pages[4]
    local ititle = infoPage:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    ititle:SetPoint("TOPLEFT", 20, -10)
    ititle:SetText(self:T("INFO_TITLE"))

    local infoBox = CreateFrame("Frame", nil, infoPage, "BackdropTemplate")
    infoBox:SetPoint("TOPLEFT", 20, -52)
    infoBox:SetSize(680, 455)
    infoBox:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = {left = 8, right = 8, top = 8, bottom = 8},
    })

    local addonName = infoBox:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
    addonName:SetPoint("TOPLEFT", 28, -26)
    addonName:SetText("ComfyBar")

    local tagline = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    tagline:SetPoint("TOPLEFT", addonName, "BOTTOMLEFT", 0, -7)
    tagline:SetWidth(620)
    tagline:SetJustifyH("LEFT")
    tagline:SetText("Customizable utility bars for buffs, consumables, professions, racials and more on WoW Forever.")

    local function InfoRow(label, value, y)
        local l = infoBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
        l:SetPoint("TOPLEFT", 28, y)
        l:SetText(label)

        local v = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        v:SetPoint("TOPLEFT", 185, y)
        v:SetWidth(455)
        v:SetJustifyH("LEFT")
        v:SetText(value or "-")
        return l, v
    end

    local clientVersion, clientBuild, _, clientInterface = CB:GetClientBuildInfo()
    local compatible, compatibilityText = CB:GetCompatibilityStatus()

    InfoRow(self:T("INFO_VERSION"), CB.version, -100)
    InfoRow(self:T("INFO_BUILD_DATE"), CB.buildDate, -122)
    InfoRow(self:T("INFO_STATUS"), CB.status, -144)
    InfoRow(self:T("INFO_CLIENT"), "WoW Forever " .. tostring(clientVersion) .. " / Build " .. tostring(clientBuild) .. " / Interface " .. tostring(clientInterface or "?"), -166)
    InfoRow(self:T("INFO_TESTED_TARGET"), CB.gameVersion .. " / Build " .. CB.targetBuild .. " / Interface " .. tostring(CB.interface), -188)

    local _, compatValue = InfoRow(self:T("INFO_COMPAT_STATUS"), compatibilityText, -210)
    if compatible then
        compatValue:SetTextColor(0.20, 1.00, 0.20)
    else
        compatValue:SetTextColor(1.00, 0.35, 0.20)
    end

    InfoRow(self:T("INFO_AUTHOR"), CB.author, -232)

    local discordLabel = infoBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    discordLabel:SetPoint("TOPLEFT", 28, -257)
    discordLabel:SetText(self:T("INFO_DISCORD"))

    local discordBox = CreateFrame("EditBox", nil, infoBox, "InputBoxTemplate")
    discordBox:SetSize(275, 30)
    discordBox:SetPoint("TOPLEFT", 180, -248)
    discordBox:SetAutoFocus(false)
    discordBox:SetText(CB.discord)
    discordBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    discordBox:SetScript("OnEnterPressed", function(self) self:HighlightText() end)
    discordBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

    local copyHint = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    copyHint:SetPoint("TOPLEFT", 470, -255)
    copyHint:SetWidth(165)
    copyHint:SetJustifyH("LEFT")
    copyHint:SetText(self:T("INFO_COPY"))

    local githubLabel = infoBox:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    githubLabel:SetPoint("TOPLEFT", 28, -292)
    githubLabel:SetText(self:T("INFO_GITHUB"))

    local githubBox = CreateFrame("EditBox", nil, infoBox, "InputBoxTemplate")
    githubBox:SetSize(395, 30)
    githubBox:SetPoint("TOPLEFT", 180, -283)
    githubBox:SetAutoFocus(false)
    githubBox:SetText(CB.github)
    githubBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    githubBox:SetScript("OnEnterPressed", function(self) self:HighlightText() end)
    githubBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)

    InfoRow(self:T("INFO_COMMANDS"), "/comfybar  ·  /cb", -328)

    local notice = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    notice:SetPoint("TOPLEFT", 28, -360)
    notice:SetWidth(620)
    notice:SetJustifyH("LEFT")
    notice:SetText(self:T("INFO_NOTICE"))

    local copyright = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    copyright:SetPoint("TOPLEFT", 28, -414)
    copyright:SetText("© 2026 TheRealDoubleG")

    local thanks = infoBox:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    thanks:SetPoint("BOTTOMLEFT", 28, 28)
    thanks:SetWidth(620)
    thanks:SetJustifyH("LEFT")
    thanks:SetText(self:T("INFO_THANKS"))

    frame:SetScript("OnShow", function()
        CB:RefreshOptions()
    end)

    SelectTab(1)

    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local canvas = CreateFrame("Frame")
        local info = canvas:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
        info:SetPoint("TOPLEFT", 16, -16)
        info:SetText("ComfyBar")

        local desc = canvas:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
        desc:SetPoint("TOPLEFT", info, "BOTTOMLEFT", 0, -12)
        desc:SetWidth(520)
        desc:SetJustifyH("LEFT")
        desc:SetText(self:T("SETTINGS_DESC"))

        CreateButton(canvas, self:T("SETTINGS_OPEN"), 16, -90, 220, function() CB:ShowOptions() end)
        local category = Settings.RegisterCanvasLayoutCategory(canvas, "ComfyBar")
        Settings.RegisterAddOnCategory(category)
        self.settingsCategory = category
    end
end

function CB:ShowOptions()
    if not self.optionsFrame then self:InitializeOptions() end
    self.optionsFrame:Show()
    self.optionsFrame:Raise()
    self:RefreshOptions()
end
