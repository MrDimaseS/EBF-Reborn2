nevermore_shadowraze = class({})

function nevermore_shadowraze:GetAOERadius()
    return self:GetSpecialValueFor("shadowraze_range")
end
function nevermore_shadowraze:OnSpellStart()
    if IsClient() then return end

    local caster = self:GetCaster();
    local shadowraze_range = self:GetSpecialValueFor("shadowraze_range")
    local shadowraze_radius = self:GetSpecialValueFor("shadowraze_radius")
    local duration = self:GetSpecialValueFor("duration")
    local offset = caster:GetForwardVector() * shadowraze_range;
    local position = caster:GetAbsOrigin() + offset;

	local damage = self:GetSpecialValueFor("shadowraze_damage")
    for _,unit in ipairs( caster:FindEnemyUnitsInRadius( position, shadowraze_radius ) ) do
        if self:GetSpecialValueFor("does_attack") ~= 0 then
            unit:AddNewModifier(caster, self, "modifier_nevermore_shadowraze_armor_reduction", { duration = duration })
            caster:PerformGenericAttack(unit, true, false, damage)
            -- deal some damage so that necromastery knows we razed
            self:DealDamage(caster, unit, 10)
        else
            if self:GetSpecialValueFor("attack_speed_reduction") ~= 0 then
                unit:AddNewModifier(caster, self, "modifier_nevermore_shadowraze_slow", { duration = duration })
            end
            if self:GetSpecialValueFor("stack_bonus_damage") ~= 0 then
				unit:AddNewModifier(caster, self, "modifier_nevermore_shadowraze_stack", { duration = duration })
            end
            self:DealDamage(caster, unit, damage)
        end
    end

    -- create the particle and sound
    local particle = ParticleManager:CreateParticle(
        "particles/units/heroes/hero_nevermore/nevermore_shadowraze.vpcf",
        PATTACH_ABSORIGIN,
        caster
    )
    ParticleManager:SetParticleControl(particle, 0, position)
    ParticleManager:ReleaseParticleIndex(particle)
	EmitSoundOnLocationWithCaster(position, "Hero_Nevermore.Shadowraze", caster)
end

nevermore_shadowraze1 = class(nevermore_shadowraze)
nevermore_shadowraze2 = class(nevermore_shadowraze)
nevermore_shadowraze3 = class(nevermore_shadowraze)

modifier_nevermore_shadowraze_stack = class({})
LinkLuaModifier("modifier_nevermore_shadowraze_stack", "heroes/hero_shadow_fiend/nevermore_shadowraze.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_nevermore_shadowraze_stack:OnCreated()
	self:OnRefresh()
end

function modifier_nevermore_shadowraze_stack:OnRefresh()
	self.stack_bonus_damage = self:GetSpecialValueFor("stack_bonus_damage")
	if IsServer() then
		self:IncrementStackCount()
	end
end

function modifier_nevermore_shadowraze_stack:IsDebuff()
    return true
end
function modifier_nevermore_shadowraze_stack:IsPurgable()
    return true
end
function modifier_nevermore_shadowraze_stack:DeclareFunctions()
    return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end
function modifier_nevermore_shadowraze_stack:GetModifierIncomingDamage_Percentage(params)
	if IsServer() then
		if params.attacker == self:GetCaster() and params.inflictor and params.attacker:HasAbility( params.inflictor:GetAbilityName() ) then
			return self.stack_bonus_damage * self:GetStackCount()
		end
	else
		return self.stack_bonus_damage * self:GetStackCount()
	end
end

function modifier_nevermore_shadowraze_stack:GetEffectName()
    return "particles/units/heroes/hero_nevermore/nevermore_shadowraze_debuff.vpcf"
end

modifier_nevermore_shadowraze_slow = class({})
LinkLuaModifier("modifier_nevermore_shadowraze_slow", "heroes/hero_shadow_fiend/nevermore_shadowraze.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_nevermore_shadowraze_slow:IsDebuff()
    return true
end
function modifier_nevermore_shadowraze_slow:IsPurgable()
    return true
end
function modifier_nevermore_shadowraze_slow:OnCreated()
    self:OnRefresh()
end
function modifier_nevermore_shadowraze_slow:OnRefresh()
    self.attack_speed_reduction = self:GetSpecialValueFor("attack_speed_reduction")
end
function modifier_nevermore_shadowraze_slow:DeclareFunctions()
    return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end
function modifier_nevermore_shadowraze_slow:GetModifierAttackSpeedBonus_Constant()
    return self.attack_speed_reduction
end
function modifier_nevermore_shadowraze_slow:GetEffectName()
    return "particles/units/heroes/hero_nevermore/nevermore_shadowraze_debuff.vpcf"
end

modifier_nevermore_shadowraze_armor_reduction = class({})
LinkLuaModifier("modifier_nevermore_shadowraze_armor_reduction", "heroes/hero_shadow_fiend/nevermore_shadowraze.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_nevermore_shadowraze_armor_reduction:IsDebuff()
    return true
end
function modifier_nevermore_shadowraze_armor_reduction:IsPurgable()
    return true
end
function modifier_nevermore_shadowraze_armor_reduction:OnCreated()
    self:OnRefresh()
end
function modifier_nevermore_shadowraze_armor_reduction:OnRefresh()
    self.armor_reduction = self:GetSpecialValueFor("armor_reduction")
end
function modifier_nevermore_shadowraze_armor_reduction:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS
    }
end
function modifier_nevermore_shadowraze_armor_reduction:GetModifierPhysicalArmorBonus()
    return self.armor_reduction
end
function modifier_nevermore_shadowraze_armor_reduction:GetEffectName()
    return "particles/units/heroes/hero_nevermore/nevermore_shadowraze_debuff.vpcf"
end