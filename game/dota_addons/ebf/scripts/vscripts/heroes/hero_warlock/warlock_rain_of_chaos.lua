warlock_rain_of_chaos = class({})

function warlock_rain_of_chaos:ShouldUseResources()
	return true
end

function warlock_rain_of_chaos:OnOwnerDied()
	local golem_on_death = self:GetSpecialValueFor("golem_on_death") == 1
	local become_golem = self:GetSpecialValueFor("become_golem") == 1
	local golem_duration = self:GetSpecialValueFor("golem_duration")
	if golem_on_death and not become_golem then
		self:SpawnGolem( caster:GetAbsOrigin(), golem_duration )
	end
end

function warlock_rain_of_chaos:OnOwnerSpawned()
	local golem_on_death = self:GetSpecialValueFor("golem_on_death") == 1
	local become_golem = self:GetSpecialValueFor("become_golem") == 1
	if golem_on_death and become_golem then
		caster:AddNewModifier( caster, self, "modifier_warlock_rain_of_chaos_golem_form", {duration = golem_duration} )
		caster:AddNewModifier( caster, self, "modifier_warlock_rain_of_chaos_immolating_presence", {duration = golem_duration} )
		ParticleManager:FireParticle( "particles/units/heroes/hero_warlock/warlock_rain_of_chaos_start.vpcf", PATTACH_WORLDORIGIN, nil, {[0] = caster:GetAbsOrigin()} )
	end
end

function warlock_rain_of_chaos:OnSpellStart()
	local caster = self:GetCaster()
	local position = self:GetCursorPosition()
	
	local become_golem = self:GetSpecialValueFor("become_golem") == 1
	local stun_delay = self:GetSpecialValueFor("stun_delay")
	local stun_duration = self:GetSpecialValueFor("stun_duration")
	local number_of_golems = self:GetSpecialValueFor("number_of_golems")
	local golem_duration = self:GetSpecialValueFor("golem_duration")
	local aoe = self:GetSpecialValueFor("aoe")
	
	if become_golem then
		caster:AddNewModifier( caster, self, "modifier_invulnerable", {duration = stun_delay} )
		EmitSoundOnLocationWithCaster( caster:GetAbsOrigin(), "Hero_Warlock.RainOfChaos", caster )
		ParticleManager:FireParticle( "particles/units/heroes/hero_warlock/warlock_death.vpcf", PATTACH_POINT_FOLLOW, caster )
		caster:StartGestureWithFadeAndPlaybackRate( ACT_DOTA_DIE, 1, 1, 3 )
	else
		EmitSoundOnLocationWithCaster( position, "Hero_Warlock.RainOfChaos", caster )
	end
	ParticleManager:FireParticle( "particles/units/heroes/hero_warlock/warlock_rain_of_chaos_start.vpcf", PATTACH_WORLDORIGIN, nil, {[0] = position} )
	
	Timers:CreateTimer( stun_delay, function()
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( position, aoe ) ) do
			local stun = self:Stun(enemy, stun_duration)
			Timers:CreateTimer( 0.1, function()
				if not IsModifierSafe( stun ) then
					caster:SpawnImp( enemy:GetAbsOrigin() + RandomVector( 300 ) )
					return
				end
				return 0.1
			end)
		end
		
		if become_golem then
			caster:RemoveGesture( ACT_DOTA_DIE )
			caster:Blink( position )
			caster:AddNewModifier( caster, self, "modifier_warlock_rain_of_chaos_golem_form", {duration = golem_duration} )
			caster:AddNewModifier( caster, self, "modifier_warlock_rain_of_chaos_immolating_presence", {duration = golem_duration} )
		else
			for i = 1, number_of_golems do
				self:SpawnGolem( position + math.floor(number_of_golems/2) * RandomVector( 200 ), golem_duration )
			end
		end
		ParticleManager:FireParticle( "particles/units/heroes/hero_warlock/warlock_rain_of_chaos.vpcf", PATTACH_WORLDORIGIN, nil, {[0] = position, [1] = Vector( aoe, 0, 0 )} )
	end)
end

