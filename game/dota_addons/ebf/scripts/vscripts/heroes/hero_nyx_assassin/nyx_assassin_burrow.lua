nyx_assassin_burrow = class({})

function nyx_assassin_burrow:GetAbilityTextureName()
	if self:GetCaster():HasModifier("modifier_nyx_assassin_burrowed") then
		return "nyx_assassin_unburrow"
	else
		return "nyx_assassin_burrow"
	end
end

function nyx_assassin_burrow:IsStealable()
	return false
end

function nyx_assassin_burrow:GetCastPoint()
	if self:GetCaster():HasModifier("modifier_nyx_assassin_burrowed") then
		return 0
	else
		return self:GetSpecialValueFor("AbilityCastPoint")
	end
end

function nyx_assassin_burrow:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	
	if caster:HasModifier("modifier_nyx_assassin_burrowed") then
	else
		if caster:HasModifier("modifier_in_water") then
			EmitSoundOn("Hero_NyxAssassin.Burrow.In.River", caster)
			self.startFX = ParticleManager:FireParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_burrow_water.vpcf", PATTACH_POINT, caster)
		else
			EmitSoundOn("Hero_NyxAssassin.Burrow.In", caster)
			self.startFX = ParticleManager:CreateParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_burrow.vpcf", PATTACH_POINT, caster)
		end
	end
end

function nyx_assassin_burrow:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
	
	if caster:HasModifier("modifier_in_water") then
		StopSoundOn("Hero_NyxAssassin.Burrow.Out.River", caster)
	else
		StopSoundOn("Hero_NyxAssassin.Burrow.Out", caster)
	end
	ParticleManager:ClearParticle( self.startFX )
end

function nyx_assassin_burrow:OnSpellStart()
	local caster = self:GetCaster()
	
	if caster:HasModifier("modifier_nyx_assassin_burrowed") then
		caster:RemoveModifierByName("modifier_nyx_assassin_burrowed")
		caster:StartGesture( ACT_DOTA_CAST_BURROW_END )
	else
		caster:AddNewModifier(caster, self, "modifier_nyx_assassin_burrowed", {})
	end
end

modifier_nyx_assassin_burrowed = class({})
LinkLuaModifier( "modifier_nyx_assassin_burrowed", "heroes/hero_nyx_assassin/nyx_assassin_burrow.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_nyx_assassin_burrowed:OnCreated()
	self.health_regen_rate = self:GetSpecialValueFor("health_regen_rate")
	self.mana_regen_rate = self:GetSpecialValueFor("mana_regen_rate")
	self.magic_resist = self:GetSpecialValueFor("magic_resist")
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
	self.bonus_attack_range = self:GetSpecialValueFor("bonus_attack_range")
	
	self.impale_cooldown_reduction = self:GetSpecialValueFor("impale_cooldown_reduction")
	self.cast_range = self:GetSpecialValueFor("cast_range")
	self.rooted = self:GetSpecialValueFor("rooted") == 1
	self.invis_delay = self:GetSpecialValueFor("invis_delay")
	if self.invis_delay > 0 and IsServer() then
		self:StartIntervalThink( 0 )
	end
end

function modifier_nyx_assassin_burrowed:OnIntervalThink()
	local parent = self:GetParent()
	if parent:HasModifier("modifier_invisible") then
		return
	end
	if not self._lastAttackTime then
		self._lastAttackTime = GameRules:GetGameTime()
	end
	if self._lastAttackTime + self.invis_delay < GameRules:GetGameTime() then
		parent:AddNewModifier( parent, self:GetAbility(), "modifier_invisible", {} )
		self._lastAttackTime = nil
	end
end

function modifier_nyx_assassin_burrowed:CheckState()
	return {[MODIFIER_STATE_ROOTED] = self.rooted}
end

function modifier_nyx_assassin_burrowed:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MODEL_CHANGE,
		MODIFIER_PROPERTY_IGNORE_CAST_ANGLE,
		MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE,
		MODIFIER_PROPERTY_MANA_REGEN_TOTAL_PERCENTAGE,
		MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_PROPERTY_CAST_RANGE_BONUS,
		MODIFIER_PROPERTY_COOLDOWN_PERCENTAGE,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
	return funcs
end

function modifier_nyx_assassin_burrowed:GetModifierModelChange()
	return "models/heroes/nerubian_assassin/mound.vmdl"
end

function modifier_nyx_assassin_burrowed:GetModifierIgnoreCastAngle()
	return 1
end

function modifier_nyx_assassin_burrowed:GetModifierHealthRegenPercentage()
	return self.health_regen_rate
end

function modifier_nyx_assassin_burrowed:GetModifierTotalPercentageManaRegen()
	return self.mana_regen_rate
end

function modifier_nyx_assassin_burrowed:GetModifierMagicalResistanceBonus()
	return self.magic_resist
end

function modifier_nyx_assassin_burrowed:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_nyx_assassin_burrowed:GetModifierAttackRangeBonus()
	return self.bonus_attack_range
end

function modifier_nyx_assassin_burrowed:GetModifierCastRangeBonus( params )
	if IsClient() then
		return self.cast_range
	end
	if not params.ability or params.ability:IsItem() then
		return self.cast_range
	end
end

function modifier_nyx_assassin_burrowed:GetModifierPercentageCooldown( params )
	if params.ability:GetAbilityName() == "nyx_assassin_impale" then
		return self.impale_cooldown_reduction
	end
end

function modifier_nyx_assassin_burrowed:OnTakeDamage( params )
	if self.invis_delay <= 0 then return end
	if params.attacker == self:GetCaster() then
		self._lastAttackTime = GameRules:GetGameTime()
		if params.attacker:HasModifier("modifier_invisible") then
			params.attacker:RemoveModifierByName("modifier_invisible")
		end
	end
end

function modifier_nyx_assassin_burrowed:OnRemoved()
	if IsServer() then
		local caster = self:GetCaster()
		if caster:HasModifier("modifier_in_water") then
			EmitSoundOn("Hero_NyxAssassin.Burrow.Out.River", caster)
			ParticleManager:FireParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_burrow_exit_water.vpcf", PATTACH_POINT, caster, {})
		else
			EmitSoundOn("Hero_NyxAssassin.Burrow.Out", caster)
			ParticleManager:FireParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_burrow_exit.vpcf", PATTACH_POINT, caster, {})
		end
	end
end

function modifier_nyx_assassin_burrowed:GetEffectName()
	return "particles/units/heroes/hero_nyx_assassin/nyx_assassin_burrow_inground.vpcf"
end

function modifier_nyx_assassin_burrowed:IsPurgable()
	return false
end

function modifier_nyx_assassin_burrowed:IsPurgeException()
	return false
end