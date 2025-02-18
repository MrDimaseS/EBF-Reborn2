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
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_tiny/tiny_tree_attack.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, caster_position)
	ParticleManager:SetParticleControlForward(particle, 0, caster_forward)
	ParticleManager:ReleaseParticleIndex(particle)

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

	for _, enemy in pairs(enemies) do
		local enemy_position = enemy:GetAbsOrigin()
		local direction = (enemy_position - caster_position):Normalized()
		local angle = math.deg(math.acos(caster_forward:Dot(direction)))

		if angle <= cone_angle / 2 then
			-- Push back
			local push_direction = direction
			enemy:ApplyKnockBack(enemy_position, 1.2, 1.2, 150, 400, caster, self)
		end
	end

	-- Spend mana and trigger cooldown
	caster:SpendMana(self:GetManaCost(self:GetLevel()), self)
	self:StartCooldown(self:GetCooldown(self:GetLevel()))
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
