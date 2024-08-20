morphling_waveform = class({})

function morphling_waveform:IsStealable()
    return true
end

function morphling_waveform:IsHiddenWhenStolen()
    return false
end

function morphling_waveform:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()

	local distance = math.max( 50, CalculateDistance(target, caster) )
	local speed = self:GetSpecialValueFor("speed")
	local width = self:GetSpecialValueFor("width")
	
	local minDuration = 0.25
	local actualDuration = distance / speed
	if actualDuration < minDuration then
		speed = distance / minDuration
	end

    ProjectileManager:ProjectileDodge(caster)
    self:FireLinearProjectile( "particles/units/heroes/hero_morphling/morphling_waveform.vpcf", CalculateDirection(target, caster) * speed, distance, width )
	EmitSoundOn("Hero_Morphling.Waveform", caster)
	self:SetActivated( false )
	caster:AddNoDraw()
end

function morphling_waveform:OnProjectileThinkHandle( iProjectile )
	local caster = self:GetCaster()
	local position = ProjectileManager:GetTrackingProjectileLocation( iProjectile )
	
	caster:SetAbsOrigin( position )
end

function morphling_waveform:OnProjectileHitHandle(hTarget, vLocation, iProjectile)
	local caster = self:GetCaster()

	if hTarget then
		local damage = self:GetSpecialValueFor("damage")
		local pct_damage = self:GetSpecialValueFor("pct_damage")
		local debuff_duration = self:GetSpecialValueFor("debuff_duration")
		
		self:DealDamage(caster, hTarget, damage)
		if IsEntitySafe( hTarget ) and hTarget:IsAlive() then
			if pct_damage > 0 then
				caster:PerformGenericAttack(hTarget, true, nil, 0, 100 + pct_damage )
			end
			if debuff_duration > 0 then
				hTarget:AddNewModifier( caster, self, "modifier_morphling_waveform_attack_slow", {duration = debuff_duration} )
			end
		end
	else -- no more projectile
		self:SetActivated( true )
		caster:RemoveNoDraw()
		FindClearSpaceForUnit( caster, vLocation, true )
	end
end

modifier_morphling_waveform_attack_slow = class({})
LinkLuaModifier( "modifier_morphling_waveform_attack_slow", "heroes/hero_morphling/morphling_waveform", LUA_MODIFIER_MOTION_NONE )

function modifier_morphling_waveform_attack_slow:OnCreated()
	self:OnRefresh()
end

function modifier_morphling_waveform_attack_slow:OnCreated()
	self.attack_slow = self:GetSpecialValueFor("attack_slow")
end

function modifier_morphling_waveform_attack_slow:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT}
end

function modifier_morphling_waveform_attack_slow:GetModifierAttackSpeedBonus_Constant()
	return -self.attack_slow
end

function modifier_morphling_waveform_attack_slow:GetEffectName()
	return "particles/econ/events/ti7/shivas_guard_slow.vpcf"
end
