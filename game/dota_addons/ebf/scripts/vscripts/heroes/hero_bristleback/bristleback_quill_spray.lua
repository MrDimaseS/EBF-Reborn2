bristleback_quill_spray = class({})

function bristleback_quill_spray:GetIntrinsicModifierName()
	return "modifier_bristleback_quill_spray_autocast"
end
function bristleback_quill_spray:OnSpellStart()
	self:DoQuill({
		position = self:GetCaster():GetAbsOrigin(),
		add_warpath_stack = true
	})
end
function bristleback_quill_spray:ApplyQuill(target, caster, damage, is_proc, boogerman_duration, mettlehead_duration)
	self:DealDamage(caster, target, damage, { damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = TernaryOperator(DOTA_DAMAGE_FLAG_REFLECTION, is_proc, DOTA_DAMAGE_FLAG_NONE) })

	if boogerman_duration ~= 0 then
		local modifier = target:AddNewModifier(caster, self, "modifier_bristleback_quill_spray_boogerman", { duration = boogerman_duration })
		modifier:AddIndependentStack()
	elseif mettlehead_duration ~= 0 then
		local modifier = target:AddNewModifier(caster, self, "modifier_bristleback_quill_spray_mettlehead", { duration = mettlehead_duration })
		modifier:AddIndependentStack()
	end
end
-- { position, is_proc, override_radius, direction, angle, add_warpath_stack }
function bristleback_quill_spray:DoQuill(params)
	local caster = self:GetCaster()
	local radius = params.override_radius or self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("quill_base_damage")
	local bonus_physical_damage_duration = self:GetSpecialValueFor("bonus_physical_damage_duration")
	local bonus_attack_damage_duration = self:GetSpecialValueFor("bonus_attack_damage_duration")

	local position = params.position or caster:GetAbsOrigin()
	local direction = params.direction or -caster:GetForwardVector()

	local enemies = {}
	if params.angle then
		enemies = caster:FindEnemyUnitsInSector(position, direction, radius, params.angle)
	else
		enemies = caster:FindEnemyUnitsInRadius(position, radius)
	end

	for _, enemy in ipairs(enemies) do
		self:DealDamage(caster, enemy, damage, { damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = TernaryOperator(DOTA_DAMAGE_FLAG_REFLECTION, params.is_proc, DOTA_DAMAGE_FLAG_NONE) })

		if bonus_physical_damage_duration ~= 0 then
			local modifier = enemy:AddNewModifier(caster, self, "modifier_bristleback_quill_spray_boogerman", { duration = bonus_physical_damage_duration })
			modifier:AddIndependentStack()
		elseif bonus_attack_damage_duration ~= 0 then
			local modifier = enemy:AddNewModifier(caster, self, "modifier_bristleback_quill_spray_mettlehead", { duration = bonus_attack_damage_duration })
			modifier:AddIndependentStack()
		end
		
		-- sounds
		local sound = "Hero_Bristleback.QuillSpray.Target"
		EmitSoundOn(sound, enemy)
	end

	if params.add_warpath_stack then
		local warpath = caster:FindAbilityByName("bristleback_warpath")
		if IsEntitySafe(warpath) and warpath:IsTrained() then
			warpath:AddStack()
		end
	end

	-- particles
	if params.angle then
		-- particles
		local particle = "particles/units/heroes/hero_bristleback/bristleback_quill_spray_conical.vpcf"
		local effect = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(effect, 0, caster:GetAbsOrigin())
		ParticleManager:SetParticleControlForward(effect, 0, direction)
		ParticleManager:ReleaseParticleIndex(effect)
	else
		local particle = "particles/units/heroes/hero_bristleback/bristleback_quill_spray.vpcf"
		local effect = ParticleManager:CreateParticle(particle, PATTACH_POINT, caster)
		ParticleManager:SetParticleControl(effect, 0, position)
		ParticleManager:ReleaseParticleIndex(effect)
	end
	
	-- sounds
	local sound = "Hero_Bristleback.QuillSpray.Cast"
	EmitSoundOnLocationWithCaster(position, sound, caster)
