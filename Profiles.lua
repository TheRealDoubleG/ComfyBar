ComfyBar = ComfyBar or {}
local CB = ComfyBar

CB.profileOrder = {"Minimal", "Bevorzugt", "Komplett"}

CB.builtinProfiles = {
    Minimal = {
        consumables = true,
        buffs = true,
        utility = true,
        professions = false,
        racials = false,
    },
    ["Bevorzugt"] = {
        consumables = true,
        buffs = true,
        utility = true,
        professions = false,
        racials = true,
    },
    ["Komplett"] = {
        consumables = true,
        buffs = true,
        utility = true,
        professions = true,
        racials = true,
    },
}

function CB:ApplyProfile(name)
    if InCombatLockdown and InCombatLockdown() then
        self:Print(self:T("COMBAT_LOCK"))
        return false
    end

    local profile = self.builtinProfiles[name]
    if not profile or not self.db then return false end

    for key, visible in pairs(profile) do
        if self.db.bars[key] then
            self.db.bars[key].enabled = visible and true or false
        end
    end

    self.db.selectedProfile = name
    if self.RefreshBars then self:RefreshBars() end
    if self.RefreshOptions then self:RefreshOptions() end
    return true
end
