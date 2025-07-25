item_soul_ring = class({})

function item_soul_ring:GetIntrinsicModifierName()
	return "modifier_item_soul_ring_passive"
end

function item_soul_ring:OnToggle()
	local caster = self:GetCaster()
	if self:GetToggleState() then
		self._soulRingToggle = caster:AddNewModifier( caster, self, "modifier_item_soul_ring_toggle", {})
	elseif self._soulRingToggle then
		self._soulRingToggle:SetDuration( self:GetSpecialValueFor("max_hp_loss_tick"), true )
		self._soulRingToggle = nil
	end
end

modifier_item_soul_ring_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_soul_ring_passive", "items/item_soul_ring.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_soul_ring_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_soul_ring_passive:OnRefresh()
	self.bonus_strength = self:GetSpecialValueFor("bonus_strength")
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
end

function modifier_item_soul_ring_passive:OnDestroy()
	if not IsServer() then return end
	self:GetCaster():RemoveModifierByName("modifier_item_soul_ring_toggle")
end

function modifier_item_soul_ring_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS}
end

function modifier_item_soul_ring_passive:GetModifierBonusStats_Strength()
	return self.bonus_strength
end

function modifier_item_soul_ring_passive:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

modifier_item_soul_ring_toggle = class(persistentModifier)
LinkLuaModifier( "modifier_item_soul_ring_toggle", "items/item_soul_ring.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_soul_ring_toggle:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:OnIntervalThink()
		self:StartIntervalThink( self.max_hp_loss_tick )
		EmitSoundOn("DOTA_Item.SoulRing.Activate", self:GetParent() )
	end
end

function modifier_item_soul_ring_toggle:OnRefresh()
	self.max_hp_loss = self:GetSpecialValueFor("max_hp_loss") / 100
	self.max_hp_loss_tick = self:GetSpecialValueFor("max_hp_loss_tick")
	-- self.loss_to_gain = self:GetSpecialValueFor("loss_to_gain")
	self.mana_gain = self:GetSpecialValueFor("mana_gain")
	self.mana_gain_radius = self:GetSpecialValueFor("mana_gain_radius")
end

function modifier_item_soul_ring_toggle:OnIntervalThink()
	local parent = self:GetParent()
	local selfDamage = parent:GetMaxHealth() * self.max_hp_loss
	local ability = self:GetAbility()
	if not ability:GetToggleState() then return end
	local damageTaken = ability:DealDamage( parent, parent, selfDamage, {damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_BYPASSES_ALL_BLOCK } )
	
	ParticleManager:FireParticle("particles/items2_fx/soul_ring.vpcf", PATTACH_POINT_FOLLOW, parent )
	EmitSoundOn( "LotusPool.Target", parent )
	
	-- old mana gain based on hp loss
	-- local manaGain = (self._manaGainLeftOver or 0) + (damageTaken / self.loss_to_gain) * self.mana_gain
	-- self._manaGainLeftOver = manaGain % 1
	-- print( manaGain, self._manaGainLeftOver )

	-- new flat mana gain
	local manaGain = self.mana_gain

	for _, ally in ipairs( parent:FindFriendlyUnitsInRadius( parent:GetAbsOrigin(), self.mana_gain_radius ) ) do
		ally:GiveMana( manaGain )
		ParticleManager:FireRopeParticle("particles/items/item_soul_ring_consumption.vpcf", PATTACH_POINT_FOLLOW, ally, parent )
	end
end

function modifier_item_soul_ring_toggle:GetAttributes()
	return MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE
end

function modifier_item_soul_ring_toggle:IsHidden()
	return self:GetRemainingTime() >= 0
end