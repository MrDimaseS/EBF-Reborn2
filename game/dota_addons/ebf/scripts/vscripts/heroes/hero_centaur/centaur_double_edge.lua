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