riki_blink_strike = class({})

function riki_blink_strike:IsStealable()
	return true
end

function riki_blink_strike:IsHiddenWhenStolen()
	return false
end

function riki_blink_strike:OnSpellStart(bDisableBlink)
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	if not bDisableBlink then
		local NFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_riki/riki_blink_strike.vpcf", PATTACH_POINT_FOLLOW, target )
		ParticleManager:SetParticleControl(NFX, 1, caster:GetAbsOrigin() )
		ParticleManager:SetParticleControlEnt(NFX, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex( NFX )
		local blinkData = {FX = false}
		local position = target:GetAbsOrigin() - target:GetForwardVector() * caster:GetAttackRange()
		caster:Blink( position, blinkData )
		if not caster:IsSameTeam( target ) then
			caster:SetForwardVector( target:GetForwardVector() )
			caster:PerformGenericAttack( target, true, true )
			caster:MoveToTargetToAttack( target )
		end
		
	end
	
	if (bDisableBlink and target:IsConsideredHero()) or not bDisableBlink then
		EmitSoundOn( "Hero_Riki.Blink_Strike", target )
	end
	if not caster:IsSameTeam( target ) then
		self:DealDamage( caster, target, self:GetSpecialValueFor("bonus_damage") )
		if target:HasModifier("modifier_riki_smoke_screen_aura_debuff") then
			self:Stun(target, self:GetSpecialValueFor("slow"), "particles/units/heroes/hero_riki/riki_blink_strike_slow.vpcf")
		else
			target:AddNewModifier( caster, self, "modifier_riki_blinkstrike_slow", {duration = self:GetSpecialValueFor("slow")} )
		end
	end
end