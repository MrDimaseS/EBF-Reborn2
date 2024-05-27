skywrath_mage_staff_of_the_scion = class({})

function skywrath_mage_staff_of_the_scion:GetIntrinsicModifierName()
	return "modifier_skywrath_mage_staff_of_the_scion_handler"
end

modifier_skywrath_mage_staff_of_the_scion_handler = class({})
LinkLuaModifier( "modifier_skywrath_mage_staff_of_the_scion_handler","heroes/hero_skywrath_mage/skywrath_mage_staff_of_the_scion.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_skywrath_mage_staff_of_the_scion_handler:OnCreated()
	self.cooldown_reduction = -self:GetSpecialValueFor("cooldown_reduction")
	self.creep_chance = self:GetSpecialValueFor("creep_chance")
end

function modifier_skywrath_mage_staff_of_the_scion_handler:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}
end

function modifier_skywrath_mage_staff_of_the_scion_handler:OnTakeDamage( params )
	if params.attacker == self:GetParent() and params.inflictor then
		if params.attacker:HasAbility( params.inflictor:GetAbilityName() ) then
			if params.unit:IsConsideredHero() or RollPercentage( self.creep_chance ) then
				 for i = 0, params.attacker:GetAbilityCount() - 1 do
					local ability = params.attacker:GetAbilityByIndex( i )
					if ability then
						ability:ModifyCooldown(self.cooldown_reduction)
					end
				end
			end
		end
	end
end

function modifier_skywrath_mage_staff_of_the_scion_handler:IsHidden()
	return self:GetStackCount() <= 0
end

function modifier_skywrath_mage_staff_of_the_scion_handler:DestroyOnExpire()
	return false
end

function modifier_skywrath_mage_staff_of_the_scion_handler:IsPurgable()
	return false
end

function modifier_skywrath_mage_staff_of_the_scion_handler:IsPermanent()
	return true
end