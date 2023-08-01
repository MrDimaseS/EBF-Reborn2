slark_essence_shift = class({})

function slark_essence_shift:GetIntrinsicModifierName()
	return "modifier_slark_essence_shift_handler"
end

function slark_essence_shift:ShouldUseResources()
	return true
end

modifier_slark_essence_shift_handler = class({})
LinkLuaModifier("modifier_slark_essence_shift_handler", "heroes/hero_slark/slark_essence_shift", LUA_MODIFIER_MOTION_NONE)

function modifier_slark_essence_shift_handler:DeclareFunctions()
	return  {MODIFIER_EVENT_ON_ATTACK_LANDED, MODIFIER_PROPERTY_STATS_AGILITY_BONUS}
end

function modifier_slark_essence_shift_handler:OnAttackLanded(params)
	local ability = self:GetAbility()
	if params.attacker == self:GetParent() and not params.attacker:PassivesDisabled() then
		local caster = self:GetCaster()
		local duration = self:GetSpecialValueFor("duration")

		local debuff = params.target:AddNewModifier(caster, ability, "modifier_slark_essence_shift_attr_debuff", {duration = duration})
		local buff = caster:AddNewModifier(caster, ability, "modifier_slark_essence_shift_agi_buff", {duration = duration})
		
		ParticleManager:FireRopeParticle( "particles/units/heroes/hero_slark/slark_essence_shift.vpcf", PATTACH_POINT_FOLLOW, target, caster )
		
		caster:CalculateStatBonus( true )
	end
end

function modifier_slark_essence_shift_handler:GetModifierBonusStats_Agility()
	return self:GetStackCount()
end

function modifier_slark_essence_shift_handler:IsHidden()
	return self:GetStackCount() <= 0
end

function modifier_slark_essence_shift_handler:IsPermanent()
	return true
end

function modifier_slark_essence_shift_handler:IsPurgable()
	return false
end

function modifier_slark_essence_shift_handler:RemoveOnDeath()
	return false
end

modifier_slark_essence_shift_attr_debuff = class({})
LinkLuaModifier("modifier_slark_essence_shift_attr_debuff", "heroes/hero_slark/slark_essence_shift", LUA_MODIFIER_MOTION_NONE)

function modifier_slark_essence_shift_attr_debuff:OnCreated()
	self:OnRefresh()
end

function modifier_slark_essence_shift_attr_debuff:OnRefresh()
	self.armor = self:GetSpecialValueFor("debuff_armor")
	self.slow = self:GetSpecialValueFor("debuff_slow")
	
	self.perma_agi = self:GetSpecialValueFor("permanent_agi")
end

function modifier_slark_essence_shift_attr_debuff:DeclareFunctions()
	return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_EVENT_ON_DEATH }
end

function modifier_slark_essence_shift_attr_debuff:OnDeath(params)
	if params.unit == self:GetParent() and params.unit:IsConsideredHero() and CalculateDistance( params.unit, self:GetCaster() ) <= 300 then
		local modifier = self:GetCaster():FindModifierByName( "modifier_slark_essence_shift_handler" )
		modifier:SetStackCount( modifier:GetStackCount() + self.perma_agi )
	end
end

function modifier_slark_essence_shift_attr_debuff:GetModifierPhysicalArmorBonus()
	return self.armor
end

function modifier_slark_essence_shift_attr_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

modifier_slark_essence_shift_agi_buff = class({})
LinkLuaModifier("modifier_slark_essence_shift_agi_buff", "heroes/hero_slark/slark_essence_shift", LUA_MODIFIER_MOTION_NONE)

function modifier_slark_essence_shift_agi_buff:OnCreated()
	self:OnRefresh()
end

function modifier_slark_essence_shift_agi_buff:OnRefresh()
	self.agi = self:GetSpecialValueFor("agi_gain")
	self.int = self:GetSpecialValueFor("int_gain")
	self.str = self:GetSpecialValueFor("str_gain")
	if IsServer() then
		self:AddIndependentStack( self:GetRemainingTime() )
	end
end


function modifier_slark_essence_shift_agi_buff:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_AGILITY_BONUS, MODIFIER_PROPERTY_STATS_STRENGTH_BONUS, MODIFIER_PROPERTY_STATS_INTELLECT_BONUS }
end

function modifier_slark_essence_shift_agi_buff:GetModifierBonusStats_Agility()
	return self.agi * self:GetStackCount()
end

function modifier_slark_essence_shift_agi_buff:GetModifierBonusStats_Strength()
	return self.str * self:GetStackCount()
end

function modifier_slark_essence_shift_agi_buff:GetModifierBonusStats_Intellect()
	return self.int * self:GetStackCount()
end