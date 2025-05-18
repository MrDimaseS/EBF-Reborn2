item_cloak_of_the_protector = class({})

function item_cloak_of_the_protector:GetIntrinsicModifierName()
	return "modifier_item_cloak_of_the_protector_ebf"
end

function item_cloak_of_the_protector:OnSpellStart()
	local caster = self:GetCaster()

	local radius = self:GetSpecialValueFor("barrier_radius")
	local duration = self:GetSpecialValueFor("duration")
	for _, ally in ipairs( caster:FindFriendlyUnitsInRadius( caster:GetAbsOrigin(), radius ) ) do
		ally:AddNewModifier( caster, self, "modifier_item_cloak_of_the_protector_ebf_active", {duration = duration} )
		ParticleManager:FireParticle( "particles/items2_fx/pipe_of_insight_launch.vpcf", PATTACH_POINT, ally )
	end
end

item_cloak_of_the_protector_2 = class(item_cloak_of_the_protector)
item_cloak_of_the_protector_3 = class(item_cloak_of_the_protector)
item_cloak_of_the_protector_4 = class(item_cloak_of_the_protector)
item_cloak_of_the_protector_5 = class(item_cloak_of_the_protector)

modifier_item_cloak_of_the_protector_ebf = class({})
LinkLuaModifier( "modifier_item_cloak_of_the_protector_ebf", "items/item_cloak_of_the_protector.lua" ,LUA_MODIFIER_MOTION_NONE )
function modifier_item_cloak_of_the_protector_ebf:OnCreated()
	self:OnRefresh()
end

function modifier_item_cloak_of_the_protector_ebf:OnRefresh()
	self.magic_resistance = self:GetAbility():GetSpecialValueFor("magic_resistance")
	self.bonus_armor = self:GetAbility():GetSpecialValueFor("bonus_armor")
	self.bonus_all = self:GetAbility():GetSpecialValueFor("bonus_all_stats")
	self.bonus_mana = self:GetAbility():GetSpecialValueFor("bonus_mana")
	self.bonus_health = self:GetAbility():GetSpecialValueFor("bonus_health")
	self.bonus_health_regen = self:GetAbility():GetSpecialValueFor("bonus_health_regen")
	
	self.aura_radius = self:GetAbility():GetSpecialValueFor("aura_radius")
end

function modifier_item_cloak_of_the_protector_ebf:DeclareFunctions(params)
	local funcs = {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_MANA_BONUS,
    }
    return funcs
end

function modifier_item_cloak_of_the_protector_ebf:GetModifierMagicalResistanceBonus()
	return self.magic_resistance
end

function modifier_item_cloak_of_the_protector_ebf:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_item_cloak_of_the_protector_ebf:GetModifierConstantHealthRegen()
	return self.bonus_health_regen
end

function modifier_item_cloak_of_the_protector_ebf:GetModifierHealthBonus()
	return self.bonus_health
end

function modifier_item_cloak_of_the_protector_ebf:GetModifierManaBonus()
	return self.bonus_mana
end

function modifier_item_cloak_of_the_protector_ebf:GetModifierBonusStats_Strength()
	return self.bonus_all
end

function modifier_item_cloak_of_the_protector_ebf:GetModifierBonusStats_Intellect()
	return self.bonus_all
end

function modifier_item_cloak_of_the_protector_ebf:GetModifierBonusStats_Agility()
	return self.bonus_all
end

function modifier_item_cloak_of_the_protector_ebf:IsAura()
	return true
end

function modifier_item_cloak_of_the_protector_ebf:GetModifierAura()
	return "modifier_item_cloak_of_the_protector_ebf_aura"
end

function modifier_item_cloak_of_the_protector_ebf:GetAuraRadius()
	return self.aura_radius
end

function modifier_item_cloak_of_the_protector_ebf:GetAuraDuration()
	return 0.5
end

function modifier_item_cloak_of_the_protector_ebf:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_item_cloak_of_the_protector_ebf:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_item_cloak_of_the_protector_ebf:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_item_cloak_of_the_protector_ebf:IsHidden()
	return true
