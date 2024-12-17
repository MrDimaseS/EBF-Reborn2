nyx_assassin_jolt = class({})

function nyx_assassin_jolt:GetIntrinsicModifierName()
	return "modifier_nyx_assassin_jolt_handler"
end

function nyx_assassin_jolt:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	EmitSoundOn( "Hero_NyxAssassin.Jolt.Cast", caster )
	
	local radius = self:GetSpecialValueFor("aoe")
	if radius > 0 then
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), radius ) ) do
			if enemy ~= target then
				self:Jolt( enemy )
			end
		end
	end
	if not target:TriggerSpellAbsorb( self ) then
		self:Jolt( target )
	end
end

function nyx_assassin_jolt:Jolt( target )
	local caster = self:GetCaster()
	
	local damage = self:GetSpecialValueFor("base_damage") * (1+caster:GetSpellAmplification( false ))
	local jolt = caster:FindModifierByName(self:GetIntrinsicModifierName())
	if jolt then
		if not jolt.damage_tracker then jolt.damage_tracker = {} end
		if not jolt.damage_tracker[target:entindex()] then jolt.damage_tracker[target:entindex()] = 0 end
		damage = damage + jolt.damage_tracker[target:entindex()]
		jolt.damage_tracker[target:entindex()] = 0
	end
	self:DealDamage( caster, target, damage, {damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION} )
	
	local refreshDebuffs = self:GetSpecialValueFor("refresh_debuffs") == 1
	if refreshDebuffs then
		for _, modifier in ipairs( target:FindAllModifiers( ) ) do
			if modifier:GetCaster() == caster then
				modifier:SetDuration( modifier:GetDuration(), true )
				modifier:RefreshAllIndependentStacks( )
			end
		end
	end
	
	ParticleManager:FireRopeParticle("particles/units/heroes/hero_nyx_assassin/nyx_assassin_jolt.vpcf", PATTACH_POINT_FOLLOW, caster, target)
	EmitSoundOn( "Hero_NyxAssassin.Jolt.Target", target )
end

modifier_nyx_assassin_jolt_handler = class({})
LinkLuaModifier( "modifier_nyx_assassin_jolt_handler", "heroes/hero_nyx_assassin/nyx_assassin_jolt.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_nyx_assassin_jolt_handler:OnCreated()
	self:OnRefresh()
end

function modifier_nyx_assassin_jolt_handler:OnRefresh()
	self.damage_tracker = {}
	self.damage_taken_echo_pct = self:GetSpecialValueFor("damage_taken_echo_pct") / 100
	self.damage_dealt_echo_pct = self:GetSpecialValueFor("damage_dealt_echo_pct") / 100
end

function modifier_nyx_assassin_jolt_handler:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_nyx_assassin_jolt_handler:OnTakeDamage( params )
	if params.damage <= 0 then return end
	if self.damage_taken_echo_pct == 0 and self.damage_dealt_echo_pct == 0 then return end
	if not (params.unit == self:GetCaster() or params.attacker == self:GetCaster()) then return end
	if params.inflictor == self:GetAbility() then return end
	self.damage_tracker = self.damage_tracker or {}
	if self.damage_taken_echo_pct > 0 and params.unit == self:GetCaster() then
		self.damage_tracker[params.attacker:entindex()] = (self.damage_tracker[params.attacker:entindex()] or 0) + params.damage * self.damage_taken_echo_pct
	end
	if self.damage_dealt_echo_pct > 0 and params.attacker == self:GetCaster()  then
		self.damage_tracker[params.unit:entindex()] = (self.damage_tracker[params.unit:entindex()] or 0) + params.damage * self.damage_dealt_echo_pct
	end
end

function modifier_nyx_assassin_jolt_handler:IsHidden()
	return true
end