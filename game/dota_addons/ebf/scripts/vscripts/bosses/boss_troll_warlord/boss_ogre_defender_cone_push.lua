boss_ogre_defender_cone_push = class({})

function boss_ogre_defender_cone_push:OnAttackLanded(params)
	if params.attacker == self:GetCaster() and self:GetAutoCastState() and self:IsCooldownReady() and self:GetCaster():GetMana() >= self:GetManaCost(self:GetLevel()) then
		self:CastAbility()
	end
end

function boss_ogre_defender_cone_push:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local cone_angle = ability:GetSpecialValueFor("cone_angle")
	local cone_distance = ability:GetSpecialValueFor("cone_distance")
	local pushback_distance = ability:GetSpecialValueFor("pushback_distance")

	local caster_position = caster:GetAbsOrigin()
	local caster_forward = caster:GetForwardVector()

	-- Play sound effect
	EmitSoundOn("Hero_Tiny.Tree.Grab", caster)

	-- Create particle effect
	local enemies = FindUnitsInRadius(
		caster:GetTeamNumber(),
		caster_position,
		nil,
		cone_distance,
		DOTA_UNIT_TARGET_TEAM_ENEMY,
		DOTA_UNIT_TARGET_HERO,
		DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		FIND_ANY_ORDER,
		false
	)
	
	local sideLength = cone_distance / math.tan( ToRadians( cone_angle/2 ) )

	for _, enemy in pairs( caster:FindEnemyUnitsInCone(caster_forward, caster_position, sideLength, cone_distance) ) do
		self:FireTrackingProjectile("particles/units/heroes/hero_tiny/tiny_tree_proj.vpcf", enemy, 900)
	end

	-- Spend mana and trigger cooldown
	caster:SpendMana(self:GetManaCost(self:GetLevel()), self)
	self:StartCooldown(self:GetCooldown(self:GetLevel()))
end

function boss_ogre_defender_cone_push:OnProjectileHit( target, position )
	local push_direction = direction
	target:ApplyKnockBack( self:GetCaster():GetAbsOrigin(), 1.2, 1.2, 150, 400, self:GetCaster(), self)
end

function boss_ogre_defender_cone_push:OnUpgrade()
	if IsServer() then
		self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_boss_ogre_defender_cone_push_autocast", {})
	end
end

LinkLuaModifier("modifier_boss_ogre_defender_cone_push_autocast", "bosses/boss_ogres/boss_ogre_defender_cone_push.lua", LUA_MODIFIER_MOTION_NONE)

modifier_boss_ogre_defender_cone_push_autocast = class({})

function modifier_boss_ogre_defender_cone_push_autocast:IsHidden() return true end
function modifier_boss_ogre_defender_cone_push_autocast:IsPurgable() return false end
function modifier_boss_ogre_defender_cone_push_autocast:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK_LANDED }
end

function modifier_boss_ogre_defender_cone_push_autocast:OnAttackLanded(params)
	if IsServer() then
		self:GetAbility():OnAttackLanded(params)
	end
end
