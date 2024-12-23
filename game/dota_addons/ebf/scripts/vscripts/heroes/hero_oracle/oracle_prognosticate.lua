oracle_prognosticate = class({})

function oracle_prognosticate:GetIntrinsicModifierName()
	return "modifier_oracle_prognosticate_innate"
end

modifier_oracle_prognosticate_innate = class({})
LinkLuaModifier("modifier_oracle_prognosticate_innate", "heroes/hero_oracle/oracle_prognosticate", LUA_MODIFIER_MOTION_NONE)

function modifier_oracle_prognosticate_innate:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ABILITY_EXECUTED }
end

function modifier_oracle_prognosticate_innate:OnAbilityExecuted( params )
	if not (params.unit == self:GetCaster()) then return end
	if not params.target then return end
	if params.ability:IsItem() then return end
	if IsEntitySafe( self.lastTarget ) and self.lastTarget:IsAlive() then
		self.lastTarget:RemoveModifierByName("modifier_oracle_prognosticate_handler")
	end
	self.lastTarget = params.target
	params.target:AddNewModifier( params.unit, self:GetAbility(), "modifier_oracle_prognosticate_handler", { } )
end

function modifier_oracle_prognosticate_innate:IsHidden()
	return true
end

modifier_oracle_prognosticate_handler = class({})
LinkLuaModifier("modifier_oracle_prognosticate_handler", "heroes/hero_oracle/oracle_prognosticate", LUA_MODIFIER_MOTION_NONE)

function modifier_oracle_prognosticate_handler:OnCreated()
	self:OnRefresh()
end

function modifier_oracle_prognosticate_handler:OnRefresh()
	self.damage_amp = self:GetSpecialValueFor("damage_amp")
	self.damage_resist = self:GetSpecialValueFor("damage_resist")
end

function modifier_oracle_prognosticate_handler:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE}
end

function modifier_oracle_prognosticate_handler:GetModifierIncomingDamage_Percentage()
	return TernaryOperator( self.damage_resist, self:GetCaster():IsSameTeam( self:GetParent() ), self.damage_amp )
end

function modifier_oracle_prognosticate_handler:IsPurgable()
	return true
end

function modifier_oracle_prognosticate_handler:GetEffectName()
	return "particles/units/heroes/hero_oracle/oracle_prognosticate_overhead.vpcf"
end

function modifier_oracle_prognosticate_handler:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW 
end