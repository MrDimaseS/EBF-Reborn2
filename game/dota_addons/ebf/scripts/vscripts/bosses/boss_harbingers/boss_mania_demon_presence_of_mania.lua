boss_mania_demon_presence_of_mania = class({})

function boss_mania_demon_presence_of_mania:GetIntrinsicModifierName()
	return "modifier_boss_mania_demon_presence_of_mania"
end

modifier_boss_mania_demon_presence_of_mania = class({})
LinkLuaModifier( "modifier_boss_mania_demon_presence_of_mania", "bosses/boss_harbingers/boss_mania_demon_presence_of_mania", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_mania_demon_presence_of_mania:OnCreated()
	self:OnRefresh()
end

function modifier_boss_mania_demon_presence_of_mania:OnRefresh()
	self.presence_radius = self:GetSpecialValueFor("presence_radius")
	self.dmg_per_stack = self:GetSpecialValueFor("dmg_per_stack")
	self.spell_stacks = self:GetSpecialValueFor("spell_stacks")
	self.max_stacks = self:GetSpecialValueFor("max_stacks")
end

function modifier_boss_mania_demon_presence_of_mania:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_boss_mania_demon_presence_of_mania:GetModifierPreAttack_BonusDamage()
	if self:GetParent():PassivesDisabled() then return end
	return self.dmg_per_stack * math.min( self:GetStackCount(), self.max_stacks )
end

function modifier_boss_mania_demon_presence_of_mania:OnTakeDamage( params )
	if self:GetParent():PassivesDisabled() then return end
	if params.attacker == self:GetParent() then
		if not params.inflictor then
			self:IncrementStackCount()
		else
			self:SetStackCount( self:GetStackCount() + self.spell_stacks )
		end
	end
end

function modifier_boss_mania_demon_presence_of_mania:IsAura()
	return not self:GetParent():PassivesDisabled()
end

function modifier_boss_mania_demon_presence_of_mania:GetModifierAura()
	return "modifier_boss_mania_demon_presence_of_mania_debuff"
end

function modifier_boss_mania_demon_presence_of_mania:GetAuraRadius()
	return self.presence_radius
end

function modifier_boss_mania_demon_presence_of_mania:GetAuraDuration()
	return 0.5
end

function modifier_boss_mania_demon_presence_of_mania:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_boss_mania_demon_presence_of_mania:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_boss_mania_demon_presence_of_mania:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_boss_mania_demon_presence_of_mania:IsHidden()
	return self:GetStackCount() <= 0
end

function modifier_boss_mania_demon_presence_of_mania:IsPurgable()
	return false
end

modifier_boss_mania_demon_presence_of_mania_debuff = class({})
LinkLuaModifier( "modifier_boss_mania_demon_presence_of_mania_debuff", "bosses/boss_harbingers/boss_mania_demon_presence_of_mania", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_mania_demon_presence_of_mania_debuff:OnCreated()
	self:OnRefresh()
end

function modifier_boss_mania_demon_presence_of_mania_debuff:OnRefresh()
	self.presence_armor_reduction = self:GetSpecialValueFor("presence_armor_reduction")
end

function modifier_boss_mania_demon_presence_of_mania_debuff:DeclareFunctions()
	return { MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS  }
end

function modifier_boss_mania_demon_presence_of_mania_debuff:GetModifierPhysicalArmorBonus()
	return self.presence_armor_reduction
end