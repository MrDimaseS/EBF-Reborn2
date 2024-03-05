boss_rift_general_atrophy_aura = class({})

function boss_rift_general_atrophy_aura:IsStealable()
	return true
end

function boss_rift_general_atrophy_aura:IsHiddenWhenStolen()
	return false
end

function boss_rift_general_atrophy_aura:GetIntrinsicModifierName()
	return "modifier_boss_rift_general_atrophy_aura"
end

modifier_boss_rift_general_atrophy_aura = class({})
LinkLuaModifier( "modifier_boss_rift_general_atrophy_aura", "bosses/boss_asura/boss_rift_general_atrophy_aura", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_rift_general_atrophy_aura:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self.wFX = ParticleManager:CreateParticle( "particles/units/heroes/heroes_underlord/underlord_atrophy_weapon.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
	end
end

function modifier_boss_rift_general_atrophy_aura:OnRefresh()
	self.radius = self:GetSpecialValueFor("radius")
	self.stackDamage = self:GetSpecialValueFor("bonus_damage_from_creep")
	self.bossStacks = self:GetSpecialValueFor("hero_multiplier")
end

function modifier_boss_rift_general_atrophy_aura:OnStackCountChanged(stacks)
	if IsServer() then
		ParticleManager:SetParticleControl(self.wFX, 2, Vector( self:GetStackCount(), 1, 1 ) )
	end
end

function modifier_boss_rift_general_atrophy_aura:OnDestroy()
	if IsServer() then
		ParticleManager:ClearParticle( self.wFX )
	end
end

function modifier_boss_rift_general_atrophy_aura:DeclareFunctions()
	return { MODIFIER_EVENT_ON_DEATH, MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE }
end

function modifier_boss_rift_general_atrophy_aura:OnDeath(params)
	local parent = self:GetParent()
	print( params.unit:IsSameTeam( parent ), ( CalculateDistance(params.unit, parent) <= self.radius or params.attacker == parent ) )
	if not params.unit:IsSameTeam( parent ) and ( CalculateDistance(params.unit, parent) <= self.radius or params.attacker == parent ) then
		local stacks = TernaryOperator( self.bossStacks, params.unit:IsConsideredHero(), 1 )
		print( stacks )
		self:SetStackCount( self:GetStackCount() + stacks )
	end
end

function modifier_boss_rift_general_atrophy_aura:GetModifierPreAttack_BonusDamage()
	return self:GetStackCount() * self.stackDamage
end

function modifier_boss_rift_general_atrophy_aura:IsAura()
	return true
end

function modifier_boss_rift_general_atrophy_aura:GetModifierAura()
	return "modifier_boss_rift_general_atrophy_aura_debuff"
end

function modifier_boss_rift_general_atrophy_aura:GetAuraEntityReject( entity )
	return self:GetCaster() == entity
end

function modifier_boss_rift_general_atrophy_aura:GetAuraRadius()
	return self.radius
end

function modifier_boss_rift_general_atrophy_aura:GetAuraDuration()
	return 0.5
end

function modifier_boss_rift_general_atrophy_aura:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_BOTH
end

function modifier_boss_rift_general_atrophy_aura:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_boss_rift_general_atrophy_aura:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_boss_rift_general_atrophy_aura:IsHidden()
	return self:GetStackCount() == 0
end

function modifier_boss_rift_general_atrophy_aura:IsPurgable()
	return false
end

function modifier_boss_rift_general_atrophy_aura:DestroyOnExpire()
	return false
end

modifier_boss_rift_general_atrophy_aura_debuff = class({})
LinkLuaModifier( "modifier_boss_rift_general_atrophy_aura_debuff", "bosses/boss_asura/boss_rift_general_atrophy_aura", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_rift_general_atrophy_aura_debuff:OnCreated()
	if self:GetCaster():IsSameTeam( self:GetParent() ) then
		if IsServer() then self:GetParent():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_boss_rift_general_atrophy_aura_ally", {} ) end
	else
		self.red = self:GetSpecialValueFor("damage_reduction_pct") * (-1)
	end
end

function modifier_boss_rift_general_atrophy_aura_debuff:OnRefresh()
	if self:GetCaster():IsSameTeam( self:GetParent() ) then
		if IsServer() then self:GetParent():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_boss_rift_general_atrophy_aura_ally", {} ) end
	else
		self.red = self:GetSpecialValueFor("damage_reduction_pct") * (-1)
	end
end

function modifier_boss_rift_general_atrophy_aura_debuff:OnDestroy()
	if IsServer() and self:GetCaster():IsSameTeam( self:GetParent() ) then
		self:GetParent():RemoveModifierByName("modifier_boss_rift_general_atrophy_aura_ally")
	end
end

function modifier_boss_rift_general_atrophy_aura_debuff:DeclareFunctions()
	return { MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE, MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS  }
end

function modifier_boss_rift_general_atrophy_aura_debuff:GetModifierBaseDamageOutgoing_Percentage()
	return self.red
end

function modifier_boss_rift_general_atrophy_aura_debuff:GetActivityTranslationModifiers()
	return "walk"
end

function modifier_boss_rift_general_atrophy_aura_debuff:GetEffectName()
	if not self:GetCaster():IsSameTeam( self:GetParent() ) then return "particles/ui/ui_debut_underlord_blastup.vpcf" end
end

function modifier_boss_rift_general_atrophy_aura_debuff:IsHidden()
	return self:GetCaster():IsSameTeam( self:GetParent() )
end

modifier_boss_rift_general_atrophy_aura_ally = class({})
LinkLuaModifier( "modifier_boss_rift_general_atrophy_aura_ally", "bosses/boss_asura/boss_rift_general_atrophy_aura", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_rift_general_atrophy_aura_ally:OnCreated()
	self.power = self:GetSpecialValueFor("bonus_shared_by_allies_pct") / 100
	self.stackDamage = self:GetSpecialValueFor("bonus_damage_from_creep")
	if IsServer() then
		self:StartIntervalThink(0.33)
	end
end

function modifier_boss_rift_general_atrophy_aura_ally:OnIntervalThink()
	self:SetStackCount( math.floor( self:GetCaster():GetModifierStackCount( "modifier_boss_rift_general_atrophy_aura", self:GetCaster() ) * self.power ) )
end

function modifier_boss_rift_general_atrophy_aura_ally:DeclareFunctions()
	return { MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE }
end

function modifier_boss_rift_general_atrophy_aura_ally:GetModifierPreAttack_BonusDamage()
	return self:GetStackCount() * self.stackDamage
end
