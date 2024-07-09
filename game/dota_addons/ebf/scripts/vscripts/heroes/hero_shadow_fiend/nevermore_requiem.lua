nevermore_requiem_ebf = class({})

function nevermore_requiem_ebf:OnAbilityPhaseStart()
    print("OnAbilityPhaseStart")
    EmitSoundOn("Hero_Nevermore.RequiemOfSoulsCast", self:GetCaster())
    self.warmupFX = ParticleManager:CreateParticle("particles/units/heroes/hero_nevermore/nevermore_wings.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster())
    ParticleManager:SetParticleControlEnt(self.warmupFX, 5, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_attack1", self:GetCaster():GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.warmupFX, 6, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_attack2", self:GetCaster():GetAbsOrigin(), true)
    ParticleManager:SetParticleControlEnt(self.warmupFX, 7, self:GetCaster(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetCaster():GetAbsOrigin(), true)
    self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_phased", {})
	if self:GetSpecialValueFor("debuff_immune") ~= 0 then
		self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_nevermore_requiem_ebf_debuff_immune", {})
	end
    return true
end
function nevermore_requiem_ebf:OnAbilityPhaseInterrupted()
    print("OnAbilityPhaseInterrupted")
    StopSoundOn("Hero_Nevermore.RequiemOfSoulsCast", self:GetCaster())
    ParticleManager:ClearParticle( self.warmupFX )
    self:GetCaster():RemoveModifierByName("modifier_phased")
	if self:GetSpecialValueFor("debuff_immune") ~= 0 then
		self:GetCaster():RemoveModifierByName("modifier_nevermore_requiem_ebf_debuff_immune")
	end
end
function nevermore_requiem_ebf:GetAOERadius()
    print("GetAOERadius")
    return self:GetSpecialValueFor("radius")
end
function nevermore_requiem_ebf:OnOwnerDied()
    print("OnOwnerDied")
    self:OnAbilityPhaseInterrupted()
    self:ReleaseSouls()
end
function nevermore_requiem_ebf:OnSpellStart()
    print("OnSpellStart")
	if self:GetSpecialValueFor("debuff_immune") ~= 0 then
		self:GetCaster():RemoveModifierByName("modifier_nevermore_requiem_ebf_debuff_immune")
	end
	if self:GetSpecialValueFor("attack_speed") ~= 0 then
		self:GetCaster():AddNewModifier(self:GetCaster(), self, "modifier_nevermore_requiem_ebf_attack_speed", { duration = self:GetSpecialValueFor("attack_speed_duration") })
	end
    self:ReleaseSouls()
end
function nevermore_requiem_ebf:ReleaseSouls()
    print("ReleaseSouls")
	local caster = self:GetCaster()

	local startPos = caster:GetAbsOrigin()
	local direction = caster:GetForwardVector()

	local souls = 0
	local modifier = caster:FindModifierByName("modifier_nevermore_necromastery_passive")
	if modifier then
		souls = modifier:GetStackCount()
	end
	
	local projectiles = souls / self:GetSpecialValueFor("soul_conversion")
	
	ParticleManager:FireParticle("particles/units/heroes/hero_nevermore/nevermore_requiemofsouls_a.vpcf", PATTACH_ABSORIGIN, caster, {[1]=Vector(projectiles, 0, 0),[2]=caster:GetAbsOrigin()})
	ParticleManager:FireParticle("particles/units/heroes/hero_nevermore/nevermore_requiemofsouls.vpcf", PATTACH_ABSORIGIN, caster, {[1]=Vector(projectiles, 0, 0)})

	local angle = math.min( 360/projectiles, 360/25 )
	EmitSoundOn("Hero_Nevermore.RequiemOfSouls", caster)
	self.requiemProj = self.requiemProj or {}
	for i=0, projectiles do
		local initialOffset = (projectiles % 2) * angle / 2
		local newDir = RotateVector2D(direction, ToRadians( initialOffset + angle * math.floor(i / 2) * (-1)^i ) )
		local projectile = self:FireRequiemSoul(newDir, startPos)
		self.requiemProj[projectile] = {}
		self.requiemProj[projectile].damage = 0
		if self:GetSpecialValueFor("returns") ~= 0 then
			self.requiemProj[projectile].bounce = true
		end
	end
end
function nevermore_requiem_ebf:FireRequiemSoul(direction, origin)
    print("FireRequiemSoul")
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

	local projectile = self:FireLinearProjectile("", direction*speed, distance, width_start, {width_end=width_end}, false, true, width_end)
	return projectile
end
function nevermore_requiem_ebf:OnProjectileHitHandle(target, location, projectile)
    print("OnProjectileHitHandle")
	local caster = self:GetCaster()
	
	local fear_duration = self:GetSpecialValueFor("fear_duration")
	local fear_duration_max = self:GetSpecialValueFor("fear_duration_max")
	local damage = self:GetSpecialValueFor("damage")
	if target then
		EmitSoundOn("Hero_Nevermore.RequiemOfSouls.Damage", target)
		if self:GetSpecialValueFor("does_fear") ~= 0 then
			local modifier = target:FindModifierByName("modifier_nevermore_requiem_fear")
			if modifier then
				fear_duration = math.min(modifier:GetRemainingTime() + fear_duration, fear_duration_max)
			else
				target:AddNewModifier(caster, self, "modifier_nevermore_requiem_fear", { duration = fear_duration })
			end
		end

		local debuff_modifier = target:FindModifierByName("modifier_nevermore_requiem_debuff")
		if debuff_modifier then
			debuff_modifier:SetDuration(self:GetSpecialValueFor("debuff_duration"))
		else
			target:AddNewModifier(caster, self, "modifier_nevermore_requiem_debuff", { duration = self:GetSpecialValueFor("debuff_duration") })
		end
		
		local raze_debuff = target:FindModifierByName("modifier_nevermore_shadowraze_stack")
		if debuff then
			damage = damage * (1 + debuff:OnTooltip() / 100)
		end
		if self.requiemProj[projectile].bounce == false then -- rebound
			damage = damage * self:GetSpecialValueFor("return_damage_percent") / 100
		end
		local damage_type = TernaryOperator(DAMAGE_TYPE_PHYSICAL, self:GetSpecialValueFor("is_physical"), DAMAGE_TYPE_MAGICAL)
		local damageDealt = self:DealDamage(caster, target, damage, { damage_type = damage_type })
		self.requiemProj[projectile].damage = self.requiemProj[projectile].damage + damageDealt
	elseif self.requiemProj[projectile] ~= nil then
		if self.requiemProj[projectile].bounce then -- outward reflect
			local newProj = self:FireRequiemSoul( -ProjectileManager:GetLinearProjectileVelocity( projectile ):Normalized(), location )
			self.requiemProj[newProj] = table.copy(self.requiemProj[projectile])
			self.requiemProj[newProj].bounce = false
		end
		self.requiemProj[projectile] = nil
	end
end

modifier_nevermore_requiem_ebf_debuff = class({})
LinkLuaModifier("modifier_nevermore_requiem_ebf_debuff", "heroes/hero_shadow_fiend/nevermore_requiem.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_nevermore_requiem_ebf_debuff:IsDebuff()
	return true
end
function modifier_nevermore_requiem_ebf_debuff:IsPurgable()
	return true
end

modifier_nevermore_requiem_ebf_debuff_immune = class({})
LinkLuaModifier("modifier_nevermore_requiem_ebf_debuff_immune", "heroes/hero_shadow_fiend/nevermore_requiem.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_nevermore_requiem_ebf_debuff_immune:IsHidden()
	return true
end
function modifier_nevermore_requiem_ebf_debuff_immune:CheckState()
	return {
		[MODIFIER_STATE_DEBUFF_IMMUNE] = true
	}
end
function modifier_nevermore_requiem_ebf_debuff_immune:GetEffectName()
	return "particles/items_fx/black_king_bar_avatar.vpcf"
end

modifier_nevermore_requiem_ebf_attack_speed = class({})
LinkLuaModifier("modifier_nevermore_requiem_ebf_attack_speed", "heroes/hero_shadow_fiend/nevermore_requiem.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_nevermore_requiem_ebf_attack_speed:IsPurgable()
	return true
end
function modifier_nevermore_requiem_ebf_attack_speed:OnCreated()
	self:OnRefresh()
end
function modifier_nevermore_requiem_ebf_attack_speed:OnRefresh()
	self.attack_speed = self:GetSpecialValueFor("attack_speed")
end
function modifier_nevermore_requiem_ebf_attack_speed:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT
	}
end
function modifier_nevermore_requiem_ebf_attack_speed:GetModifierAttackSpeedBonus_Constant()
	return self.attack_speed
end