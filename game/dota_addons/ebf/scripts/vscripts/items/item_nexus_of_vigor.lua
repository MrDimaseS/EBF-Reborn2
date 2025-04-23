item_nexus_of_vigor = class({})

function item_nexus_of_vigor:GetIntrinsicModifierName()
	return "modifier_item_nexus_of_vigor_passive"
end

modifier_item_nexus_of_vigor_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_nexus_of_vigor_passive", "items/item_nexus_of_vigor.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_nexus_of_vigor_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_nexus_of_vigor_passive:OnRefresh()
	self.bonus_strength = self:GetSpecialValueFor("bonus_strength")
	self.incoming_heal_amp = self:GetSpecialValueFor("incoming_heal_amp")
	self.overheal_damage = self:GetSpecialValueFor("overheal_damage") / 100
	self.damage_radius = self:GetSpecialValueFor("damage_radius")
end

function modifier_item_nexus_of_vigor_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
			MODIFIER_EVENT_ON_HEAL_RECEIVED }
end

function modifier_item_nexus_of_vigor_passive:GetModifierBonusStats_Strength()
	return self.bonus_strength
end

function modifier_item_nexus_of_vigor_passive:GetModifierHealAmplify_PercentageSource()
	return self.incoming_heal_amp
end

function modifier_item_nexus_of_vigor_passive:OnHealReceived( params )
	local parent = self:GetParent()
	if not params.inflictor then return end -- no health regen
	if params.fail_type == 0 then return end -- no lifesteal
	if params.unit ~= parent then return end
	local overheal = (params.gain - parent:GetHealthDeficit()) * self.overheal_damage
	if overheal > 0 then
		local ability = self:GetAbility()
		for _, enemy in ipairs( parent:FindEnemyUnitsInRadius( parent:GetAbsOrigin(), self.damage_radius ) ) do
			ability:DealDamage( parent, enemy, overheal, {damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL } )
			ParticleManager:FireRopeParticle( "particles/items/nexus_of_vigor_overheal.vpcf", PATTACH_POINT_FOLLOW, parent, enemy )
		end
	end
end