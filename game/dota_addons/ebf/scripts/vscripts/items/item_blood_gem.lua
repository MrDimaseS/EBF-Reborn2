item_blood_gem = class({})

function item_blood_gem:GetIntrinsicModifierName()
	return "modifier_item_blood_gem_passive"
end

function item_blood_gem:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier( caster, self, "modifier_item_blood_gem_active", {duration = self:GetSpecialValueFor("duration")} )
end

function item_blood_gem:AddFalseBarrier( amount )
	local caster = self:GetCaster()
	local barrier = math.max( 0, math.min( caster:GetMaxHealth() * self:GetSpecialValueFor("overheal_maximum") / 100, self._internalAbilityModifier.barrier_block + amount ) )
	self._internalAbilityModifier.barrier_block = barrier
	self._internalAbilityModifier:SendBuffRefreshToClients()
end

item_blood_gem_2 = class(item_blood_gem)
item_blood_gem_3 = class(item_blood_gem)
item_blood_gem_4 = class(item_blood_gem)
item_blood_gem_5 = class(item_blood_gem)

modifier_item_blood_gem_active = class({})
LinkLuaModifier( "modifier_item_blood_gem_active", "items/item_blood_gem.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_blood_gem_active:OnCreated()
	if IsClient() then return end
	self:OnRefresh()
	
	local nFX = ParticleManager:CreateParticle("particles/econ/items/wisp/wisp_overcharge_ti7.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControlEnt(nFX, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
	self:AddEffect( nFX )
	
	self._passiveModifier = self:GetParent():FindModifierByNameAndAbility( self:GetAbility():GetIntrinsicModifierName(), self:GetAbility() )
end

function modifier_item_blood_gem_active:OnRefresh()
	self.spell_lifesteal = self:GetSpecialValueFor("spell_lifesteal") / 100
	self.lifesteal_percent = self:GetSpecialValueFor("lifesteal_percent") / 100
	self.link_radius = self:GetSpecialValueFor("link_radius")
end

function modifier_item_blood_gem_active:DeclareFunctions(params)
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
    }
    return funcs
end

function modifier_item_blood_gem_active:OnTakeDamage( params )
	if HasBit( params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS ) then return end
	if HasBit( params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION ) then return end
	if HasBit( params.damage_category, DOTA_DAMAGE_CATEGORY_BARRIER ) then return end
	if CalculateDistance( params.unit, self:GetCaster() ) > self.link_radius then return end
	if params.damage <= 0 then return end
	
	local barrier = params.damage * TernaryOperator( self.spell_lifesteal, HasBit( params.damage_category, DOTA_DAMAGE_CATEGORY_SPELL ), self.lifesteal_percent )
	self:GetAbility():AddFalseBarrier( barrier )
end

modifier_item_blood_gem_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_blood_gem_passive", "items/item_blood_gem.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_blood_gem_passive:OnCreated()
	self.barrier_block = 0
	self:GetAbility()._internalAbilityModifier = self
	if IsServer() then self:SetHasCustomTransmitterData(true) end
	self:OnRefresh()
end

function modifier_item_blood_gem_passive:OnRefresh()
	self.bonus_health = self:GetAbility():GetSpecialValueFor("bonus_health")
	self.bonus_mana = self:GetAbility():GetSpecialValueFor("bonus_mana")
	
	self.spell_lifesteal = self:GetAbility():GetSpecialValueFor("spell_lifesteal")
	self.lifesteal_percent = self:GetAbility():GetSpecialValueFor("lifesteal_percent")
	self.overheal_maximum = self:GetAbility():GetSpecialValueFor("overheal_maximum") / 100
	
	self:GetParent()._spellLifestealModifiersList = self:GetParent()._spellLifestealModifiersList or {}
	self:GetParent()._spellLifestealModifiersList[self] = true
	
	self:GetParent()._attackLifestealModifiersList = self:GetParent()._attackLifestealModifiersList or {}
	self:GetParent()._attackLifestealModifiersList[self] = true
	
	self:GetParent()._onLifestealModifiersList = self:GetParent()._onLifestealModifiersList or {}
	self:GetParent()._onLifestealModifiersList[self] = true
	if IsServer() then self:SendBuffRefreshToClients() end
end

function modifier_item_blood_gem_passive:DeclareFunctions(params)
	local funcs = {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT,
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_MANA_BONUS,
    }
    return funcs
end

function modifier_item_blood_gem_passive:GetModifierHealthBonus()
	return self.bonus_health
end

function modifier_item_blood_gem_passive:GetModifierManaBonus()
	return self.bonus_mana
end

function modifier_item_blood_gem_passive:GetModifierIncomingDamageConstant( params )
	if (self.barrier_block or 0) <= 0 then return end
	if IsServer() then
		local barrier_block = math.min( self.barrier_block, params.damage )
		self:GetAbility():AddFalseBarrier( -barrier_block )
		return -barrier_block
	else
		return self.barrier_block
	end
end

function modifier_item_blood_gem_passive:AddCustomTransmitterData()
	return {barrier_block = self.barrier_block}
end

function modifier_item_blood_gem_passive:HandleCustomTransmitterData(data)
	self.barrier_block = data.barrier_block
end

function modifier_item_blood_gem_passive:GetModifierProperty_MagicalLifesteal(params)
	return self.spell_lifesteal
end

function modifier_item_blood_gem_passive:GetModifierProperty_PhysicalLifesteal(params)
	return self.lifesteal_percent
end

function modifier_item_blood_gem_passive:OnLifesteal(params)
	if params.excess > 0 then
		self.barrier_block = self.barrier_block + math.min( params.excess,  self:GetParent():GetMaxHealth() * self.overheal_maximum - self.barrier_block )
		self:SendBuffRefreshToClients()
	end
end

function modifier_item_blood_gem_passive:IsHidden()
	return true
end

function modifier_item_blood_gem_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE 
end