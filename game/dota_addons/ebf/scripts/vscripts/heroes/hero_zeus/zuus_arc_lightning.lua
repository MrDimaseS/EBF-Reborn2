zuus_arc_lightning = class({})

function zuus_arc_lightning:GetIntrinsicModifierName()
	return "modifier_zuus_arc_lightning_passive"
end

function zuus_arc_lightning:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	local damage = self:GetSpecialValueFor("arc_damage")
	local radius = self:GetSpecialValueFor("radius")
	local jumpCount = self:GetSpecialValueFor("jump_count")
	local jumpDelay = self:GetSpecialValueFor("jump_delay")
	
	local applyAttack = self:GetSpecialValueFor("apply_attack")
	
	local dmgMax = self:GetSpecialValueFor("bonus_damage_max")
	local dmgMin = self:GetSpecialValueFor("bonus_damage_min")
	local rangeMax = self:GetSpecialValueFor("range_damage_max")
	local rangeMin = self:GetSpecialValueFor("range_damage_min")
	
	self:ChainLightning( target, caster, damage )
	local targetsHit = {[target] = true}
	local prevTarget = target
	Timers:CreateTimer(jumpDelay, function()
		bounces = bounces - 1
		
		
		
		if bounces > 1 then
			return jumpDelay
		end
	end)
end

function zeus_arc_lightning:ChainLightning( target, source, damage )
	local caster = self:GetCaster()
	
	ParticleManager:FireRopeParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", PATTACH_POINT_FOLLOW, source, target, {})
	EmitSoundOn("Hero_Zuus.ArcLightning.Target", target)
	
	if target:TriggerSpellAbsorb( self ) then return end
	self:DealDamage( caster, target, damage )
end

LinkLuaModifier("modifier_zuus_arc_lightning_divine_rampage", "heroes/hero_zeus/zuus_arc_lightning", LUA_MODIFIER_MOTION_NONE)
modifier_zuus_arc_lightning_divine_rampage = class({})

function modifier_zuus_arc_lightning_divine_rampage:OnCreated()
	self.bonus_spell_damage = self:GetSpecialValueFor("bonus_spell_damage") / 100
end

LinkLuaModifier("modifier_zuus_arc_lightning_passive", "heroes/hero_zeus/zuus_arc_lightning", LUA_MODIFIER_MOTION_NONE)
modifier_zuus_arc_lightning_passive = class({})

function modifier_zuus_arc_lightning_passive:OnCreated()
	if IsServer() then self:SetHasCustomTransmitterData(true) end
	self:OnRefresh()
end

function modifier_zuus_arc_lightning_passive:OnRefresh()
	self.bonus_damage_spell = self:GetSpecialValueFor("bonus_damage_spell")
	self.bonus_damage_attack = self:GetSpecialValueFor("bonus_damage_attack")
	self.creep_multiplier = self:GetSpecialValueFor("creep_multiplier")
	self.damage_to_barrier = self:GetSpecialValueFor("damage_to_barrier") / 100

	if IsServer() then
		self.barrier = 0
		self:SendBuffRefreshToClients()
	end
end

function modifier_zuus_arc_lightning_passive:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE, MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT}
end

function modifier_zuus_arc_lightning_passive:OnTakeDamage(params)
	if params.attacker ~= self:GetParent() then return end
	if params.inflictor == self:GetAbility() then return end
	if not self:GetParent():HasAbility( params.inflictor:GetAbilityName() ) then return end
	if self._processingStaticField then return end

	local ability = self:GetAbility()
	local damage = self.bonus_damage_attack
	
	if params.inflictor then
		damage = self.bonus_damage_spell
		EmitSoundOn( "Hero_Zuus.StaticField", params.unit )
	end
	if not params.unit:IsConsideredHero() then
		damage = damage * self.creep_multiplier
	end
	
	ParticleManager:FireParticle("particles/units/heroes/hero_zuus/zuus_arc_lightning.vpcf", PATTACH_POINT_FOLLOW, params.unit )
	local damageDealt = ability:DealDamage( params.attacker, params.unit, damage )
	
	if self.damage_to_barrier > 0 then
		self.barrier = self.barrier + damageDealt * self.damage_to_barrier
		self:SendBuffRefreshToClients()
	end
end

function modifier_zuus_arc_lightning_passive:GetModifierIncomingDamageConstant( params )
	if self.barrier <= 0 then return end
	if IsServer() then
		local barrier = math.min( self.barrier, math.max( self.barrier, params.damage ) )
		self.barrier = math.max( 0, self.barrier - params.damage )
		
		self:SendBuffRefreshToClients()
		return -barrier
	else
		return self.barrier
	end
end

function modifier_zuus_arc_lightning_passive:AddCustomTransmitterData()
	return {barrier = self.barrier}
end

function modifier_zuus_arc_lightning_passive:HandleCustomTransmitterData(data)
	self.barrier = data.barrier
	print( self.barrier, IsClient() )
end

function modifier_zuus_arc_lightning_passive:IsHidden()
	return true
end

function modifier_zuus_arc_lightning_passive:IsPurgable()
	return false
end