function warlock_rain_of_chaos:SpawnGolem(position, duration)
	local caster = self:GetCaster()
	local golem = caster:CreateSummon( "npc_dota_warlock_golem", position, duration  )
	
	FindClearSpaceForUnit(golem, position, true)
	local golemHP = self:GetSpecialValueFor("golem_hp")
	local golemDmg = self:GetSpecialValueFor("golem_dmg")
	local golemArmor = self:GetSpecialValueFor("tooltip_golem_armor")
	local golemSpeed = self:GetSpecialValueFor("golem_movement_speed")

	golem:SetCoreHealth( golemHP )
	golem:SetAverageBaseDamage( golemDmg, 10 )
	golem:SetPhysicalArmorBaseValue( golemArmor )
	golem:SetBaseMoveSpeed( golemSpeed )
	
	golem:AddNewModifier( caster, self, "modifier_warlock_rain_of_chaos_immolating_presence", {duration} )
	return golem
end

LinkLuaModifier("modifier_warlock_rain_of_chaos_immolating_presence", "heroes/hero_warlock/warlock_rain_of_chaos", LUA_MODIFIER_MOTION_NONE)
modifier_warlock_rain_of_chaos_immolating_presence = class({})

function modifier_warlock_rain_of_chaos_immolating_presence:OnCreated()
	self:OnRefresh()
end

function modifier_warlock_rain_of_chaos_immolating_presence:OnRefresh()
	self.bonus_magic_resistance = self:GetSpecialValueFor("bonus_magic_resistance")
	self.golem_health_regen = self:GetSpecialValueFor("golem_health_regen")
	self.bonus_slow_resistance = self:GetSpecialValueFor("bonus_slow_resistance")
	self.immolation_radius = self:GetSpecialValueFor("immolation_radius")
	self.immolation_linger_duration = self:GetSpecialValueFor("immolation_linger_duration")
end

function modifier_warlock_rain_of_chaos_immolating_presence:DeclareFunctions()
	return {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			MODIFIER_PROPERTY_SLOW_RESISTANCE_STACKING,
			MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE }
end

function modifier_warlock_rain_of_chaos_immolating_presence:GetModifierMagicalResistanceBonus()
	return self.bonus_magic_resistance
end

function modifier_warlock_rain_of_chaos_immolating_presence:GetModifierHealthRegenPercentage()
	return self.golem_health_regen
end

function modifier_warlock_rain_of_chaos_immolating_presence:GetModifierSlowResistance_Stacking()
	return self.bonus_slow_resistance
end

function modifier_warlock_rain_of_chaos_immolating_presence:IsAura()
	return true
end

function modifier_warlock_rain_of_chaos_immolating_presence:GetModifierAura()
	return "modifier_warlock_rain_of_chaos_immolating_presence_debuff"
end

function modifier_warlock_rain_of_chaos_immolating_presence:GetAuraRadius()
	return self.immolation_radius
end

function modifier_warlock_rain_of_chaos_immolating_presence:GetAuraDuration()
	return self.immolation_linger_duration
end

function modifier_warlock_rain_of_chaos_immolating_presence:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_warlock_rain_of_chaos_immolating_presence:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_warlock_rain_of_chaos_immolating_presence:GetEffectName()
	return "particles/units/heroes/hero_brewmaster/brewmaster_fire_immolation_owner_rays.vpcf"
end

LinkLuaModifier("modifier_warlock_rain_of_chaos_immolating_presence_debuff", "heroes/hero_warlock/warlock_rain_of_chaos", LUA_MODIFIER_MOTION_NONE)
modifier_warlock_rain_of_chaos_immolating_presence_debuff = class({})

function modifier_warlock_rain_of_chaos_immolating_presence_debuff:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink( 1 )
	end
end

function modifier_warlock_rain_of_chaos_immolating_presence_debuff:OnRefresh()
	self.immolation_radius = self:GetSpecialValueFor("immolation_radius")
	self.immolation_damage = self:GetSpecialValueFor("immolation_damage")
	self.immolation_heal_reduction = self:GetSpecialValueFor("immolation_heal_reduction")
end

function modifier_warlock_rain_of_chaos_immolating_presence_debuff:OnIntervalThink()
	self:GetAbility():DealDamage( self:GetCaster(), self:GetParent(), self.immolation_damage )
