boss_death_avatar_death_seeker = class({})

function boss_death_avatar_death_seeker:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	self:FireTrackingProjectile("particles/units/heroes/hero_necrolyte/necrolyte_death_seeker_enemy.vpcf", target,  self:GetSpecialValueFor("projectile_speed"))
	
	caster:AddNewModifier( caster, self, "modifier_invulnerable", {} )
	caster:AddNoDraw()
	
	EmitSoundOn( "Hero_Necrolyte.DeathSeeker", caster )
end

function boss_death_avatar_death_seeker:OnProjectileHit( target, position )
	if target then
		local caster = self:GetCaster()
		
		target:AddNewModifier( caster, self, "modifier_boss_death_avatar_death_seeker_debuff", {duration = self:GetSpecialValueFor("ethereal_duration")} )
		
		caster:RemoveNoDraw()
		FindClearSpaceForUnit( caster, position, true )
		caster:RemoveModifierByName("modifier_invulnerable")
	end
end

modifier_boss_death_avatar_death_seeker_debuff = class({})
LinkLuaModifier( "modifier_boss_death_avatar_death_seeker_debuff", "bosses/boss_necrophos/boss_death_avatar_death_seeker", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_death_avatar_death_seeker_debuff:OnCreated()
	self.magic_resistance_reduction = self:GetSpecialValueFor("magic_resistance_reduction")
end

function modifier_boss_death_avatar_death_seeker_debuff:CheckState()
	if self:GetParent():IsSameTeam( self:GetCaster() ) then
		return {[MODIFIER_STATE_ATTACK_IMMUNE] = true}
	else
		return {[MODIFIER_STATE_DISARMED] = true}
	end
end

function modifier_boss_death_avatar_death_seeker_debuff:DeclareFunctions()
	return {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS}
end

function modifier_boss_death_avatar_death_seeker_debuff:GetModifierMagicalResistanceBonus()
	return -self.magic_resistance_reduction
end

function modifier_boss_death_avatar_death_seeker_debuff:GetEffectName()
	return "particles/items_fx/ghost.vpcf"
end

function modifier_boss_death_avatar_death_seeker_debuff:GetStatusEffectName()
	return "particles/status_fx/status_effect_ghost.vpcf"
end

function modifier_boss_death_avatar_death_seeker_debuff:StatusEffectPriority()
	return 5
end