end

modifier_bristleback_quill_spray_boogerman = class({})
LinkLuaModifier( "modifier_bristleback_quill_spray_boogerman", "heroes/hero_bristleback/bristleback_quill_spray", LUA_MODIFIER_MOTION_NONE )

function modifier_bristleback_quill_spray_boogerman:IsHidden()
	return false
end
function modifier_bristleback_quill_spray_boogerman:IsDebuff()
	return true
end
function modifier_bristleback_quill_spray_boogerman:IsPurgable()
	return false
end
function modifier_bristleback_quill_spray_boogerman:OnCreated()
	self:OnRefresh()
end
function modifier_bristleback_quill_spray_boogerman:OnRefresh()
	self.bonus_physical_damage_per_stack = self:GetSpecialValueFor("bonus_physical_damage_per_stack")
	self.bonus_physical_damage_self_multiplier = self:GetSpecialValueFor("bonus_physical_damage_self_multiplier")
end
function modifier_bristleback_quill_spray_boogerman:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_TAKEDAMAGE
	}
end
function modifier_bristleback_quill_spray_boogerman:OnTakeDamage(params)
	if params.unit ~= self:GetParent()
	or params.damage_type ~= DAMAGE_TYPE_PHYSICAL
	or HasBit(params.damage_flags, DOTA_DAMAGE_FLAG_PROPERTY_FIRE)
	then return end

	local damage = self.bonus_physical_damage_per_stack * self:GetStackCount() * TernaryOperator(self.bonus_physical_damage_self_multiplier, params.attacker == self:GetCaster(), 1)
	local ability = self:GetAbility()
	ability:DealDamage(params.attacker, params.unit, damage, { damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = DOTA_DAMAGE_FLAG_PROPERTY_FIRE })
end

modifier_bristleback_quill_spray_mettlehead = class({})
LinkLuaModifier( "modifier_bristleback_quill_spray_mettlehead", "heroes/hero_bristleback/bristleback_quill_spray", LUA_MODIFIER_MOTION_NONE )

function modifier_bristleback_quill_spray_mettlehead:IsHidden()
	return false
end
function modifier_bristleback_quill_spray_mettlehead:IsDebuff()
	return true
end
function modifier_bristleback_quill_spray_mettlehead:IsPurgable()
	return false
end

modifier_bristleback_quill_spray_autocast = class({})
LinkLuaModifier( "modifier_bristleback_quill_spray_autocast", "heroes/hero_bristleback/bristleback_quill_spray", LUA_MODIFIER_MOTION_NONE )

function modifier_bristleback_quill_spray_autocast:IsHidden()
	return true
end
function modifier_bristleback_quill_spray_autocast:OnCreated()
	if IsServer() then
		self:StartIntervalThink(0)
	end
end
function modifier_bristleback_quill_spray_autocast:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PHYSICAL
	}
end
function modifier_bristleback_quill_spray_autocast:GetModifierProcAttack_BonusDamage_Physical(params)
	if params.attacker ~= self:GetParent()
	or not params.target:HasModifier("modifier_bristleback_quill_spray_mettlehead")
	then return end

	local modifier = params.target:FindModifierByName("modifier_bristleback_quill_spray_mettlehead")
	if modifier and modifier:GetStackCount() ~= 0 then
		local damage = self:GetSpecialValueFor("bonus_attack_damage_per_stack") * modifier:GetStackCount()
		modifier:SetStackCount(0)
		return damage
	end
end
function modifier_bristleback_quill_spray_autocast:OnIntervalThink()
	local caster = self:GetCaster()
	if caster:IsSilenced()
	or caster:IsStunned()
	then return end

	local ability = self:GetAbility()
	if ability:GetAutoCastState() and ability:IsFullyCastable() then
		caster:CastAbilityNoTarget(ability, caster:GetPlayerOwnerID())
	end
end