end

function modifier_warlock_rain_of_chaos_immolating_presence_debuff:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED,
			MODIFIER_PROPERTY_HEAL_AMPLIFY_PERCENTAGE_SOURCE,
			MODIFIER_PROPERTY_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,}
end

function modifier_warlock_rain_of_chaos_immolating_presence_debuff:GetModifierHealAmplify_PercentageSource()
	return self.immolation_heal_reduction
end

function modifier_warlock_rain_of_chaos_immolating_presence_debuff:GetModifierLifestealRegenAmplify_Percentage()
	return self.immolation_heal_reduction
end

function modifier_warlock_rain_of_chaos_immolating_presence_debuff:GetModifierSpellLifestealRegenAmplify_Percentage()
	return self.immolation_heal_reduction
end

function modifier_warlock_rain_of_chaos_immolating_presence_debuff:GetModifierHPRegenAmplify_Percentage()
	return self.immolation_heal_reduction
end

function modifier_warlock_rain_of_chaos_immolating_presence_debuff:OnAttackLanded( params )
	if params.target ~= self:GetParent() then return end
	if params.attacker:GetPlayerOwnerID() ~= self:GetCaster():GetPlayerOwnerID() then return end
	for _, enemy in ipairs( self:GetCaster():FindEnemyUnitsInRadius( params.target:GetAbsOrigin(), self.immolation_radius ) ) do
		self:GetAbility():DealDamage( self:GetCaster(), enemy, self.immolation_damage )
	end
end

function modifier_warlock_rain_of_chaos_immolating_presence_debuff:GetEffectName()
	return "particles/units/heroes/hero_brewmaster/brewmaster_fire_immolation_child.vpcf"
end

function modifier_warlock_rain_of_chaos_immolating_presence_debuff:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

LinkLuaModifier("modifier_warlock_rain_of_chaos_golem_form", "heroes/hero_warlock/warlock_rain_of_chaos", LUA_MODIFIER_MOTION_NONE)
modifier_warlock_rain_of_chaos_golem_form = class({})

function modifier_warlock_rain_of_chaos_golem_form:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:GetCaster():SetAttackCapability( DOTA_UNIT_CAP_MELEE_ATTACK )
	end
end

function modifier_warlock_rain_of_chaos_golem_form:OnRefresh()
	self.golem_hp = self:GetSpecialValueFor("golem_hp")
	self.golem_dmg = self:GetSpecialValueFor("golem_dmg")
	self.golem_movement_speed = self:GetSpecialValueFor("golem_movement_speed")
	self.golem_armor = self:GetSpecialValueFor("tooltip_golem_armor")
end

function modifier_warlock_rain_of_chaos_golem_form:OnDestroy()
	self:OnRefresh()
	if IsServer() then
		self:GetCaster():SetAttackCapability( DOTA_UNIT_CAP_RANGED_ATTACK )
	end
end

function modifier_warlock_rain_of_chaos_golem_form:DeclareFunctions()
	return {MODIFIER_PROPERTY_HEALTH_BONUS,
			MODIFIER_PROPERTY_BASEATTACK_BONUSDAMAGE,
			MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE,
			MODIFIER_PROPERTY_ATTACK_RANGE_BASE_OVERRIDE,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_MODEL_CHANGE }
end

function modifier_warlock_rain_of_chaos_golem_form:GetModifierHealthBonus()
	return self.golem_hp
end

function modifier_warlock_rain_of_chaos_golem_form:GetModifierBaseAttack_BonusDamage()
	return self.golem_dmg
end

function modifier_warlock_rain_of_chaos_golem_form:GetModifierMoveSpeedOverride()
	return self.golem_movement_speed
end

function modifier_warlock_rain_of_chaos_golem_form:GetModifierAttackRangeOverride()
	return 150
end

function modifier_warlock_rain_of_chaos_golem_form:GetModifierPhysicalArmorBonus()
	return self.golem_armor
end

function modifier_warlock_rain_of_chaos_golem_form:GetModifierModelChange()
	return "models/heroes/warlock/warlock_demon.vmdl"
end

function modifier_warlock_rain_of_chaos_golem_form:IsHidden()
	return true
end