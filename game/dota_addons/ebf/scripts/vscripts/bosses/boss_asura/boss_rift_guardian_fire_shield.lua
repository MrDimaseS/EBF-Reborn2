boss_rift_guardian_fire_shield = class({})

function boss_rift_guardian_fire_shield:OnSpellStart()
	local caster = self:GetCaster()
	
	caster:AddNewModifier( caster, self, "modifier_boss_rift_guardian_shield", {duration = self:GetSpecialValueFor("duration")})
	EmitSoundOn( "Hero_EmberSpirit.FlameGuard.Cast", caster )
end

modifier_boss_rift_guardian_shield = class({})
LinkLuaModifier( "modifier_boss_rift_guardian_shield", "bosses/boss_asura/boss_rift_guardian_fire_shield", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_rift_guardian_shield:OnCreated()
	self.max_barrier = self:GetParent():GetMaxHealth() * self:GetSpecialValueFor("max_hp_shield") / 100
	self.barrier = self.max_barrier
	self.barrier_regen = self.barrier * self:GetSpecialValueFor("shield_regen") / 100
	
	self.shield_damage = self:GetSpecialValueFor("shield_damage")
	self.radius = self:GetSpecialValueFor("radius")
	self.break_stun = self:GetSpecialValueFor("break_stun")
	self.gate_duration = self:GetSpecialValueFor("gate_duration")
	self.gate_attacks = self:GetSpecialValueFor("gate_attacks")
	
	self.tick = 0.25
	if IsServer() then
		local pFX = ParticleManager:CreateParticle( "particles/econ/items/ember_spirit/ember_ti9/ember_ti9_flameguard.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
		self:AddEffect( pFX )
		
		self:StartIntervalThink( self.tick )
		self:SetHasCustomTransmitterData(true)
		
		EmitSoundOn( "Hero_EmberSpirit.FlameGuard.Loop", self:GetParent() )
	end
end

function modifier_boss_rift_guardian_shield:OnIntervalThink()
	if self.barrier > 0 then
		if self.barrier < self.max_barrier then
			self.barrier = math.min( self.max_barrier, self.barrier + self.barrier_regen * self.tick )
			self:SendBuffRefreshToClients()
		end
		local ability = self:GetAbility()
		local caster = self:GetCaster()
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), self.radius ) ) do
			ability:DealDamage( caster, enemy, self.shield_damage )
		end
	else
		self:Destroy()
	end
end

function modifier_boss_rift_guardian_shield:OnDestroy()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if self.barrier <= 0 then
		ability:Stun( caster, self.break_stun )
	end
	local gate_attacks = self.gate_attacks
	local gate_duration = self:GetSpecialValueFor("gate_duration")
	CreateUnitByNameAsync( "npc_dota_unit_underlord_portal", caster:GetAbsOrigin() + ActualRandomVector( 512, 128 ), true, nil, nil, caster:GetTeamNumber(),
	function(entUnit)
		local totalHeroes = HeroList:GetActiveHeroCount()
		local fullScaling = math.min( totalHeroes, 5 )
		local halfScaling = math.min( totalHeroes - fullScaling, 3 )
		local minScaling = math.min( totalHeroes - fullScaling - halfScaling, 0 )
		entUnit:SetBaseMaxHealth(gate_attacks * fullScaling + math.ceil(gate_attacks) / 2 * halfScaling + minScaling * 1 )
		entUnit:SetMaxHealth( gate_attacks * fullScaling + math.ceil(gate_attacks) / 2 * halfScaling + minScaling * 1 )
		entUnit:SetHealth( entUnit:GetMaxHealth() )
		entUnit:AddNewModifier( caster, ability, "modifier_boss_rift_guardian_shield_rift", {duration = gate_duration})
	end)
	StopSoundOn( "Hero_EmberSpirit.FlameGuard.Loop", caster )
end

function modifier_boss_rift_guardian_shield:CheckState()
	return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
end

function modifier_boss_rift_guardian_shield:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT }
end

function modifier_boss_rift_guardian_shield:GetModifierIncomingDamageConstant( params )
	if IsServer() then
		local barrier = math.min( self.barrier, math.max( self.barrier, params.damage ) )
		self.barrier = self.barrier - params.damage
		self:SendBuffRefreshToClients()
		return -barrier
	else
		return self.barrier
	end
end

function modifier_boss_rift_guardian_shield:AddCustomTransmitterData()
	return {barrier = self.barrier}
end

function modifier_boss_rift_guardian_shield:HandleCustomTransmitterData(data)
	self.barrier = data.barrier
end

modifier_boss_rift_guardian_shield_rift = class({})
LinkLuaModifier( "modifier_boss_rift_guardian_shield_rift", "bosses/boss_asura/boss_rift_guardian_fire_shield", LUA_MODIFIER_MOTION_NONE )
if IsServer() then
	function modifier_boss_rift_guardian_shield_rift:OnCreated( )
		local portalFX = ParticleManager:CreateParticle( "particles/econ/items/underlord/underlord_2021_immortal/underlord_2021_immortal_portal_crimson.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
		self:AddEffect( portalFX )
	end
	
	function modifier_boss_rift_guardian_shield_rift:OnDestroy()
		if self:GetRemainingTime() > 0 then return end
		local caster = self:GetCaster()
		local rift = self:GetParent()
		local ability = self:GetAbility()
		
		if rift:IsAlive() then
			CreateUnitByNameAsync( "npc_dota_boss_rift_general", rift:GetAbsOrigin() + ActualRandomVector( 128, 32 ), true, nil, nil, caster:GetTeamNumber(),
			function(entUnit)
				ParticleManager:FireParticle( "particles/units/heroes/heroes_underlord/abbysal_underlord_portal_arrival_burst.vpcf", PATTACH_POINT_FOLLOW, entUnit )
			end)
		end
		rift:ForceKill( false )
	end
end

function modifier_boss_rift_guardian_shield_rift:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, MODIFIER_EVENT_ON_ABILITY_END_CHANNEL, MODIFIER_EVENT_ON_ABILITY_FULLY_CAST, MODIFIER_EVENT_ON_ABILITY_START , MODIFIER_EVENT_ON_ABILITY_EXECUTED, MODIFIER_EVENT_ON_ORDER   }
end

function modifier_boss_rift_guardian_shield_rift:OnOrder( params )
	if params.unit._fireShieldChannelToKillStarted then
		params.unit._fireShieldChannelToKillStarted = false
	end
end

function modifier_boss_rift_guardian_shield_rift:OnAbilityEndChannel( params )
	if params.ability:GetAbilityName() == "abyssal_underlord_portal_warp" and params.unit._fireShieldChannelToKillStarted then
		self:GetParent():ForceKill( false )
	end
end

function modifier_boss_rift_guardian_shield_rift:OnAbilityFullyCast( params )
	if params.ability:GetAbilityName() == "abyssal_underlord_portal_warp" then
		params.unit._fireShieldChannelToKillStarted = true
	end
end

function modifier_boss_rift_guardian_shield_rift:GetDisableHealing( params )
	return 1
end

function modifier_boss_rift_guardian_shield_rift:IsHidden()
	return true
end

function modifier_boss_rift_guardian_shield_rift:IsPurgable()
	return false
end
