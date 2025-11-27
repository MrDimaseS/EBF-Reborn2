huskar_berserkers_blood = class({})

function huskar_berserkers_blood:IsStealable()
	return true
end

function huskar_berserkers_blood:IsHiddenWhenStolen()
	return false
end

function huskar_berserkers_blood:GetBehavior()
	if self:GetSpecialValueFor("active_duration") > 0 then
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
	else
		return DOTA_ABILITY_BEHAVIOR_PASSIVE
	end
end

function huskar_berserkers_blood:GetIntrinsicModifierName()
	return "modifier_huskar_berserkers_blood_passive"
end

function huskar_berserkers_blood:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier(caster, self, "modifier_huskar_berserkers_blood_fire_hardened", {duration = self:GetSpecialValueFor("active_duration")})
	caster:Dispel( caster )
end

modifier_huskar_berserkers_blood_fire_hardened = class({})
LinkLuaModifier("modifier_huskar_berserkers_blood_fire_hardened", "heroes/hero_huskar/huskar_berserkers_blood", LUA_MODIFIER_MOTION_NONE)

function modifier_huskar_berserkers_blood_fire_hardened:OnCreated()
	self:OnRefresh()
end

function modifier_huskar_berserkers_blood_fire_hardened:OnRefresh()
	self.burn_health_regen = self:GetSpecialValueFor("burn_health_regen")
end

function modifier_huskar_berserkers_blood_fire_hardened:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT}
end

function modifier_huskar_berserkers_blood_fire_hardened:GetModifierConstantHealthRegen()
	return self.burn_health_regen * self:GetParent():GetBurn()
end


modifier_huskar_berserkers_blood_passive = class({})
LinkLuaModifier("modifier_huskar_berserkers_blood_passive", "heroes/hero_huskar/huskar_berserkers_blood", LUA_MODIFIER_MOTION_NONE)

function modifier_huskar_berserkers_blood_passive:OnCreated()
	self:OnRefresh()
	self:StartIntervalThink(0.3)
	if IsServer() then
		self.glowFX = ParticleManager:CreateParticle("particles/units/heroes/hero_huskar/huskar_berserkers_blood_glow.vpcf", PATTACH_POINT_FOLLOW, self:GetParent())
	end
end

function modifier_huskar_berserkers_blood_passive:OnRefresh()
	self.maximum_attack_speed = self:GetSpecialValueFor("maximum_attack_speed")
	self.maximum_magic_resist = self:GetSpecialValueFor("maximum_magic_resist")
	self.maximum_health_regen = self:GetSpecialValueFor("maximum_health_regen") / 100
	self.regen = self:GetParent():GetStrength() * self.maximum_health_regen
	self.hp_threshold_max = self:GetSpecialValueFor("hp_threshold_max")
	self.hpPct = math.min(1, (100 - self:GetParent():GetHealthPercent()) / (100 - self.hp_threshold_max) )
	
	self.burn_immunity_threshold = self:GetSpecialValueFor("burn_immunity_threshold") == 1
end

function modifier_huskar_berserkers_blood_passive:OnDestroy()
	if IsServer() then ParticleManager:ClearParticle( self.glowFX ) end
end

function modifier_huskar_berserkers_blood_passive:OnIntervalThink()
	self.hpPct = math.min(1, (100 - self:GetParent():GetHealthPercent()) / (100 - self.hp_threshold_max) )
	if IsServer() then
		ParticleManager:SetParticleControl(self.glowFX, 1, Vector(self.hpPct * 100, 0, 0) )
	end
	self.regen = self:GetParent():GetStrength() * self.maximum_health_regen
	self.total_as = self.maximum_attack_speed * self.hpPct 
	self.total_mr = self.maximum_magic_resist * self.hpPct 
	self.total_regen = self.regen * self.hpPct
end

function modifier_huskar_berserkers_blood_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT, 
			MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS, 
			MODIFIER_PROPERTY_MODEL_SCALE, 
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
			MODIFIER_PROPERTY_MIN_HEALTH }
end

function modifier_huskar_berserkers_blood_passive:GetModifierAttackSpeedBonus_Constant()
	return self.total_as
end

function modifier_huskar_berserkers_blood_passive:GetModifierConstantHealthRegen()
	return self.total_regen
end

function modifier_huskar_berserkers_blood_passive:GetModifierMagicalResistanceBonus()
	return self.total_mr
end

function modifier_huskar_berserkers_blood_passive:GetModifierIncomingDamage_Percentage( params )
	if not params.inflictor then return end
	self._lastInflictor = params.inflictor
	if not self.burn_immunity_threshold then return end
	if params.inflictor._isBurnDamage then
		local parent = self:GetParent()
		local damageBlockMax = -50 -- 50% from blood magic
		if parent:GetHealthPercent() < self.hp_threshold_max then
			return damageBlockMax
		else
			local goalHP = parent:GetMaxHealth() * self.hp_threshold_max / 100
			local postDamageHP = parent:GetHealth() - params.damage * 0.5
			local damageDiff = math.max( 0, goalHP - postDamageHP )
			local damageBlock = damageBlockMax * ( damageDiff / (params.damage * 0.5) )
			return damageBlock
		end
	end
end

function modifier_huskar_berserkers_blood_passive:GetMinHealth( params )
	if not self._lastInflictor then return end
	if self._lastInflictor._isBurnDamage then
		return 1
	else
		self._lastInflictor = nil
	end
end

function modifier_huskar_berserkers_blood_passive:GetModifierModelScale()
	return 35 * self.hpPct
end
