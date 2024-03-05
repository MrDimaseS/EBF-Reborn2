boss_mania_demon_requiem_of_insanity = class({})

function boss_mania_demon_requiem_of_insanity:OnOwnerDied()
	self:OnSpellStart( true )
end

function boss_mania_demon_requiem_of_insanity:OnAbilityPhaseStart()
	EmitSoundOn( "Hero_Nevermore.RequiemOfSoulsCast", self:GetCaster() )
	self.warmUp = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_wings.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster())
end

function boss_mania_demon_requiem_of_insanity:OnAbilityPhaseInterrupted()
	StopSoundOn( "Hero_Nevermore.RequiemOfSoulsCast", self:GetCaster() )
	ParticleManager:ClearParticle( self.warmUp )
end

function boss_mania_demon_requiem_of_insanity:OnSpellStart(bDied)
	local caster = self:GetCaster()
	
	local presenceModifier = caster:FindModifierByName("modifier_boss_mania_demon_presence_of_mania")
	local requiemLines = 0
	if presenceModifier then
		requiemLines = math.min( self:GetSpecialValueFor("max_stacks"), presenceModifier:GetStackCount() ) / self:GetSpecialValueFor("requiem_soul_conversion")
	end
	if bDied then
		requiemLines = requiemLines * self:GetSpecialValueFor("soul_death_release") / 100
	end
	local angleRotation = 360 / requiemLines
	local requiem_line_speed = self:GetSpecialValueFor("requiem_line_speed")
	local requiem_line_width_start = self:GetSpecialValueFor("requiem_line_width_start")
	local requiem_line_width_end = self:GetSpecialValueFor("requiem_line_width_end")
	
	
	for i = 1, requiemLines do
		local direction = RotateVector2D( caster:GetForwardVector(), ToRadians( angleRotation * (i-1) ) )
		
		local particle_lines_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_line.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(particle_lines_fx, 0, caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(particle_lines_fx, 1, direction*requiem_line_speed)
		ParticleManager:SetParticleControl(particle_lines_fx, 2, Vector(0, self:GetTrueCastRange()/requiem_line_speed, 0))
		ParticleManager:ReleaseParticleIndex(particle_lines_fx)
		
		self:FireLinearProjectile("", direction * requiem_line_speed, self:GetTrueCastRange(), requiem_line_width_start, {width_end = requiem_line_width_end})
	end
	presenceModifier:SetStackCount( 0 )
	EmitSoundOn( "Hero_Nevermore.RequiemOfSouls", caster )
	ParticleManager:FireParticle("particles/units/heroes/hero_nevermore/nevermore_requiemofsouls.vpcf", PATTACH_ABSORIGIN, caster, {[1]=Vector(requiemLines, 0, 0)})
end

function boss_mania_demon_requiem_of_insanity:OnProjectileHit( target, position )
	if not target then return end
	local caster = self:GetCaster()
	self:DealDamage( caster, target )
	target:AddNewModifier( caster, self, "modifier_nevermore_requiem_slow", {duration = self:GetSpecialValueFor("requiem_slow_duration")} )
	target:AddNewModifier( caster, self, "modifier_nevermore_requiem_fear", {duration = self:GetSpecialValueFor("requiem_slow_duration")} )
	
	CreateUnitByNameAsync( "npc_dota_minion_mania_splinter", target:GetAbsOrigin() + ActualRandomVector( 128, 32 ), true, nil, nil, caster:GetTeamNumber(),
	function(entUnit)
		entUnit:MoveToTargetToAttack( target )
	end)
end