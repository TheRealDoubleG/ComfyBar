ComfyBar = ComfyBar or {}
local CB = ComfyBar

CB.version = "0.17"
CB.buildDate = "04.10.2026"

local PREFIXES = {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarRightButton",
    "MultiBarLeftButton",
    "MultiBar5Button",
    "MultiBar6Button",
    "MultiBar7Button",
}

local function EnsureDefaults()
    if not CB.db then return end
    CB.db.rangeTint = CB.db.rangeTint or {}
    local c = CB.db.rangeTint
    if c.enabled == nil then c.enabled = true end
    if c.tintIcon == nil then c.tintIcon = true end
    if c.showBorder == nil then c.showBorder = false end
    if c.strength == nil then c.strength = 42 end
end

local originalInitializeDB = CB.InitializeDB
function CB:InitializeDB(...)
    local result
    if originalInitializeDB then result = originalInitializeDB(self, ...) end
    EnsureDefaults()
    return result
end

local function FindHotKey(button)
    if not button then return nil end
    if button.HotKey then return button.HotKey end
    local name = button.GetName and button:GetName()
    return name and _G[name .. "HotKey"] or nil
end

local function FindIcon(button)
    if not button then return nil end
    if button.icon then return button.icon end
    if button.Icon then return button.Icon end
    local name = button.GetName and button:GetName()
    return name and (_G[name .. "Icon"] or _G[name .. "IconTexture"]) or nil
end

local function IsHotKeyRed(button)
    local hotkey = FindHotKey(button)
    if not hotkey or type(hotkey.GetTextColor) ~= "function" then return false end
    local ok, r, g, b = pcall(hotkey.GetTextColor, hotkey)
    if not ok then return false end
    r, g, b = tonumber(r), tonumber(g), tonumber(b)
    if not r or not g or not b then return false end
    -- Blizzard's range state paints shortcut text strongly red. Reading the
    -- rendered colour avoids inspecting a protected/secret range boolean.
    return r >= 0.80 and g <= 0.40 and b <= 0.40
end

local function EnsureVisuals(button)
    if not button or button.__ComfyRangeOverlay then return end
    local icon = FindIcon(button)
    if not icon then return end

    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetPoint("TOPLEFT", icon, "TOPLEFT", 0, 0)
    overlay:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
    overlay:SetColorTexture(1, 0.03, 0.03, 1)
    overlay:SetBlendMode("BLEND")
    overlay:Hide()
    button.__ComfyRangeOverlay = overlay

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    border:SetBlendMode("ADD")
    border:SetVertexColor(1, 0.05, 0.05, 0.95)
    border:SetPoint("CENTER", icon, "CENTER", 0, 0)
    border:SetSize((button:GetWidth() or 36) * 1.75, (button:GetHeight() or 36) * 1.75)
    border:Hide()
    button.__ComfyRangeBorder = border
end

local function ResetButton(button)
    if not button then return end
    if button.__ComfyRangeOverlay then button.__ComfyRangeOverlay:Hide() end
    if button.__ComfyRangeBorder then button.__ComfyRangeBorder:Hide() end
end

local function ApplyButton(button)
    if not button or not button:IsShown() then ResetButton(button); return end
    EnsureDefaults()
    local c = CB.db and CB.db.rangeTint
    if not c or not c.enabled then ResetButton(button); return end
    EnsureVisuals(button)
    local out = IsHotKeyRed(button)
    local strength = math.max(0, math.min(100, tonumber(c.strength) or 42)) / 100
    if button.__ComfyRangeOverlay then
        button.__ComfyRangeOverlay:SetAlpha(strength)
        button.__ComfyRangeOverlay:SetShown(out and c.tintIcon ~= false)
    end
    if button.__ComfyRangeBorder then
        button.__ComfyRangeBorder:SetShown(out and c.showBorder == true)
    end
end

