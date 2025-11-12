muerta_pierce_the_veil = class({})

function muerta_pierce_the_veil:GetIntrinsicModifierName()
    return "modifier_muerta_shard_ebf"
end

function muerta_pierce_the_veil:OnSpellStart()
    local caster = self:GetCaster()
    local duration = self:GetSpecialValueFor("duration")
    local transformation_duration = self:GetSpecialValueFor("transformation_duration")

    caster:AddNewModifier(caster, self, "modifier_muerta_pierce_the_veil_transform", {duration = transformation_duration})
    Timers:CreateTimer(transformation_duration, function()
        caster:AddNewModifier(caster, self, "modifier_muerta_pierce_the_veil", {duration = duration})
        caster:AddNewModifier(caster, self, "modifier_muerta_pierce_the_veil_buff", {duration = duration})
        caster:AddNewModifier(caster, self, "modifier_muerta_pierce_the_veil_magic_immunity_damage_cancel", {duration = duration})
    end)
    EmitSoundOn("Hero_Muerta.PierceTheVeil.Cast", caster)
end

modifier_muerta_shard_ebf = class({})
LinkLuaModifier("modifier_muerta_shard_ebf", "heroes/hero_muerta/muerta_pierce_the_veil", LUA_MODIFIER_MOTION_NONE)

function modifier_muerta_shard_ebf:IsHidden()
    return false
end

function modifier_muerta_shard_ebf:OnCreated()
    self:OnRefresh()
end

function modifier_muerta_shard_ebf:OnRefresh()
    self.spell_lifesteal = self:GetSpecialValueFor("spell_lifesteal") / 100
    self.spell_amp_steal = self:GetSpecialValueFor("spell_amp_steal")
    self.spell_amp_steal_range = self:GetSpecialValueFor("spell_amp_steal_range")

    self:GetParent()._spellLifestealModifiersList = self:GetParent()._spellLifestealModifiersList or {}
	self:GetParent()._spellLifestealModifiersList[self] = true

    if IsServer() then self:SendBuffRefreshToClients() end
end

function modifier_muerta_shard_ebf:OnDeath(params)
    local caster = self:GetCaster()
    if not caster:IsSameTeam( params.unit ) and ( params.attacker == caster or CalculateDistance( caster, params.unit ) <= self.spell_amp_steal_range ) and caster:HasModifier("modifier_muerta_pierce_the_veil") then
        if params.unit:IsConsideredHero() then
            self:IncrementStackCount()
        end
    end
end

function modifier_muerta_shard_ebf:DeclareFunctions()
    return {MODIFIER_EVENT_ON_DEATH, MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE}
end

function modifier_muerta_shard_ebf:GetModifierProperty_MagicalLifesteal(params)
    if self:GetParent():HasModifier("modifier_muerta_pierce_the_veil") then
	    return self.spell_lifesteal
    end
end

function modifier_muerta_shard_ebf:GetModifierSpellAmplify_Percentage()
    return self.spell_amp_steal * self:GetStackCount()
end