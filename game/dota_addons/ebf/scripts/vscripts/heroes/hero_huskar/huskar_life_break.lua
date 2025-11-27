huskar_life_break = class({})

function huskar_life_break:IsStealable()
	return true
end

function huskar_life_break:IsHiddenWhenStolen()
	return false
end

function huskar_life_break:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	caster:AddNewModifier(caster, self, "modifier_huskar_life_break_movement", {duration = 2})
	EmitSoundOn("Hero_Huskar.Life_Break", caster)
end

function huskar_life_break:SunderLife( target )
	local caster = self:GetCaster()
	if target:TriggerSpellAbsorb( self ) then return end
	
	local cost = self:GetSpecialValueFor("tooltip_health_cost_percent") / 100
	local damage = self:GetSpecialValueFor("tooltip_health_damage") / 100
	local burnTransfer = self:GetSpecialValueFor("burn_transfer") / 100
	local duration = self:GetSpecialValueFor("slow_durtion_tooltip")
	
	self:DealDamage( caster, caster, caster:GetHealth() * cost, {damage_type = DAMAGE_TYPE_MAGICAL, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION})
	self:DealDamage( caster, target, target:GetHealth() * damage * target:GetMaxHealthDamageResistance(), {damage_type = DAMAGE_TYPE_MAGICAL, DAMAGE_TYPE_MAGICAL, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION})
	
	target:AddNewModifier( caster, self, "modifier_huskar_life_break_debuff", {duration = duration} )
	target:AddBurn( caster, caster:GetBurn() * burnTransfer )
end

modifier_huskar_life_break_movement = class({})
LinkLuaModifier("modifier_huskar_life_break_movement", "heroes/hero_huskar/huskar_life_break", LUA_MODIFIER_MOTION_NONE)

if IsServer() then
	function modifier_huskar_life_break_movement:OnCreated()
		local parent = self:GetParent()
		
		self.burn_immunity = self:GetSpecialValueFor("burn_immunity") == 1
		if self.burn_immunity then
			self.burnToMaintain = parent:GetBurn()
		end
		self.speed = self:GetSpecialValueFor("charge_speed") * FrameTime()
		self.target = self:GetAbility():GetCursorTarget()
		self:StartMotionController()
		print("?")
	end
	
	function modifier_huskar_life_break_movement:OnDestroy()
		local parent = self:GetParent()
		local parentPos = parent:GetAbsOrigin()
		FindClearSpaceForUnit(parent, parentPos, true)
		self:StopMotionController()
	end
	
	function modifier_huskar_life_break_movement:DoControlledMotion()
		local parent = self:GetParent()
		if parent:IsAlive() then
			if self.burnToMaintain and parent:GetBurn() < self.burnToMaintain then
				parent:AddBurn( parent, self.burnToMaintain - parent:GetBurn() )
			end
			local direction = CalculateDirection( self.target, parent )
			local newPos = GetGroundPosition(parent:GetAbsOrigin() + direction * self.speed, parent) 
			parent:SetAbsOrigin( newPos )
			if CalculateDistance( self.target, parent ) <= (self.target:GetPaddedCollisionRadius() + parent:GetPaddedCollisionRadius() + 24) then
				self:GetAbility():SunderLife( self.target )
				self:Destroy()
				return nil
			end       
		end
	end
end

function modifier_huskar_life_break_movement:GetEffectName()
	return "particles/units/heroes/hero_huskar/huskar_life_break.vpcf"
end

function modifier_huskar_life_break_movement:CheckState()
	return {[MODIFIER_STATE_DISARMED] = true,
			[MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			[MODIFIER_STATE_MAGIC_IMMUNE] = true}
end

function modifier_huskar_life_break_movement:DeclareFunctions()
	return { MODIFIER_PROPERTY_OVERRIDE_ANIMATION,
			 MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS,
			 MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

function modifier_huskar_life_break_movement:GetOverrideAnimation()
	return ACT_DOTA_CAST_LIFE_BREAK_START
end

function modifier_huskar_life_break_movement:GetModifierMagicalResistanceBonus()
	return 60
end

function modifier_huskar_life_break_movement:GetModifierIncomingDamage_Percentage( params )
	if not self.burn_immunity then return end
	if params.inflictor and params.inflictor._isBurnDamage then
		return -100
	end
end

modifier_huskar_life_break_debuff = class({})
LinkLuaModifier("modifier_huskar_life_break_debuff", "heroes/hero_huskar/huskar_life_break", LUA_MODIFIER_MOTION_NONE)

function modifier_huskar_life_break_debuff:OnCreated()
	self:OnRefresh()
end

function modifier_huskar_life_break_debuff:OnRefresh()
	self.movespeed = -self:GetSpecialValueFor("movespeed")
	self.attack_speed = -self:GetSpecialValueFor("attack_speed")
	
	self.deathburst_radius = self:GetSpecialValueFor("deathburst_radius")
	self.deathburst_spread = self:GetSpecialValueFor("deathburst_spread")
	
	self.slow_taunts = self:GetSpecialValueFor("slow_taunts") == 1
	
	if IsClient() then return end
	local parent = self:GetParent()
	local caster = self:GetCaster()
	if self.slow_taunts then
		if parent:IsNeutralUnitType() then
			parent:SetForceAttackTarget( caster )
		else
			parent:MoveToTargetToAttack( caster )
			parent:SetAttacking( caster )
			
			ExecuteOrderFromTable({
				UnitIndex = caster:entindex(),
				OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
				TargetIndex = parent:entindex()
			})
		end
	end
end

function modifier_huskar_life_break_debuff:OnDestroy()
	if IsClient() then return end
	local parent = self:GetParent()
	if parent:IsAlive() then return end
	local caster = self:GetCaster()
	ParticleManager:FireParticle("particles/fire_ball_explosion.vpcf", PATTACH_POINT_FOLLOW, parent )
	if self.deathburst_radius > 0 and parent:GetBurn() > 0 then
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( parent:GetAbsOrigin(), self.deathburst_radius ) ) do
			if enemy:IsAlive() then
				enemy:AddBurn( caster, parent:GetBurn() )
			end
		end
	end
	if self.slow_taunts then
		if parent:IsNeutralUnitType() then
			parent:SetForceAttackTarget( nil )
		end
	end
end

function modifier_huskar_life_break_debuff:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

function modifier_huskar_life_break_debuff:CheckState()
	if slow_taunts then
		return {[MODIFIER_STATE_TAUNTED] = true}
	end
end

function modifier_huskar_life_break_debuff:GetTauntTarget()
	if self.slow_taunts then
		return self:GetCaster()
	end
end

function modifier_huskar_life_break_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.movespeed
end

function modifier_huskar_life_break_debuff:GetModifierAttackSpeedBonus_Constant()
	return self.attack_speed
end

function modifier_huskar_life_break_debuff:GetStatusEffectName()
	return "particles/status_fx/status_effect_huskar_lifebreak.vpcf"
end

function modifier_huskar_life_break_debuff:StatusEffectPriority()
	return 3
end