boss_troll_warlord_battle_trance = class({})

function boss_troll_warlord_battle_trance:OnSpellStart()
	local caster = self:GetCaster()
	
	local duration = self:GetSpecialValueFor("duration")
	caster:AddNewModifier( caster, self, "modifier_boss_troll_warlord_battle_trance", {duration = duration})
	caster:StartGesture(ACT_DOTA_CAST_ABILITY_4)
	caster:EmitSound("Hero_TrollWarlord.BattleTrance.Cast")
	caster:Dispel( caster, true )
	ParticleManager:FireParticle("particles/units/heroes/hero_troll_warlord/troll_warlord_battletrance_cast.vpcf", PATTACH_POINT_FOLLOW, caster)
end

modifier_boss_troll_warlord_battle_trance = class({})
LinkLuaModifier( "modifier_boss_troll_warlord_battle_trance", "bosses/boss_troll_warlord/boss_troll_warlord_battle_trance", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_troll_warlord_battle_trance:OnCreated()
	self:OnRefresh()
end

function modifier_boss_troll_warlord_battle_trance:OnRefresh()
	self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	self.bonus_lifesteal = self:GetSpecialValueFor("bonus_lifesteal") / 100
end

function modifier_boss_troll_warlord_battle_trance:CheckState()
	return {[MODIFIER_STATE_SILENCED] = true}
end

function modifier_boss_troll_warlord_battle_trance:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_EVENT_ON_TAKEDAMAGE,
			MODIFIER_PROPERTY_MIN_HEALTH }
end

function modifier_boss_troll_warlord_battle_trance:GetMinHealth()
	return 1
end

function modifier_boss_troll_warlord_battle_trance:OnTakeDamage(params)
	if params.attacker == self:GetParent() and self:GetParent():GetHealth() > 0 then
		local flHeal = params.damage * self.bonus_lifesteal
		params.attacker:HealEvent(flHeal, self:GetAbility(), params.attacker)
	end
end

function modifier_boss_troll_warlord_battle_trance:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

function modifier_boss_troll_warlord_battle_trance:GetEffectName()
	return "particles/units/heroes/hero_troll_warlord/troll_warlord_battletrance_buff.vpcf"
end

function modifier_boss_troll_warlord_battle_trance:GetStatusEffectName()
	return "particles/status_fx/status_effect_troll_warlord_battletrance.vpcf"
end

function modifier_boss_troll_warlord_battle_trance:StatusEffectPriority()
	return 20
end