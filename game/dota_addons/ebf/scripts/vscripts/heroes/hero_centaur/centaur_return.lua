centaur_return = class({})

function centaur_return:GetCastRange(position, target)
	local radius = self:GetSpecialValueFor("radius")
	local auto_bonus_range = self:GetSpecialValueFor("auto_retaliate_bonus_range")
	local attack_bonus_range = self:GetSpecialValueFor("attack_retaliate_bonus_range")
	if radius ~= 0 then
		return radius
	elseif auto_bonus_range ~= 0 then
		return self:GetCaster():Script_GetAttackRange() + auto_bonus_range
	elseif attack_bonus_range ~= 0 then
		return self:GetCaster():Script_GetAttackRange() + attack_bonus_range
	end
end
function centaur_return:GetIntrinsicModifierName()
	return "modifier_centaur_return_passive"
end
function centaur_return:DoReturn(target)
	local caster = self:GetCaster()
	local damage = self:GetSpecialValueFor("return_damage")
	self:DealDamage(caster, target, damage, { damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_DAMAGE_FLAG_REFLECTION })

	local attack_damage_reduction_duration = self:GetSpecialValueFor("attack_damage_reduction_duration")
	if attack_damage_reduction_duration ~= 0 then
		target:AddNewModifier(caster, self, "modifier_centaur_return_thunderhoof", { duration = attack_damage_reduction_duration })
	end

	-- particles
	local particle = "particles/units/heroes/hero_centaur/centaur_return.vpcf"
	ParticleManager:FireRopeParticle(particle, PATTACH_POINT_FOLLOW, caster, target)
end

modifier_centaur_return_passive = class({})
LinkLuaModifier( "modifier_centaur_return_passive", "heroes/hero_centaur/centaur_return", LUA_MODIFIER_MOTION_NONE )

function modifier_centaur_return_passive:IsHidden()
	return true
end
function modifier_centaur_return_passive:IsPurgable()
	return false
end
function modifier_centaur_return_passive:IsAura()
	return true
end
function modifier_centaur_return_passive:GetModifierAura()
	return "modifier_centaur_return_buff"
end
function modifier_centaur_return_passive:GetAuraRadius()
	return self:GetSpecialValueFor("radius")
end
function modifier_centaur_return_passive:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end
function modifier_centaur_return_passive:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HEROES_AND_CREEPS
end
function modifier_centaur_return_passive:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

modifier_centaur_return_buff = class({})
LinkLuaModifier( "modifier_centaur_return_buff", "heroes/hero_centaur/centaur_return", LUA_MODIFIER_MOTION_NONE )

function modifier_centaur_return_buff:IsHidden()
	return false
end
function modifier_centaur_return_buff:IsDebuff()
	return false
end
function modifier_centaur_return_buff:IsPurgable()
	return false
end
function modifier_centaur_return_buff:OnCreated()
	self:OnRefresh()
	if IsClient() then return end

	print(self.auto_retaliate_interval)
	if self.auto_retaliate_interval ~= 0 then
		self:StartIntervalThink(self.auto_retaliate_interval)
	elseif self.attack_retaliate_history ~= 0 then
		self:StartIntervalThink(0)
	end
end
function modifier_centaur_return_buff:OnRefresh()
	self.auto_retaliate_interval = self:GetSpecialValueFor("auto_retaliate_interval")
	self.auto_retaliate_bonus_range = self:GetSpecialValueFor("auto_retaliate_bonus_range")

	self.attack_retaliate_pct = self:GetSpecialValueFor("attack_retaliate_pct")
	self.attack_retaliate_bonus_range = self:GetSpecialValueFor("attack_retaliate_bonus_range")
	self.attack_retaliate_history = self:GetSpecialValueFor("attack_retaliate_history")
	self.attacks = {}
end
function modifier_centaur_return_buff:OnIntervalThink()
	if self.auto_retaliate_bonus_range ~= 0 then
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local enemy = parent:FindRandomEnemyInRadius(parent:GetAbsOrigin(), parent:Script_GetAttackRange() + self.auto_retaliate_bonus_range)
		if enemy then
			ability:DoReturn(enemy)
		end
	elseif self.attack_retaliate_pct ~= 0 then
		for attacker, time in pairs(self.attacks) do
			time = time - FrameTime()

			if time <= 0 then
				self.attacks[attacker] = nil
			else
				self.attacks[attacker] = time
			end
		end
	end
