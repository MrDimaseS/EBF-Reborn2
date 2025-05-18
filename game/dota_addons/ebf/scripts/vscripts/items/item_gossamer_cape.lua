item_gossamer_cape = class({})

function item_gossamer_cape:GetIntrinsicModifierName()
	return "modifier_item_gossamer_cape_passive"
end

modifier_item_gossamer_cape_passive = class({})
LinkLuaModifier( "modifier_item_gossamer_cape_passive", "items/item_gossamer_cape.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_gossamer_cape_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_gossamer_cape_passive:OnRefresh()
	self.movement_speed = self:GetSpecialValueFor("movement_speed")
	self.creep_attacks = self:GetSpecialValueFor("creep_attacks")
	self.bonus_agility = self:GetSpecialValueFor("bonus_agility")
	self.bonus_intellect = self:GetSpecialValueFor("bonus_intellect")
	if IsServer() then
		self:StartIntervalThink(0.1)
	end
end

function modifier_item_gossamer_cape_passive:OnIntervalThink()
	local ability = self:GetAbility()
	if ability:GetCooldownTimeRemaining() > 0 then
	else
		self:StartIntervalThink( -1 )
		self:SetStackCount( self.creep_attacks )
		self.nFX = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_blur.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
	end
end

function modifier_item_gossamer_cape_passive:OnDestroy()
	if IsServer() then
		ParticleManager:ClearParticle(self.nFX, true)
	end
end

function modifier_item_gossamer_cape_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_EVASION_CONSTANT,
			}
end


function modifier_item_gossamer_cape_passive:GetModifierBonusStats_Strength()
	return self.bonus_agility
end

function modifier_item_gossamer_cape_passive:GetModifierBonusStats_Agility()
	return self.bonus_intellect
end

function modifier_item_gossamer_cape_passive:GetModifierEvasion_Constant( params )
	if self:GetStackCount() <= 0 then return end
	if not params.attacker then return 100 end
	if params.attacker:IsConsideredHero() then
		self:SetStackCount( 0 )
	else
		self:DecrementStackCount()
	end
	if self:GetStackCount() <= 0 then
		self:GetAbility():SetCooldown()
		self:StartIntervalThink( 0.1 )
		ParticleManager:ClearParticle(self.nFX, true)
	end
	return 100
end

function modifier_item_gossamer_cape_passive:GetModifierMoveSpeedBonus_Constant()
	return self.movement_speed
end

function modifier_item_gossamer_cape_passive:IsHidden()
	return self:GetStackCount() <= 0
end