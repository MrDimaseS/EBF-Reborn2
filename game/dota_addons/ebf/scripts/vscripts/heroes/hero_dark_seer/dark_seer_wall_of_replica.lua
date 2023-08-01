dark_seer_wall_of_replica = class({})

function dark_seer_wall_of_replica:Precache( context )
	PrecacheResource( "soundfile", "soundevents/game_sounds_heroes/game_sounds_dark_seer.vsndevts", context )
	PrecacheResource( "particle", "particles/status_fx/status_effect_dark_seer_illusion.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_dark_seer/dark_seer_wall_of_replica.vpcf", context )
	PrecacheResource( "particle", "particles/units/heroes/hero_dark_seer/dark_seer_wall_of_replica_replicate.vpcf", context )
end

function dark_seer_wall_of_replica:GetVectorTargetRange()
	return self:GetSpecialValueFor("width")
end

function dark_seer_wall_of_replica:IsDualVectorDirection()
	return true
end

function dark_seer_wall_of_replica:OnVectorCastStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local vector_point = self:GetVectorPosition()
	
	local direction = self:GetVectorDirection()
	CreateModifierThinker( caster, self, "modifier_dark_seer_wall_of_replica_thinker", {duration = self:GetSpecialValueFor( "duration" ), x = direction.x, y = direction.y,}, point, caster:GetTeamNumber(), false )
end

modifier_dark_seer_wall_of_replica_thinker = class({})
LinkLuaModifier( "modifier_dark_seer_wall_of_replica_thinker", "heroes/hero_dark_seer/dark_seer_wall_of_replica", LUA_MODIFIER_MOTION_NONE )

function modifier_dark_seer_wall_of_replica_thinker:OnCreated( kv )
	self.duration = self:GetAbility():GetSpecialValueFor( "slow_duration" )

	local length = self:GetAbility():GetSpecialValueFor( "width" )
	print("created")
	if not IsServer() then return end

	-- get data
	local direction = Vector( kv.x, kv.y, 0 ):Normalized()
	self.origin = self:GetParent():GetOrigin() + direction*length/2
	self.target = self:GetParent():GetOrigin() - direction*length/2

	self.width = 50
	self.bounty = 0
	local tick = 0.5
	self.illusions = {}

	self:StartIntervalThink( tick )
	self:OnIntervalThink()
	
	local effect_cast = ParticleManager:CreateParticle( "particles/units/heroes/hero_dark_seer/dark_seer_wall_of_replica.vpcf", PATTACH_WORLDORIGIN, nil )
	ParticleManager:SetParticleControl( effect_cast, 0, self.origin )
	ParticleManager:SetParticleControl( effect_cast, 1, self.target )

	self:AddEffect( effect_cast )

	EmitSoundOn( "Hero_Dark_Seer.Wall_of_Replica_Start", self:GetParent() )
	EmitSoundOn( "Hero_Dark_Seer.Wall_of_Replica_lp", self:GetParent() )
end

function modifier_dark_seer_wall_of_replica_thinker:OnDestroy()
	if not IsServer() then return end

	-- stop effects
	local sound_loop = "Hero_Dark_Seer.Wall_of_Replica_lp"
	StopSoundOn( sound_loop, self:GetParent() )

	UTIL_Remove( self:GetParent() )
	
	for id, illusion in ipairs( self.illusions ) do
		illusion:SetUnitCanRespawn( false )
		illusion:ForceKill( false )
		illusion:RemoveSelf()
	end
end

function modifier_dark_seer_wall_of_replica_thinker:OnIntervalThink()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	local enemies = caster:FindEnemyUnitsInLine(self.origin, self.target, self.width, {flag = DOTA_UNIT_TARGET_FLAG_INVULNERABLE})
	
	for _,enemy in pairs(enemies) do
		if not enemy:IsInvulnerable() then
			enemy:AddNewModifier(caster, ability, "modifier_dark_seer_wall_slow", { duration = self.duration } )
		end
		if enemy:IsConsideredHero() then
			local id = enemy:entindex()
			if not self.illusions[id] then -- create
				local illusions = enemy:ConjureImage( {ability = ability, illusion_modifier = "modifier_dark_seer_wall_of_replica_illusion", }, self:GetRemainingTime(), caster )
				self.illusions[id] = illusions[1]
				illusions[1]:SetUnitCanRespawn( true )
				illusions[1].hasBeenProcessed = true
			elseif not self.illusions[id]:IsAlive() then -- respawn
				self.illusions[id]:RespawnUnit()
				self.illusions[id]:AddNewModifier( caster, ability, "modifier_dark_seer_wall_of_replica_illusion", {duration = self:GetRemainingTime() } )
				self.illusions[id]:AddNewModifier( caster, ability, "modifier_kill", {duration = self:GetRemainingTime() } )
			end
		end
	end
end

function modifier_dark_seer_wall_of_replica_thinker:IsHidden()
	return true
end

function modifier_dark_seer_wall_of_replica_thinker:IsPurgable()
	return false
end

LinkLuaModifier( "modifier_dark_seer_wall_of_replica_illusion", "heroes/hero_dark_seer/dark_seer_wall_of_replica", LUA_MODIFIER_MOTION_NONE )
modifier_dark_seer_wall_of_replica_illusion = class({})

--------------------------------------------------------------------------------
-- Classifications
function modifier_dark_seer_wall_of_replica_illusion:IsHidden()
	return true
end

function modifier_dark_seer_wall_of_replica_illusion:IsPurgable()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_dark_seer_wall_of_replica_illusion:OnCreated( kv )
	self.outgoing = self:GetSpecialValueFor( "tooltip_outgoing" ) - 100
	self.incoming = self:GetSpecialValueFor( "tooltip_replica_total_damage_incoming" ) - 100
	if not IsServer() then return end
	ParticleManager:FireParticle( "particles/units/heroes/hero_dark_seer/dark_seer_wall_of_replica_replicate.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
end

function modifier_dark_seer_wall_of_replica_illusion:OnDestroy()
	if not IsServer() then return end
	self:GetParent():ForceKill( true )
end

function modifier_dark_seer_wall_of_replica_illusion:DeclareFunctions()
	return {MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE_ILLUSION,
			MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE,
			MODIFIER_PROPERTY_ILLUSION_LABEL,
			MODIFIER_PROPERTY_IS_ILLUSION }
end

function modifier_dark_seer_wall_of_replica_illusion:GetModifierDamageOutgoing_Percentage_Illusion()
	return self.outgoing
end

function modifier_dark_seer_wall_of_replica_illusion:GetModifierIllusionLabel()
	return 1
end

function modifier_dark_seer_wall_of_replica_illusion:GetModifierIncomingDamage_Percentage()
	return self.incoming
end

function modifier_dark_seer_wall_of_replica_illusion:GetIsIllusion()
	return 1
end 

function modifier_dark_seer_wall_of_replica_illusion:GetStatusEffectName()
	return "particles/status_fx/status_effect_dark_seer_illusion.vpcf"
end

function modifier_dark_seer_wall_of_replica_illusion:StatusEffectPriority()
	return 9999
end