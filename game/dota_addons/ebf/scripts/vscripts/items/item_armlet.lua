item_armlet = class({})

function item_armlet:GetIntrinsicModifierName()
	return "modifier_item_armlet_passive_ebf"
end

function item_armlet:GetAbilityTextureName()
	if self:GetToggleState() then
		return self.BaseClass.GetAbilityTextureName( self ) .. '_active'
	else
		return self.BaseClass.GetAbilityTextureName( self )
	end
end

function item_armlet:OnToggle()
	local caster = self:GetCaster()
	
	local active = caster:FindModifierByName("modifier_item_armlet_active")
	local berserk = caster:FindModifierByName("modifier_item_armlet_berserk")
	if not self:GetToggleState() then
		if caster:HasModifier("modifier_item_armlet_berserk") then
			if active then
				active:SetDuration( berserk:GetRemainingTime(), true )
			end
		else
			caster:RemoveModifierByName("modifier_item_armlet_active")
		end
		EmitSoundOn("DOTA_Item.Armlet.DeActivate", caster )
	else
		if active then
			active:SetDuration( -1, true )
		else
			caster:AddNewModifier( caster, self, "modifier_item_armlet_active", {} )
		end
		caster:RemoveModifierByName("modifier_item_armlet_berserk")
		if self:GetSpecialValueFor("berserk_duration") > 0 then
			caster:AddNewModifier( caster, self, "modifier_item_armlet_berserk", {duration = self:GetSpecialValueFor("berserk_duration")} )
		end
		EmitSoundOn("DOTA_Item.Armlet.Activate", self:GetCaster() )
	end
end

item_armlet_2 = class(item_armlet)
item_armlet_3 = class(item_armlet)
item_armlet_4 = class(item_armlet)
item_armlet_5 = class(item_armlet)

