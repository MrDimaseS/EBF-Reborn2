tidehunter_kraken_shell = class({})

function tidehunter_kraken_shell:GetIntrinsicModifierName()
	return "modifier_tidehunter_kraken_shell_passive"
end

function tidehunter_kraken_shell:ShouldUseResources()
	return true
end

LinkLuaModifier("modifier_tidehunter_kraken_shell_passive", "heroes/hero_tidehunter/tidehunter_kraken_shell", LUA_MODIFIER_MOTION_NONE)
modifier_tidehunter_kraken_shell_passive = class({})

function modifier_tidehunter_kraken_shell_passive:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink( 0.1 )
	end
end

function modifier_tidehunter_kraken_shell_passive:OnRefresh()
	self.bonus_duration_per_kill = self:GetSpecialValueFor("bonus_duration_per_kill")
end

function modifier_tidehunter_kraken_shell_passive:OnIntervalThink()
	local caster = self:GetCaster()
	if caster:HasModifier("modifier_tidehunter_kraken_shell_effect") then return end
	local ability = self:GetAbility()
	if ability:IsCooldownReady() then
		caster:AddNewModifier( caster, ability, "modifier_tidehunter_kraken_shell_effect", {} )
	end
end

function modifier_tidehunter_kraken_shell_passive:DeclareFunctions()
	return {MODIFIER_EVENT_ON_DEATH,
			MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL,
			MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE}
end

function modifier_tidehunter_kraken_shell_passive:GetModifierOverrideAbilitySpecial(params)
	if params.ability == self:GetAbility() and (self.bonus_duration_per_kill or 0) > 0 then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "linger_duration" then
			return 1
		end
	end
end

function modifier_tidehunter_kraken_shell_passive:GetModifierOverrideAbilitySpecialValue(params)
	if params.ability == self:GetAbility() and self.bonus_duration_per_kill > 0 then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "linger_duration" then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return flBaseValue + self:GetStackCount() * self.bonus_duration_per_kill
		end
	end
end

function modifier_tidehunter_kraken_shell_passive:OnDeath( params )
	if params.unit:IsConsideredHero() and params.unit:HasModifier("modifier_tidehunter_anchor_smash") and self.bonus_duration_per_kill > 0 then
		self:IncrementStackCount()
	end
end

function modifier_tidehunter_kraken_shell_passive:IsHidden()
	return self:GetStackCount() == 0
end

function modifier_tidehunter_kraken_shell_passive:IsPurgable()
	return false
end

LinkLuaModifier("modifier_tidehunter_kraken_shell_effect", "heroes/hero_tidehunter/tidehunter_kraken_shell", LUA_MODIFIER_MOTION_NONE)
modifier_tidehunter_kraken_shell_effect = class({})

function modifier_tidehunter_kraken_shell_effect:OnCreated()
	self.linger_duration = self:GetSpecialValueFor("linger_duration")
	self.health_restore = self:GetSpecialValueFor("health_restore")
	self.spell_amp_bonus_duration = self:GetSpecialValueFor("spell_amp_bonus_duration")
end

function modifier_tidehunter_kraken_shell_effect:OnIntervalThink()
end

function modifier_tidehunter_kraken_shell_effect:OnDestroy()
	if IsServer() then
		self:GetAbility():SetFrozenCooldown( false )
	end
end

function modifier_tidehunter_kraken_shell_effect:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE}
end

function modifier_tidehunter_kraken_shell_effect:GetModifierIncomingDamage_Percentage( params )
	if self:GetParent():PassivesDisabled() and self:GetDuration() <= 0 then return end
	if params.damage < 0 then return end
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	if not self.triggered then
		local NFX = ParticleManager:CreateParticle("particles/units/heroes/hero_tidehunter/tidehunter_kraken_shell_shieldp_buff.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster )
		ParticleManager:SetParticleControlEnt(NFX, 1, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		self:AddEffect( NFX )
		
		if self.health_restore > 0 then
			caster:HealEvent(self.health_restore, self, caster)
		else
			caster:AddNewModifier(caster, self:GetAbility(), "modifier_tidehunter_kraken_shell_mawcaller", {duration = self.spell_amp_bonus_duration})
		end

		self.triggered = true
		self:SetDuration( self.linger_duration, true )
		ability:SetCooldown()
		ability:SetFrozenCooldown( true )
	end
	if self:GetSpecialValueFor("should_ravage") > 0 then
        local target = params.attacker
		self.ravage = caster:FindAbilityByName("tidehunter_ravage")
		if self.ravage:GetLevel() > 0 then
			local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_tidehunter/tidehunter_ravage_tentacle_model.vpcf", PATTACH_POINT, caster)
			ParticleManager:SetParticleControl(nfx, 0, target:GetAbsOrigin())
			ParticleManager:ReleaseParticleIndex(nfx)
			
			local position = target:GetAbsOrigin()
			target:ApplyKnockBack(position, 0.5, 0.5, 0, 350, caster, ability)
			ability:Stun(target, self.ravage:GetSpecialValueFor("duration"))
			if self:GetSpecialValueFor("autoattack") ~= 0 then
				caster:PerformGenericAttack(target, true, {neverMiss = true, procAttackEffects = true})
			end
			EmitSoundOn( "Hero_Tidehunter.RavageDamage", target )
			Timers:CreateTimer( 0.5, function()
				self.ravage:DealDamage(caster, target, self.ravage:GetSpecialValueFor("damage"))
			end)
		end
	end
	return -80
end

function modifier_tidehunter_kraken_shell_effect:IsHidden()
	return self:GetRemainingTime() < 0
end

modifier_tidehunter_kraken_shell_mawcaller = class({})
LinkLuaModifier("modifier_tidehunter_kraken_shell_mawcaller", "heroes/hero_tidehunter/tidehunter_kraken_shell", LUA_MODIFIER_MOTION_NONE)
function modifier_tidehunter_kraken_shell_mawcaller:OnCreated()
	self:OnRefresh()
end
function modifier_tidehunter_kraken_shell_mawcaller:IsBuff()
	return true
end
function modifier_tidehunter_kraken_shell_mawcaller:IsPurgable()
	return true
end
function modifier_tidehunter_kraken_shell_mawcaller:OnRefresh()
	self.spell_amp_bonus = self:GetSpecialValueFor("spell_amp_bonus")
end
function modifier_tidehunter_kraken_shell_mawcaller:DeclareFunctions()
	return {MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE}
end
function modifier_tidehunter_kraken_shell_mawcaller:GetModifierSpellAmplify_Percentage()
	return self.spell_amp_bonus
end