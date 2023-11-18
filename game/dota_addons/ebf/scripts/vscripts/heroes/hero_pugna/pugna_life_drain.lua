pugna_life_drain = class({})

function pugna_life_drain:GetBehavior()
	return DOTA_ABILITY_BEHAVIOR_PASSIVE
end

function pugna_life_drain:ShouldUseResources()
	return true
end

function pugna_life_drain:ApplyLifeDrain( target )
	local caster = self:GetCaster()
	local duration = self:GetSpecialValueFor("duration")
	
	target:AddNewModifier( caster, self, "modifier_pugna_life_drain_tether", {duration = duration, source = caster:entindex()} )
end

modifier_pugna_life_drain_tether = class({})
LinkLuaModifier("modifier_pugna_life_drain_tether", "heroes/hero_pugna/pugna_life_drain", LUA_MODIFIER_MOTION_NONE)

function modifier_pugna_life_drain_tether:OnCreated(kv)
	self:OnRefresh(kv)
	
	if IsServer() then
		self:StartIntervalThink( self.tick )
		
		-- particles
		local caster = self:GetCaster()
		local parent = self:GetParent()
		EmitSoundOn("Hero_Pugna.LifeDrain.Target", parent)

		if not caster:IsSameTeam( parent ) then
			self.drainFX = ParticleManager:CreateRopeParticle("particles/units/heroes/hero_pugna/pugna_life_drain.vpcf", PATTACH_POINT_FOLLOW, self.source, parent)
		else
			self.drainFX = ParticleManager:CreateRopeParticle("particles/units/heroes/hero_pugna/pugna_life_drain_beam_give.vpcf", PATTACH_POINT_FOLLOW, self.source, parent)
		end
		
		self:AddEffect( self.drainFX )
	end
end

function modifier_pugna_life_drain_tether:OnRefresh(kv)
	self.drain = self:GetSpecialValueFor("health_drain")
	self.heal_pct = self:GetSpecialValueFor("heal_pct") / 100
	self.creep_pct = (100 - self:GetSpecialValueFor("creep_pct")) / 100
	self.drain_buffer = self:GetSpecialValueFor("drain_buffer")
	self.spell_amp_drain_duration = self:GetSpecialValueFor("spell_amp_drain_duration")
	self.tick = 0.25
	
	if IsServer() then self.source = EntIndexToHScript( kv.source ) end
end

function modifier_pugna_life_drain_tether:OnIntervalThink()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	
	-- shard handling
	local source = self.source
	local radius
	if caster:HasShard() and not parent:IsSameTeam( caster ) then
		for ward, wardRadius in pairs( caster.netherwards ) do
			if (source == caster or CalculateDistance( ward, parent ) <= CalculateDistance( source, parent )) and ward:IsAlive() then
				source = ward
				radius = wardRadius
			end
		end
		ParticleManager:SetParticleControlEnt(self.drainFX, 0, source, PATTACH_POINT_FOLLOW, "attach_hitloc", source:GetAbsOrigin(), true)
	end
	
	if CalculateDistance( source, parent ) >= self.drain_buffer + ability:GetTrueCastRange() or caster:IsStunned() or caster:IsSilenced() or not caster:IsAlive() then
		self:Destroy()
		return
	end
	
	if caster:HasScepter() then
		parent:AddNewModifier( caster, ability, "modifier_pugna_life_drain_tether_spell_amp", {duration = self.spell_amp_drain_duration} )
	end
	
	if parent:IsSameTeam( caster ) then -- only exists for FX and distance handling
		if parent:GetHealth() < parent:GetMaxHealth() then
			ParticleManager:SetParticleControl( self.drainFX, 11, Vector(0,0,0) )
		else
			ParticleManager:SetParticleControl( self.drainFX, 11, Vector(1,0,0) )
		end
		return
	end
	
	local damage = ability:DealDamage( caster, parent, self.drain * self.tick )
	local heal_pct = TernaryOperator( 1, parent:IsConsideredHero(), self.creep_pct ) * self.heal_pct
	
	
	if caster:HasShard() and source ~= caster then
		self.alliedBuffs = self.alliedBuffs or {}
		for _, ally in ipairs( caster:FindFriendlyUnitsInRadius( source:GetAbsOrigin(), radius ) ) do
			if ally:IsConsideredHero() then
				if not self.alliedBuffs[ally] then
					self.alliedBuffs[ally] = ally:AddNewModifier( caster, ability, "modifier_pugna_life_drain_tether", {duration = self:GetRemainingTime(), source = source:entindex()} )
				end
				if ally:GetHealth() < ally:GetMaxHealth() then
					ally:HealEvent( damage * heal_pct, ability, caster )
				else
					ally:GiveMana( damage * heal_pct )
				end
			end
		end
	else -- standard behavior
		if caster:GetHealth() < caster:GetMaxHealth() then
			caster:HealEvent( damage * heal_pct, ability, caster )
			ParticleManager:SetParticleControl( self.drainFX, 11, Vector(0,0,0) )
		else
			caster:GiveMana( damage * heal_pct )
			ParticleManager:SetParticleControl( self.drainFX, 11, Vector(1,0,0) )
		end
		if caster:HasScepter() then
			caster:AddNewModifier( caster, ability, "modifier_pugna_life_drain_tether_spell_amp", {duration = self.spell_amp_drain_duration} )
		end
	end
end

function modifier_pugna_life_drain_tether:OnDestroy()
	if IsServer() then
		StopSoundOn("Hero_Pugna.LifeDrain.Target", parent)
		ParticleManager:ClearParticle( self.drainFX )
		if self.alliedBuffs then
			for ally, buff in pairs( self.alliedBuffs ) do
				if IsModifierSafe( buff ) then
					buff:Destroy()
				end
			end
		end
	end
end

function modifier_pugna_life_drain_tether:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

modifier_pugna_life_drain_tether_spell_amp = class({})
LinkLuaModifier("modifier_pugna_life_drain_tether_spell_amp", "heroes/hero_pugna/pugna_life_drain", LUA_MODIFIER_MOTION_NONE)

function modifier_pugna_life_drain_tether_spell_amp:OnCreated()
	self:OnRefresh()
end

function modifier_pugna_life_drain_tether_spell_amp:OnRefresh()
	self.spell_amp_drain_rate = self:GetSpecialValueFor("spell_amp_drain_rate") * 0.25
	self.spell_amp_drain_max = self:GetSpecialValueFor("spell_amp_drain_max")
	self.multiplier = TernaryOperator( 1, self:GetParent():IsSameTeam( self:GetCaster() ), -1 )
	if IsServer() then
		self:SetStackCount( math.min( self.spell_amp_drain_max, self:GetStackCount() + self.spell_amp_drain_rate ) )
	end
end

function modifier_pugna_life_drain_tether_spell_amp:DeclareFunctions()
	local funcs = { MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE }
	return funcs
end

function modifier_pugna_life_drain_tether_spell_amp:GetModifierSpellAmplify_Percentage()
	return self:GetStackCount() * self.multiplier
end