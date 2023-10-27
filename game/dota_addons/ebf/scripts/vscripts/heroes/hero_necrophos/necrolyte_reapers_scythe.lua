necrolyte_reapers_scythe = class({})

function necrolyte_reapers_scythe:GetIntrinsicModifierName()
	return "modifier_necrolyte_reapers_scythe_upgrader"
end

function necrolyte_reapers_scythe:CastFilterResultTarget( target )
	return UnitFilter(target, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, DOTA_UNIT_TARGET_FLAG_NONE, self:GetCaster():GetTeamNumber() )
end

function necrolyte_reapers_scythe:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	EmitSoundOn("Hero_Necrolyte.ReapersScythe.Cast", caster)
	local sFX = ParticleManager:CreateParticle("particles/units/heroes/hero_necrolyte/necrolyte_scythe_start.vpcf", PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(sFX, 1, target:GetAbsOrigin() )
	
	local duration = self:GetSpecialValueFor("stun_duration")
	local damage_per_health = self:GetSpecialValueFor("damage_per_health")
	
	local modifier = self:Stun(target, duration)
	target:AddNewModifier( caster, self, "modifier_necrolyte_reapers_scythe_upgrader_mark", {duration = duration+0.1})
	if modifier then
		local nFX = ParticleManager:CreateParticle("particles/units/heroes/hero_necrolyte/necrolyte_scythe.vpcf", PATTACH_POINT_FOLLOW, target)
		modifier:AddEffect(nFX)
	end
	
	Timers:CreateTimer(duration, function()
		if target:IsAlive() then
			self:DealDamage( caster, target, target:GetHealthDeficit() * damage_per_health )
		end
	end)
end

modifier_necrolyte_reapers_scythe_upgrader_mark = class({})
LinkLuaModifier( "modifier_necrolyte_reapers_scythe_upgrader_mark", "heroes/hero_necrophos/necrolyte_reapers_scythe", LUA_MODIFIER_MOTION_NONE )

function modifier_necrolyte_reapers_scythe_upgrader_mark:IsHidden()	
	return true
end


function modifier_necrolyte_reapers_scythe_upgrader_mark:GetAttributes()
	return ""
end

modifier_necrolyte_reapers_scythe_upgrader = class({})
LinkLuaModifier( "modifier_necrolyte_reapers_scythe_upgrader", "heroes/hero_necrophos/necrolyte_reapers_scythe", LUA_MODIFIER_MOTION_NONE )

function modifier_necrolyte_reapers_scythe_upgrader:OnCreated()
	self:OnRefresh()
end

function modifier_necrolyte_reapers_scythe_upgrader:OnRefresh()
	self.death_pulse_bonus_heal = self:GetSpecialValueFor("death_pulse_bonus_heal")
	self.death_pulse_bonus_dmg = self:GetSpecialValueFor("death_pulse_bonus_dmg")
	self.heartstopper_bonus_hp_regen = self:GetSpecialValueFor("heartstopper_bonus_hp_regen")
	self.heartstopper_bonus_mp_regen = self:GetSpecialValueFor("heartstopper_bonus_mp_regen")
	self.sadist_bonus_duration = self:GetSpecialValueFor("sadist_bonus_duration")
end

function modifier_necrolyte_reapers_scythe_upgrader:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL, MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE, MODIFIER_EVENT_ON_DEATH }
end

function modifier_necrolyte_reapers_scythe_upgrader:GetModifierOverrideAbilitySpecial(params)
	if params.ability:GetAbilityName() == "necrolyte_death_pulse" then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "damage"then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return 1
		elseif specialValue == "heal" then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return 1
		end
	end
	if params.ability:GetAbilityName() == "necrolyte_sadist" then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "duration"then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return 1
		end
	end
	if params.ability:GetAbilityName() == "necrolyte_heartstopper_aura" then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "health_regen"then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return 1
		elseif specialValue == "mana_regen" then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return 1
		end
	end
end

function modifier_necrolyte_reapers_scythe_upgrader:GetModifierOverrideAbilitySpecialValue(params)
	if params.ability:GetAbilityName() == "necrolyte_death_pulse" then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "damage"then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return flBaseValue + self:GetStackCount() * self.death_pulse_bonus_dmg
		elseif specialValue == "heal" then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return flBaseValue + self:GetStackCount() * self.death_pulse_bonus_heal
		end
	end
	if params.ability:GetAbilityName() == "necrolyte_sadist" then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "duration"then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return flBaseValue + self:GetStackCount() * self.sadist_bonus_duration
		end
	end
	if params.ability:GetAbilityName() == "necrolyte_heartstopper_aura" then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "health_regen"then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return flBaseValue + self:GetStackCount() * self.heartstopper_bonus_hp_regen
		elseif specialValue == "mana_regen" then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return flBaseValue + self:GetStackCount() * self.heartstopper_bonus_mp_regen
		end
	end
end


function modifier_necrolyte_reapers_scythe_upgrader:OnDeath(params)
	if params.unit:FindModifierByNameAndCaster("modifier_necrolyte_reapers_scythe_upgrader_mark", self:GetCaster() ) and params.unit:IsConsideredHero() then
		self:IncrementStackCount()
	end
end

function modifier_necrolyte_reapers_scythe_upgrader:IsHidden()
	return self:GetStackCount() == 0
end

function modifier_necrolyte_reapers_scythe_upgrader:UpdateStacks( )
	self:SetStackCount( self.bosses + self.monsters + self.minions )
end

function modifier_necrolyte_reapers_scythe_upgrader:IsPurgable( )
	return false
end

function modifier_necrolyte_reapers_scythe_upgrader:RemoveOnDeath( )
	return false
end

function modifier_necrolyte_reapers_scythe_upgrader:IsPermanent()
	return true
end