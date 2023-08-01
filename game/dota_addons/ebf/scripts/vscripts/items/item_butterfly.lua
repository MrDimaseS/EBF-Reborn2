item_butterfly = class({})

function item_butterfly:GetIntrinsicModifierName()
	return "modifier_item_butterfly_passive"
end

function item_butterfly:OnSpellStart()
	local caster = self:GetCaster()
	
	local stacks = self:GetSpecialValueFor("max_stacks")
	local duration = self:GetSpecialValueFor("duration")
	caster:AddNewModifier( caster, self, "modifier_item_butterfly_untouchable", {duration = duration} )
	if stacks > 0 then
		caster:AddNewModifier( caster, self, "modifier_item_butterfly_zephyr", {duration = duration} ):SetStackCount( stacks )
	end
	
	ParticleManager:FireParticle("particles/items2_fx/butterfly_active.vpcf", PATTACH_POINT_FOLLOW, caster )
	EmitSoundOn( "DOTA_Item.Butterfly", caster )
end

item_butterfly2 = class(item_butterfly)
item_butterfly3 = class(item_butterfly)
item_butterfly4 = class(item_butterfly)
item_butterfly5 = class(item_butterfly)
item_asura_rapier = class(item_butterfly)

modifier_item_butterfly_untouchable = class({})
LinkLuaModifier( "modifier_item_butterfly_untouchable", "items/item_butterfly.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_butterfly_untouchable:OnCreated()
	self.magic_immune = self:GetSpecialValueFor("magic_immune") > 0
	if self.magic_immune then
		self.magic_resistance = self:GetSpecialValueFor("bonus_evasion") * self:GetSpecialValueFor("evasion_multiplier")
		if IsServer() then
			local bkbFX = ParticleManager:CreateParticle("particles/items_fx/black_king_bar_avatar.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
			self:AddEffect( bkbFX )
			
			EmitSoundOn( "DOTA_Item.BlackKingBar.Activate", self:GetParent() )
		end
	end
end

function modifier_item_butterfly_untouchable:DeclareFunctions()
	return {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS}
end

function modifier_item_butterfly_untouchable:CheckState()
	if self.magic_immune then
		return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
	end
end

function modifier_item_butterfly_untouchable:GetModifierMagicalResistanceBonus()
	return self.magic_resistance
end

function modifier_item_butterfly_untouchable:GetEffectName()
	return "particles/items2_fx/butterfly_buff.vpcf"
end

modifier_item_butterfly_zephyr = class({})
LinkLuaModifier( "modifier_item_butterfly_zephyr", "items/item_butterfly.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_butterfly_zephyr:OnCreated()
	self:OnRefresh()
end

function modifier_item_butterfly_zephyr:OnRefresh()
	self.as_bonus_stack = self:GetSpecialValueFor("as_bonus_stack")
	self.ms_bonus_stack = self:GetSpecialValueFor("ms_bonus_stack")
	self.ls_bonus_stack = self:GetSpecialValueFor("ls_bonus_stack")
	self.max_agi_bonus = self:GetSpecialValueFor("max_agi_bonus")
	self.max_stacks = self:GetSpecialValueFor("max_stacks")
	if IsServer() and self:GetStackCount() < self.max_stacks then
		self:IncrementStackCount()
	end
end

function modifier_item_butterfly_zephyr:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_TOOLTIP}
end

function modifier_item_butterfly_zephyr:GetModifierMoveSpeedBonus_Percentage()
	return self:GetStackCount() * self.ms_bonus_stack
end

function modifier_item_butterfly_zephyr:GetModifierAttackSpeedBonus_Constant()
	return self:GetStackCount() * self.as_bonus_stack
end

function modifier_item_butterfly_zephyr:OnTooltip()
	return self:GetStackCount() * self.ls_bonus_stack
end

function modifier_item_butterfly_zephyr:GetModifierBonusStats_Agility()
	if self:GetParent().checkingForAgilityMultipliers then return end
	self:GetParent().checkingForAgilityMultipliers = true
	local totalAgility = self:GetParent():GetAgility()
	self:GetParent().checkingForAgilityMultipliers = false
	if self:GetStackCount() == self.max_stacks then
		return totalAgility * self.max_agi_bonus / 100
	end
end

modifier_item_butterfly_passive = class({})
LinkLuaModifier( "modifier_item_butterfly_passive", "items/item_butterfly.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_butterfly_passive:OnCreated()
	self.bonus_agility = self:GetSpecialValueFor("bonus_agility")
	self.bonus_strength = self:GetSpecialValueFor("bonus_strength")
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.bonus_evasion = self:GetSpecialValueFor("bonus_evasion")
	self.evasion_multiplier = self:GetSpecialValueFor("evasion_multiplier")
	self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	self.bonus_movespeed = self:GetSpecialValueFor("bonus_movespeed")
	self.lifesteal_percent = self:GetSpecialValueFor("lifesteal_percent")
	self.ls_bonus_stack = self:GetSpecialValueFor("ls_bonus_stack")
	
	self.bonus_agility_pr = self:GetSpecialValueFor("bonus_agility_pr")
	self.bonus_damage_pr = self:GetSpecialValueFor("bonus_damage_pr")
	
	self.stack_duration = self:GetSpecialValueFor("stack_duration")
	self.max_stacks = self:GetSpecialValueFor("max_stacks")
	
	if self.bonus_agility_pr > 0 and IsServer() then
		self:StartIntervalThink(0.25)
	end
end

function modifier_item_butterfly_passive:OnIntervalThink()
	local stack = GameRules._roundnumber
	if stack ~= self:GetStackCount() then
		self:SetStackCount( stack )
	end
end

function modifier_item_butterfly_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_PROPERTY_EVASION_CONSTANT,
			MODIFIER_EVENT_ON_TAKEDAMAGE,
			MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_item_butterfly_passive:GetModifierBonusStats_Agility()
	return self.bonus_agility + self:GetStackCount() * self.bonus_agility_pr
end

function modifier_item_butterfly_passive:GetModifierBonusStats_Strength()
	return self.bonus_strength
end

function modifier_item_butterfly_passive:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

function modifier_item_butterfly_passive:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_movespeed
end

function modifier_item_butterfly_passive:GetModifierEvasion_Constant()
	return TernaryOperator( self.bonus_evasion * self.evasion_multiplier, self:GetParent():HasModifier("modifier_item_butterfly_untouchable"), self.bonus_evasion )
end

function modifier_item_butterfly_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage + self:GetStackCount() * self.bonus_damage_pr
end

function modifier_item_butterfly_passive:OnTakeDamage(params)
	if self.lifesteal_percent > 0 and params.attacker == self:GetParent() and params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
		local EHPMult = self:GetParent().EHP_MULT or 1
		local lifesteal = self.lifesteal_percent 
		local stacks = params.attacker:FindModifierByNameAndAbility( "modifier_item_butterfly_zephyr", self:GetAbility() )
		if stacks then
			lifesteal = lifesteal + self.ls_bonus_stack * stacks:GetStackCount()
		end
		
		lifesteal = params.damage * lifesteal / 100 * math.max( 1, EHPMult )
		
		local preHP = params.attacker:GetHealth()
		params.attacker:HealWithParams( lifesteal, self:GetAbility(), true, true, self:GetCaster(), false )
		local postHP = params.attacker:GetHealth()
		
		if (postHP - preHP) > 0 then
			SendOverheadEventMessage( params.attacker:GetPlayerOwner(), OVERHEAD_ALERT_HEAL, params.attacker, postHP - preHP, params.attacker:GetPlayerOwner() )
			
			ParticleManager:FireParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_POINT_FOLLOW, params.attacker )
		end
	end
end
function modifier_item_butterfly_passive:OnAttackLanded( params )
	if params.attacker == self:GetParent() and not params.attacker:IsIllusion() and self.max_stacks > 0 and not params.no_attack_cooldown then
		if params.target == self.lastUnitAttacked then
			params.attacker:AddNewModifier( params.attacker, self:GetAbility(), "modifier_item_butterfly_zephyr", {duration = self.stack_duration} )
		elseif not params.attacker:HasModifier("modifier_item_butterfly_untouchable") then
			params.attacker:RemoveModifierByName("modifier_item_butterfly_zephyr")
		end
		self.lastUnitAttacked = params.target
	end
end

function modifier_item_butterfly_passive:IsHidden()
	return true
end

function modifier_item_butterfly_passive:IsPurgable()
	return false
end

function modifier_item_butterfly_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end