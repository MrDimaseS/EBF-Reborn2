centaur_double_edge = class({})

function centaur_double_edge:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end
function centaur_double_edge:GetIntrinsicModifierName()
	return "modifier_centaur_double_edge_stepperazer"
end
function centaur_double_edge:OnSpellStart()
	if IsClient() then return end

	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("edge_damage")
	local self_damage_multiplier = self:GetSpecialValueFor("self_damage") / 100
	local max_self_damage_multiplier = self:GetSpecialValueFor("max_self_damage") / 100
	local self_damage = damage * self_damage_multiplier
	local max_self_damage = damage * max_self_damage_multiplier
	local enemies_hit = 0

	local str_pct_duration = self:GetSpecialValueFor("strength_duration")
	local max_str_stacks = self:GetSpecialValueFor("max_strength_stacks")
	local add_strength = str_pct_duration ~= 0
	local str_modifier = nil
	if add_strength then
		str_modifier = caster:AddNewModifier(caster, self, "modifier_centaur_double_edge_chieftain", { duration = str_pct_duration })
	end

	local allied_lifesteal_radius = self:GetSpecialValueFor("allied_lifesteal_radius")
	local allied_lifesteal_self_damage = self:GetSpecialValueFor("allied_lifesteal_self_damage") / 100
	local allied_lifesteal_enemy_damage = self:GetSpecialValueFor("allied_lifesteal_enemy_damage") / 100
	local self_lifesteal = self:GetSpecialValueFor("self_lifesteal") / 100

	local stepperazer = caster:FindModifierByName("modifier_centaur_double_edge_stepperazer")
	local final_enemy_damage = damage + stepperazer:GetStackCount()
	stepperazer:SetStackCount(0)

	local heal_allies = allied_lifesteal_radius ~= 0

	local enemies = caster:FindEnemyUnitsInRadius(target:GetAbsOrigin(), radius)
	for _, enemy in ipairs(enemies) do
		if not enemy:TriggerSpellAbsorb(self) then
			if add_strength and str_modifier then
				str_modifier:AddIndependentStack({ limit = max_str_stacks })
			end

			self:DealDamage(caster, enemy, final_enemy_damage)
			enemies_hit = enemies_hit + 1
		end
	end

	local final_self_damage = math.min(self_damage * enemies_hit, max_self_damage)
	self:DealDamage(caster, caster, final_self_damage, { damage_flags = DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION })

	if heal_allies then
		local allies = caster:FindFriendlyUnitsInRadius(caster:GetAbsOrigin(), allied_lifesteal_radius)
		for _, ally in ipairs(allies) do
			if ally == caster then
				caster:HealEvent(final_enemy_damage * enemies_hit * self_lifesteal, self, caster, false)
			else
				ally:HealEvent(final_enemy_damage * enemies_hit * allied_lifesteal_enemy_damage + final_self_damage * allied_lifesteal_self_damage, self, caster, false)
			end
		end
	end

	-- particles
	local particle = "particles/units/heroes/hero_centaur/centaur_double_edge.vpcf"
	local effect = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(effect, 0, caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(effect, 1, target:GetAbsOrigin())
	ParticleManager:SetParticleControl(effect, 5, target:GetAbsOrigin())

	-- sounds
	local sound = "Hero_Centaur.DoubleEdge"
	EmitSoundOn(sound, caster)
end

modifier_centaur_double_edge_chieftain = class({})
LinkLuaModifier( "modifier_centaur_double_edge_chieftain", "heroes/hero_centaur/centaur_double_edge", LUA_MODIFIER_MOTION_NONE )

function modifier_centaur_double_edge_chieftain:IsHidden()
	return self:GetStackCount() == 0
end
function modifier_centaur_double_edge_chieftain:IsDebuff()
	return false
end
function modifier_centaur_double_edge_chieftain:IsPurgable()
	return false
end
function modifier_centaur_double_edge_chieftain:OnCreated()
	self:OnRefresh()
	if IsClient() then return end

	self:StartIntervalThink(0)
end
function modifier_centaur_double_edge_chieftain:OnRefresh()
	self.str_pct_per_stack = self:GetSpecialValueFor("strength_pct_per_hit") / 100
end
function modifier_centaur_double_edge_chieftain:OnIntervalThink()
	self.strength = self:GetParent():GetStrength() * self.str_pct_per_stack * self:GetStackCount()
	self:GetParent():CalculateStatBonus(true)
end
function modifier_centaur_double_edge_chieftain:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS
	}
end
function modifier_centaur_double_edge_chieftain:GetModifierBonusStats_Strength()
	return self.strength
end

modifier_centaur_double_edge_stepperazer = class({})
LinkLuaModifier( "modifier_centaur_double_edge_stepperazer", "heroes/hero_centaur/centaur_double_edge", LUA_MODIFIER_MOTION_NONE )

function modifier_centaur_double_edge_stepperazer:IsHidden()
	return false
end
function modifier_centaur_double_edge_stepperazer:IsDebuff()
	return false
end
function modifier_centaur_double_edge_stepperazer:IsPurgable()
	return false
end
function modifier_centaur_double_edge_stepperazer:OnCreated()
	self:OnRefresh()
end
function modifier_centaur_double_edge_stepperazer:OnRefresh()
	self.damage_taken_multiplier = self:GetSpecialValueFor("damage_taken_multiplier")
	self.damage_taken_multiplier_maximum = self:GetSpecialValueFor("damage_taken_multiplier_maximum") / 100
	self.maximum_bonus_damage = self:GetSpecialValueFor("edge_damage") * self.damage_taken_multiplier_maximum
