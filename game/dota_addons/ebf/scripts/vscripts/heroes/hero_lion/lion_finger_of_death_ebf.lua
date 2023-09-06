LinkLuaModifier("modifier_lion_finger_of_death_ebf_bonus", "heroes/hero_lion/lion_finger_of_death_ebf.lua", LUA_MODIFIER_MOTION_NONE)
LinkLuaModifier("modifier_lion_finger_of_death_ebf_death", "heroes/hero_lion/lion_finger_of_death_ebf.lua", LUA_MODIFIER_MOTION_NONE)

lion_finger_of_death_ebf = class({})

function lion_finger_of_death_ebf:GetBehavior()
	if self:GetCaster():HasScepter() then
		return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_AOE
	end
	return DOTA_ABILITY_BEHAVIOR_UNIT_TARGET
end

function lion_finger_of_death_ebf:GetAOERadius()
	if self:GetCaster():HasScepter() then
		return self:GetSpecialValueFor("splash_radius_scepter")
	end
end

function lion_finger_of_death_ebf:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local target = self:GetCursorTarget()
		local targets = {target}

		local damage_delay = self:GetSpecialValueFor("damage_delay")
		local kill_grace_duration = self:GetSpecialValueFor("kill_grace_duration")
		local splash_radius = self:GetSpecialValueFor("splash_radius_scepter")
	 
		local base_damage = self:GetSpecialValueFor("damage")
		local damage_per_kill = self:GetSpecialValueFor("damage_per_kill")
		local extra_int = TernaryOperator( self:GetSpecialValueFor("damage_per_int") * caster:GetIntellect(), caster:HasScepter(), 0 )
		local kill_count = caster:GetModifierStackCount("modifier_lion_finger_of_death_ebf_bonus", caster)
		local damage = math.ceil(base_damage + extra_int + damage_per_kill * kill_count)

		caster:EmitSound("Hero_Lion.FingerOfDeath")

		if caster:HasScepter() then
			targets = FindUnitsInRadius(caster:GetTeamNumber(), target:GetAbsOrigin(), nil, splash_radius, self:GetAbilityTargetTeam(), self:GetAbilityTargetType(), DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES, FIND_ANY_ORDER, false)
		end

		for _, target in pairs(targets) do
			_PlayEffect(caster, target)

			local sound_name = TernaryOperator("Hero_Lion.FingerOfDeathImpact.Immortal", caster:HasScepter(), "Hero_Lion.FingerOfDeathImpact")

			if caster:HasTalent("special_bonus_finger_of_death_health_inf_kill_duration") then
				target:AddNewModifier(caster, self, "modifier_lion_finger_of_death_ebf_death", {duration = nil})
			else
				target:AddNewModifier(caster, self, "modifier_lion_finger_of_death_ebf_death", {duration = kill_grace_duration})
			end

			for i = 1, 1 do
				Timers:CreateTimer(damage_delay * FrameTime(), function()
					if target ~= nil and IsValidEntity(target) and target:IsAlive() and (not target:IsMagicImmune() or caster:HasScepter()) then
						ApplyDamage({
							attacker = caster,
							victim = target,
							damage = damage,
							damage_type = DAMAGE_TYPE_MAGICAL,
							ability = self,
						})
					end
				end)
			end
		end
	end
end

function _PlayEffect(caster, target)
	local particle_finger_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_lion/lion_spell_finger_of_death.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(particle_finger_fx, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack2", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(particle_finger_fx, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(particle_finger_fx, 2, target:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle_finger_fx, 3, target:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle_finger_fx, 4, target:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle_finger_fx, 5, target:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle_finger_fx, 6, target:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle_finger_fx, 7, target:GetAbsOrigin())
	ParticleManager:SetParticleControlEnt(particle_finger_fx, 10, caster, PATTACH_ABSORIGIN, "attach_attack2", caster:GetAbsOrigin(), true)
	ParticleManager:ReleaseParticleIndex(particle_finger_fx)
end

--------------------------------------------------------------------------------

modifier_lion_finger_of_death_ebf_bonus = class({})
function modifier_lion_finger_of_death_ebf_bonus:IsBuff() return true end
function modifier_lion_finger_of_death_ebf_bonus:IsPermanent() return true end
function modifier_lion_finger_of_death_ebf_bonus:IsPurgable() return false end
function modifier_lion_finger_of_death_ebf_bonus:RemoveOnDeath() return false end
function modifier_lion_finger_of_death_ebf_bonus:OnCreated() if not IsServer() then return end self:SetStackCount(1) end
function modifier_lion_finger_of_death_ebf_bonus:OnRefresh() if not IsServer() then return end self:IncrementStackCount() end
function modifier_lion_finger_of_death_ebf_bonus:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL, MODIFIER_PROPERTY_OVERRIDE_ABILITY_SPECIAL_VALUE, MODIFIER_PROPERTY_TOOLTIP, MODIFIER_PROPERTY_HEALTH_BONUS} 
end
function modifier_lion_finger_of_death_ebf_bonus:OnStackCountChanged(old)
	if IsServer() then self:GetParent():CalculateStatBonus(true) end
end

function modifier_lion_finger_of_death_ebf_bonus:GetModifierOverrideAbilitySpecial(params)
	if params.ability == self:GetAbility() then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "damage" then
			return 1
		end
	end
end

function modifier_lion_finger_of_death_ebf_bonus:GetModifierOverrideAbilitySpecialValue(params)
	if params.ability == self:GetAbility() then
		local caster = params.ability:GetCaster()
		local specialValue = params.ability_special_value
		if specialValue == "damage"then
			local flBaseValue = params.ability:GetLevelSpecialValueNoOverride( specialValue, params.ability_special_level )
			return flBaseValue + self:GetStackCount() * self:GetSpecialValueFor("damage_per_kill")
		end
	end
end

function modifier_lion_finger_of_death_ebf_bonus:GetModifierHealthBonus()
	return self:GetStackCount() * self:GetSpecialValueFor("health_per_kill")
end
function modifier_lion_finger_of_death_ebf_bonus:OnTooltip() return self:GetStackCount() * self:GetAbility():GetSpecialValueFor("damage_per_kill") end


modifier_lion_finger_of_death_ebf_death = class({})
function modifier_lion_finger_of_death_ebf_death:IsHidden() return false end
function modifier_lion_finger_of_death_ebf_death:IsPurgable() return false end
function modifier_lion_finger_of_death_ebf_death:GetAttributes() return MODIFIER_ATTRIBUTE_MULTIPLE end
function modifier_lion_finger_of_death_ebf_death:DeclareFunctions()
	return {MODIFIER_PROPERTY_TOOLTIP}
end
function modifier_lion_finger_of_death_ebf_death:OnTooltip()
	return self:GetAbility():GetSpecialValueFor("damage_per_kill")
end
function modifier_lion_finger_of_death_ebf_death:OnRemoved()
	if not IsServer() then return end
	if not self:GetParent():IsAlive() then
		self:GetParent():EmitSoundParams("Hero_Lion.KillCounter", 1, 0.5, 0)
		self:GetCaster():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_lion_finger_of_death_ebf_bonus", {})
	end
end