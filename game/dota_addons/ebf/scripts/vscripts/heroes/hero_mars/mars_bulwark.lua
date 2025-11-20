mars_bulwark = class({})

function mars_bulwark:IsStealable()
	return false
end

function mars_bulwark:IsHiddenWhenStolen()
	return false
end

function mars_bulwark:OnToggle()
	local caster = self:GetCaster()
	if self:GetToggleState() then
		caster:AddNewModifier( caster, self, "modifier_mars_bulwark_toggle", {})
	else
		caster:RemoveModifierByName("modifier_mars_bulwark_toggle") 
	end
end

function mars_bulwark:GetIntrinsicModifierName()
	return "modifier_mars_bulwark_passive"
end

modifier_mars_bulwark_toggle = class(toggleModifierBaseClass)
LinkLuaModifier( "modifier_mars_bulwark_toggle", "heroes/hero_mars/mars_bulwark.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_mars_bulwark_toggle:OnCreated()
	self.redirect_speed_penatly = -self:GetSpecialValueFor("redirect_speed_penatly")
	self.redirect_chance = self:GetSpecialValueFor("redirect_chance")
	self.redirect_range = self:GetSpecialValueFor("redirect_range")
	self.redirect_taunts = self:GetSpecialValueFor("redirect_taunts") == 1
	self.ally_radius = self:GetSpecialValueFor("ally_radius")
	if IsServer() then
		self:GetAbility().lastTimeScepterAttacked = 0
		self:StartIntervalThink( 0 )
		GameRules:GetGameModeEntity():SetTrackingProjectileFilter( Dynamic_Wrap( modifier_mars_bulwark_toggle, "RedirectTrackingProjectiles" ), self )
	end
end

function modifier_mars_bulwark_toggle:OnDestroy()
	if IsServer() then
		GameRules:GetGameModeEntity():ClearTrackingProjectileFilter()
		for _, soldier in ipairs( self:GetAbility()._marsSoldiers or {} ) do
			if soldier._isCurrentlyActive then
				soldier._isCurrentlyActive = false
				soldier:AddNoDraw()
			end
		end
	end
end

BASE_PLAYBACKRATE = 1/1.7

function modifier_mars_bulwark_toggle:OnIntervalThink()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if not ability._marsSoldiers then return end -- arena isn't skilled yet
	if not caster:HasModifier("modifier_mars_arena_of_blood_aura_buff") then
		for _, soldier in ipairs( ability._marsSoldiers ) do
			if soldier._isCurrentlyActive then
				soldier._isCurrentlyActive = false
				soldier:AddNoDraw()
			end
		end
		return
	else
		for _, soldier in ipairs( ability._marsSoldiers ) do
			soldier:SetAbsOrigin( caster:GetAbsOrigin() + caster:GetRightVector() * soldier._soldierOffset )
			soldier:SetForwardVector( caster:GetForwardVector() )
			if not soldier._isCurrentlyActive then
				soldier._isCurrentlyActive = true
				soldier:RemoveNoDraw()
			end
		end
	end
	if GameRules:GetGameTime() < ability.lastTimeScepterAttacked + caster:GetSecondsPerAttack(false) then return end
	ability.lastTimeScepterAttacked = GameRules:GetGameTime()
	local attackSpeed = caster:GetAttackSpeed(true)
	local unitsHit = {}
	
	for _, soldier in ipairs( ability._marsSoldiers ) do
		local attackAnimationRate = BASE_PLAYBACKRATE * attackSpeed
		soldier:StartGestureWithPlaybackRate( ACT_DOTA_ATTACK, attackAnimationRate )
		EmitSoundOn( "Hero_Mars.PreAttack", soldier )
		Timers:CreateTimer( soldier:GetAttackAnimationPoint() / attackAnimationRate, function()
			for _, enemy in ipairs( caster:FindEnemyUnitsInLine( soldier:GetAbsOrigin(), soldier:GetAbsOrigin() + caster:GetForwardVector() * caster:GetAttackRange(), caster:GetAttackRange() ) )  do
				if not unitsHit[enemy] then
					unitsHit[enemy] = true
					caster:PerformGenericAttack( enemy, true )
				end
			end
		end)
	end
end

function modifier_mars_bulwark_toggle:CheckState()
	return {[MODIFIER_STATE_DISARMED] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true,}
end

function modifier_mars_bulwark_toggle:DeclareFunctions()
	return {MODIFIER_PROPERTY_DISABLE_TURNING,
			MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
			MODIFIER_PROPERTY_IGNORE_CAST_ANGLE,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_EVENT_ON_ATTACK_START}
end

function modifier_mars_bulwark_toggle:GetModifierDisableTurning()
	return 1
end

function modifier_mars_bulwark_toggle:GetModifierIgnoreCastAngle()
	return 1
end

function modifier_mars_bulwark_toggle:GetActivityTranslationModifiers()
	return "bulwark"
end

function modifier_mars_bulwark_toggle:GetModifierMoveSpeedBonus_Percentage()
	return self.redirect_speed_penatly
end

function modifier_mars_bulwark_toggle:RedirectTrackingProjectiles( filterTable )
	local isAttack = filterTable.is_attack
	
	if not isAttack then return true end
	local attacker = EntIndexToHScript( filterTable.entindex_source_const )
	local caster = self:GetCaster()
	if not IsEntitySafe( attacker) or attacker:IsSameTeam( caster ) then return true end
	local target = EntIndexToHScript( filterTable.entindex_target_const )
	if not IsEntitySafe( target ) or target == caster then return true end
	if not self:RollPRNG( self.redirect_chance ) then return true end
	attacker:PerformGenericAttack( caster, false )
	return false
end

function modifier_mars_bulwark_toggle:OnAttackStart( params )
	if not self.redirect_taunts then return end
	local caster = self:GetCaster()
	if params.target == caster then return end
	if CalculateDistance( params.target, caster ) > self.redirect_range then return end
	if not self:RollPRNG( self.redirect_chance ) then return end
	params.attacker:SetForceAttackTarget( caster )
	Timers:CreateTimer( 1, function() params.attacker:SetForceAttackTarget( nil ) end )
end

function modifier_mars_bulwark_toggle:IsAura()
	return self.ally_radius > 0
end

function modifier_mars_bulwark_toggle:GetModifierAura()
	return "modifier_mars_bulwark_passive"
end

function modifier_mars_bulwark_toggle:GetAuraRadius()
	return self.ally_radius
end

function modifier_mars_bulwark_toggle:GetAuraDuration()
	return 0.5
end

function modifier_mars_bulwark_toggle:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_mars_bulwark_toggle:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_HERO
end

function modifier_mars_bulwark_toggle:GetAuraEntityReject( unit )
	return unit == self:GetCaster()
end

modifier_mars_bulwark_passive = class({})
LinkLuaModifier( "modifier_mars_bulwark_passive", "heroes/hero_mars/mars_bulwark.lua" ,LUA_MODIFIER_MOTION_NONE )
function modifier_mars_bulwark_passive:OnCreated()
	self:OnRefresh()
	self.rebuke = self:GetCaster():FindAbilityByName("mars_gods_rebuke")
end

function modifier_mars_bulwark_passive:OnCreated()
	self.physical_damage_reduction = self:GetSpecialValueFor("physical_damage_reduction")
	self.forward_angle = self:GetSpecialValueFor("forward_angle")
	self.physical_damage_reduction_side = self:GetSpecialValueFor("physical_damage_reduction_side")
	self.side_angle = self:GetSpecialValueFor("side_angle")
	
	self.damage_duration = self:GetSpecialValueFor("damage_duration")
	self.front_damage_boost = self:GetSpecialValueFor("front_damage_boost")
	self.side_damage_boost = self:GetSpecialValueFor("side_damage_boost")
	self.back_damage_boost = self:GetSpecialValueFor("back_damage_boost")
end

function modifier_mars_bulwark_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_PERCENTAGE}
end

