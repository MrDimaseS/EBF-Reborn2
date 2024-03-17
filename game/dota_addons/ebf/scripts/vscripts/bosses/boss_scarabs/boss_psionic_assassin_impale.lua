boss_psionic_assassin_impale = class({})

function boss_psionic_assassin_impale:GetAOERadius()
	return self:GetSpecialValueFor("unburrow_aoe")
end

function boss_psionic_assassin_impale:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
	
	caster:AddNewModifier( caster, self, "modifier_invulnerable", {} )
	caster:AddNoDraw()
	
	EmitSoundOn( "Hero_NyxAssassin.Impale", caster )
	
	self:FireLinearProjectile( "particles/units/heroes/hero_nyx_assassin/nyx_assassin_impale.vpcf", CalculateDirection( target, caster ) * self:GetSpecialValueFor("speed"), math.min( self:GetSpecialValueFor("length"), CalculateDistance( caster, target ) ), self:GetSpecialValueFor("width") )
end

function boss_psionic_assassin_impale:OnProjectileHit(target, position)
	local caster = self:GetCaster()
	if target then
		EmitSoundOn( "Hero_NyxAssassin.Impale", caster )
		target:AddNewModifier( caster, self, "modifier_nyx_assassin_impale", {duration = self:GetSpecialValueFor("duration")} )
	else -- end
		caster:RemoveNoDraw()
		FindClearSpaceForUnit( caster, position, true )
		caster:StartGesture( ACT_DOTA_CAST_BURROW_END )
		caster:RemoveModifierByName("modifier_invulnerable")
		
		local damage = self:GetSpecialValueFor("unburrow_damage")
		local radius = self:GetSpecialValueFor("unburrow_aoe")
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), radius ) ) do
			self:DealDamage( caster, enemy, damage )
		end
		
		EmitSoundOn("Hero_NyxAssassin.Burrow.Out", caster)
		EmitSoundOn("Hero_NyxAssassin.SpikedCarapace.Stun", caster)
		ParticleManager:FireParticle("particles/units/heroes/hero_leshrac/leshrac_split_earth.vpcf", PATTACH_POINT, caster, {[0]=GetGroundPosition( caster:GetAbsOrigin(), caster ), [1]=Vector(radius, 0, 0)})
	end
end