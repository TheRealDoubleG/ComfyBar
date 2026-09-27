ComfyBar = ComfyBar or {}\nlocal CB = ComfyBar

local function HubWantsBundled()
    local hub = rawget(_G, "ComfyHub")
    if type(hub) ~= "table" then return false end

    if type(hub.IsMinimapBundlingActive) == "function" then
        local ok, bundled = pcall(hub.IsMinimapBundlingActive, hub)
        if ok then return bundled and true or false end
    end

    return hub.db
        and hub.db.minimap
        and hub.db.minimap.show
        and hub.db.minimap.bundleSuiteIcons ~= false
end

local function GetButtonRadius(button)
    if not Minimap then return 95 end
    local width = Minimap:GetWidth() or 140
    local height = Minimap:GetHeight() or width
    local mapRadius = math.min(width, height) / 2
    local buttonRadius = ((button and button:GetWidth()) or 32) / 2
    return mapRadius + buttonRadius + 2
end

local function PositionFromAngle(button, angle)
    if not Minimap then return end
    local radians = math.rad(angle or 220)
    local radius = GetButtonRadius(button)
    local x = math.cos(radians) * radius
    local y = math.sin(radians) * radius
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

function CB:SetMinimapBundled(bundled)
    self.minimapBundled = bundled and true or false
    if self.minimapButton and self.db then
        self:UpdateMinimapPosition()
    end
end

function CB:ShouldShowMinimapButton()
    if not self.db or not self.db.minimap then return false end
    return self.db.minimap.show and not self.minimapBundled and not HubWantsBundled()
end

function CB:UpdateMinimapPosition()
    if not self.minimapButton or not self.db then return end
    PositionFromAngle(self.minimapButton, self.db.minimap.angle)
    self.minimapButton:SetShown(self:ShouldShowMinimapButton())
end

function CB:UpdateMinimapAppearance()
    if not self.minimapButton then return end
    if self.db and self.db.enabled then
        self.minimapButton.icon:SetDesaturated(false)
        self.minimapButton.icon:SetVertexColor(1, 1, 1)
    else
        self.minimapButton.icon:SetDesaturated(true)
        self.minimapButton.icon:SetVertexColor(0.65, 0.65, 0.65)
    end
end

function CB:InitializeMinimap()
    if self.minimapButton or not Minimap then return end

    local button = CreateFrame("Button", "ComfyBarMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    background:SetSize(20, 20)
    background:SetPoint("CENTER")

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)

    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then
            CB:ToggleEnabled()
        elseif mouseButton == "RightButton" then
            CB:OpenOptions()
        end
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("ComfyBar", 1, 0.82, 0)
        GameTooltip:AddLine(CB.db.enabled and CB:T("ACTIVE") or CB:T("INACTIVE"), CB.db.enabled and 0.2 or 1, CB.db.enabled and 1 or 0.3, 0.2)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine(CB:T("MINIMAP_LEFT"), 1, 1, 1)
        GameTooltip:AddLine(CB:T("MINIMAP_RIGHT"), 1, 1, 1)
        GameTooltip:AddLine(CB.db.minimap.locked and CB:T("MINIMAP_LOCKED") or CB:T("MINIMAP_DRAG"), 0.7, 0.7, 0.7)
        GameTooltip:Show()
    end)

    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    button:SetScript("OnDragStart", function(self)
        if CB.db.minimap.locked then return end
        self:SetScript("OnUpdate", function(btn)
            local mx, my = Minimap:GetCenter()
            local cx, cy = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            if scale and scale > 0 then
                cx, cy = cx / scale, cy / scale
                CB.db.minimap.angle = math.deg(math.atan2(cy - my, cx - mx))
                PositionFromAngle(btn, CB.db.minimap.angle)
            end
        end)
    end)

    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    self.minimapButton = button
    self.minimapBundled = HubWantsBundled()
    self:UpdateMinimapPosition()
    self:UpdateMinimapAppearance()\nend
