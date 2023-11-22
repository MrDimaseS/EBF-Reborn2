venomancer_poison_nova = class({})

function venomancer_poison_nova:GetIntrinsicModifierName()
	return "modifier_venomancer_poison_nova_innate"
end

function venomancer_poison_nova:PoisonNova( target )
	local caster = self:GetCaster()
	local origin = target or self:GetCaster()
	
	local radius = self:GetTalentSpecialValueFor("start_radius")
	local maxRadius = self:GetTalentSpecialValueFor("radius")
	local radiusGrowth = self:GetTalentSpecialValueFor("speed") * 0.1
	local duration = self:GetTalentSpecialValueFor("duration")

	local enemies = FindUnitsInRadius(caster:GetTeam(), origin:GetAbsOrigin(), nil, maxRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, 0, false)
	for _,enemy in pairs(enemies) do
		if not enemy:TriggerSpellAbsorb( self ) then
			enemy:AddNewModifier(caster, self, "modifier_venomancer_poison_nova", {duration = duration})
		end
		EmitSoundOn( "Hero_Venomancer.PoisonNovaImpact", self:GetCaster() )
	end
	EmitSoundOn( "Hero_Venomancer.PoisonNova", self:GetCaster() )
	
	local novaCloud = ParticleManager:CreateParticle( "particles/units/heroes/hero_venomancer/venomancer_poison_nova.vpcf", PATTACH_ABSORIGIN_FOLLOW, origin )
		ParticleManager:SetParticleControlEnt(novaCloud, 0, origin, PATTACH_POINT_FOLLOW, "attach_origin", origin:GetAbsOrigin(), true)
		ParticleManager:SetParticleControl(novaCloud, 1, Vector(maxRadius,1,maxRadius) )
		ParticleManager:SetParticleControl(novaCloud, 2, origin:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(novaCloud)
end

LinkLuaModifier( "modifier_venomancer_poison_nova_innate","heroes/hero_venomancer/venomancer_poison_nova", LUA_MODIFIER_MOTION_NONE)
modifier_venomancer_poison_nova_innate = class({})

function modifier_venomancer_poison_nova_innate:DeclareFunctions()
	return {MODIFIER_EVENT_ON_DEATH}
end

function modifier_venomancer_poison_nova_innate:OnDeath(params)
	if params.unit == self:GetParent() then
		self:GetAbility():PoisonNova()
	end
end

function modifier_venomancer_poison_nova_innate:IsHidden()
	return false
end