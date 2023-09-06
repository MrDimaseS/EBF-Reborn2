zuus_thundergods_wrath = class({})

function zuus_thundergods_wrath:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	EmitSoundOn( "Hero_Zuus.GodsWrath.PreCast", caster )
	
	-- self.startFXL = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_thundergods_wrath_start.vpcf", PATTACH_ABSORIGIN, caster )
	-- ParticleManager:SetParticleControl( self.startFXL, 0, caster:GetAbsOrigin() )
	-- ParticleManager:SetParticleControlEnt(self.startFXL, 1, self, PATTACH_POINT_FOLLOW, "attach_attack1", caster:GetAbsOrigin(), true)
	-- ParticleManager:SetParticleControl( self.startFXL, 2, caster:GetAbsOrigin() )
	
	-- self.startFXR = ParticleManager:CreateParticle("particles/units/heroes/hero_zuus/zuus_thundergods_wrath_start.vpcf", PATTACH_ABSORIGIN, caster )
	-- ParticleManager:SetParticleControl( self.startFXR, 0, caster:GetAbsOrigin() )
	-- ParticleManager:SetParticleControlEnt(self.startFXR, 1, self, PATTACH_POINT_FOLLOW, "attach_attack2", caster:GetAbsOrigin(), true)
	-- ParticleManager:SetParticleControl( self.startFXR, 2, caster:GetAbsOrigin() )
end

function zuus_thundergods_wrath:OnAbilityPhaseInterrupted()
	local caster = self:GetCaster()
	StopSoundOn( "Hero_Zuus.GodsWrath.PreCast", caster )
	-- ParticleManager:ClearParticle( self.startFXL )
	-- ParticleManager:ClearParticle( self.startFXR )
	-- self.startFXL = nil
	-- self.startFXR = nil
end

function zuus_thundergods_wrath:OnSpellStart()
	local caster = self:GetCaster()
	
	local damage = self:GetSpecialValueFor("damage")
	local damage_pct = self:GetSpecialValueFor("damage_pct") / 100
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), -1 ) ) do
		self:DealDamage( caster, enemy, damage * (1+caster:GetSpellAmplification(false)) + enemy:GetMaxHealth() * damage_pct, {damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION } )
	
		ParticleManager:FireRopeParticle("particles/units/heroes/hero_zuus/zuus_thundergods_wrath.vpcf", PATTACH_POINT, caster, enemy:GetAbsOrigin(), {[0]=enemy:GetAbsOrigin()+Vector(0,0,1000)})
		EmitSoundOn( "Hero_Zuus.GodsWrath.Target", enemy )
	end
	
	EmitSoundOn( "Hero_Zuus.GodsWrath", caster )
	-- ParticleManager:ClearParticle( self.startFXL )
	-- ParticleManager:ClearParticle( self.startFXR )
	-- self.startFXL = nil
	-- self.startFXR = nil
end