end

LinkLuaModifier( "modifier_item_cloak_of_the_protector_ebf_aura", "items/item_cloak_of_the_protector.lua" ,LUA_MODIFIER_MOTION_NONE )
modifier_item_cloak_of_the_protector_ebf_aura = class({})

function modifier_item_cloak_of_the_protector_ebf_aura:OnCreated()
	self:OnRefresh( )
end

function modifier_item_cloak_of_the_protector_ebf_aura:OnRefresh()
	self.aura_health_regen = self:GetAbility():GetSpecialValueFor("aura_health_regen")
	self.magic_resistance_aura = self:GetAbility():GetSpecialValueFor("magic_resistance_aura")
	
	self.trigger_cd_reduction = self:GetAbility():GetSpecialValueFor("trigger_cd_reduction")
	self.trigger_hp_threshold = self:GetAbility():GetSpecialValueFor("trigger_hp_threshold") / 100
end

function modifier_item_cloak_of_the_protector_ebf_aura:DeclareFunctions(params)
	local funcs = {
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
    }
    return funcs
end

function modifier_item_cloak_of_the_protector_ebf_aura:GetModifierConstantHealthRegen()
	return self.aura_health_regen
end

function modifier_item_cloak_of_the_protector_ebf_aura:GetModifierMagicalResistanceBonus()
	return self.magic_resistance_aura
end

function modifier_item_cloak_of_the_protector_ebf_aura:GetModifierIncomingDamage_Percentage( params )
	self._unitDamageTaken = (self._unitDamageTaken or 0) + params.damage
	if self._unitDamageTaken > self:GetParent():GetMaxHealth() * self.trigger_hp_threshold then
		self:GetAbility():ModifyCooldown( -self.trigger_cd_reduction )
		self._unitDamageTaken = 0
	end
end

LinkLuaModifier( "modifier_item_cloak_of_the_protector_ebf_active", "items/item_cloak_of_the_protector.lua" ,LUA_MODIFIER_MOTION_NONE )
modifier_item_cloak_of_the_protector_ebf_active = class({})

function modifier_item_cloak_of_the_protector_ebf_active:OnCreated()
	self:OnRefresh( )
	if IsServer() then
		local parent = self:GetParent()
		local radius = parent:GetModelRadius()
		local nfx = ParticleManager:CreateParticle( "particles/items2_fx/pipe_of_insight_v2.vpcf", PATTACH_POINT_FOLLOW, parent )
		ParticleManager:SetParticleControlEnt(nfx, 0, parent, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(nfx, 1, parent, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
		ParticleManager:SetParticleControl(nfx, 2, Vector(radius, 0, 0))
		self:AddEffect(nfx)
		
		self:SetHasCustomTransmitterData(true)
	end
end

function modifier_item_cloak_of_the_protector_ebf_active:OnRefresh()
	if not IsServer() then return end
	self.barrier_block = self:GetAbility():GetSpecialValueFor("barrier_block")
	self:SendBuffRefreshToClients()
end

function modifier_item_cloak_of_the_protector_ebf_active:DeclareFunctions(params)
	local funcs = {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT
    }
    return funcs
end

function modifier_item_cloak_of_the_protector_ebf_active:GetModifierIncomingDamageConstant( params )
	if IsServer() then
		local barrier_block = math.min( self.barrier_block, math.max( self.barrier_block, params.damage ) )
		self.barrier_block = self.barrier_block - params.damage
		if self.barrier_block <= 0 then 
			self:Destroy()
			return
		end
		self:SendBuffRefreshToClients()
		return -barrier_block
	else
		return self.barrier_block
	end
end

function modifier_item_cloak_of_the_protector_ebf_active:AddCustomTransmitterData()
	return {barrier_block = self.barrier_block}
end

function modifier_item_cloak_of_the_protector_ebf_active:HandleCustomTransmitterData(data)
	self.barrier_block = data.barrier_block
end
