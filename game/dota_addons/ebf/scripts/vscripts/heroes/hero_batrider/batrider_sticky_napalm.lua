batrider_sticky_napalm = class({})

function batrider_sticky_napalm:GetIntrinsicModifierName()
	return "modifier_batrider_sticky_napalm_autocast"
end

function batrider_sticky_napalm:IsStealable()
    return true
end

function batrider_sticky_napalm:IsHiddenWhenStolen()
    return false
end

function batrider_sticky_napalm:GetAOERadius()
    return self:GetSpecialValueFor("radius")
end

function batrider_sticky_napalm:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("duration")
	
	EmitSoundOn("Hero_Batrider.StickyNapalm.Cast", caster)
	EmitSoundOnLocationWithCaster(point, "Hero_Batrider.StickyNapalm.Impact", caster)
	
	local casts = TernaryOperator( self:GetSpecialValueFor("shard_extra_napalm"), caster:HasShard(), 1 )
	Timers:CreateTimer(function()
		local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_batrider/batrider_stickynapalm_impact.vpcf", PATTACH_POINT, caster)
				ParticleManager:SetParticleControl(nfx, 0, point)
				ParticleManager:SetParticleControl(nfx, 1, Vector(radius, 0, 0))
				ParticleManager:SetParticleControlEnt(nfx, 2, caster, PATTACH_POINT, "lasso_attack", caster:GetAbsOrigin(), true)
				ParticleManager:ReleaseParticleIndex(nfx)

		local enemies = caster:FindEnemyUnitsInRadius(point, radius)
		for _,enemy in pairs(enemies) do
			if not enemy:TriggerSpellAbsorb(self) then
				enemy:AddNewModifier(caster, self, "modifier_batrider_sticky_napalm_debuff", {Duration = duration})
			end
		end
		casts = casts - 1
		if casts > 0 then
			return 0.1
		end
	end)
end

modifier_batrider_sticky_napalm_debuff = class({})
LinkLuaModifier("modifier_batrider_sticky_napalm_debuff", "heroes/hero_batrider/batrider_sticky_napalm", LUA_MODIFIER_MOTION_NONE)
function modifier_batrider_sticky_napalm_debuff:OnCreated(table)
	if IsServer() then
		local caster = self:GetCaster()
		local parent = self:GetParent()

		self.nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_batrider/batrider_stickynapalm_stack.vpcf", PATTACH_POINT, caster)
					ParticleManager:SetParticleControlEnt(self.nfx, 0, parent, PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
					ParticleManager:SetParticleControl(self.nfx, 1, Vector(0, self:GetStackCount(), 0))
		self:AttachEffect(self.nfx)
	end
	self:OnRefresh()
end

function modifier_batrider_sticky_napalm_debuff:OnRefresh(table)
	self.max_stacks = self:GetSpecialValueFor("max_stacks")
	self.turnRate = self:GetSpecialValueFor("turn_rate_pct")
	self.application_damage = self:GetSpecialValueFor("application_damage")
	self.hero_damage_pct = self:GetSpecialValueFor("hero_damage_pct") / 100
	if IsServer() then
		self:SetStackCount( math.min(self:GetStackCount() + 1, self.max_stacks) )
		ParticleManager:SetParticleControl(self.nfx, 1, Vector(math.floor(self:GetStackCount() / 10), self:GetStackCount() % 10, 0))
		self.damage = self:GetSpecialValueFor("damage") * self:GetStackCount()
		self:GetAbility():DealDamage( self:GetCaster(), self:GetParent(), self.application_damage )
	end
	self.slow = self:GetSpecialValueFor("movement_speed_pct") * self:GetStackCount()
end

function modifier_batrider_sticky_napalm_debuff:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_TURN_RATE_PERCENTAGE}
end

function modifier_batrider_sticky_napalm_debuff:OnTakeDamage(params)
    if IsServer() then
    	local caster = self:GetCaster()
    	local parent = self:GetParent()
    	local unit = params.unit
    	local attacker = params.attacker
		if self.preventStickyNapalmLoop then return end
		
        if unit == parent and attacker == caster 
		and ( (params.inflictor and caster:HasAbility( params.inflictor:GetName() ) )
		or params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK ) then
        	local ability = self:GetAbility()

        	ParticleManager:FireParticle("particles/units/heroes/hero_batrider/batrider_base_attack_explosion.vpcf", PATTACH_POINT_FOLLOW, parent)
			Timers:CreateTimer(0.1, function()
				self.preventStickyNapalmLoop = true
				ability:DealDamage(caster, parent, self.damage*TernaryOperator( self.hero_damage_pct, parent:IsConsideredHero(), 1 ) )
				self.preventStickyNapalmLoop = false
			end)
        end
    end
end

function modifier_batrider_sticky_napalm_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

function modifier_batrider_sticky_napalm_debuff:GetModifierTurnRate_Percentage()
	return self.turnRate
end

function modifier_batrider_sticky_napalm_debuff:GetEffectName()
	return "particles/units/heroes/hero_batrider/batrider_stickynapalm_debuff.vpcf"
end

function modifier_batrider_sticky_napalm_debuff:GetStatusEffectName()
	return "particles/status_fx/status_effect_stickynapalm.vpcf"
end

function modifier_batrider_sticky_napalm_debuff:StatusEffectPriority()
	return 11
end

function modifier_batrider_sticky_napalm_debuff:IsDebuff()
	return true
end

modifier_batrider_sticky_napalm_autocast = class({})
LinkLuaModifier("modifier_batrider_sticky_napalm_autocast", "heroes/hero_batrider/batrider_sticky_napalm", LUA_MODIFIER_MOTION_NONE)

function modifier_batrider_sticky_napalm_autocast:OnCreated(table)
	if IsServer() then
		self:StartIntervalThink(0)
	end
end

function modifier_batrider_sticky_napalm_autocast:OnIntervalThink()
	local caster = self:GetCaster()
	local target = caster:GetAttackTarget()
	if target and not caster:AttackReady() then
		local ability = self:GetAbility()
		if ability:GetAutoCastState() and ability:IsFullyCastable() then
			caster:CastAbilityOnPosition( target:GetAbsOrigin(), ability, caster:GetPlayerOwnerID() )
		end
	end
end

function modifier_batrider_sticky_napalm_autocast:IsHidden()
	return true
end
