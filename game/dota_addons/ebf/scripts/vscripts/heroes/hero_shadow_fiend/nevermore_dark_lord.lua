nevermore_dark_lord = class({})

function nevermore_dark_lord:GetIntrinsicModifierName()
	return "modifier_nevermore_dark_lord_passive"
end
function nevermore_dark_lord:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

modifier_nevermore_dark_lord_passive = class({})
LinkLuaModifier( "modifier_nevermore_dark_lord_passive","heroes/hero_shadow_fiend/nevermore_dark_lord.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_nevermore_dark_lord_passive:OnCreated()
	self:OnRefresh()
end
function modifier_nevermore_dark_lord_passive:OnRefresh()
	self.radius = self:GetSpecialValueFor("radius")
	if IsServer() then
		for _, unit in ipairs( self:GetCaster():FindAllUnitsInRadius( self:GetCaster():GetAbsOrigin(), self.radius ) ) do
			if unit:HasModifier("modifier_nevermore_dark_lord_passive_aura") then
				unit:RemoveModifierByName("modifier_nevermore_dark_lord_passive_aura")
			end
		end
	end
end
function modifier_nevermore_dark_lord_passive:IsAura()
	return true
end
function modifier_nevermore_dark_lord_passive:GetModifierAura()
	return "modifier_nevermore_dark_lord_passive_aura"
end
function modifier_nevermore_dark_lord_passive:GetAuraRadius()
	return self.radius
end
function modifier_nevermore_dark_lord_passive:GetAuraDuration()
	return 0.5
end
function modifier_nevermore_dark_lord_passive:GetAuraSearchTeam()
	if self:GetSpecialValueFor("affects_allies") ~= 0 then
		return DOTA_UNIT_TARGET_TEAM_BOTH
	else
		return DOTA_UNIT_TARGET_TEAM_ENEMY
	end
end
function modifier_nevermore_dark_lord_passive:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end
function modifier_nevermore_dark_lord_passive:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end
function modifier_nevermore_dark_lord_passive:IsHidden()
	return true
end

modifier_nevermore_dark_lord_passive_aura = class({})
LinkLuaModifier( "modifier_nevermore_dark_lord_passive_aura","heroes/hero_shadow_fiend/nevermore_dark_lord.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_nevermore_dark_lord_passive_aura:OnCreated()
	self:OnRefresh()
end
function modifier_nevermore_dark_lord_passive_aura:OnRefresh()
	self.armor_reduction = self:GetSpecialValueFor("armor_reduction")
	self.armor_stack = self:GetSpecialValueFor("armor_stack")

	self.magic_resistance_reduction = self:GetSpecialValueFor("magic_resistance_reduction")
	self.magic_resistance_stack = self:GetSpecialValueFor("magic_resistance_stack")
	
	self.outgoing_damage_reduction = self:GetSpecialValueFor("outgoing_damage_reduction")
	self.outgoing_damage_stack = self:GetSpecialValueFor("outgoing_damage_stack")

	-- self.hero_stack_multiplier = self:GetSpecialValueFor("hero_stack_multiplier")
	self.requiem_multiplier = self:GetSpecialValueFor("requiem_multiplier")
	
	if IsServer() then
		self:StartIntervalThink(0.25)
	end
end
function modifier_nevermore_dark_lord_passive_aura:OnDestroy()
	if IsServer() then
		if not self:GetParent():IsAlive() then
			local buff_duration = self:GetSpecialValueFor("buff_duration")
			local stacks = 1
			if self:GetParent():IsConsideredHero() then
				-- stacks = stacks * self:GetSpecialValueFor("hero_stack_multiplier")
				buff_duration = buff_duration * self:GetSpecialValueFor("hero_buff_multiplier")
			end
			
			local buff = self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_nevermore_dark_lord_kill_buff", { duration = buff_duration })
			if not buff then return end
			for i = 1, stacks do
				buff:AddIndependentStack(buff_duration)
			end
		end
	end
end
function modifier_nevermore_dark_lord_passive_aura:OnIntervalThink()
	local buff = self:GetCaster():FindModifierByName("modifier_nevermore_dark_lord_kill_buff")
	if buff and buff:GetStackCount() ~= self:GetStackCount() then
		self:SetStackCount( buff:GetStackCount() )
	elseif not buff and self:GetStackCount() > 0 then
		self:SetStackCount(0)
	end
end
function modifier_nevermore_dark_lord_passive_aura:DeclareFunctions()
	return { 
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_TOTALDAMAGEOUTGOING_PERCENTAGE
	}
end
function modifier_nevermore_dark_lord_passive_aura:GetModifierPhysicalArmorBonus()
	local negator = 1
	if self:GetParent():GetTeamNumber() == self:GetCaster():GetTeamNumber() then
		negator = -1
	end
	if self:GetParent():HasModifier("modifier_nevermore_requiem_debuff") then
		return ((self.armor_reduction + self.armor_stack * self:GetStackCount()) * self.requiem_multiplier) * negator
	else
		return (self.armor_reduction + self.armor_stack * self:GetStackCount()) * negator
	end
end
function modifier_nevermore_dark_lord_passive_aura:GetModifierMagicalResistanceBonus()
	local negator = 1
	if self:GetParent():GetTeamNumber() == self:GetCaster():GetTeamNumber() then
		negator = -1
	end
	if self:GetParent():HasModifier("modifier_nevermore_requiem_debuff") then
		return ((self.magic_resistance_reduction + self.magic_resistance_stack * self:GetStackCount()) * self.requiem_multiplier) * negator
	else
		return (self.magic_resistance_reduction + self.magic_resistance_stack * self:GetStackCount()) * negator
	end
end
function modifier_nevermore_dark_lord_passive_aura:GetModifierTotalDamageOutgoing_Percentage()
	local negator = 1
	if self:GetParent():GetTeamNumber() == self:GetCaster():GetTeamNumber() then
		negator = -1
	end
	if self:GetParent():HasModifier("modifier_nevermore_requiem_debuff") then
		return ((self.outgoing_damage_reduction + self.outgoing_damage_stack * self:GetStackCount()) * self.requiem_multiplier) * negator
	else
		return (self.outgoing_damage_reduction + self.outgoing_damage_stack * self:GetStackCount()) * negator
	end
end

modifier_nevermore_dark_lord_kill_buff = class({})
LinkLuaModifier( "modifier_nevermore_dark_lord_kill_buff","heroes/hero_shadow_fiend/nevermore_dark_lord.lua",LUA_MODIFIER_MOTION_NONE )