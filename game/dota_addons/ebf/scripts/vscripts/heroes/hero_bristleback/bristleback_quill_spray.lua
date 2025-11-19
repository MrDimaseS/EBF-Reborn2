bristleback_quill_spray = class({})

function bristleback_quill_spray:GetIntrinsicModifierName()
	return "modifier_bristleback_quill_spray_autocast"
end
function bristleback_quill_spray:OnSpellStart()
	self:DoQuill()
end

function bristleback_quill_spray:DoQuill( target )
	local caster = self:GetCaster()
	local radius = params.override_radius or self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("quill_base_damage")
	local bonus_goo_power_duration = self:GetSpecialValueFor("bonus_goo_power_duration")

	local position = caster:GetAbsOrigin()
	
	if target and target.GetAbsOrigin() then
		local direction = CalculateDirection( caster, target )
		local effect = ParticleManager:CreateParticle("particles/units/heroes/hero_bristleback/bristleback_quill_spray_conical.vpcf", PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControl(effect, 0, caster:GetAbsOrigin() )
		ParticleManager:SetParticleControlForward(effect, 0, direction)
		ParticleManager:ReleaseParticleIndex(effect)
	else
		position = target or caster:GetAbsOrigin()
		local enemies = caster:FindEnemyUnitsInRadius(position, radius)
		for _, enemy in ipairs(enemies) do
			self:DealDamage(caster, enemy, damage, { damage_type = DAMAGE_TYPE_PHYSICAL, damage_flags = TernaryOperator(DOTA_DAMAGE_FLAG_REFLECTION, params.is_proc, DOTA_DAMAGE_FLAG_NONE) })

			if bonus_goo_power_duration ~= 0 then
				local modifier = enemy:AddNewModifier(caster, self, "modifier_bristleback_quill_spray_boogerman", { duration = bonus_goo_power_duration })
				modifier:AddIndependentStack()
			end
			EmitSoundOn("Hero_Bristleback.QuillSpray.Target", enemy)
		end
		
		local effect = ParticleManager:CreateParticle("particles/units/heroes/hero_bristleback/bristleback_quill_spray.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl(effect, 0, position)
		ParticleManager:ReleaseParticleIndex(effect)
	end
	EmitSoundOnLocationWithCaster(position, "Hero_Bristleback.QuillSpray.Cast", caster)
end

modifier_bristleback_quill_spray_boogerman = class({})
LinkLuaModifier( "modifier_bristleback_quill_spray_boogerman", "heroes/hero_bristleback/bristleback_quill_spray", LUA_MODIFIER_MOTION_NONE )

function modifier_bristleback_quill_spray_boogerman:OnCreated()
	self:OnRefresh()
end

function modifier_bristleback_quill_spray_boogerman:OnRefresh()
	self.bonus_goo_power = self:GetSpecialValueFor("bonus_goo_power")
end

function modifier_bristleback_quill_spray_boogerman:DeclareFunctions()
	return {MODIFIER_PROPERTY_TOOLTIP}
end

function modifier_bristleback_quill_spray_boogerman:OnTakeDamage(params)
	return self.bonus_goo_power * self:GetStackCount()
end

function modifier_bristleback_quill_spray_boogerman:IsHidden()
	return false
end

function modifier_bristleback_quill_spray_boogerman:IsDebuff()
	return true
end

function modifier_bristleback_quill_spray_boogerman:IsPurgable()
	return false
end

modifier_bristleback_quill_spray_autocast = class({})
LinkLuaModifier( "modifier_bristleback_quill_spray_autocast", "heroes/hero_bristleback/bristleback_quill_spray", LUA_MODIFIER_MOTION_NONE )

function modifier_bristleback_quill_spray_autocast:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink(0.1)
	end
end

function modifier_bristleback_quill_spray_autocast:OnRefresh()
	self.strike_cooldown_reduction = self:GetSpecialValueFor("strike_cooldown_reduction")
end

function modifier_bristleback_quill_spray_autocast:OnIntervalThink()
	local caster = self:GetCaster()
	if caster:IsSilenced() or caster:IsStunned() then return end

	local ability = self:GetAbility()
	if ability:GetAutoCastState() and ability:IsFullyCastable() then
		caster:CastAbilityNoTarget(ability, caster:GetPlayerOwnerID())
	end
end

function modifier_bristleback_quill_spray_autocast:DeclareFunctions()
	return {
		MODIFIER_EVENT_ON_ATTACK_LANDED
	}
end

function modifier_bristleback_quill_spray_autocast:OnAttackLanded(params)
	if self.strike_cooldown_reduction <= 0 then return end
	if params.attacker ~= self:GetParent() then return end
	local ability = self:GetAbility()
	if ability:IsFullyCastable() then return end

	ability:ModifyCooldown( -self.strike_cooldown_reduction )
end

function modifier_bristleback_quill_spray_autocast:IsHidden()
	return true
end