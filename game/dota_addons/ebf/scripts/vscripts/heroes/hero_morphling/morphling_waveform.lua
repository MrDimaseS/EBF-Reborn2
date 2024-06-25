morphling_waveform = class({})

function morph_wave:IsStealable()
    return true
end

function morph_wave:IsHiddenWhenStolen()
    return false
end

function morph_wave:GetIntrinsicModifierName()
	return "modifier_morph_wave_charges_handle"
end

function morph_wave:HasCharges()
	return true
end

function morph_wave:GetManaCost(iLevel)
	if self:GetCaster():IsIllusion() then
		return 0
	end
end

function morph_wave:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("range")
end

function morph_wave:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()

	local distance = CalculateDistance(target, caster)
	local speed = self:GetSpecialValueFor("speed")
	local width = self:GetSpecialValueFor("width")

    ProjectileManager:ProjectileDodge(caster)
    self:FireLinearProjectile( "particles/units/heroes/hero_morphling/morphling_waveform.vpcf", CalculateDirection(target, caster) * speed, distance, width )
	EmitSoundOn("Hero_Morphling.Waveform", caster)
	self:SetActivated( false )
end

function morphling_waveform:OnProjectileThinkHandle( iProjectile )
end

function morph_wave:OnProjectileHitHandle(hTarget, vLocation, iProjectile)
	local caster = self:GetCaster()

	if hTarget and not hTarget:TriggerSpellAbsorb(self) then
		local damage = self:GetSpecialValueFor("damage")
		local pct_damage = self:GetSpecialValueFor("pct_damage")
		local attack_slow = self:GetSpecialValueFor("attack_slow")
		local debuff_duration = self:GetSpecialValueFor("debuff_duration")
		
		self:DealDamage(caster, hTarget, damage)
		if IsEntitySafe( hTarget ) and hTarget:IsAlive() then
			if pct_damage > 0 then
				caster:PerformGenericAttack(hTarget, true, nil, 0, pct_damage )
			end
			if debuff_duration > 0 then
			end
		end
	else -- no more projectile
		self:SetActivated( true )
	end
end