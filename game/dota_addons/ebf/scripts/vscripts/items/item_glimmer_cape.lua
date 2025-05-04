item_glimmer_cape = class({})

function item_glimmer_cape:GetIntrinsicModifierName()
	return "modifier_item_glimmer_cape_passive"
end

function item_glimmer_cape:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	ParticleManager:FireParticle("particles/items3_fx/glimmer_cape_initial.vpcf", PATTACH_POINT_FOLLOW, target )
	EmitSoundOn("Item.GlimmerCape.Activate", target )
	target:AddNewModifier( caster, self, "modifier_item_glimmer_cape_active", {duration = self:GetSpecialValueFor("duration")} )
end

modifier_item_glimmer_cape_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_glimmer_cape_passive", "items/item_glimmer_cape.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_glimmer_cape_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_glimmer_cape_passive:OnRefresh()
	self.bonus_magical_armor = self:GetSpecialValueFor("bonus_magical_armor")
end

function modifier_item_glimmer_cape_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS}
end

function modifier_item_glimmer_cape_passive:GetModifierMagicalResistanceBonus()
	return self.bonus_magical_armor
end

LinkLuaModifier( "modifier_item_glimmer_cape_active", "items/item_glimmer_cape.lua" ,LUA_MODIFIER_MOTION_NONE )
modifier_item_glimmer_cape_active = class({})

function modifier_item_glimmer_cape_active:OnCreated()
	self:OnRefresh( )
	if IsServer() then
		self:StartIntervalThink( self.initial_fade_delay )
		
		self:SetHasCustomTransmitterData(true)
	end
end

function modifier_item_glimmer_cape_active:OnRefresh()
	self.active_movement_speed = self:GetAbility():GetSpecialValueFor("active_movement_speed")
	self.initial_fade_delay = self:GetAbility():GetSpecialValueFor("initial_fade_delay")
	self.secondary_fade_delay = self:GetAbility():GetSpecialValueFor("secondary_fade_delay")
	self.barrier_to_mana = self:GetAbility():GetSpecialValueFor("barrier_to_mana") / 100
	self.invis = false
	if not IsServer() then return end
	self.barrier_block = self:GetAbility():GetSpecialValueFor("barrier_block")
	self:SendBuffRefreshToClients()
end

function modifier_item_glimmer_cape_active:OnIntervalThink()
	self.invis = true
	self:StartIntervalThink( -1 )
	self:GetParent():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_invisible", {duration = self:GetRemainingTime()} )
end

function modifier_item_glimmer_cape_active:DeclareFunctions(params)
	local funcs = {
		MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT,
		MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,	
		MODIFIER_EVENT_ON_ATTACK,
		MODIFIER_EVENT_ON_ABILITY_EXECUTED,
    }
    return funcs
end

function modifier_item_glimmer_cape_active:GetModifierMoveSpeedBonus_Constant()
	return self.active_movement_speed
end

function modifier_item_glimmer_cape_active:OnAttack(params)
	if params.attacker == self:GetParent() then
		self:StartIntervalThink( self.secondary_fade_delay )
	end
end

function modifier_item_glimmer_cape_active:OnAbilityExecuted(params)
	if params.unit == self:GetParent() then
		self:StartIntervalThink( self.secondary_fade_delay )
	end
end

function modifier_item_glimmer_cape_active:GetModifierIncomingSpellDamageConstant( params )
	if IsServer() then
		local barrier_block = math.min( self.barrier_block, params.damage )
		self.barrier_block = self.barrier_block - barrier_block
		self:GetParent():GiveMana( barrier_block * self.barrier_to_mana )
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

function modifier_item_glimmer_cape_active:AddCustomTransmitterData()
	return {barrier_block = self.barrier_block}
end

function modifier_item_glimmer_cape_active:HandleCustomTransmitterData(data)
	self.barrier_block = data.barrier_block
end
