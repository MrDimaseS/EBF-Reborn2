boss_troll_warlord_fervor = class({})

function boss_troll_warlord_fervor:GetIntrinsicModifierName()
	return "modifier_boss_troll_warlord_fervor"
end

modifier_boss_troll_warlord_fervor = class({})
LinkLuaModifier("modifier_boss_troll_warlord_fervor", "bosses/boss_troll_warlord/boss_troll_warlord_fervor", LUA_MODIFIER_MOTION_NONE)

function modifier_boss_troll_warlord_fervor:OnCreated()
	self:OnRefresh()
end

function modifier_boss_troll_warlord_fervor:OnRefresh()
	self.duration = self:GetSpecialValueFor("duration")
end

function modifier_boss_troll_warlord_fervor:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_boss_troll_warlord_fervor:OnAttackLanded(params)
	local parent = self:GetParent()
	local caster = self:GetCaster()
	if params.attacker == parent then
		if params.target ~= self.attackTarget then
			parent:RemoveModifierByName("modifier_boss_troll_warlord_fervor_attack_speed")
		end
		self.attackTarget = params.target
		parent:AddNewModifier( caster, self:GetAbility(), "modifier_boss_troll_warlord_fervor_attack_speed", {duration = self.duration})
	end
end


function modifier_boss_troll_warlord_fervor:IsHidden()
	return true
end

modifier_boss_troll_warlord_fervor_attack_speed = class({})
LinkLuaModifier("modifier_boss_troll_warlord_fervor_attack_speed", "bosses/boss_troll_warlord/boss_troll_warlord_fervor", LUA_MODIFIER_MOTION_NONE)

function modifier_boss_troll_warlord_fervor_attack_speed:OnCreated()
	self:OnRefresh()
end

function modifier_boss_troll_warlord_fervor_attack_speed:OnRefresh()
	self.attack_speed = self:GetSpecialValueFor("attack_speed")
	self.max = self:GetSpecialValueFor("max_stacks")
	if IsServer() then
		self:SetStackCount( math.min( self:GetStackCount() + 1, self.max ) )
	end
end

function modifier_boss_troll_warlord_fervor_attack_speed:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

function modifier_boss_troll_warlord_fervor_attack_speed:GetModifierAttackSpeedBonus_Constant()
	return self.attack_speed * self:GetStackCount()
end