BIG_BLOCK = 2
SMALL_BLOCK = 1

function modifier_mars_bulwark_passive:GetModifierIncomingPhysicalDamage_Percentage( params )
	local damageBlock
	local blocked
	local shieldsUp = params.target:HasModifier("modifier_mars_bulwark_toggle")
	if params.target:IsAtAngleWithEntity(params.attacker, self.forward_angle) and shieldsUp then
		damageBlock = -self.physical_damage_reduction
		blocked = BIG_BLOCK
	elseif params.target:IsAtAngleWithEntity(params.attacker, self.side_angle) or params.target:IsAtAngleWithEntity(params.attacker, self.forward_angle) then
		damageBlock = -self.physical_damage_reduction_side
		blocked = SMALL_BLOCK
	end
	if self.damage_duration > 0 then
		local buff = params.target:AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_mars_bulwark_damage_amp", {duration = self.damage_duration})
		if blocked then
			if blocked == BIG_BLOCK then
				buff:SetStackCount( math.max( buff:GetStackCount(), self.front_damage_boost ) )
			else
				buff:SetStackCount( math.max( buff:GetStackCount(), self.side_damage_boost ) )
			end
		else
			buff:SetStackCount( math.max( buff:GetStackCount(), self.back_damage_boost ) )
		end
	end
	if blocked then
		if blocked == BIG_BLOCK and params.attacker:IsConsideredHero() then
			ParticleManager:FireParticle("particles/units/heroes/hero_mars/mars_shield_of_mars.vpcf", PATTACH_ABSORIGIN_FOLLOW, params.target, {[0] = "attach_hitloc"})
			EmitSoundOn("Hero_Mars.Shield.Block", params.target)
			
			if self.rebuke and self.rebuke:IsTrained() then
				if shieldsUp and RollPercentage( self:GetSpecialValueFor("rebuke_chance") ) then
					self.rebuke:Rebuke( self:GetCaster(), params.attacker:GetAbsOrigin() )
				end
			end
		else
			ParticleManager:FireParticle("particles/units/heroes/hero_mars/mars_shield_of_mars_small.vpcf", PATTACH_ABSORIGIN_FOLLOW, params.target, {[0] = "attach_hitloc"})
			EmitSoundOn("Hero_Mars.Shield.BlockSmall", params.target)
		end
		params.target:StartGesture( ACT_DOTA_OVERRIDE_ABILITY_2 )
	end
	return damageBlock
end

function modifier_mars_bulwark_passive:IsHidden()
	return self:GetParent() == self:GetCaster()
end

function modifier_mars_bulwark_passive:IsPurgable()
	return false
end

function modifier_mars_bulwark_passive:IsPurgeException()
	return false
end

function modifier_mars_bulwark_passive:IsDebuff()
	return false
end

modifier_mars_bulwark_damage_amp = class({})
LinkLuaModifier( "modifier_mars_bulwark_damage_amp", "heroes/hero_mars/mars_bulwark.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_mars_bulwark_damage_amp:OnCreated()
	self.damage_amp = self:GetSpecialValueFor("front_damage_boost")
end

function modifier_mars_bulwark_damage_amp:DeclareFunctions()
	return {MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE, MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_mars_bulwark_damage_amp:GetModifierDamageOutgoing_Percentage()
	return self:GetStackCount()
end

function modifier_mars_bulwark_damage_amp:OnAttackLanded( params )
	if params.attacker ~= self:GetParent() then return end
	self:Destroy()
end