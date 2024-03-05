boss_death_avatar_poison_nova = class({})

function boss_death_avatar_poison_nova:ShouldUseResources()
	return true
end

function boss_death_avatar_poison_nova:GetIntrinsicModifierName()
	return "modifier_boss_death_avatar_poison_nova_innate"
end

function boss_death_avatar_poison_nova:Spawn()
	if not IsServer() then return end
	self:SetCooldown( 20 )
end

function boss_death_avatar_poison_nova:PoisonNova( target )
	local caster = self:GetCaster()
	local origin = target or caster
	
	local maxRadius = self:GetTalentSpecialValueFor("radius")
	local duration = self:GetTalentSpecialValueFor("duration")
	
	if target ~= caster then
		local power = self:GetSpecialValueFor("ward_power") / 100
		maxRadius = maxRadius * power
		duration = duration * power
		
		print( power, maxRadius )
	end

	local enemies = FindUnitsInRadius(caster:GetTeam(), origin:GetAbsOrigin(), nil, maxRadius, DOTA_UNIT_TARGET_TEAM_ENEMY, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO, 0, 0, false)
	for _,enemy in pairs(enemies) do
		enemy:AddNewModifier(caster, self, "modifier_venomancer_poison_nova", {duration = duration})
		EmitSoundOn( "Hero_Venomancer.PoisonNovaImpact", self:GetCaster() )
	end
	EmitSoundOn( "Hero_Venomancer.PoisonNova", self:GetCaster() )
	
	local novaCloud = ParticleManager:CreateParticle( "particles/units/heroes/hero_venomancer/venomancer_poison_nova.vpcf", PATTACH_ABSORIGIN_FOLLOW, origin )
	ParticleManager:SetParticleControlEnt(novaCloud, 0, origin, PATTACH_POINT_FOLLOW, "attach_origin", origin:GetAbsOrigin(), true)
	ParticleManager:SetParticleControl(novaCloud, 1, Vector(maxRadius,1,maxRadius) )
	ParticleManager:SetParticleControl(novaCloud, 2, origin:GetAbsOrigin())
	ParticleManager:ReleaseParticleIndex(novaCloud)
end

LinkLuaModifier( "modifier_boss_death_avatar_poison_nova_innate","bosses/boss_necrophos/boss_death_avatar_poison_nova", LUA_MODIFIER_MOTION_NONE)
modifier_boss_death_avatar_poison_nova_innate = class({})

function modifier_boss_death_avatar_poison_nova_innate:OnCreated()
	self:OnRefresh()
end

function modifier_boss_death_avatar_poison_nova_innate:OnRefresh()
	if IsServer() then
		self:StartIntervalThink( 0.5 )
	end
end

function modifier_boss_death_avatar_poison_nova_innate:OnIntervalThink()
	local caster = self:GetCaster()
	if caster:PassivesDisabled() then return end
	if caster:IsStunned() then return end
	if caster:IsHexed() then return end
	local ability = self:GetAbility()
	if ability:IsCooldownReady() and ability:IsFullyCastable() then
		ability:PoisonNova( caster )
		ability:SetCooldown()
	end
end

function modifier_boss_death_avatar_poison_nova_innate:DeclareFunctions()
	return {MODIFIER_EVENT_ON_DEATH}
end

function modifier_boss_death_avatar_poison_nova_innate:OnDeath(params)
	self:GetAbility():PoisonNova( params.unit )
end

function modifier_boss_death_avatar_poison_nova_innate:IsHidden()
	return false
end