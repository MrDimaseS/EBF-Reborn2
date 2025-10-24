sniper_shrapnel = class({})

function sniper_shrapnel:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function sniper_shrapnel:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	local duration =  self:GetSpecialValueFor("duration")
	local radius =  self:GetSpecialValueFor("radius")
	
	EmitSoundOn("Hero_Sniper.ShrapnelShoot", caster)
	
	local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_sniper/sniper_shrapnel_launch.vpcf", PATTACH_POINT, caster)
				ParticleManager:SetParticleControlEnt(nfx, 0, caster, PATTACH_POINT, "attach_attack1", caster:GetAbsOrigin(), true)
				ParticleManager:SetParticleControl(nfx, 1, point + Vector(0,0,1500))
				ParticleManager:ReleaseParticleIndex(nfx)
	
	Timers:CreateTimer(self:GetSpecialValueFor("damage_delay"), function()
		AddFOWViewer(caster:GetTeam(), point, radius, duration, false)
		CreateModifierThinker(caster, self, "modifier_sniper_shrapnel_handler", {Duration = duration}, point, caster:GetTeam(), false)
	end)
end

modifier_sniper_shrapnel_handler = class({})
LinkLuaModifier( "modifier_sniper_shrapnel_handler","heroes/hero_sniper/sniper_shrapnel.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_sniper_shrapnel_handler:OnCreated(table)
	self.damage = self:GetSpecialValueFor("shrapnel_damage")
	self.radius = self:GetSpecialValueFor("radius")
	self.slow_duration = self:GetSpecialValueFor("slow_duration")
	if IsServer() then
		local caster = self:GetCaster()
		EmitSoundOnLocationWithCaster(self:GetParent():GetAbsOrigin(), "Hero_Sniper.ShrapnelShatter", caster)

		local point = self:GetParent():GetAbsOrigin()
		local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_sniper/sniper_shrapnel.vpcf", PATTACH_POINT, caster)
					ParticleManager:SetParticleControl(nfx, 0, point)
					ParticleManager:SetParticleControl(nfx, 1, Vector(self.radius, 0, 0))
					ParticleManager:SetParticleControl(nfx, 2, point)

		self:AttachEffect(nfx)
		
		self:OnIntervalThink()
		self:StartIntervalThink(1)
	end
end

function modifier_sniper_shrapnel_handler:OnRemoved()
	if IsServer() then
		StopSoundOn("Hero_Sniper.ShrapnelShatter", self:GetCaster())
	end
end

function modifier_sniper_shrapnel_handler:OnIntervalThink()
	local caster = self:GetCaster()
	local point = self:GetParent():GetAbsOrigin()
	
	GridNav:DestroyTreesAroundPoint(point, self.radius, false)
	local enemies = caster:FindEnemyUnitsInRadius(point, self.radius) 
	for _,enemy in pairs(enemies) do
		self:GetAbility():DealDamage(caster, enemy, self.damage)
	end
end

function modifier_sniper_shrapnel_handler:GetModifierAura()
	return "modifier_sniper_shrapnel_handler_slow"
end

function modifier_sniper_shrapnel_handler:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_sniper_shrapnel_handler:GetAuraSearchType()
	return DOTA_UNIT_TARGET_ALL
end

function modifier_sniper_shrapnel_handler:GetAuraRadius()
	return self.radius
end

function modifier_sniper_shrapnel_handler:GetAuraDuration()
	return self.slow_duration
end

function modifier_sniper_shrapnel_handler:IsAura()
    return true
end

modifier_sniper_shrapnel_handler_slow = class({})
LinkLuaModifier( "modifier_sniper_shrapnel_handler_slow","heroes/hero_sniper/sniper_shrapnel.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_sniper_shrapnel_handler_slow:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
	}
	return funcs
end

function modifier_sniper_shrapnel_handler_slow:GetModifierMoveSpeedBonus_Percentage()
	return self:GetSpecialValueFor("slow_movement_speed")
end

function modifier_sniper_shrapnel_handler_slow:IsDebuff()
	return true
end