item_blood_gem = class({})

function item_blood_gem:GetIntrinsicModifierName()
	return "modifier_item_blood_gem_passive"
end

function item_blood_gem:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier( caster, self, "modifier_item_blood_gem_active", {duration = self:GetSpecialValueFor("duration")} )
end

item_blood_gem_2 = class(item_blood_gem)
item_blood_gem_3 = class(item_blood_gem)
item_blood_gem_4 = class(item_blood_gem)
item_blood_gem_5 = class(item_blood_gem)

modifier_item_blood_gem_active = class({})
LinkLuaModifier( "modifier_item_blood_gem_active", "items/item_blood_gem.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_blood_gem_active:OnCreated()
	if IsClient() then return end
	local nFX = ParticleManager:CreateParticle("particles/econ/items/wisp/wisp_overcharge_ti7.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
	ParticleManager:SetParticleControlEnt(nFX, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
	self:AddEffect( nFX )
end

modifier_item_blood_gem_passive = class({})
LinkLuaModifier( "modifier_item_blood_gem_passive", "items/item_blood_gem.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_blood_gem_passive:OnCreated()
	self.barrier_block = 0
	if IsServer() then self:SetHasCustomTransmitterData(true) end
	self:OnRefresh()
end

function modifier_item_blood_gem_passive:OnRefresh()
	self.spell_lifesteal = self:GetAbility():GetSpecialValueFor("spell_lifesteal") / 100
	self.lifesteal_percent = self:GetAbility():GetSpecialValueFor("lifesteal_percent") / 100
	self.overheal_maximum = self:GetAbility():GetSpecialValueFor("overheal_maximum") / 100
	
	if IsServer() then self:SendBuffRefreshToClients() end
end

function modifier_item_blood_gem_passive:DeclareFunctions(params)
	local funcs = {
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT
    }
    return funcs
end

function modifier_item_blood_gem_passive:GetModifierIncomingDamageConstant( params )
	if (self.barrier_block or 0) <= 0 then return end
	if IsServer() then
		local barrier_block = math.min( self.barrier_block, math.max( self.barrier_block, params.damage ) )
		self.barrier_block = math.max( 0, self.barrier_block - barrier_block )
		self:SendBuffRefreshToClients()
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


function modifier_item_blood_gem_passive:OnTakeDamage(params)
	if not params.attacker:IsSameTeam( self:GetParent() ) then return end
	if not( self:GetParent():HasModifier("modifier_item_blood_gem_active") or params.attacker == self:GetParent() ) then return end
	local lifestealExcess = 0
	if params.inflictor 
	and not ( HasBit( params.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL ) 
			  or HasBit( params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS ) 
			  or HasBit( params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION ) ) 
	then
		local spell_lifesteal = self.spell_lifesteal
		if not params.unit:IsConsideredHero() then
			spell_lifesteal =  spell_lifesteal / 5
		end
		
		local EHPMult = self:GetParent().EHP_MULT or 1
		local lifesteal = params.damage * spell_lifesteal * math.max( 1, EHPMult )
		
		self.lifeToGive = (self.lifeToGive or 0) + lifesteal
		if self.lifeToGive > 1 then
			local lifeGained = self.lifeToGive
			local preHP = params.attacker:GetHealth()
			params.attacker:HealWithParams( lifeGained, params.inflictor, false, true, self, true )
			self.lifeToGive = self.lifeToGive - math.floor(self.lifeToGive)
			local postHP = params.attacker:GetHealth()
		
			local actualLifeGained = postHP - preHP
			if actualLifeGained > 0 then
				ParticleManager:FireParticle( "particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_POINT_FOLLOW, params.attacker )
			end
			if actualLifeGained < lifeGained then
				lifestealExcess = lifestealExcess + (lifeGained - actualLifeGained)
			end
		end
	end
	if params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
		local EHPMult = self:GetParent().EHP_MULT or 1
		local lifesteal = params.damage * self.lifesteal_percent * math.max( 1, EHPMult )
		
		self.lifeToGive = (self.lifeToGive or 0) + lifesteal
		if self.lifeToGive > 1 then
			local lifeGained = self.lifeToGive
			local preHP = params.attacker:GetHealth()
			params.attacker:HealWithParams( lifeGained, params.inflictor, false, true, self, true )
			self.lifeToGive = self.lifeToGive - math.floor(self.lifeToGive)
			local postHP = params.attacker:GetHealth()
			
			
			local actualLifeGained = postHP - preHP
			if actualLifeGained > 0 then
				ParticleManager:FireParticle( "particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_POINT_FOLLOW, params.attacker )
			end
			if actualLifeGained < lifeGained then
				lifestealExcess = lifestealExcess + (lifeGained - actualLifeGained)
			end
		end
	end
	lifestealExcess = math.min( lifestealExcess,  params.attacker:GetMaxHealth() * self.overheal_maximum - self.barrier_block )
	if lifestealExcess > 0 then
		self.barrier_block = self.barrier_block + lifestealExcess
		self:SendBuffRefreshToClients()
	end
end
	
function modifier_item_blood_gem_passive:IsHidden()
	return true
end

function modifier_item_blood_gem_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE 
end