function CB:GetRangeTintButtons()
    self.rangeTintButtons = self.rangeTintButtons or {}
    wipe(self.rangeTintButtons)
    local seen = {}
    for _, prefix in ipairs(PREFIXES) do
        for i = 1, 12 do
            local button = _G[prefix .. i]
            if button and not seen[button] then
                seen[button] = true
                self.rangeTintButtons[#self.rangeTintButtons + 1] = button
            end
        end
    end
    return self.rangeTintButtons
end

function CB:RefreshRangeTint()
    if not self.db then return end
    for _, button in ipairs(self:GetRangeTintButtons()) do ApplyButton(button) end
end

local function StartTicker()
    if CB.rangeTintTicker then return end
    local f = CreateFrame("Frame")
    f:SetScript("OnUpdate", function(self, elapsed)
        self.elapsed = (self.elapsed or 0) + (tonumber(elapsed) or 0)
        if self.elapsed < 0.12 then return end
        self.elapsed = 0
        CB:RefreshRangeTint()
    end)
    CB.rangeTintTicker = f
end

local originalRefreshFeature = CB.RefreshFeature
function CB:RefreshFeature(...)
    if originalRefreshFeature then originalRefreshFeature(self, ...) end
    self:RefreshRangeTint()
end

local originalInitializeFeature = CB.InitializeFeature
function CB:InitializeFeature(...)
    if originalInitializeFeature then originalInitializeFeature(self, ...) end
    EnsureDefaults()
    StartTicker()
    self:RefreshRangeTint()
end

local function CreateCheck(parent, text, x, y, getter, setter)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", x, y)
    local label = cb.Text or cb.text
    if label then label:SetText(text) end
    cb:SetChecked(getter() and true or false)
    cb:SetScript("OnClick", function(self)
        setter(self:GetChecked() and true or false)
        CB:RefreshRangeTint()
    end)
    return cb
end

local function CreateStrengthSlider(parent)
    local name = "ComfyBarRangeTintStrength"
    local s = CreateFrame("Slider", name, parent, "OptionsSliderTemplate")
    s:SetPoint("TOPLEFT", 405, -180)
    s:SetWidth(230)
    s:SetMinMaxValues(0, 100)
    s:SetValueStep(5)
    s:SetObeyStepOnDrag(true)
    _G[name .. "Low"]:SetText("0")
    _G[name .. "High"]:SetText("100")
    _G[name .. "Text"]:SetText("Rotfärbung")
    s.valueText = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    s.valueText:SetPoint("LEFT", s, "RIGHT", 10, 0)
    s:SetValue(tonumber(CB.db.rangeTint.strength) or 42)
    s.valueText:SetText(tostring(CB.db.rangeTint.strength or 42) .. "%")
    s:SetScript("OnValueChanged", function(self, value)
        value = math.floor((tonumber(value) or 0) / 5 + 0.5) * 5
        CB.db.rangeTint.strength = value
        self.valueText:SetText(value .. "%")
        CB:RefreshRangeTint()
    end)
    return s
end

local originalInitializeOptions = CB.InitializeOptions
function CB:InitializeOptions(...)
    if originalInitializeOptions then originalInitializeOptions(self, ...) end
    if self.__rangeTintOptionsBuilt or not self.optionsFrame or not self.db then return end
    self.__rangeTintOptionsBuilt = true
    EnsureDefaults()
    local page = self.optionsFrame.pages and self.optionsFrame.pages[1]
    if not page then return end

    local title = page:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 390, -18)
    title:SetText("Reichweitenanzeige")
    local note = page:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    note:SetPoint("TOPLEFT", 390, -48)
    note:SetWidth(325)
    note:SetJustifyH("LEFT")
    note:SetText("Wenn Blizzard den Hotkey wegen Reichweite rot färbt, kann ComfyBar zusätzlich das ganze Icon markieren.")

    CreateCheck(page, "Reichweiten-Markierung", 390, -90,
        function() return CB.db.rangeTint.enabled end,
        function(v) CB.db.rangeTint.enabled = v end)
    CreateCheck(page, "Spell-Icon rot einfärben", 390, -120,
        function() return CB.db.rangeTint.tintIcon end,
        function(v) CB.db.rangeTint.tintIcon = v end)
    CreateCheck(page, "Zusätzlich roten Rahmen", 390, -150,
        function() return CB.db.rangeTint.showBorder end,
        function(v) CB.db.rangeTint.showBorder = v end)
    self.rangeTintStrengthSlider = CreateStrengthSlider(page)
end
