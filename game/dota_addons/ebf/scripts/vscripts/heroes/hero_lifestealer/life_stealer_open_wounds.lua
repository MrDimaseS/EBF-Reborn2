life_stealer_open_wounds = class({})

function life_stealer_open_wounds:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
    
    EmitSoundOn("Hero_LifeStealer.OpenWounds.Cast", target)
	if target:TriggerSpellAbsorb( self ) then return end
    target:AddNewModifier(caster, self, "modifier_life_stealer_open_wounds_debuff", {Duration = self:GetTalentSpecialValueFor("duration")})
end

modifier_life_stealer_open_wounds_debuff = class({})
LinkLuaModifier( "modifier_life_stealer_open_wounds_debuff", "heroes/hero_lifestealer/life_stealer_open_wounds.lua" ,LUA_MODIFIER_MOTION_NONE )
function modifier_life_stealer_open_wounds_debuff:OnCreated(table)
	self.slow = self:GetTalentSpecialValueFor("slow_tooltip")
	self.spread_radius = self:GetTalentSpecialValueFor("spread_radius")
	self.heal_percent = self:GetTalentSpecialValueFor("heal_percent") / 100
	self.damage_threshold = self:GetTalentSpecialValueFor("damage_threshold") / 100
	self.damage_counter = 0
	self.slow_decay = ( self.slow / self:GetRemainingTime() ) * 0.5
    self:StartIntervalThink(0.5)
end

function modifier_life_stealer_open_wounds_debuff:OnIntervalThink()
	self.slow = self.slow - self.slow_decay
end

function modifier_life_stealer_open_wounds_debuff:DeclareFunctions()
    funcs = {
                MODIFIER_EVENT_ON_TAKEDAMAGE,
                MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
            }
    return funcs
end

function modifier_life_stealer_open_wounds_debuff:OnTakeDamage(params)
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if params.attacker:IsSameTeam( caster ) then
		ParticleManager:FireParticle("particles/units/heroes/hero_life_stealer/life_stealer_open_wounds_impact.vpcf", PATTACH_POINT, self:GetCaster(), {[0]=params.unit:GetAbsOrigin()})
		local heal = params.damage * self.heal_percent
		params.attacker:HealEvent(heal, ability, caster, false)

		self.damage_counter = self.damage_counter + params.damage
		if self.damage_counter >= params.unit:GetMaxHealth() * self.damage_threshold then
			for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( params.unit:GetAbsOrigin(), self.spread_radius ) ) do
				if not enemy:HasModifier( "modifier_life_stealer_open_wounds_debuff" then
					enemy:AddNewModifier(caster, ability, "modifier_life_stealer_open_wounds_debuff", { Duration = self:GetRemainingTime() })
				end
			end
		end
	end
end

function modifier_life_stealer_open_wounds_debuff:GetModifierMoveSpeedBonus_Percentage()
    return self.slow
end

function modifier_life_stealer_open_wounds_debuff:IsDebuff()
    return true
end

function modifier_life_stealer_open_wounds_debuff:GetEffectName()
    return "particles/units/heroes/hero_life_stealer/life_stealer_open_wounds.vpcf"
end

function modifier_life_stealer_open_wounds_debuff:GetStatusEffectName()
    return "particles/status_fx/status_effect_life_stealer_open_wounds.vpcf"
end

function modifier_life_stealer_open_wounds_debuff:StatusEffectPriority()
    return 10
end