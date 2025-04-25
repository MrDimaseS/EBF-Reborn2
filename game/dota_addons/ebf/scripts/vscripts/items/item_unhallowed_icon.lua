item_unhallowed_icon = class({})

function item_unhallowed_icon:GetIntrinsicModifierName()
	return "modifier_item_unhallowed_icon_passive"
end

modifier_item_unhallowed_icon_passive = class({})
LinkLuaModifier( "modifier_item_unhallowed_icon_passive", "items/item_unhallowed_icon.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_unhallowed_icon_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_unhallowed_icon_passive:OnRefresh()
	self.bonus_health = self:GetAbility():GetSpecialValueFor("bonus_health")
	self.bonus_health_regen = self:GetAbility():GetSpecialValueFor("bonus_health_regen")
	
	self.bloodbound_radius = self:GetAbility():GetSpecialValueFor("bloodbound_radius")
	if IsServer() then
		self:OnIntervalThink( )
		self:StartIntervalThink( 0.5 )
	end
end

function modifier_item_unhallowed_icon_passive:OnIntervalThink()
	self:GetAbility()._bloodBoundAllies = {}
	for _, ally in ipairs( self:GetCaster():FindFriendlyUnitsInRadius( self:GetCaster():GetAbsOrigin(), -1, {type = DOTA_UNIT_TARGET_HERO} ) ) do
		if ally:HasModifier("modifier_item_unhallowed_icon_aura") and ally ~= parent and ally:IsRealHero() then
			table.insert( self:GetAbility()._bloodBoundAllies, ally )
		end
	end
end

function modifier_item_unhallowed_icon_passive:DeclareFunctions(params)
	local funcs = {
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
    }
    return funcs
end

function modifier_item_unhallowed_icon_passive:GetModifierHealthBonus()
	return self.bonus_health
end

function modifier_item_unhallowed_icon_passive:GetModifierConstantHealthRegen()
	return self.bonus_health_regen
end

function modifier_item_unhallowed_icon_passive:IsAura()
	return true
end

function modifier_item_unhallowed_icon_passive:GetModifierAura()
	return "modifier_item_unhallowed_icon_aura"
end

function modifier_item_unhallowed_icon_passive:GetAuraRadius()
	return self.bloodbound_radius
end

function modifier_item_unhallowed_icon_passive:GetAuraDuration()
	return 0.5
end

function modifier_item_unhallowed_icon_passive:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_unhallowed_icon_passive:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_HERO
end

function modifier_item_unhallowed_icon_passive:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_item_unhallowed_icon_passive:IsHidden()
	return true
end

function modifier_item_unhallowed_icon_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE 
end

LinkLuaModifier( "modifier_item_unhallowed_icon_aura", "items/item_unhallowed_icon.lua" ,LUA_MODIFIER_MOTION_NONE )
modifier_item_unhallowed_icon_aura = class({})

function modifier_item_unhallowed_icon_aura:OnCreated()
	self:OnRefresh( )
end

function modifier_item_unhallowed_icon_aura:OnRefresh()
	self.bloodbound_lifesteal = self:GetSpecialValueFor("bloodbound_lifesteal")
	
	self:GetParent()._attackLifestealModifiersList = self:GetParent()._attackLifestealModifiersList or {}
	self:GetParent()._attackLifestealModifiersList[self] = true
	
	self:GetParent()._spellLifestealModifiersList = self:GetParent()._spellLifestealModifiersList or {}
	self:GetParent()._spellLifestealModifiersList[self] = true
	
	self:GetParent()._onLifestealModifiersList = self:GetParent()._onLifestealModifiersList or {}
	self:GetParent()._onLifestealModifiersList[self] = true
	
	if IsServer() then
		self:OnIntervalThink()
		self:StartIntervalThink( 0.5 )
	end
end

function modifier_item_unhallowed_icon_aura:OnIntervalThink()
	self:SetStackCount( #self:GetAbility()._bloodBoundAllies )
end

function modifier_item_unhallowed_icon_aura:DeclareFunctions(params)
	local funcs = {
		MODIFIER_EVENT_ON_HEAL_RECEIVED,
    }
    return funcs
end

function modifier_item_unhallowed_icon_aura:OnLifesteal( params )
	local caster = self:GetCaster()
	local parent = self:GetParent()
	if self:GetStackCount() == 0 then return end
	local lifestealFromBlood = params.excess + params.damage * (self.bloodbound_lifesteal / self:GetStackCount()) / 100
	for _, ally in ipairs( self:GetAbility()._bloodBoundAllies ) do
		if ally ~= parent then
			ally:HealEvent( lifestealFromBlood, ability, caster, {heal_type = DOTA_HEAL_TYPE_LIFESTEAL, heal_category = params.damage_category + 1} )
		end
	end
end

function modifier_item_unhallowed_icon_aura:GetModifierProperty_PhysicalLifesteal( params )
	if self:GetStackCount() == 0 then return end
	return self.bloodbound_lifesteal / self:GetStackCount()
end

function modifier_item_unhallowed_icon_aura:GetModifierProperty_MagicalLifesteal( params )
	if self:GetStackCount() == 0 then return end
	return self.bloodbound_lifesteal / self:GetStackCount()
end

function modifier_item_unhallowed_icon_aura:OnHealReceived( params )
	if not params.inflictor then return end -- no health regen
	if params.inflictor:GetName() == "item_unhallowed_icon" then return end -- no looping
	if params.fail_type == 0 then return end -- no lifesteal
	local parent = self:GetParent()
	if params.unit ~= parent then return end
	local overheal = (params.gain - parent:GetHealthDeficit())
	if overheal > 0 then
		print(overheal)
		local ability = self:GetAbility()
		local allies = 0
		local orderedByHP = {}
		for _, ally in ipairs( self:GetAbility()._bloodBoundAllies ) do
			if ally:GetHealthDeficit() > 0 then
				allies = allies + 1
				if #orderedByHP == 0 then
					table.insert( orderedByHP, ally )
				else
					for i = 1, #orderedByHP do
						if ally:GetHealthDeficit() < orderedByHP[i]:GetHealthDeficit() then
							table.insert( orderedByHP, i, ally )
						elseif i == #orderedByHP then
							table.insert( orderedByHP, ally )
						end
					end
				end
			end
		end
		for _, ally in ipairs( orderedByHP ) do
			if ally ~= parent and overheal > 0 and allies > 0 then
				local realHeal = math.min( overheal / allies, ally:GetHealthDeficit() )
				overheal = overheal - realHeal
				allies = allies - 1
				print("real heal:", realHeal )
				ally:HealEvent( realHeal, ability, caster )
			end
		end
	end
end