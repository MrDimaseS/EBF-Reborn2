item_silver_edge = class({})

function item_silver_edge:GetIntrinsicModifierName()
	return "modifier_item_silver_edge_passive"
end

function item_silver_edge:OnSpellStart()
	local caster = self:GetCaster()
	
	caster:AddNewModifier( caster, self, "modifier_item_silver_edge_bash_walk", {duration = self:GetSpecialValueFor("windwalk_fade_time")+0.1} )
	caster:AddNewModifier( caster, self, "modifier_item_silver_edge_bash_walk", {duration = self:GetSpecialValueFor("windwalk_fade_time")+0.1} )
	EmitSoundOn( "DOTA_Item.InvisibilitySword.Activate", caster )
end

item_silver_edge_2 = class(item_silver_edge)
item_silver_edge_3 = class(item_silver_edge)
item_silver_edge_4 = class(item_silver_edge)
item_silver_edge_5 = class(item_silver_edge)

modifier_item_silver_edge_bash_walk = class({})
LinkLuaModifier( "modifier_item_silver_edge_bash_walk", "items/item_silver_edge.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_silver_edge_bash_walk:OnCreated()
	self:OnRefresh()
	
	self:StartIntervalThink( self.windwalk_fade_time )
end

function modifier_item_silver_edge_bash_walk:OnRefresh()
	self.windwalk_movement_speed = self:GetSpecialValueFor("windwalk_movement_speed")
	self.windwalk_bonus_damage = self:GetSpecialValueFor("windwalk_bonus_damage")
	self.windwalk_duration = self:GetSpecialValueFor("windwalk_duration")
	self.windwalk_fade_time = self:GetSpecialValueFor("windwalk_fade_time")
	
	self.invisible = false
	
	self:StartIntervalThink( self.windwalk_fade_time )
end

function modifier_item_silver_edge_bash_walk:OnIntervalThink()
	self.invisible = true
	self:SetDuration( self.windwalk_duration, true )
	self:StartIntervalThink( -1 )
end

function modifier_item_silver_edge_bash_walk:CheckState()
	if self.invisible then
		return {[MODIFIER_STATE_INVISIBLE] = true}
	end
end

function modifier_item_silver_edge_bash_walk:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_EVENT_ON_ATTACK,
			MODIFIER_EVENT_ON_ABILITY_EXECUTED,
			MODIFIER_PROPERTY_INVISIBILITY_LEVEL 
			}
end

function modifier_item_silver_edge_bash_walk:GetModifierPreAttack_BonusDamage()
	return self.windwalk_bonus_damage
end

function modifier_item_silver_edge_bash_walk:GetModifierMoveSpeedBonus_Percentage()
	return self.windwalk_movement_speed
end

function modifier_item_silver_edge_bash_walk:OnAbilityExecuted( params )
	if params.unit == self:GetParent() then
		self:Destroy()
	end
end

function modifier_item_silver_edge_bash_walk:OnAttack( params )
	if params.attacker == self:GetParent() then
		local ability = self:GetAbility()
		ability.primedForBash = ability.primedForBash or {}
		ability.primedForBash[params.record] = true
		self:Destroy()
	end
end

function modifier_item_silver_edge_bash_walk:GetModifierInvisibilityLevel()
	return 1.00
end

modifier_item_silver_edge_backstab = class({})
LinkLuaModifier( "modifier_item_silver_edge_backstab", "items/item_silver_edge.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_silver_edge_backstab:OnCreated()
	self:OnRefresh()
end

function modifier_item_silver_edge_backstab:OnRefresh()
	self.backstab_slow = self:GetSpecialValueFor("backstab_slow")
end

function modifier_item_silver_edge_backstab:CheckState()
	return {[MODIFIER_STATE_PASSIVES_DISABLED] = true}
end

function modifier_item_silver_edge_backstab:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_item_silver_edge_backstab:GetModifierMoveSpeedBonus_Percentage()
	return self.backstab_slow
end

function modifier_item_silver_edge_backstab:GetEffectName()
	return "particles/items3_fx/silver_edge.vpcf"
end

modifier_item_generic_bash_cd = class({})
LinkLuaModifier( "modifier_item_generic_bash_cd", "items/item_silver_edge.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_generic_bash_cd:IsDebuff()
	return true
end

function modifier_item_generic_bash_cd:IsPurgable()
	return false
end

modifier_item_silver_edge_passive = class({})
LinkLuaModifier( "modifier_item_silver_edge_passive", "items/item_silver_edge.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_silver_edge_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_silver_edge_passive:OnRefresh()
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	self.bonus_strength = self:GetSpecialValueFor("bonus_strength")
	
	self.bash_chance_melee = self:GetSpecialValueFor("bash_chance_melee")
	self.bash_chance_ranged = self:GetSpecialValueFor("bash_chance_ranged")
	self.bash_duration = self:GetSpecialValueFor("bash_duration")
	self.bash_cooldown = self:GetSpecialValueFor("bash_cooldown")
	self.bash_cooldown_ranged = self:GetSpecialValueFor("bash_cooldown_ranged")
	self.bonus_chance_damage = self:GetSpecialValueFor("bonus_chance_damage")
	
	self.backstab_duration = self:GetSpecialValueFor("backstab_duration")
	
	if IsServer() then
		self:GetAbility().primedForBash = {}
	end
end

function modifier_item_silver_edge_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_EVENT_ON_ATTACK_LANDED,
			}
end

function modifier_item_silver_edge_passive:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

function modifier_item_silver_edge_passive:GetModifierBonusStats_Strength()
	return self.bonus_strength
end

function modifier_item_silver_edge_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_silver_edge_passive:OnAttackLanded( params )
	if params.attacker == self:GetParent() and not params.attacker:IsIllusion() then
		local ability = self:GetAbility()
		if ability.primedForBash[params.record] 
		or ( RollPseudoRandomPercentage( TernaryOperator( self.bash_chance_ranged, params.attacker:IsRangedAttacker(), self.bash_chance_melee ), ability:entindex(), params.attacker )
		and not params.attacker:HasModifier("modifier_item_generic_bash_cd") ) then
			ability:DealDamage( params.attacker, params.target, self.bonus_chance_damage, {damage_type = DAMAGE_TYPE_PHYSICAL} )
			ability:Stun( params.target, self.bash_duration )
			
			if ability.primedForBash[params.record] then
				params.target:AddNewModifier( params.attacker, ability, "modifier_item_silver_edge_backstab", {duration = self.bash_cooldown} )
				ability.primedForBash[params.record] = nil
				
				EmitSoundOn( "DOTA_Item.SilverEdge.Target", params.target )
			end
			local bash_cooldown = TernaryOperator( self.bash_cooldown_ranged, caster:IsRangedAttacker(), self.bash_cooldown )
			params.attacker:AddNewModifier( params.attacker, ability, "modifier_item_generic_bash_cd", {duration = bash_cooldown} )
			EmitSoundOn( "DOTA_Item.SkullBasher", params.target )
		end
	end
end

function modifier_item_silver_edge_passive:IsHidden()
	return true
end

function modifier_item_silver_edge_passive:IsPurgable()
	return false
end

function modifier_item_silver_edge_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end