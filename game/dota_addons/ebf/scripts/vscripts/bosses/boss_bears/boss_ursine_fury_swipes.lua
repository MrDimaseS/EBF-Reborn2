boss_ursine_fury_swipes = class({})

function boss_ursine_fury_swipes:IsStealable()
	return false
end

function boss_ursine_fury_swipes:IsHiddenWhenStolen()
	return false
end

function boss_ursine_fury_swipes:GetIntrinsicModifierName()
	return "modifier_boss_ursine_fury_swipes_handle"
end

modifier_boss_ursine_fury_swipes_handle = class({})
LinkLuaModifier("modifier_boss_ursine_fury_swipes_handle", "bosses/boss_bears/boss_ursine_fury_swipes", LUA_MODIFIER_MOTION_NONE)

function modifier_boss_ursine_fury_swipes_handle:OnCreated()
	self:OnRefresh()
end

function modifier_boss_ursine_fury_swipes_handle:OnRefresh()
	self.damage_per_stack = self:GetSpecialValueFor("damage_per_stack")
	self.bonus_reset_time = self:GetSpecialValueFor("bonus_reset_time")
	self.stun_stack_count = self:GetSpecialValueFor("stun_stack_count")
	self.stun_duration = self:GetSpecialValueFor("stun_duration")
end

function modifier_boss_ursine_fury_swipes_handle:DeclareFunctions()
	return {MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL }
end

function modifier_boss_ursine_fury_swipes_handle:GetModifierProcAttack_BonusDamage_Physical(params)
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if caster:PassivesDisabled() then return nil end
	local stacks = params.target:GetModifierStackCount( "modifier_boss_ursine_fury_swipes", nil )
	local damage = self.damage_per_stack * stacks
	if stacks > 0 and stacks % self.stun_stack_count == 0 then
		ability:Stun( params.target, self.stun_duration )
		self.stun_stack_count = self.stun_stack_count + 1
	end
	local modifier = params.target:AddNewModifier( params.attacker, self:GetAbility(), "modifier_boss_ursine_fury_swipes", {duration = self.bonus_reset_time} )
	if caster:HasModifier("modifier_boss_ursine_fury_swipes_talent") then
		local stacks = caster:FindModifierByName("modifier_boss_ursine_fury_swipes_talent"):GetStackCount()
		caster:RemoveModifierByName("modifier_boss_ursine_fury_swipes_talent")
		modifier:SetStackCount( modifier:GetStackCount() + stacks )
	end
	return damage
end

function modifier_boss_ursine_fury_swipes_handle:IsHidden()
	return true
end

modifier_boss_ursine_fury_swipes = class({})
LinkLuaModifier("modifier_boss_ursine_fury_swipes", "bosses/boss_bears/boss_ursine_fury_swipes", LUA_MODIFIER_MOTION_NONE)
function modifier_boss_ursine_fury_swipes:OnCreated(table)
	self:OnRefresh()
end

function modifier_boss_ursine_fury_swipes:OnRefresh(table)
	local caster = self:GetCaster()
	self.damage = self:GetSpecialValueFor("damage_per_stack")
	self.stackLoss = self:GetSpecialValueFor("stack_loss_on_dispel") / 100
	if IsServer() then
		self:IncrementStackCount()
	end
end

function modifier_boss_ursine_fury_swipes:OnDestroy()
	if not IsServer() then return end
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	local stacks = math.floor( self:GetStackCount() * self.stackLoss )
	local duration = self:GetRemainingTime()
	if duration <= 0 or stacks <= 0 then return end
	Timers:CreateTimer( function()
		if IsEntitySafe( parent ) and parent:IsAlive() then
			parent:AddNewModifier( caster, ability, "modifier_boss_ursine_fury_swipes", {duration = duration} ):SetStackCount( stacks )
		end
	end)
end

function modifier_boss_ursine_fury_swipes:DeclareFunctions()
	return { MODIFIER_PROPERTY_TOOLTIP }
end

function modifier_boss_ursine_fury_swipes:OnTooltip()
	return self.damage * self:GetStackCount()
end

function modifier_boss_ursine_fury_swipes:GetEffectName()
	return "particles/units/heroes/hero_ursa/ursa_fury_swipes_debuff.vpcf"
end

function modifier_boss_ursine_fury_swipes:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

function modifier_boss_ursine_fury_swipes:IsDebuff()
	return true
end

function modifier_boss_ursine_fury_swipes:IsHidden()
	return false
end

function modifier_boss_ursine_fury_swipes:IsPurgable()
	return true
end