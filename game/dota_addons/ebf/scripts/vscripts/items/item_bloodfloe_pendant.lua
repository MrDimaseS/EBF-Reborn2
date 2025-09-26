item_bloodfloe_pendant = class({})

function item_bloodfloe_pendant:GetIntrinsicModifierName()
	return "modifier_item_bloodfloe_pendant_passive"
end

modifier_item_bloodfloe_pendant_passive = class({})
LinkLuaModifier( "modifier_item_bloodfloe_pendant_passive", "items/item_bloodfloe_pendant.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_bloodfloe_pendant_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_bloodfloe_pendant_passive:OnRefresh()
	self.bonus_spell_amp = self:GetSpecialValueFor("bonus_spell_amp")
	self.bonus_health_regen = self:GetSpecialValueFor("bonus_health_regen")
	
	self.heal_threshold = self:GetSpecialValueFor("heal_threshold") / 100
	self.explosion_aoe = self:GetSpecialValueFor("explosion_aoe")
	self.freeze_duration = self:GetSpecialValueFor("freeze_duration")
	
	self._internalHeroTable = {}
end

function modifier_item_bloodfloe_pendant_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
			MODIFIER_EVENT_ON_HEAL_RECEIVED,
			}
end

function modifier_item_bloodfloe_pendant_passive:GetModifierSpellAmplify_Percentage()
	return self.bonus_spell_amp
end

function modifier_item_bloodfloe_pendant_passive:GetModifierConstantHealthRegen()
	return self.bonus_health_regen
end

function modifier_item_bloodfloe_pendant_passive:OnHealReceived( params )
	local parent = self:GetParent()
	if not params.unit:IsRealHero() then return end
	local overheal = params.gain - parent:GetHealthDeficit()
	local heal = params.gain
	if overheal > 0 then
		heal = heal - overheal
	end
	if heal <= 0 then return end
	self._internalHeroTable[params.unit] = (self._internalHeroTable[params.unit] or 0) + heal
	if params.unit:GetMaxHealth() * self.heal_threshold < self._internalHeroTable[params.unit] then
		self._internalHeroTable[params.unit] = 0
		
		ParticleManager:FireParticle("particles/neutral_fx/icefire_bomb_explosion.vpcf", PATTACH_POINT_FOLLOW, params.unit, {[0] = params.unit:GetAbsOrigin(),[1] = params.unit:GetAbsOrigin(),[3] = params.unit:GetAbsOrigin()})
		EmitSoundOn("Hero_Lich.IceAge.Tick", params.unit )
		
		local ability = self:GetAbility()
		for _, enemy in ipairs( parent:FindEnemyUnitsInRadius( params.unit:GetAbsOrigin(), self.explosion_aoe ) ) do
			enemy:AddNewModifier( parent, ability, "modifier_item_bloodfloe_pendant_freeze", {duration = self.freeze_duration} )
		end
	end
end

function modifier_item_bloodfloe_pendant_passive:IsHidden()
	return true
end

function modifier_item_bloodfloe_pendant_passive:IsPurgable()
	return false
end

function modifier_item_bloodfloe_pendant_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

modifier_item_bloodfloe_pendant_freeze = class({})
LinkLuaModifier( "modifier_item_bloodfloe_pendant_freeze", "items/item_bloodfloe_pendant.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_bloodfloe_pendant_freeze:CheckState()
	return {[MODIFIER_STATE_DISARMED] = true,
			[MODIFIER_STATE_ROOTED] = true}
end

function modifier_item_bloodfloe_pendant_freeze:GetEffectName()
	return "particles/units/heroes/hero_crystalmaiden/maiden_frostbite_buff.vpcf"
end