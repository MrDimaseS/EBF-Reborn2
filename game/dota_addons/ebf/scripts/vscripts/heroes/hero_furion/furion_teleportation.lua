furion_teleportation = class({})

function furion_teleportation:IsStealable()
	return true
end

function furion_teleportation:IsHiddenWhenStolen()
	return false
end

function furion_teleportation:GetAbilityTextureName()
	return "furion_teleportation"
end

function furion_teleportation:OnAbilityPhaseStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	EmitSoundOn("Hero_Furion.Teleport_Grow", caster)

	self.nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_furion/furion_teleport.vpcf", PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(self.nfx, 0, caster:GetAbsOrigin())

	self.nfx2 = ParticleManager:CreateParticle("particles/units/heroes/hero_furion/furion_teleport_end.vpcf", PATTACH_WORLDORIGIN, caster)
	ParticleManager:SetParticleControl(self.nfx2, 1, point)
	
	return true
end

function furion_teleportation:OnAbilityPhaseInterrupted()
	StopSoundOn("Hero_Furion.Teleport_Grow", caster)

	ParticleManager:DestroyParticle(self.nfx, false)
	ParticleManager:DestroyParticle(self.nfx2, false)
end

function furion_teleportation:OnSpellStart()
	local caster = self:GetCaster()
	local ogPos = caster:GetAbsOrigin()
	local point = self:GetCursorPosition()
	
	ProjectileManager:ProjectileDodge( caster )
	FindClearSpaceForUnit(caster, point, true)

	GridNav:DestroyTreesAroundPoint(point, 150, true)

	ParticleManager:DestroyParticle(self.nfx, false)
	ParticleManager:DestroyParticle(self.nfx2, false)

	StopSoundOn("Hero_Furion.Teleport_Grow", caster)
	EmitSoundOn("Hero_Furion.Teleport_Disappear", caster)
	EmitSoundOn("Hero_Furion.Teleport_Appear", caster)
	
	local duration = self:GetSpecialValueFor("buff_duration")
	local treants_gain_barrier = self:GetSpecialValueFor("treants_gain_barrier") == 1
	caster:AddNewModifier( caster, self, "modifier_furion_teleportation_barrier", {duration = duration})
	
	for _, treant in ipairs( caster:FindFriendlyUnitsInRadius( point, -1, {type = DOTA_UNIT_TARGET_CREEP} ) ) do
		if treant:GetUnitLabel() == "treants" then
			if self:GetAutoCastState() then
				ProjectileManager:ProjectileDodge( treant )
				FindClearSpaceForUnit(treant, point + RandomVector( 150 ), true)
			end
			if treants_gain_barrier then
				treant:AddNewModifier( caster, self, "modifier_furion_teleportation_barrier", {duration = duration})
			end
		end
	end
	
	if self:GetSpecialValueFor("damage_radius") > 0 then
		local damage_duration = self:GetSpecialValueFor("damage_duration")
		local damage_per_sec = self:GetSpecialValueFor("damage_per_sec")
		local damage_radius = self:GetSpecialValueFor("damage_radius")
		
		for _, ally in ipairs( caster:FindFriendlyUnitsInRadius( point, damage_radius, {type = DOTA_UNIT_TARGET_HERO} ) ) do
			if caster ~= ally then
				caster:AddNewModifier( caster, self, "modifier_furion_teleportation_barrier", {duration = duration})
			end
		end
		
		local nFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_furion/furion_teleportation_flower.vpcf", PATTACH_WORLDORIGIN, nil )
		ParticleManager:SetParticleControl( nFX, 0, ogPos )
		ParticleManager:SetParticleControl( nFX, 1, Vector( damage_radius, damage_radius, damage_radius ) )
		
		Timers:CreateTimer( function()	
			for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( ogPos, damage_radius) ) do
				self:DealDamage( caster, enemy, damage_per_sec, {damage_type = DAMAGE_TYPE_MAGICAL} )
			end
			if damage_duration > 0 then
				damage_duration = damage_duration - 1
				return 1
			else
				ParticleManager:ClearParticle( nFX )
			end
		end)
	end

	Timers:CreateTimer(1, function()
		StopSoundOn("Hero_Furion.Teleport_Disappear", caster)
		StopSoundOn("Hero_Furion.Teleport_Appear", caster)
	end)
end

modifier_furion_teleportation_barrier = class({})
LinkLuaModifier( "modifier_furion_teleportation_barrier", "heroes/hero_furion/furion_teleportation.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_furion_teleportation_barrier:OnCreated()
	self:OnRefresh()
	if IsServer() then self:SetHasCustomTransmitterData(true) end
end

function modifier_furion_teleportation_barrier:OnRefresh()
	self.barrier = self:GetSpecialValueFor("barrier")
	if IsServer() then
		self:SendBuffRefreshToClients()
	end
end

function modifier_furion_teleportation_barrier:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT }
end

function modifier_furion_teleportation_barrier:GetModifierIncomingDamageConstant( params )
	if IsServer() then
		local barrier = math.min( self.barrier, math.max( self.barrier, params.damage ) )
		self.barrier = math.max( 0, self.barrier - params.damage )
		if self.barrier > 0 then
			self:SendBuffRefreshToClients()
		else
			self:Destroy()
		end
		return -barrier
	else
		return self.barrier
	end
end

function modifier_furion_teleportation_barrier:AddCustomTransmitterData()
	return {barrier = self.barrier}
end

function modifier_furion_teleportation_barrier:HandleCustomTransmitterData(data)
	self.barrier = data.barrier
end