modifier_item_armlet_berserk = class({})
LinkLuaModifier( "modifier_item_armlet_berserk", "items/item_armlet.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_armlet_berserk:OnCreated()
	if IsServer() then
		EmitSoundOn( "DOTA_Item.MaskOfMadness.Activate", self:GetParent() )
	end
end

function modifier_item_armlet_berserk:IsDebuff()
	return true
end

function modifier_item_armlet_berserk:IsPurgable()
	return false
end

modifier_item_armlet_active = class({})
LinkLuaModifier( "modifier_item_armlet_active", "items/item_armlet.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_armlet_active:OnCreated()
	self.unholy_bonus_damage = self:GetSpecialValueFor("bonus_damage") * self:GetSpecialValueFor("unholy_bonus_damage") / 100
	self.unholy_bonus_armor = self:GetSpecialValueFor("unholy_bonus_armor")
	self.berserk_bonus_attack_speed = self:GetSpecialValueFor("berserk_bonus_attack_speed")
	self.berserk_bonus_movement_speed = self:GetSpecialValueFor("berserk_bonus_movement_speed")
	self.unholy_bonus_slow_resistance = self:GetSpecialValueFor("unholy_bonus_slow_resistance")
	
	self.unholy_bonus_strength = self:GetSpecialValueFor("unholy_bonus_strength")
	self.unholy_bonus_strength_pct = self:GetCaster():GetStrength() * self:GetSpecialValueFor("unholy_bonus_strength_pct") / 100
	self.total_strength = self.unholy_bonus_strength + self.unholy_bonus_strength_pct
	self.current_strength = 0
	
	self.str_ramp_up = self:GetSpecialValueFor("str_ramp_up")
	self.tick_rate = 0.1
	self.ticks = self.str_ramp_up / self.tick_rate
	self.str_per_tick = self.total_strength / self.ticks
	
	self.unholy_health_drain_per_second = self:GetSpecialValueFor("unholy_health_drain_per_second")
	
	if IsServer() then
		self:StartIntervalThink( self.tick_rate )
		
		local armletFX = ParticleManager:CreateParticle( "particles/items_fx/armlet.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
		self:AddEffect( armletFX )
		local momFX = ParticleManager:CreateParticle( "particles/items2_fx/mask_of_madness.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
		self:AddEffect( momFX )
	end
end

function modifier_item_armlet_active:OnIntervalThink()
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	
	if self:GetDuration() < 0 then
		if not IsEntitySafe( caster ) then self:Destroy() return end
		if not IsEntitySafe( ability ) 
		or (not ability:GetToggleState() or ability:GetItemSlot() > 5 or ability:GetItemSlot() == -1) then
			local berserk = caster:FindModifierByName("modifier_item_armlet_berserk")
			if berserk then
				self:SetDuration( berserk:GetRemainingTime(), true )
			else
				self:Destroy()
				return
			end
		end
	end
	if self.ticks > 0 then
		self.current_strength = math.min( self.total_strength, self.current_strength + self.str_per_tick )
		self:GetCaster():CalculateStatBonus( true )
		self:GetCaster():HealEvent( self.str_per_tick * 22, ability, self:GetCaster() )
		
		self.ticks = self.ticks - 1
	end
	if not IsEntitySafe( ability ) then
		ability = caster:GetAbilityByIndex(0)
	end
	if not IsEntitySafe( ability ) then return end 
	ability:DealDamage( caster, caster, self.current_strength * self.unholy_health_drain_per_second * self.tick_rate, {damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY + DOTA_DAMAGE_FLAG_BYPASSES_BLOCK + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL} )
	
	
end

function modifier_item_armlet_active:OnDestroy()
	if not IsServer() then return end
	local ability = self:GetAbility()
	local caster = self:GetCaster()
	if not IsEntitySafe( caster ) then return end
	if not IsEntitySafe( ability ) then 
		ability = caster:GetAbilityByIndex(0)
	elseif ability and ability:GetToggleState() then 
		ability:ToggleAbility()
	end
	if not IsEntitySafe( ability ) then return end
	ability:DealDamage( caster, caster, self.current_strength * 22, {damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_BYPASSES_INVULNERABILITY + DOTA_DAMAGE_FLAG_BYPASSES_BLOCK + DOTA_DAMAGE_FLAG_NON_LETHAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL} )
end

function modifier_item_armlet_active:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_SLOW_RESISTANCE,
			MODIFIER_PROPERTY_EXTRA_STRENGTH_BONUS,
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
			MODIFIER_PROPERTY_HP_REGEN_CAN_BE_NEGATIVE 
			}
end

function modifier_item_armlet_active:CheckState()
	return {[MODIFIER_STATE_SILENCED] = true}
end
	

function modifier_item_armlet_active:GetModifierAttackSpeedBonus_Constant()
	return self.berserk_bonus_attack_speed
end

function modifier_item_armlet_active:GetModifierPreAttack_BonusDamage()
	return self.unholy_bonus_damage
end

function modifier_item_armlet_active:GetModifierPhysicalArmorBonus()
	return self.unholy_bonus_armor
end

function modifier_item_armlet_active:GetModifierMoveSpeedBonus_Constant()
	return self.berserk_bonus_movement_speed
end

function modifier_item_armlet_active:GetModifierSlowResistance()
	return self.unholy_bonus_slow_resistance
end

function modifier_item_armlet_active:GetModifierExtraStrengthBonus()
	return self.current_strength
end

function modifier_item_armlet_active:IsPermanent()
	return true
end

function modifier_item_armlet_active:RemoveOnDeath()
	return false
end

function modifier_item_armlet_active:IsPurgable()
	return false
end

modifier_item_armlet_passive_ebf = class({})
LinkLuaModifier( "modifier_item_armlet_passive_ebf", "items/item_armlet.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_armlet_passive_ebf:OnCreated()
	self:OnRefresh()
end

function modifier_item_armlet_passive_ebf:OnRefresh()
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
	self.bonus_health_regen = self:GetSpecialValueFor("bonus_health_regen")
	self.lifesteal_percent = self:GetSpecialValueFor("lifesteal_percent") / 100
end

function modifier_item_armlet_passive_ebf:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
			MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_item_armlet_passive_ebf:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

function modifier_item_armlet_passive_ebf:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_item_armlet_passive_ebf:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_armlet_passive_ebf:GetModifierConstantHealthRegen()
	return self.bonus_health_regen
end

function modifier_item_armlet_passive_ebf:OnTakeDamage(params)
	if params.attacker ~= self:GetParent() then return end
	if params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
		local EHPMult = self:GetParent().EHP_MULT or 1
		local lifesteal = params.damage * self.lifesteal_percent * math.max( 1, EHPMult )
		
		self.lifeToGive = (self.lifeToGive or 0) + lifesteal
		if self.lifeToGive > 1 then
			local lifeGained = self.lifeToGive
			local preHP = params.attacker:GetHealth()
			params.attacker:HealWithParams( lifeGained, params.inflictor, false, true, self, true )
			self.lifeToGive = self.lifeToGive - math.floor(self.lifeToGive)
			local postHP = params.attacker:GetHealth()
			
			
			local actualLifeGained = postHP - preHP
			if actualLifeGained > 0 then
				ParticleManager:FireParticle( "particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_POINT_FOLLOW, params.attacker )
			end
		end
	end
end
	
function modifier_item_armlet_passive_ebf:IsHidden()
	return true
end

function modifier_item_armlet_passive_ebf:IsPurgable()
	return false
end

function modifier_item_armlet_passive_ebf:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end