item_mind_breaker = class({})

function item_mind_breaker:ShouldUseResources()
	return true
end

function item_mind_breaker:GetIntrinsicModifierName()
	return "modifier_item_mind_breaker_passive"
end

modifier_item_mind_breaker_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_mind_breaker_passive", "items/item_mind_breaker.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_mind_breaker_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_mind_breaker_passive:OnRefresh()
	self.magic_damage = self:GetSpecialValueFor("magic_damage")
	self.attack_speed = self:GetSpecialValueFor("attack_speed")
	
	self.duration = self:GetSpecialValueFor("duration")
end

function modifier_item_mind_breaker_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_MAGICAL,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,				
			MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_item_mind_breaker_passive:GetModifierProcAttack_BonusDamage_Magical()
	return self.magic_damage
end

function modifier_item_mind_breaker_passive:GetModifierAttackSpeedBonus_Constant()
	return self.attack_speed
end

function modifier_item_mind_breaker_passive:OnAttackLanded( params )
	local parent = self:GetParent()
	if params.attacker ~= parent then return end
	local ability = self:GetAbility()
	if not ability:IsCooldownReady() then return end
	ability:SetCooldown()
	ability:Silence(params.target, self.duration)
	ParticleManager:FireParticle( "particles/econ/items/antimage/antimage_weapon_basher_ti5/am_basher.vpcf", PATTACH_POINT_FOLLOW, params.target )
end