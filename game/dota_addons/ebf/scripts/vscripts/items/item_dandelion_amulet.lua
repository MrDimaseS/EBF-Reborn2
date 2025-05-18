item_dandelion_amulet = class({})

function item_dandelion_amulet:ShouldUseResources()
	return true
end

function item_dandelion_amulet:GetIntrinsicModifierName()
	return "modifier_item_dandelion_amulet_passive"
end

modifier_item_dandelion_amulet_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_dandelion_amulet_passive", "items/item_dandelion_amulet.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_dandelion_amulet_passive:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:SetHasCustomTransmitterData(true)
	end
end

function modifier_item_dandelion_amulet_passive:OnRefresh()
	self.move_speed = self:GetSpecialValueFor("move_speed")
	self.mana = self:GetSpecialValueFor("mana")
	self.bonus_int = self:GetSpecialValueFor("bonus_int")
	self.magic_block = self:GetSpecialValueFor("magic_block")
	self.min_damage = self:GetSpecialValueFor("min_damage") / 100
	self.linger_duration = self:GetSpecialValueFor("linger_duration")
end

function modifier_item_dandelion_amulet_passive:OnIntervalThink()
	local ability = self:GetAbility()
	self.barrier_block = 0
	self:StartIntervalThink( -1 )
	self:SendBuffRefreshToClients()
end

function modifier_item_dandelion_amulet_passive:OnDestroy()
	if IsServer() then
		ParticleManager:ClearParticle(self.nFX, true)
	end
end

function modifier_item_dandelion_amulet_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_MANA_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_INCOMING_SPELL_DAMAGE_CONSTANT,
			}
end

function modifier_item_dandelion_amulet_passive:GetModifierManaBonus( params )
	return self.mana
end

function modifier_item_dandelion_amulet_passive:GetModifierMoveSpeedBonus_Constant()
	return self.move_speed
end

function modifier_item_dandelion_amulet_passive:GetModifierBonusStats_Intellect( params )
	return self.bonus_int
end

function modifier_item_dandelion_amulet_passive:GetModifierIncomingSpellDamageConstant( params )
	if IsServer() and self:GetAbility():IsCooldownReady() and params.damage >= self:GetParent():GetMaxHealth() * self.min_damage then
		self:GetAbility():SetCooldown()
		self.barrier_block = self.magic_block
		self:SendBuffRefreshToClients()
		self:StartIntervalThink( self.linger_duration )
	end
	if not self.barrier_block or self.barrier_block <= 0 then return end
	if IsServer() then
		local barrier_block = math.max( math.min( self.barrier_block, math.max( self.barrier_block, params.damage ) ), 0 )
		self.barrier_block = self.barrier_block - params.damage
		self:SendBuffRefreshToClients()
		return -barrier_block
	else
		return self.barrier_block
	end
end

function modifier_item_dandelion_amulet_passive:AddCustomTransmitterData()
	return {barrier_block = self.barrier_block}
end

function modifier_item_dandelion_amulet_passive:HandleCustomTransmitterData(data)
	self.barrier_block = data.barrier_block
end
