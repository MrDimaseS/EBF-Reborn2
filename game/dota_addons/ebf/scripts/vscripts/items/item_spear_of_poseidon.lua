item_spear_of_poseidon = class({})

function item_spear_of_poseidon:GetIntrinsicModifierName()
	return "modifier_item_spear_of_poseidon_passive"
end

function item_spear_of_poseidon:ShouldUseResources()
	return true
end

function item_spear_of_poseidon:OnProjectileHit( target, position )
	local caster = self:GetCaster()
	if IsEntitySafe( target ) then
		self:DealDamage( caster, target, caster:GetHealth() * self:GetSpecialValueFor("wave_damage") / 100, {damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION } )
		target:Root( target, self:GetSpecialValueFor("root_duration") )
		EmitSoundOn( "Hero_Tidehunter.Gush.AghsProjectile", target )
	end
end

modifier_item_spear_of_poseidon_passive = class({})
LinkLuaModifier( "modifier_item_spear_of_poseidon_passive", "items/item_spear_of_poseidon.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_spear_of_poseidon_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_spear_of_poseidon_passive:OnRefresh()
	self.bonus_all = self:GetSpecialValueFor("bonus_all")
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	
	self.wave_distance = self:GetSpecialValueFor("wave_distance")
	self.wave_speed = self:GetSpecialValueFor("wave_speed")
	self.wave_radius = self:GetSpecialValueFor("wave_radius")
end

function modifier_item_spear_of_poseidon_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_EVENT_ON_ATTACK }
end

function modifier_item_spear_of_poseidon_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_spear_of_poseidon_passive:GetModifierBonusStats_Strength()
	return self.bonus_all
end

function modifier_item_spear_of_poseidon_passive:GetModifierBonusStats_Agility()
	return self.bonus_all
end

function modifier_item_spear_of_poseidon_passive:GetModifierBonusStats_Intellect()
	return self.bonus_all
end

function modifier_item_spear_of_poseidon_passive:OnAttack( params )
	local parent = self:GetParent()
	if params.attacker ~= parent then return end
	if params.attacker:IsMuted() then return end
	local ability = self:GetAbility()
	if not ability:IsFullyCastable() then return end
	if not ability:IsCooldownReady() then return end
	ability:SetCooldown()
	ability:FireLinearProjectile("particles/units/heroes/hero_tidehunter/tidehunter_gush_upgrade.vpcf", CalculateDirection( params.target, params.attacker ) * self.wave_speed, self.wave_distance, self.wave_radius / 2)
	EmitSoundOn( "Ability.GushCast", parent )
end

function modifier_item_spear_of_poseidon_passive:IsHidden()
	return true
end

function modifier_item_spear_of_poseidon_passive:IsPurgable()
	return false
end

function modifier_item_spear_of_poseidon_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end