item_abyssal_blade = class({})
LinkLuaModifier( "modifier_item_generic_bash_cd", "items/item_silver_edge.lua", LUA_MODIFIER_MOTION_NONE )

function item_abyssal_blade:GetIntrinsicModifierName()
	return "modifier_item_abyssal_blade_passive"
end

function item_abyssal_blade:OnSpellStart(  )
	local target = self:GetCursorTarget()
	
	EmitSoundOn( "DOTA_Item.AbyssalBlade.Activate", self:GetCaster() )
	if target:TriggerSpellAbsorb( self ) then return end
	
	self.activatedBash = true
	self:Bash( self:GetCursorTarget() )
	
end

function item_abyssal_blade:Bash( target )
	local caster = self:GetCaster()
	
	local bash_duration = self:GetSpecialValueFor("bash_duration")
	local bash_cooldown = self:GetSpecialValueFor("bash_cooldown")
	local bash_radius = self:GetSpecialValueFor("bash_radius")
	local bonus_chance_damage = self:GetSpecialValueFor("bonus_chance_damage")
	local bonus_str_damage = self:GetSpecialValueFor("bonus_str_damage") / 100
	
	if self.activatedBash then
		local active_multiplier = self:GetSpecialValueFor("active_multiplier") / 100
		
		bash_duration = bash_duration * (1+active_multiplier)
		bash_radius = bash_radius * (1+active_multiplier)
		bonus_chance_damage = bonus_chance_damage * (1+active_multiplier)
		bonus_str_damage = bonus_str_damage * (1+active_multiplier)
		self.activatedBash =  false
	end
	
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), bash_radius ) ) do
		self:DealDamage( caster, enemy, bonus_chance_damage + caster:GetStrength() * bonus_str_damage, {damage_type = DAMAGE_TYPE_PHYSICAL} )
		self:Stun( enemy, bash_duration )
	end
	ParticleManager:FireParticle( "particles/items5_fx/abyssal_blade_aoe_bash.vpcf", PATTACH_WORLDORIGIN, nil, {[0] = target:GetAbsOrigin(), [1] = Vector(bash_radius,bash_radius,bash_radius)} )
	caster:AddNewModifier( caster, self, "modifier_item_generic_bash_cd", {duration = bash_cooldown} )
	EmitSoundOn( "DOTA_Item.SkullBasher", target )
end

item_abyssal_blade_2 = class(item_abyssal_blade)
item_abyssal_blade_3 = class(item_abyssal_blade)
item_abyssal_blade_4 = class(item_abyssal_blade)
item_abyssal_blade_5 = class(item_abyssal_blade)

modifier_item_abyssal_blade_passive = class({})
LinkLuaModifier( "modifier_item_abyssal_blade_passive", "items/item_abyssal_blade.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_abyssal_blade_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_abyssal_blade_passive:OnRefresh()
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.bonus_health = self:GetSpecialValueFor("bonus_health")
	self.bonus_health_regen = self:GetSpecialValueFor("bonus_health_regen")
	self.bonus_strength = self:GetSpecialValueFor("bonus_strength")
	
	self.bash_chance_melee = self:GetSpecialValueFor("bash_chance_melee")
	self.bash_chance_ranged = self:GetSpecialValueFor("bash_chance_ranged")
	
	self.block_damage_pct = self:GetSpecialValueFor("block_damage_pct") / 100
	self.block_chance = self:GetSpecialValueFor("block_chance")
	
	if IsServer() then
		self:GetAbility().primedForBash = {}
	end
end

function modifier_item_abyssal_blade_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
			MODIFIER_PROPERTY_HEALTH_BONUS,
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_TOTAL_CONSTANT_BLOCK_UNAVOIDABLE_PRE_ARMOR,
			MODIFIER_EVENT_ON_ATTACK_LANDED,
			}
end

function modifier_item_abyssal_blade_passive:GetModifierBonusStats_Strength()
	return self.bonus_strength
end

function modifier_item_abyssal_blade_passive:GetModifierConstantHealthRegen()
	return self.bonus_health_regen
end

function modifier_item_abyssal_blade_passive:GetModifierHealthBonus()
	return self.bonus_health
end

function modifier_item_abyssal_blade_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_abyssal_blade_passive:GetModifierPhysical_ConstantBlockUnavoidablePreArmor( params )
	if params.damage_category ~= DOTA_DAMAGE_CATEGORY_ATTACK or params.damage <= 0 then return end
	local roll = RollPseudoRandomPercentage( self.block_chance, self:GetAbility():entindex()+1, params.attacker )
	if roll then
		local block = self:GetParent():GetStrength() * self.block_damage_pct
		SendOverheadEventMessage( nil, OVERHEAD_ALERT_BLOCK, self:GetParent(), block, nil)
		return block
	end
end

function modifier_item_abyssal_blade_passive:OnAttackLanded( params )
	if params.attacker == self:GetParent() and not params.attacker:IsIllusion() then
		local ability = self:GetAbility()
		if ability.primedForBash[params.record] 
		or ( RollPseudoRandomPercentage( TernaryOperator( self.bash_chance_ranged, params.attacker:IsRangedAttacker(), self.bash_chance_melee ), ability:entindex(), params.attacker )
		and not params.attacker:HasModifier("modifier_item_generic_bash_cd") ) then
			ability:Bash( params.target )
		end
	end
end

function modifier_item_abyssal_blade_passive:IsHidden()
	return true
end

function modifier_item_abyssal_blade_passive:IsPurgable()
	return false
end

function modifier_item_abyssal_blade_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end