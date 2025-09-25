item_sange_and_yasha = class({})

function item_sange_and_yasha:GetIntrinsicModifierName()
	return "modifier_item_sange_and_yasha_passive"
end

modifier_item_sange_and_yasha_passive = class({})
LinkLuaModifier( "modifier_item_sange_and_yasha_passive", "items/item_sange_and_yasha.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_sange_and_yasha_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_sange_and_yasha_passive:OnRefresh()
	self.bonus_agility = self:GetSpecialValueFor("bonus_agility")
	self.bonus_strength = self:GetSpecialValueFor("bonus_strength")
	self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	
	self.indomitable_duration = self:GetSpecialValueFor("indomitable_duration")
end

function modifier_item_sange_and_yasha_passive:DeclareFunctions()
	return {
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_EVENT_ON_HEAL_RECEIVED,
			MODIFIER_EVENT_ON_TAKEDAMAGE 
	}
end

function modifier_item_sange_and_yasha_passive:OnHealReceived( params )
	local parent = self:GetParent()
	if not params.inflictor then return end -- no health regen
	if params.fail_type == 0 then return end -- no lifesteal
	if params.unit ~= parent then return end
	parent:AddNewModifier( parent, self:GetAbility(), "modifier_item_sange_and_yasha_indomitable_status_resist", {duration = self.indomitable_duration} )
end

function modifier_item_sange_and_yasha_passive:OnTakeDamage( params )
	local parent = self:GetParent()
	if params.unit ~= parent then return end
	parent:AddNewModifier( parent, self:GetAbility(), "modifier_item_sange_and_yasha_indomitable_restore_amp", {duration = self.indomitable_duration} )
end

function modifier_item_sange_and_yasha_passive:GetModifierBonusStats_Strength()
	return self.bonus_strength
end

function modifier_item_sange_and_yasha_passive:GetModifierBonusStats_Agility()
	return self.bonus_agility
end

function modifier_item_sange_and_yasha_passive:IsHidden()
	return true
end

function modifier_item_sange_and_yasha_passive:IsPurgable()
	return false
end

function modifier_item_sange_and_yasha_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

modifier_item_sange_and_yasha_indomitable_status_resist = class({})
LinkLuaModifier( "modifier_item_sange_and_yasha_indomitable_status_resist", "items/item_sange_and_yasha.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_sange_and_yasha_indomitable_status_resist:OnCreated()
	self:OnRefresh()
end

function modifier_item_sange_and_yasha_indomitable_status_resist:OnRefresh()
	self.indomitable_status_resist = self:GetSpecialValueFor("indomitable_status_resist")
end

function modifier_item_sange_and_yasha_indomitable_status_resist:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATUS_RESISTANCE_STACKING}
end

function modifier_item_sange_and_yasha_indomitable_status_resist:GetModifierStatusResistanceStacking()
	return self.indomitable_status_resist
end

modifier_item_sange_and_yasha_indomitable_restore_amp = class({})
LinkLuaModifier( "modifier_item_sange_and_yasha_indomitable_restore_amp", "items/item_sange_and_yasha.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_sange_and_yasha_indomitable_restore_amp:OnCreated()
	self:OnRefresh()
end

function modifier_item_sange_and_yasha_indomitable_restore_amp:OnRefresh()
	self.indomitable_restore_amp = self:GetSpecialValueFor("indomitable_restore_amp")
end

function modifier_item_sange_and_yasha_indomitable_restore_amp:DeclareFunctions()
	return { MODIFIER_PROPERTY_TOOLTIP }
end

function modifier_item_sange_and_yasha_indomitable_restore_amp:OnTooltip()
	return self.indomitable_restore_amp
end

function modifier_item_sange_and_yasha_indomitable_restore_amp:GetModifierPropertyRestorationAmplification()
	return self.indomitable_restore_amp
end