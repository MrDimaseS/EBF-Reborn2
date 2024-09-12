nevermore_requiem = class({})

function nevermore_requiem:OnAbilityPhaseStart()
    EmitSoundOn("Hero_Nevermore.RequiemOfSoulsCast", self:GetCaster())
    self.warmupFX = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_wings.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster())
    ParticleManager:SetParticleControlEnt(self.warmupFX, 5, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_attack1", self:GetCaster():GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.warmupFX, 6, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_attack2", self:GetCaster():GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.warmupFX, 7, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetCaster():GetAbsOrigin(), true)
    self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_phased", {})
	if self:GetSpecialValueFor("debuff_immune") ~= 0 then
		self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_nevermore_requiem_debuff_immune", {})
	end
    return true
end
function nevermore_requiem:OnAbilityPhaseInterrupted()
    StopSoundOn("Hero_Nevermore.RequiemOfSoulsCast", self:GetCaster())
    ParticleManager:ClearParticle( self.warmupFX )
    self:GetCaster():RemoveModifierByName("modifier_phased")
	if self:GetSpecialValueFor("debuff_immune") ~= 0 then
		self:GetCaster():RemoveModifierByName("modifier_nevermore_requiem_debuff_immune")
	end
end
function nevermore_requiem:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end
function nevermore_requiem:OnOwnerDied()
    self:OnAbilityPhaseInterrupted()
	if not self:IsTrained() then return end
    self:ReleaseSouls(true, false)
end
function nevermore_requiem:OnSpellStart()
    self:GetCaster():RemoveModifierByName("modifier_phased")
	if self:GetSpecialValueFor("debuff_immune") ~= 0 then
		self:GetCaster():RemoveModifierByName("modifier_nevermore_requiem_debuff_immune")
	end
	if self:GetSpecialValueFor("is_physical") ~= 0 then
		self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_nevermore_requiem_attack_speed", { duration = self:GetSpecialValueFor("attack_speed_duration") })
	end
    self:ReleaseSouls(false, false)
	if self:GetSpecialValueFor("returns") ~= 0 then
		self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_nevermore_requiem_return_delay", { duration = self:GetSpecialValueFor("radius") / self:GetSpecialValueFor("line_speed") })
	end
end
function nevermore_requiem:ReleaseSouls(is_death, is_return)
	if IsClient() then return end
	local caster = self:GetCaster()

	local souls = 0
	local modifier = caster:FindModifierByName("modifier_nevermore_necromastery_passive")
	if modifier then
		souls = modifier:GetStackCount()
	end
	
	local projectile_count = math.ceil(souls / self:GetSpecialValueFor("soul_conversion"))
	
	ParticleManager:FireParticle("particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_a.vpcf", PATTACH_ABSORIGIN, caster, {[1]=Vector(projectile_count, 0, 0),[2]=caster:GetAbsOrigin()})
	ParticleManager:FireParticle("particles/units/heroes/hero_nevermore/nevermore_requiemofsouls.vpcf", PATTACH_ABSORIGIN, caster, {[1]=Vector(projectile_count, 0, 0)})
	EmitSoundOn("Hero_Nevermore.RequiemOfSouls", caster)

	if projectile_count == 0 then return end
	local center = caster:GetAbsOrigin()
	local offset_per = 360 / projectile_count;
	local initial_angle = Vector(1.0, 0.0, 0.0)
	local distance = self:GetSpecialValueFor("radius")
	self.projectiles = self.projectiles or {}
	for i = 0, projectile_count - 1 do
		local direction = RotateVector2D(initial_angle, ToRadians(offset_per * i))
		local projectile = nil
		if is_return then
			projectile = self:FireRequiemSoul(-direction, center + direction * distance)
		else
			projectile = self:FireRequiemSoul(direction, center)
		end
		self.projectiles[projectile] = {
			returning = is_return,
			damaged = {}
		}
	end
end
function nevermore_requiem:FireRequiemSoul(direction, origin)
	local caster = self:GetCaster()
	
	local distance = self:GetSpecialValueFor("radius")
	local width_start = self:GetSpecialValueFor("line_width_start")
	local width_end = self:GetSpecialValueFor("line_width_end")
	local speed = self:GetSpecialValueFor("line_speed")
	
	local particle_lines_fx = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_line.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(particle_lines_fx, 0, origin or caster:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle_lines_fx, 1, direction*speed)
	ParticleManager:SetParticleControl(particle_lines_fx, 2, Vector(0, distance/speed, 0))
	ParticleManager:ReleaseParticleIndex(particle_lines_fx)

	return self:FireLinearProjectile("", direction*speed, distance, width_start, { width_end = width_end, origin = origin }, false, true, width_end)