end
function modifier_centaur_double_edge_stepperazer:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_TOOLTIP,
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}
end
function modifier_centaur_double_edge_stepperazer:OnTooltip()
	return self:GetStackCount()
end
function modifier_centaur_double_edge_stepperazer:OnTakeDamage(params)
	if self.damage_taken_multiplier ~= 0 and params.unit and params.unit == self:GetParent() then
		local damage_added = params.damage * self.damage_taken_multiplier
		local stacks = self:GetStackCount()
		local new_stacks = math.min(stacks + damage_added, self.maximum_bonus_damage)
		self:SetStackCount(new_stacks)
	end
end

function modifier_centaur_double_edge_stepperazer:IsHidden()
	return self:GetStackCount() <= 0
end

--[[
centaur_double_edge = class({})

function centaur_double_edge:GetIntrinsicModifierName()
	return "modifier_centaur_double_edge_counter_strike"
end

function centaur_double_edge:IsStealable()
	return true
end

function centaur_double_edge:IsHiddenWhenStolen()
	return false
end

function centaur_double_edge:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	local edgeDamage = self:GetSpecialValueFor( "edge_damage" )
	local bonusDamage = 0
	local selfDamage = self:GetSpecialValueFor("self_damage") / 100
	local maxSelfDamage = self:GetSpecialValueFor("max_self_damage") / 100
	local unitCap = math.floor( maxSelfDamage / selfDamage + 0.5 )
	local radius = self:GetSpecialValueFor("radius")
	
	local counterStrike = caster:FindModifierByName( self:GetIntrinsicModifierName() )
	
	if counterStrike then
		bonusDamage = edgeDamage * (counterStrike:GetStackCount() / 100)
		counterStrike:SetStackCount( 0 )
	end
	
	EmitSoundOn( "Hero_Centaur.DoubleEdge", caster )
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_centaur/centaur_double_edge.vpcf", PATTACH_ABSORIGIN_FOLLOW, target)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin()) -- Origin
	ParticleManager:SetParticleControl(particle, 1, target:GetAbsOrigin()) -- Destination
	ParticleManager:SetParticleControl(particle, 5, target:GetAbsOrigin()) -- Hit Glow
	
	local units = caster:FindEnemyUnitsInRadius(target:GetAbsOrigin(), radius)
	for _, enemy in ipairs(units) do
		if not enemy:TriggerSpellAbsorb( self ) then
			self:DealDamage( caster, enemy, edgeDamage + bonusDamage, {damage_type = DAMAGE_TYPE_MAGICAL} )
			if caster:HasShard() then
				if enemy:IsConsideredHero() then
					local buff = caster:AddNewModifier( caster, self, "modifier_centaur_doubleedge_buff", {duration = self:GetSpecialValueFor("shard_str_duration")} )
					if buff:GetStackCount() < self:GetSpecialValueFor("shard_max_stacks") then
						buff:IncrementStackCount()
					end
				end
				target:AddNewModifier( caster, self, "modifier_centaur_doubleedge_slow", {duration = self:GetSpecialValueFor("shard_movement_slow_duration")} )
			end
		end
	end
	self:DealDamage( caster, caster, edgeDamage * selfDamage * math.min(#units, unitCap), {damage_type = DAMAGE_TYPE_MAGICAL, damage_flags = DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION})
end

modifier_centaur_double_edge_counter_strike = class({})
LinkLuaModifier("modifier_centaur_double_edge_counter_strike", "heroes/hero_centaur/centaur_double_edge", LUA_MODIFIER_MOTION_NONE)

function modifier_centaur_double_edge_counter_strike:OnCreated()
	self.stack_duration = self:GetSpecialValueFor("stack_duration")
	self.pct_of_incoming_damage_as_bonus = self:GetSpecialValueFor("pct_of_incoming_damage_as_bonus") / 100
	self.max_damage_increase_pct = self:GetSpecialValueFor("max_damage_increase_pct") / 100
	self.max_damage_increase = self:GetSpecialValueFor("edge_damage") * self.max_damage_increase_pct
	self.damage_increase = 0
end

function modifier_centaur_double_edge_counter_strike:OnIntervalThink()
	self:SetStackCount( 0 )
end

function modifier_centaur_double_edge_counter_strike:DeclareFunctions()
	return {MODIFIER_PROPERTY_TOOLTIP, MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_centaur_double_edge_counter_strike:OnTooltip()
	return self:GetStackCount()
end

function modifier_centaur_double_edge_counter_strike:OnTakeDamage( params )
	if params.unit == self:GetParent() and self.stack_duration > 0 then
		local damageAdded = params.damage * self.pct_of_incoming_damage_as_bonus
		self.damage_increase = math.min( self.max_damage_increase, self.damage_increase + damageAdded )
		
		self:SetStackCount( math.floor( ( self.damage_increase / self.max_damage_increase ) * 100 ) )
		
		self:StartIntervalThink( self.stack_duration )
		self:SetDuration( self.stack_duration + 0.1, true )
	end
end

function modifier_centaur_double_edge_counter_strike:DestroyOnExpire()
	return false
end

function modifier_centaur_double_edge_counter_strike:IsPurgable()
	return false
end

function modifier_centaur_double_edge_counter_strike:IsHidden()
	return self:GetStackCount() == 0
end
]]