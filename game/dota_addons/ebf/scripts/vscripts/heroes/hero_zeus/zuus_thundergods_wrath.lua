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
	local growing_delay = self:GetSpecialValueFor("growing_delay")
	local grow_kill_amp = self:GetSpecialValueFor("grow_kill_amp")/100
	
	EmitSoundOn( "Hero_Zuus.GodsWrath", caster )
	local enemies = caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), -1 )
	Timers:CreateTimer( growing_delay, function()
		local enemyToStrike
		local enemyToStrikeIndex
		for index, enemy in ipairs( enemies ) do
			if not enemyToStrike or enemy:GetHealth() < enemyToStrike:GetHealth() then
				enemyToStrike = enemy
				enemyToStrikeIndex = index
			end
		end
		if enemyToStrike then
			table.remove( enemies, enemyToStrikeIndex )

			ParticleManager:FireRopeParticle("particles/units/heroes/hero_zuus/zuus_thundergods_wrath.vpcf", PATTACH_POINT, caster, enemyToStrike:GetAbsOrigin(), {[0]=enemyToStrike:GetAbsOrigin()+Vector(0,0,1000)})
			EmitSoundOn( "Hero_Zuus.GodsWrath.Target", enemyToStrike )
			
			self:DealDamage( caster, enemyToStrike, damage )
			if not enemyToStrike:IsAlive() then
				damage = damage * (1+grow_kill_amp)
			end
			return growing_delay
		end
	end )
	-- ParticleManager:ClearParticle( self.startFXL )
	-- ParticleManager:ClearParticle( self.startFXR )
	-- self.startFXL = nil
	-- self.startFXR = nil
end