end
function nevermore_requiem:OnProjectileHitHandle(target, location, projectile)
	if target and not self.projectiles[projectile].damaged[target] then
		EmitSoundOn("Hero_Nevermore.RequiemOfSouls.Damage", target)
		local caster = self:GetCaster()

		local fear_duration = self:GetSpecialValueFor("fear_duration")
		local fear_duration_max = self:GetSpecialValueFor("fear_duration_max")
		if self:GetSpecialValueFor("does_fear") ~= 0 then
			local modifier = target:FindModifierByName("modifier_nevermore_requiem_fear")
			if modifier then
				modifier:SetDuration(math.min(modifier:GetRemainingTime() + fear_duration, fear_duration_max), true)
			else
				target:AddNewModifier(caster, self, "modifier_nevermore_requiem_fear", { duration = fear_duration})
			end
		end

		local debuff_modifier = target:FindModifierByName("modifier_nevermore_requiem_debuff")
		if debuff_modifier then
			debuff_modifier:SetDuration(self:GetSpecialValueFor("debuff_duration"), true)
		else
			target:AddNewModifier(caster, self, "modifier_nevermore_requiem_debuff", { duration = self:GetSpecialValueFor("debuff_duration") })
		end

		local damage = self:GetSpecialValueFor("damage")
		if self.projectiles[projectile].returning then
			damage = damage * (self:GetSpecialValueFor("return_damage_percent") / 100)
		end
		local damage_type = TernaryOperator(DAMAGE_TYPE_PHYSICAL, self:GetSpecialValueFor("is_physical") ~= 0, DAMAGE_TYPE_MAGICAL)
		self:DealDamage(caster, target, damage, { damage_type = damage_type })
		self.projectiles[projectile].damaged[target] = true
	else
		self.projectiles[projectile] = nil
	end
end

modifier_nevermore_requiem_debuff = class({})
LinkLuaModifier("modifier_nevermore_requiem_debuff", "heroes/hero_shadow_fiend/nevermore_requiem.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_nevermore_requiem_debuff:IsDebuff()
	return true
end
function modifier_nevermore_requiem_debuff:IsPurgable()
	return true
end

modifier_nevermore_requiem_debuff_immune = class({})
LinkLuaModifier("modifier_nevermore_requiem_debuff_immune", "heroes/hero_shadow_fiend/nevermore_requiem.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_nevermore_requiem_debuff_immune:IsPurgable()
	return false
end
function modifier_nevermore_requiem_debuff_immune:CheckState()
	return {
		[MODIFIER_STATE_DEBUFF_IMMUNE] = true
	}
end
function modifier_nevermore_requiem_debuff_immune:GetEffectName()
	return "particles/items_fx/black_king_bar_avatar.vpcf"
end
function modifier_nevermore_requiem_debuff_immune:GetTexture()
	return "modifier_magicimmune"
end

modifier_nevermore_requiem_attack_speed = class({})
LinkLuaModifier("modifier_nevermore_requiem_attack_speed", "heroes/hero_shadow_fiend/nevermore_requiem.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_nevermore_requiem_attack_speed:IsPurgable()
	return true
end
function modifier_nevermore_requiem_attack_speed:OnCreated()
	self:OnRefresh()
end
function modifier_nevermore_requiem_attack_speed:OnRefresh()
	self.attack_speed = self:GetSpecialValueFor("attack_speed")
end
function modifier_nevermore_requiem_attack_speed:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	}
end
function modifier_nevermore_requiem_attack_speed:GetModifierAttackSpeedBonus_Constant()
	return self.attack_speed
end

modifier_nevermore_requiem_return_delay = class({})
LinkLuaModifier("modifier_nevermore_requiem_return_delay", "heroes/hero_shadow_fiend/nevermore_requiem.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_nevermore_requiem_return_delay:IsHidden()
	return true
end
function modifier_nevermore_requiem_return_delay:IsPurgable()
	return false
end
function modifier_nevermore_requiem_return_delay:OnRemoved(death)
	if death then return end

	local ability = self:GetAbility()
	if ability then
		ability:ReleaseSouls(false, true)
	end
end