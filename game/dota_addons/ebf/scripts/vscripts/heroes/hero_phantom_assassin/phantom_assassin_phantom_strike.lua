phantom_assassin_phantom_strike = class({})

function phantom_assassin_phantom_strike:GetBehavior()
	if self:GetSpecialValueFor("point_target") == 1 then
		return DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES
	elseif self:GetSpecialValueFor("no_target") == 1 then
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET
	else
		return self.BaseClass.GetBehavior( self )
	end
end

function phantom_assassin_phantom_strike:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local position = self:GetCursorPosition()
	
	if target then -- unit target
		position = target:GetAbsOrigin() + CalculateDirection( target, caster ) * caster:GetAttackRange()
		Timers:CreateTimer( function()
			caster:MoveToTargetToAttack( target )
		end)
	elseif CalculateDistance( position, Vector(0,0,0) ) <= 0.5 then -- no target
		position = caster:GetAbsOrigin()
	end
	caster:Blink(position, {FX = "particles/units/heroes/hero_phantom_assassin/phantom_assassin_phantom_strike_start.vpcf"})
	
	caster:AddNewModifier( caster, self, "modifier_phantom_assassin_phantom_strike_buff", {duration = self:GetSpecialValueFor("duration")})
	caster:EmitSound("Hero_PhantomAssassin.Blur")
	
	local daggerRefresh = self:GetSpecialValueFor("dagger_refresh") == 1
	local resetDelay = self:GetSpecialValueFor("reset_delay") == 1
	local immaterialStacks = self:GetSpecialValueFor("immaterial_stacks")
	if daggerRefresh then
		self._stiflingDagger = caster:FindAbilityByName("phantom_assassin_stifling_dagger")
		if self._stiflingDagger then
			if self._stiflingDagger:IsCooldownReady() then
				caster:AddNewModifier( caster, self, "modifier_phantom_assassin_phantom_strike_lanceuse", {})
			else
				self._stiflingDagger:EndCooldown()
			end
		end
	end
	if immaterialStacks > 0 then
		local immaterial = caster:FindModifierByName("modifier_phantom_assassin_immaterial_handler")
		immaterial:SetStackCount( immaterial:GetStackCount() + immaterialStacks )
		
		immaterial:StartIntervalThink( immaterial.loss_delay )
		immaterial._currentMode = IMMATERIAL_STATE_REDUCE
	end
end

modifier_phantom_assassin_phantom_strike_lanceuse = class({})
LinkLuaModifier( "modifier_phantom_assassin_phantom_strike_lanceuse", "heroes/hero_phantom_assassin/phantom_assassin_phantom_strike", LUA_MODIFIER_MOTION_NONE )

function modifier_phantom_assassin_phantom_strike_lanceuse:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ABILITY_FULLY_CAST }
end

function modifier_phantom_assassin_phantom_strike_lanceuse:OnAbilityFullyCast( params )
	if params.unit == self:GetParent() and params.ability == self:GetAbility()._stiflingDagger then
		params.ability:EndCooldown()
		self:Destroy()
	end
end

modifier_phantom_assassin_phantom_strike_buff = class({})
LinkLuaModifier( "modifier_phantom_assassin_phantom_strike_buff", "heroes/hero_phantom_assassin/phantom_assassin_phantom_strike", LUA_MODIFIER_MOTION_NONE )
function modifier_phantom_assassin_phantom_strike_buff:OnCreated()
	self:OnRefresh()
end

function modifier_phantom_assassin_phantom_strike_buff:OnRefresh()
	self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	self.counter_damage = self:GetSpecialValueFor("counter_damage")
end

function modifier_phantom_assassin_phantom_strike_buff:DeclareFunctions()
	return { MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_EVENT_ON_ATTACK_FAIL }
end

function modifier_phantom_assassin_phantom_strike_buff:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

function modifier_phantom_assassin_phantom_strike_buff:OnAttackFail( params )
	if self.counter_damage <= 0 then return end
	if params.target ~= self:GetParent() then return end
	if params.attacker == self:GetParent() then return end
	if params.target:GetPaddedCollisionRadius() + params.attacker:GetPaddedCollisionRadius() + params.target:GetAttackRange() + 50 < CalculateDistance( params.target, params.attacker ) then return end
	params.target:StartGestureWithPlaybackRate( ACT_DOTA_ATTACK, 6 )
	params.target:PerformGenericAttack(params.attacker, true, {bonusDamage = self.counter_damage, neverMiss = false} )
end