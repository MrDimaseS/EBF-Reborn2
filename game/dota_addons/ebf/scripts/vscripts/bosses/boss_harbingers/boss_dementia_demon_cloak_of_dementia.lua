boss_dementia_demon_cloak_of_dementia = class({})

function boss_dementia_demon_cloak_of_dementia:GetIntrinsicModifierName()
	return "modifier_boss_dementia_demon_cloak_of_dementia"
end

modifier_boss_dementia_demon_cloak_of_dementia = class({})
LinkLuaModifier( "modifier_boss_dementia_demon_cloak_of_dementia", "bosses/boss_harbingers/boss_dementia_demon_cloak_of_dementia", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_dementia_demon_cloak_of_dementia:OnCreated()
	self:OnRefresh()
end

function modifier_boss_dementia_demon_cloak_of_dementia:OnRefresh()
	self.mania_damage_pct = self:GetSpecialValueFor("mania_damage_pct") / 100
end

function modifier_boss_dementia_demon_cloak_of_dementia:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE}
end

function modifier_boss_dementia_demon_cloak_of_dementia:GetModifierIncomingDamage_Percentage( params )
	if self:GetParent():PassivesDisabled() then return end
	if HasBit(params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS) or HasBit(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION) then return end
	if params.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK then return end
	if params.target ~= self:GetParent() then return end
	
	local parent = self:GetParent()
	local ability = self:GetAbility()
	for _, demon in ipairs( parent:FindFriendlyUnitsInRadius( parent:GetAbsOrigin(), -1, {order = FIND_NEAREST} ) ) do
		if demon:GetUnitName() == "npc_dota_boss_mania_demon" then
			local damage_split = params.damage
			local enemies = parent:FindAllUnitsInRadius( parent:GetAbsOrigin(), -1 )
			local unitCount = 0
			for _, enemy in ipairs( enemies ) do
				if not (enemy == demon or enemy == parent) then
					unitCount = unitCount + 1
				end
			end
			ability:DealDamage( params.attacker, demon, params.damage * self.mania_damage_pct, {damage_type = params.damage_type, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_REFLECTION} )
			ParticleManager:FireRopeParticle( "particles/units/heroes/hero_shadow_demon/shadow_demon_disseminate.vpcf", PATTACH_POINT_FOLLOW, parent, demon )
			for _, enemy in ipairs( enemies ) do
				if not (enemy == demon or enemy == parent) then
					ability:DealDamage( parent, enemy, (damage_split * (1-self.mania_damage_pct)) / unitCount, {damage_type = params.damage_type, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_REFLECTION} )
					ParticleManager:FireRopeParticle( "particles/units/heroes/hero_shadow_demon/shadow_demon_disseminate.vpcf", PATTACH_POINT_FOLLOW, demon, enemy )
				end
			end
			return -999
		end
	end
end