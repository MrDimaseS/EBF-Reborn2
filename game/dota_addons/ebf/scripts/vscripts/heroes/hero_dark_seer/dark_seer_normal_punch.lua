dark_seer_normal_punch = class({})

function dark_seer_normal_punch:Precache( context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_dark_seer.vsndevts", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_dark_seer/dark_seer_attack_normal_punch.vpcf", context )
end

function dark_seer_normal_punch:ShouldUseResources()
	return true
end

function dark_seer_normal_punch:GetIntrinsicModifierName()
	return "modifier_dark_seer_normal_punch_thinker"
end

modifier_dark_seer_normal_punch_thinker = class({})
LinkLuaModifier( "modifier_dark_seer_normal_punch_thinker", "heroes/hero_dark_seer/dark_seer_normal_punch", LUA_MODIFIER_MOTION_NONE )

function modifier_dark_seer_normal_punch_thinker:OnCreated( kv )
	self:OnRefresh()
end
function modifier_dark_seer_normal_punch_thinker:OnRefresh( kv )
	self.max_stun = self:GetSpecialValueFor("max_stun")
	self.knockback_distance = self:GetSpecialValueFor("knockback_distance")
	self.normal_punch_illusion_delay = self:GetSpecialValueFor("normal_punch_illusion_delay")
	self.max_damage = self:GetSpecialValueFor("max_damage")
end

function modifier_dark_seer_normal_punch_thinker:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_START,
			MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_dark_seer_normal_punch_thinker:OnAttackStart( params )
	if params.attacker == self:GetCaster() and self:GetAbility():IsCooldownReady() and not self:GetAbility():IsHidden() then
		params.attacker:AddNewModifier( params.attacker, self:GetAbility(), "modifier_special_bonus_truestrike", {} )
	end
end

function modifier_dark_seer_normal_punch_thinker:OnAttackLanded( params )
	if params.attacker == self:GetCaster() and self:GetAbility():IsCooldownReady() and not self:GetAbility():IsHidden() then
		local ability = self:GetAbility()
		params.attacker:RemoveModifierByName( "modifier_special_bonus_truestrike" )
		
		ability:Stun(params.target, self.max_stun)
		params.target:ApplyKnockBack( params.attacker:GetAbsOrigin(), self.normal_punch_illusion_delay, self.normal_punch_illusion_delay, self.knockback_distance, 0, params.attacker, ability)
		ability:DealDamage( params.attacker, params.target, self.max_damage )
		
		EmitSoundOn( "Hero_Dark_Seer.NormalPunch.Lv3", params.target )
		
		ParticleManager:FireParticle( "particles/units/heroes/hero_dark_seer/dark_seer_attack_normal_punch.vpcf", PATTACH_POINT_FOLLOW, params.attacker )
		ability:SetCooldown()
	end
end

function modifier_dark_seer_normal_punch_thinker:IsHidden()
	return true
end