juggernaut_duelist = class({})

function juggernaut_duelist:GetIntrinsicModifierName()
    return "modifier_juggernaut_duelist_ebf"
end

function juggernaut_duelist:GetBehavior()
    return DOTA_ABILITY_BEHAVIOR_PASSIVE
end

modifier_juggernaut_duelist_ebf = class({})
LinkLuaModifier("modifier_juggernaut_duelist_ebf", "heroes/hero_juggernaut/juggernaut_duelist", LUA_MODIFIER_MOTION_NONE)

function modifier_juggernaut_duelist_ebf:IsHidden()
    return true
end

function modifier_juggernaut_duelist_ebf:DeclareFunctions()
    return
    {
        MODIFIER_EVENT_ON_ATTACK,
        MODIFIER_EVENT_ON_ATTACKED
    }
end
function modifier_juggernaut_duelist_ebf:OnCreated()
    self.sohei_duration = self:GetSpecialValueFor("sohei_duration")
    self.ronin_duration = self:GetSpecialValueFor("ronin_duration")
end

function modifier_juggernaut_duelist_ebf:OnAttack(params)
    if IsServer() then
        local parent = self:GetParent()
        local enemy = params.target
        local cdr = self:GetSpecialValueFor("cooldown_reduction")

        if parent:HasModifier("modifier_juggernaut_omni_slash_ebf") then return end
        if parent == params.attacker then
            if cdr ~= 0 then
                parent:AddNewModifier(parent, self:GetAbility(), "modifier_juggernaut_duelist_sohei", {duration = self.sohei_duration})
            else
                enemy:AddNewModifier(parent, self:GetAbility(), "modifier_juggernaut_duelist_ronin_tag", {duration = self.ronin_duration} )
            end
        end
    end
end

function modifier_juggernaut_duelist_ebf:OnAttacked(params)
    if IsServer() then
        local parent = self:GetParent()
        local enemy = params.attacker
        local miss_chance = self:GetSpecialValueFor("miss_chance")

        if parent == params.target then
            if miss_chance ~= 0 then
                enemy:AddNewModifier(parent, self:GetAbility(), "modifier_juggernaut_duelist_ronin", {duration = self.ronin_duration} )
            end
        end
    end
end


--Sohei: Attacking speeds up jugg's cooldowns by 12%
modifier_juggernaut_duelist_sohei = class({})
LinkLuaModifier("modifier_juggernaut_duelist_sohei", "heroes/hero_juggernaut/juggernaut_duelist", LUA_MODIFIER_MOTION_NONE)

function modifier_juggernaut_duelist_sohei:IsHidden()
    return true
end

function modifier_juggernaut_duelist_sohei:IsBuff()
    return true
end

function modifier_juggernaut_duelist_sohei:IsPurgable()
    return false
end

function modifier_juggernaut_duelist_sohei:OnCreated()
    self:OnRefresh()
    self:StartIntervalThink(0)
end

function modifier_juggernaut_duelist_sohei:OnRefresh()
    self.cdr = self:GetSpecialValueFor("cooldown_reduction") / 10000 --idk if i did this right
end

function modifier_juggernaut_duelist_sohei:OnIntervalThink()
    if IsServer() then
        local parent = self:GetParent()
        for i = 0, parent:GetAbilityCount() - 1 do
            local ability = parent:GetAbilityByIndex(i)
            if ability and ability:GetCooldownTimeRemaining() > 0 and ability ~= nil and not ability:IsInnateAbility() then
                ability:ModifyCooldown(-ability:GetCooldownTimeRemaining() * self.cdr)
            end
        end
    end
end

--Ronin: Units that attack you have a 12% chance to miss, which is increased to 24% if Juggernaut damaged the unit within the last 5 seconds.
modifier_juggernaut_duelist_ronin = class({})
LinkLuaModifier("modifier_juggernaut_duelist_ronin", "heroes/hero_juggernaut/juggernaut_duelist", LUA_MODIFIER_MOTION_NONE)

function modifier_juggernaut_duelist_ronin:IsHidden()
    return true
end

function modifier_juggernaut_duelist_ronin:IsDebuff()
    return true
end

function modifier_juggernaut_duelist_ronin:IsPurgable()
    return true
end

function modifier_juggernaut_duelist_ronin:OnCreated()
    self:OnRefresh()
end

function modifier_juggernaut_duelist_ronin:OnRefresh()
    self.miss_chance = self:GetSpecialValueFor("miss_chance")
end

function modifier_juggernaut_duelist_ronin:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_MISS_PERCENTAGE
    }
end

function modifier_juggernaut_duelist_ronin:GetModifierMiss_Percentage()
    return self.miss_chance
end


--tag to identify if enemy wants 24% instead of 12% miss chance lmao
modifier_juggernaut_duelist_ronin_tag = class({})
LinkLuaModifier("modifier_juggernaut_duelist_ronin_tag", "heroes/hero_juggernaut/juggernaut_duelist", LUA_MODIFIER_MOTION_NONE)

function modifier_juggernaut_duelist_ronin_tag:IsHidden()
    return false
end

function modifier_juggernaut_duelist_ronin_tag:IsDebuff()
    return true
end

function modifier_juggernaut_duelist_ronin_tag:IsPurgable()
    return true
end

function modifier_juggernaut_duelist_ronin_tag:OnCreated()
    self:OnRefresh()
end

function modifier_juggernaut_duelist_ronin_tag:OnRefresh()
    self.miss_chance = self:GetSpecialValueFor("miss_chance")
end

function modifier_juggernaut_duelist_ronin_tag:DeclareFunctions()
    return
    {
        MODIFIER_PROPERTY_MISS_PERCENTAGE
    }
end

function modifier_juggernaut_duelist_ronin_tag:GetModifierMiss_Percentage()
    return self.miss_chance
end

function modifier_juggernaut_duelist_ronin_tag:GetTexture()
    return "juggernaut_duelist"
end