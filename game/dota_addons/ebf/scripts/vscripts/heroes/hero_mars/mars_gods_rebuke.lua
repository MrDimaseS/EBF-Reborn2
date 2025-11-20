mars_gods_rebuke = class({})

function mars_gods_rebuke:IsStealable()
	return true
end

function mars_gods_rebuke:IsHiddenWhenStolen()
	return false
end

function mars_gods_rebuke:GetIntrinsicModifierName()
	return "modifier_mars_gods_rebuke_handler"
end

function mars_gods_rebuke:GetCastRange(vLocation, hTarget)
	return self:GetCaster():GetAttackRange() + self:GetSpecialValueFor("radius") - self:GetCaster():GetCastRangeBonus()
end

function mars_gods_rebuke:OnSpellStart()
	local caster = self:GetCaster()
	local pos = self:GetCursorPosition()

	EmitSoundOn("Hero_Mars.Shield.Cast", caster)
	self:Rebuke(caster, pos)
end

function mars_gods_rebuke:Rebuke(source, position, lowFX)
	local caster = self:GetCaster()
	local origin = source or caster

	local direction = CalculateDirection(position, origin:GetAbsOrigin())

	local angle = self:GetSpecialValueFor("angle")	
	local distance = self:GetTrueCastRange()
	local knockback_duration = self:GetSpecialValueFor("knockback_duration")	
	local knockback_distance = self:GetSpecialValueFor("knockback_distance")
	
	local particle = "particles/units/heroes/hero_mars/mars_shield_bash.vpcf"
	if lowFX then
		particle = "particles/units/heroes/hero_mars/mars_shield_bash_lowfx.vpcf"
	end
	local nfx = ParticleManager:CreateParticle(particle, PATTACH_POINT_FOLLOW, origin)
				ParticleManager:SetParticleControlForward(nfx, 0, direction)
				ParticleManager:SetParticleControl( nfx, 0, origin:GetAbsOrigin() )
				ParticleManager:SetParticleControl(nfx, 1, Vector(distance, distance, distance))
				ParticleManager:ReleaseParticleIndex(nfx)
	
	local critHandler = caster:FindModifierByName("modifier_mars_gods_rebuke_handler")
	local stacks = 0
	if critHandler then
		stacks = critHandler:GetStackCount()
		Timers:CreateTimer( function() critHandler:SetStackCount( 0 ) end )
	end
	caster:AddNewModifier(caster, self, "modifier_mars_gods_rebuke_damage_handler", {Duration = 1}):SetStackCount( stacks )

	local enemies = caster:FindEnemyUnitsInCone(direction, origin:GetAbsOrigin(), distance, distance)
	local slow_duration = self:GetSpecialValueFor("knockback_slow_duration")
	
	EmitSoundOn("Hero_Mars.Shield.Crit", caster)
	for _,enemy in pairs(enemies) do
		if not enemy:HasModifier( "modifier_mars_gods_rebuke_debuff" ) then
			local nfx2 = ParticleManager:CreateParticle("particles/units/heroes/hero_mars/mars_shield_bash_crit.vpcf", PATTACH_WORLDORIGIN, enemy)
						ParticleManager:SetParticleControl(nfx2, 0, enemy:GetAbsOrigin())
						ParticleManager:SetParticleControl(nfx2, 1, enemy:GetAbsOrigin())
						ParticleManager:SetParticleControlForward(nfx2, 1, CalculateDirection(enemy, origin))
						ParticleManager:ReleaseParticleIndex(nfx2)
			enemy:ApplyKnockBack(origin:GetAbsOrigin(), knockback_duration, knockback_duration, knockback_distance, 0, caster, self, false)
			enemy:AddNewModifier( caster, self, "modifier_mars_gods_rebuke_debuff", {duration = slow_duration} )
			caster:PerformGenericAttack(enemy, true, {ability = self})
		end
	end

	caster:RemoveModifierByName("modifier_mars_gods_rebuke_damage_handler")
end

