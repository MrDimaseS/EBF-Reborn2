nevermore_shadowraze = class({})

function nevermore_shadowraze:GetAOERadius()
    return self:GetSpecialValueFor("shadowraze_range")
end
function nevermore_shadowraze:OnSpellStart()
    if IsClient() then return end

    local caster = self:GetCaster();
    local shadowraze_range = self:GetSpecialValueFor("shadowraze_range")
    local shadowraze_radius = self:GetSpecialValueFor("shadowraze_radius")
    local duration = self:GetSpecialValueFor("duration")
    local offset = caster:GetForwardVector() * shadowraze_range;
    local position = caster:GetAbsOrigin() + offset;

	local damage = self:GetSpecialValueFor("shadowraze_damage")
	local attack_interval = self:GetSpecialValueFor("attack_interval")
	local triggers = math.max( 1, math.floor( caster:GetAttacksPerSecond( false ) * self:GetSpecialValueFor("attack_speed_pct") / 100 ) + #self:RollPRNG( (caster:GetAttacksPerSecond( false )-math.floor( caster:GetAttacksPerSecond( false )))*100 ) )
	
	local base_triggers = triggers
	
	Timers:CreateTimer( function()
		for _,unit in ipairs( caster:FindEnemyUnitsInRadius( position, shadowraze_radius ) ) do
			if base_triggers == triggers then -- only apply debuff on primary burst
				if self:GetSpecialValueFor("attack_speed_reduction") ~= 0 then
					unit:AddNewModifier(caster, self, "modifier_nevermore_shadowraze_id_debuff", { duration = duration })
				end
				if self:GetSpecialValueFor("stack_bonus_damage") ~= 0 then
					unit:AddNewModifier(caster, self, "modifier_nevermore_shadowraze_psyche_debuff", { duration = duration })
				end
				if self:GetSpecialValueFor("bonus_damage_taken") ~= 0 then
					unit:AddNewModifier(caster, self, "modifier_nevermore_shadowraze_ego_debuff", { duration = duration })
				end
			end
			if self:GetSpecialValueFor("does_attack") ~= 0 then
				caster:PerformGenericAttack(unit, true, {neverMiss = false, bonusDamage = damage})
				-- deal some damage so that necromastery knows we razed
				if base_triggers == triggers then self:DealDamage(caster, unit, 1) end
			else
				local damage_flags = 0
				if base_triggers < triggers then damage_flags = DOTA_DAMAGE_FLAG_PROPERTY_FIRE  end
				self:DealDamage(caster, unit, damage, {damage_flags = damage_flags})
			end
		end

		-- create the particle and sound
		local particle = ParticleManager:FireParticle(
			"particles/units/heroes/hero_nevermore/nevermore_shadowraze.vpcf",
			PATTACH_ABSORIGIN,
			caster,
			{[0] = position + Vector(0,0,1),
			 [1] = Vector(shadowraze_radius,0,1)}
		)
		EmitSoundOnLocationWithCaster(position, "Hero_Nevermore.Shadowraze", caster)
		
		triggers = triggers -1
		if triggers > 0 then
			return attack_interval
		end
	end)
end

nevermore_shadowraze1 = class(nevermore_shadowraze)
nevermore_shadowraze2 = class(nevermore_shadowraze)
nevermore_shadowraze3 = class(nevermore_shadowraze)

modifier_nevermore_shadowraze_psyche_debuff = class({})
LinkLuaModifier("modifier_nevermore_shadowraze_psyche_debuff", "heroes/hero_shadow_fiend/nevermore_shadowraze.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_nevermore_shadowraze_psyche_debuff:OnCreated()
	self:OnRefresh()
end

function modifier_nevermore_shadowraze_psyche_debuff:OnRefresh()
	self.stack_bonus_damage = self:GetSpecialValueFor("stack_bonus_damage")
	if IsServer() then
		self:AddIndependentStack()
	end
end

function modifier_nevermore_shadowraze_psyche_debuff:IsDebuff()
    return true
end
function modifier_nevermore_shadowraze_psyche_debuff:IsPurgable()
    return true
end
function modifier_nevermore_shadowraze_psyche_debuff:DeclareFunctions()
    return { MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end
function modifier_nevermore_shadowraze_psyche_debuff:GetModifierIncomingDamage_Percentage(params)
	if IsServer() then
		if params.attacker == self:GetCaster() and params.inflictor and params.attacker:HasAbility( params.inflictor:GetAbilityName() ) then
			return self.stack_bonus_damage * self:GetStackCount()
		end
	else
		return self.stack_bonus_damage * self:GetStackCount()
	end
end

function modifier_nevermore_shadowraze_psyche_debuff:GetEffectName()
    return "particles/units/heroes/hero_nevermore/nevermore_shadowraze_debuff.vpcf"
end

modifier_nevermore_shadowraze_id_debuff = class({})
LinkLuaModifier("modifier_nevermore_shadowraze_id_debuff", "heroes/hero_shadow_fiend/nevermore_shadowraze.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_nevermore_shadowraze_id_debuff:IsDebuff()
    return true
end
function modifier_nevermore_shadowraze_id_debuff:IsPurgable()
    return true
end
function modifier_nevermore_shadowraze_id_debuff:OnCreated()
    self:OnRefresh()
end
function modifier_nevermore_shadowraze_id_debuff:OnRefresh()
    self.attack_speed_reduction = self:GetSpecialValueFor("attack_speed_reduction")
	if IsServer() then
		self:AddIndependentStack()
	end
end
function modifier_nevermore_shadowraze_id_debuff:DeclareFunctions()
    return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end
function modifier_nevermore_shadowraze_id_debuff:GetModifierAttackSpeedBonus_Constant()
    return self.attack_speed_reduction * self:GetStackCount()
end
function modifier_nevermore_shadowraze_id_debuff:GetEffectName()
    return "particles/units/heroes/hero_nevermore/nevermore_shadowraze_debuff.vpcf"
end

modifier_nevermore_shadowraze_ego_debuff = class({})
LinkLuaModifier("modifier_nevermore_shadowraze_ego_debuff", "heroes/hero_shadow_fiend/nevermore_shadowraze.lua", LUA_MODIFIER_MOTION_NONE)

function modifier_nevermore_shadowraze_ego_debuff:IsDebuff()
    return true
end
function modifier_nevermore_shadowraze_ego_debuff:IsPurgable()
    return true
end
function modifier_nevermore_shadowraze_ego_debuff:OnCreated()
    self:OnRefresh()
end
function modifier_nevermore_shadowraze_ego_debuff:OnRefresh()
    self.bonus_damage_taken = self:GetSpecialValueFor("bonus_damage_taken")
	if IsServer() then
		self:AddIndependentStack()
	end
end
function modifier_nevermore_shadowraze_ego_debuff:DeclareFunctions()
    return {
        MODIFIER_PROPERTY_INCOMING_PHYSICAL_DAMAGE_CONSTANT
    }
end
function modifier_nevermore_shadowraze_ego_debuff:GetModifierIncomingPhysicalDamageConstant( params )
    return self.bonus_damage_taken * self:GetStackCount()
end
function modifier_nevermore_shadowraze_ego_debuff:GetEffectName()
    return "particles/units/heroes/hero_nevermore/nevermore_shadowraze_debuff.vpcf"
end