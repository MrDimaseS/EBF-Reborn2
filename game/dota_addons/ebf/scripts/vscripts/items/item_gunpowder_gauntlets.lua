item_gunpowder_gauntlets = class({})

function item_gunpowder_gauntlets:GetIntrinsicModifierName()
	return "modifier_item_gunpowder_gauntlets_passive"
end

modifier_item_gunpowder_gauntlets_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_gunpowder_gauntlets_passive", "items/item_gunpowder_gauntlets.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_gunpowder_gauntlets_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_gunpowder_gauntlets_passive:OnRefresh()
	self.bonus_attack_damage = self:GetSpecialValueFor("bonus_attack_damage")
	self.bonus_health = self:GetSpecialValueFor("bonus_health")
	
	self.hero_attack_cdr = -self:GetSpecialValueFor("hero_attack_cdr")
	self.creep_attack_cdr = -self:GetSpecialValueFor("creep_attack_cdr")
	
	self.splash_radius = self:GetSpecialValueFor("splash_radius")
	self.splash_pct = self:GetSpecialValueFor("splash_pct") / 100
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
end

function modifier_item_gunpowder_gauntlets_passive:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			 MODIFIER_PROPERTY_HEALTH_BONUS,
			 MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_item_gunpowder_gauntlets_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_attack_damage
end

function modifier_item_gunpowder_gauntlets_passive:GetModifierHealthBonus()
	return self.bonus_health
end

function modifier_item_gunpowder_gauntlets_passive:OnAttackLanded( params )
	local parent = self:GetParent()
	if not (params.attacker == parent or params.target == parent) then return end
	if params.attacker == parent then
		local ability = self:GetAbility()
		if not ability:IsCooldownReady() then return end
		ability:SetCooldown()
		EmitSoundOn( "Item.BlackPowder", params.target )
		ParticleManager:FireParticle("particles/items4_fx/gunpowder_gauntlets.vpcf", PATTACH_POINT_FOLLOW, params.target )
		for _, enemy in ipairs( parent:FindEnemyUnitsInRadius( params.target:GetAbsOrigin(), self.splash_radius ) ) do
			if enemy ~= params.target then
				ability:DealDamage( parent, enemy, params.original_damage * self.splash_pct, {damage_type = DAMAGE_TYPE_MAGICAL, damage_flags = DOTA_DAMAGE_FLAG_ATTACK_MODIFIER + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION } )
			end
			ability:DealDamage( parent, enemy, self.bonus_damage, {damage_type = DAMAGE_TYPE_MAGICAL} )
		end
	elseif params.target == parent then
		if ability:IsCooldownReady() then return end
		ability:ModifyCooldown( TernaryOperator( self.hero_attack_cdr, params.attacker:IsConsideredHero(), self.creep_attack_cdr ) )
	end
end