modifier_mars_gods_rebuke_handler = class({})
LinkLuaModifier( "modifier_mars_gods_rebuke_handler", "heroes/hero_mars/mars_gods_rebuke.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_mars_gods_rebuke_handler:OnCreated()
	self.bonus_crit_per_hero = self:GetSpecialValueFor("bonus_crit_per_hero")
	self.bonus_crit_per_creep = self:GetSpecialValueFor("bonus_crit_per_creep")
	if self.bonus_crit_per_creep > 0 and self.bonus_crit_per_hero > 0 then
		self.hero_stacks = self.bonus_crit_per_hero / self.bonus_crit_per_creep
	end
end

function modifier_mars_gods_rebuke_handler:DeclareFunctions()
	return {MODIFIER_PROPERTY_TOOLTIP, MODIFIER_EVENT_ON_ATTACK }
end

function modifier_mars_gods_rebuke_handler:OnTooltip(params)
	return self.bonus_crit_per_creep * self:GetStackCount()
end


function modifier_mars_gods_rebuke_handler:OnAttack(params)
	if not self.hero_stacks then return end
	local parent = self:GetParent()
	if params.target ~= parent then return end
	if params.attacker:IsConsideredHero() then
		self:SetStackCount( self:GetStackCount() + self.hero_stacks )
	else
		self:IncrementStackCount()
	end
end

function modifier_mars_gods_rebuke_handler:IsHidden()
	return self:GetStackCount() == 0
end

modifier_mars_gods_rebuke_damage_handler = class({})
LinkLuaModifier( "modifier_mars_gods_rebuke_damage_handler", "heroes/hero_mars/mars_gods_rebuke.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_mars_gods_rebuke_damage_handler:OnCreated()
	self:OnRefresh()
end

function modifier_mars_gods_rebuke_damage_handler:OnRefresh()
	self.crit = self:GetSpecialValueFor("crit_mult")
	self.bonus_dmg = self:GetSpecialValueFor("bonus_damage_vs_heroes")
	
	self.bonus_crit_per_creep = self:GetSpecialValueFor("bonus_crit_per_creep")
	self.lifesteal = self:GetSpecialValueFor("lifesteal")
	if self.lifesteal > 0 then
		self:GetParent()._pureLifestealModifiersList = self:GetParent()._pureLifestealModifiersList or {}
		self:GetParent()._pureLifestealModifiersList[self] = true
		
		self:GetParent()._spellLifestealModifiersList = self:GetParent()._spellLifestealModifiersList or {}
		self:GetParent()._spellLifestealModifiersList[self] = true
		
		self:GetParent()._attackLifestealModifiersList = self:GetParent()._attackLifestealModifiersList or {}
		self:GetParent()._attackLifestealModifiersList[self] = true
	end
end

function modifier_mars_gods_rebuke_damage_handler:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE, MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE }
end

function modifier_mars_gods_rebuke_damage_handler:GetModifierPreAttack_CriticalStrike(params)
	return self.crit + self.bonus_crit_per_creep * self:GetStackCount()
end

function modifier_mars_gods_rebuke_damage_handler:GetModifierPreAttack_BonusDamage(params)
	if not params.target then return end
	if params.target:IsConsideredHero() then
		return self.bonus_dmg
	end
end

function modifier_mars_gods_rebuke_damage_handler:GetModifierProperty_MagicalLifesteal(params)
	return self.lifesteal
end

function modifier_mars_gods_rebuke_damage_handler:GetModifierProperty_PhysicalLifesteal(params)
	return self.lifesteal
end

function modifier_mars_gods_rebuke_damage_handler:GetModifierProperty_PureLifesteal(params)
	return self.lifesteal
end

function modifier_mars_gods_rebuke_damage_handler:IsPurgable()
	return false
end

function modifier_mars_gods_rebuke_damage_handler:IsPurgeException()
	return false
end

function modifier_mars_gods_rebuke_damage_handler:IsHidden()
	return true
end

modifier_mars_gods_rebuke_debuff = class({})
LinkLuaModifier( "modifier_mars_gods_rebuke_debuff", "heroes/hero_mars/mars_gods_rebuke.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_mars_gods_rebuke_debuff:OnCreated()
	self:OnRefresh()
end

function modifier_mars_gods_rebuke_debuff:OnRefresh()
	self.knockback_slow = -self:GetSpecialValueFor("knockback_slow")
	self.knockback_attack_slow = -self:GetSpecialValueFor("knockback_attack_slow")
end

function modifier_mars_gods_rebuke_debuff:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT  }
end

function modifier_mars_gods_rebuke_debuff:GetModifierMoveSpeedBonus_Percentage(params)
	return self.knockback_slow
end

function modifier_mars_gods_rebuke_debuff:GetModifierAttackSpeedBonus_Constant(params)
	return self.knockback_attack_slow
end