end
function modifier_centaur_return_buff:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK
	}
end
function modifier_centaur_return_buff:OnAttack(params)
	local ability = self:GetAbility()
	if params.target == self:GetParent() and not self:GetParent():PassivesDisabled() then
		ability:DoReturn(params.attacker)
		
		if self.attack_retaliate_pct ~= 0 then
			self.attacks[params.attacker] = self.attack_retaliate_history
		end
	elseif params.attacker == self:GetParent() and self.attack_retaliate_pct ~= 0 then
		for attacker, _ in pairs(self.attacks) do
			if CalculateDistance(params.attacker, attacker) <= params.attacker:Script_GetAttackRange() + self.attack_retaliate_bonus_range then
				ability:DoReturn(attacker)
			end
		end
	end
end

modifier_centaur_return_thunderhoof = class({})
LinkLuaModifier( "modifier_centaur_return_thunderhoof", "heroes/hero_centaur/centaur_return", LUA_MODIFIER_MOTION_NONE )

function modifier_centaur_return_thunderhoof:IsHidden()
	return false
end
function modifier_centaur_return_thunderhoof:IsDebuff()
	return true
end
function modifier_centaur_return_thunderhoof:IsPurgable()
	return true
end
function modifier_centaur_return_thunderhoof:OnCreated()
	self:OnRefresh()
end
function modifier_centaur_return_thunderhoof:OnRefresh()
	self.attack_damage_reduction = self:GetSpecialValueFor("attack_damage_reduction")
end
function modifier_centaur_return_thunderhoof:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE
	}
end
function modifier_centaur_return_thunderhoof:GetModifierDamageOutgoing_Percentage()
	return -self.attack_damage_reduction
end

--[[
function centaur_return:GetIntrinsicModifierName()
	return "modifier_centaur_return_passive"
end

function centaur_return:ProcReturn(target, damage)
	local caster = self:GetCaster()
	local fDmg = damage or self:GetSpecialValueFor("return_damage")
	ParticleManager:FireRopeParticle("particles/units/heroes/hero_centaur/centaur_return.vpcf", PATTACH_POINT_FOLLOW, caster, target)
	return self:DealDamage( caster, target, fDmg, {damage_flags = DOTA_DAMAGE_FLAG_REFLECTION} )
end

modifier_centaur_return_passive = class({})
LinkLuaModifier("modifier_centaur_return_passive", "heroes/hero_centaur/centaur_return", LUA_MODIFIER_MOTION_NONE)

function modifier_centaur_return_passive:IsHidden()
	return true
end

function modifier_centaur_return_passive:IsAura()
	return true
end

function modifier_centaur_return_passive:GetModifierAura()
	return "modifier_centaur_return_return"
end

function modifier_centaur_return_passive:GetAuraRadius()
	return self:GetSpecialValueFor("aura_radius")
end

function modifier_centaur_return_passive:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_centaur_return_passive:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

function modifier_centaur_return_passive:GetAuraSearchFlags()
	return DOTA_UNIT_TARGET_FLAG_INVULNERABLE
end

modifier_centaur_return_return = class({})
LinkLuaModifier("modifier_centaur_return_return", "heroes/hero_centaur/centaur_return", LUA_MODIFIER_MOTION_NONE)

function modifier_centaur_return_return:OnCreated()
	self:OnRefresh()
end

function modifier_centaur_return_return:OnRefresh()
	self.bonus_armor_str = self:GetSpecialValueFor("bonus_armor_str") / 100
end

function modifier_centaur_return_return:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACK, MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS  }
end

function modifier_centaur_return_return:OnAttack(params)
	if params.target == self:GetParent() then
		if self:GetParent():PassivesDisabled() then return end
		self:GetAbility():ProcReturn( params.attacker )
	end
end

function modifier_centaur_return_return:GetModifierPhysicalArmorBonus(params)
	return self:GetCaster():GetStrength() * self.bonus_armor_str
end
]]