item_yasha_and_kaya_2 = class({})

function item_yasha_and_kaya_2:GetIntrinsicModifierName()
	return "modifier_item_yasha_and_kaya_2_passive"
end

function item_yasha_and_kaya_2:OnSpellStart()
	local caster = self:GetCaster()
	
	caster:AddNewModifier( caster, self, "modifier_item_yasha_and_kaya_2_wild_magic", {duration = self:GetSpecialValueFor("berserk_duration")} )
	EmitSoundOn( "DOTA_Item.MaskOfMadness.Activate", caster )
end

item_yasha_and_kaya_3 = class(item_yasha_and_kaya_2)
item_yasha_and_kaya_4 = class(item_yasha_and_kaya_2)
item_yasha_and_kaya_5 = class(item_yasha_and_kaya_2)

modifier_item_yasha_and_kaya_2_wild_magic = class({})
LinkLuaModifier( "modifier_item_yasha_and_kaya_2_wild_magic", "items/item_yasha_and_kaya.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_yasha_and_kaya_2_wild_magic:OnCreated()
	self.berserk_armor_reduction = self:GetSpecialValueFor("berserk_armor_reduction")
	
	self.berserk_bonus_attack_speed = self:GetSpecialValueFor("berserk_bonus_attack_speed")
	self.berserk_bonus_movement_speed = self:GetSpecialValueFor("berserk_bonus_movement_speed")
end

function modifier_item_yasha_and_kaya_2_wild_magic:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

function modifier_item_yasha_and_kaya_2_wild_magic:GetModifierAttackSpeedBonus_Constant()
	return self.berserk_bonus_attack_speed
end

function modifier_item_yasha_and_kaya_2_wild_magic:GetModifierMoveSpeedBonus_Percentage()
	return self.berserk_bonus_movement_speed
end

function modifier_item_yasha_and_kaya_2_wild_magic:GetModifierPhysicalArmorBonus()
	return -self.berserk_armor_reduction
end

function modifier_item_yasha_and_kaya_2_wild_magic:GetEffectName()
	return "particles/items2_fx/mask_of_madness.vpcf"
end

modifier_item_yasha_and_kaya_2_passive = class({})
LinkLuaModifier( "modifier_item_yasha_and_kaya_2_passive", "items/item_yasha_and_kaya.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_yasha_and_kaya_2_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_yasha_and_kaya_2_passive:OnRefresh()
	self.bonus_agility = self:GetSpecialValueFor("bonus_agility")
	self.bonus_intellect = self:GetSpecialValueFor("bonus_intellect")
	
	self.movement_speed_percent_bonus = self:GetSpecialValueFor("movement_speed_percent_bonus")
	self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.spell_amp = self:GetSpecialValueFor("spell_amp")
	self.spell_lifesteal_amp = self:GetSpecialValueFor("spell_lifesteal_amp")
	self.mana_regen_multiplier = self:GetSpecialValueFor("mana_regen_multiplier")
	
	self.lifesteal_percent = self:GetSpecialValueFor("lifesteal_percent")
	self.berserk_mana_steal = self:GetSpecialValueFor("berserk_mana_steal") / 100
	
	self.bonus_cooldown = self:GetSpecialValueFor("bonus_cooldown")
	self.base_attack_range = self:GetSpecialValueFor("base_attack_range")
	self.melee_pct = self:GetSpecialValueFor("melee_pct") / 100
	self.cast_range_bonus = self:GetSpecialValueFor("cast_range_bonus")
	
	self.bonus_mana = self:GetSpecialValueFor("bonus_mana")
	self.bonus_mana_regen = self:GetSpecialValueFor("bonus_mana_regen")
	
	self.buff_duration = self:GetSpecialValueFor("buff_duration")
	
	
	self.chain_chance = self:GetSpecialValueFor("chain_chance")
	self.static_chance = self:GetSpecialValueFor("static_chance")
	
	self.chain_damage = self:GetSpecialValueFor("chain_damage")
	self.chain_strikes = self:GetSpecialValueFor("chain_strikes")
	self.chain_radius = self:GetSpecialValueFor("chain_radius")
	self.chain_delay = self:GetSpecialValueFor("chain_delay")
	self.chain_cooldown = self:GetSpecialValueFor("chain_cooldown")
	self.bounce_penalty = self:GetSpecialValueFor("bounce_penalty")
	
	self.max_stacks = self:GetSpecialValueFor("max_stacks")
	self.total_duration = self:GetSpecialValueFor("buffer_duration") + self:GetSpecialValueFor("loss_timer")
	
	self.records = {}
	self.lastChain = 0
	
	self:GetParent().cooldownModifiers = self:GetParent().cooldownModifiers or {}
	self:GetParent().cooldownModifiers[self] = true
	
	self:GetCaster()._attackLifestealModifiersList = self:GetCaster()._attackLifestealModifiersList or {}
	self:GetCaster()._attackLifestealModifiersList[self] = true
end

function modifier_item_yasha_and_kaya_2_passive:OnDestroy()
	self:GetParent().cooldownModifiers[self] = nil
end


function modifier_item_yasha_and_kaya_2_passive:DeclareFunctions()
	return {
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE_UNIQUE,
			MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_MANA_BONUS,
			MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
			MODIFIER_PROPERTY_CAST_RANGE_BONUS_STACKING,
			MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
			MODIFIER_EVENT_ON_TAKEDAMAGE,
			MODIFIER_EVENT_ON_ATTACK_RECORD,
			MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
			MODIFIER_EVENT_ON_ABILITY_FULLY_CAST 
	}
end

function modifier_item_yasha_and_kaya_2_passive:CheckState()
	if self.bash then
		return {[MODIFIER_STATE_CANNOT_MISS ] = true}
	end
end

function modifier_item_yasha_and_kaya_2_passive:OnAbilityFullyCast(params)
	if params.unit == self:GetParent() and not params.ability:IsItem() then
		params.unit:RemoveModifierByName("modifier_item_yasha_and_kaya_2_archon")
		params.unit:AddNewModifier( params.unit, self:GetAbility(), "modifier_item_yasha_and_kaya_2_archon_as", {duration = self.buff_duration})
	end
end

function modifier_item_yasha_and_kaya_2_passive:OnAttackRecord(params)
	if params.attacker == self:GetParent() and not params.attacker:IsIllusion() and self.chain_chance > 0 and self.lastChain <= GameRules:GetGameTime() then
		local chain_chance = self.chain_chance
		if params.attacker:HasModifier("modifier_item_yasha_and_kaya_2_wild_magic") then
			chain_chance = chain_chance + self.static_chance
		end
		local trigger = RollPercentage( self.chain_chance )
		self.records[params.record] = trigger
		if self.records[params.record] then
			self.bash = true
		end
	end
end

function modifier_item_yasha_and_kaya_2_passive:OnAttackRecordDestroy(params)
	if self.records[params.record] then
		self.records[params.record] = nil
	end
end

function modifier_item_yasha_and_kaya_2_passive:OnTakeDamage(params)
	if params.attacker == self:GetParent() and params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK then
		if not params.attacker:IsIllusion() then
			local modifier = params.attacker:AddNewModifier( params.attacker, self:GetAbility(), "modifier_item_yasha_and_kaya_2_archon", {duration = self.total_duration} )
			modifier:SetStackCount( math.min( modifier:GetStackCount() + 1, self.max_stacks ) )
			modifier:ForceRefresh()
		end
		local itemIsActive = params.attacker:HasModifier("modifier_item_yasha_and_kaya_2_wild_magic")
		if self.chain_chance > 0 then
			if params.unit:IsAlive() and self.records[params.record] then
				local caster = params.attacker
				local ability = self:GetAbility()
				local target = params.unit
				
				local strikes = self.chain_strikes
				local lastTarget = params.attacker
				local currentTarget = params.unit
				local strike_cost = 1
				
				self.lastChain = GameRules:GetGameTime() + self.chain_cooldown
				EmitSoundOn( "Item.Maelstrom.Chain_Lightning", caster )
				
				local targets = {[currentTarget] = true}
				Timers:CreateTimer( function()
					
					ParticleManager:FireRopeParticle("particles/items_fx/chain_lightning.vpcf", PATTACH_POINT_FOLLOW, lastTarget, currentTarget, {})
					EmitSoundOn( "Item.Maelstrom.Chain_Lightning.Jump", currentTarget )
					if not currentTarget:IsSameTeam( caster ) then 
						ability:DealDamage( caster, currentTarget, self.chain_damage )
					end
					
					lastTarget = currentTarget
					currentTarget = nil
					for _, unit in ipairs( caster:FindEnemyUnitsInRadius( lastTarget:GetAbsOrigin(), self.chain_radius ) ) do
						if not targets[unit] then
							currentTarget = unit
							targets[unit] = true
							break
						end
					end
					
					if not currentTarget and itemIsActive then -- reset chain
						for _, unit in ipairs( caster:FindAllUnitsInRadius( lastTarget:GetAbsOrigin(), self.chain_radius ) ) do
							if unit ~= lastTarget then
								currentTarget = unit
								targets = {}
								strike_cost = strike_cost + self.bounce_penalty 
								break
							end
						end
					end
					
					if strikes > 0 and currentTarget then
						strikes = strikes - strike_cost
						return self.chain_delay
					end
				end)
			end
			self.bash = false
		end
	end
end

function modifier_item_yasha_and_kaya_2_passive:GetModifierProperty_PhysicalLifesteal(params)
	return self.lifesteal_percent
end

function modifier_item_yasha_and_kaya_2_passive:GetModifierBonusStats_Intellect()
	return self.bonus_intellect
end

function modifier_item_yasha_and_kaya_2_passive:GetModifierBonusStats_Agility()
	return self.bonus_agility
end

function modifier_item_yasha_and_kaya_2_passive:GetModifierMoveSpeedBonus_Percentage_Unique()
	return self.movement_speed_percent_bonus
end

function modifier_item_yasha_and_kaya_2_passive:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

function modifier_item_yasha_and_kaya_2_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_yasha_and_kaya_2_passive:GetModifierSpellAmplify_Percentage()
	return self.spell_amp
end

function modifier_item_yasha_and_kaya_2_passive:GetModifierSpellLifestealRegenAmplify_Percentage()
	return self.spell_lifesteal_amp
end

function modifier_item_yasha_and_kaya_2_passive:GetModifierCastSpeed( params )
	return self.bonus_cooldown
end

function modifier_item_yasha_and_kaya_2_passive:GetModifierCastRangeBonusStacking()
	return self.cast_range_bonus
end

function modifier_item_yasha_and_kaya_2_passive:GetModifierAttackRangeBonus(params)
	if self:GetParent():IsRangedAttacker() then 
		return self.base_attack_range 
	else
		return self.base_attack_range * self.melee_pct
	end
end

function modifier_item_yasha_and_kaya_2_passive:GetModifierHealthBonus()
	return self.bonus_health
end

function modifier_item_yasha_and_kaya_2_passive:GetModifierManaBonus()
	return self.bonus_mana
end

function modifier_item_yasha_and_kaya_2_passive:GetModifierConstantHealthRegen()
	return self.bonus_health_regen
end

function modifier_item_yasha_and_kaya_2_passive:GetModifierConstantManaRegen()
	return self.bonus_mana_regen
end

function modifier_item_yasha_and_kaya_2_passive:GetModifierMPRegenAmplify_Percentage()
	return self.mana_regen_multiplier
end


function modifier_item_yasha_and_kaya_2_passive:IsHidden()
	return true
end

function modifier_item_yasha_and_kaya_2_passive:IsPurgable()
	return false
end

function modifier_item_yasha_and_kaya_2_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

modifier_item_yasha_and_kaya_2_archon = class({})
LinkLuaModifier( "modifier_item_yasha_and_kaya_2_archon", "items/item_yasha_and_kaya.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_yasha_and_kaya_2_archon:OnCreated()
	self:OnRefresh()
end

function modifier_item_yasha_and_kaya_2_archon:OnRefresh()
	self.cooldown_stacks = self:GetSpecialValueFor("cooldown_stacks")
	self.casttime_stacks = self:GetSpecialValueFor("casttime_stacks")
	self.buffer_duration = self:GetSpecialValueFor("buffer_duration")
	self.loss_per_sec = self:GetSpecialValueFor("loss_timer") / self:GetStackCount()
	self.loss_float = 0
	
	self:GetParent().cooldownModifiers[self] = true
	
	if IsServer() then
		self:StartIntervalThink(self.buffer_duration)
	end
end

function modifier_item_yasha_and_kaya_2_archon:OnDestroy()
	self:GetParent().cooldownModifiers[self] = nil
end

function modifier_item_yasha_and_kaya_2_archon:OnIntervalThink()
	if self:GetStackCount() > 1 and not self:GetParent():HasActiveAbility() then
		self:DecrementStackCount( ) 
		self:StartIntervalThink(self.loss_per_sec)
	end
end

function modifier_item_yasha_and_kaya_2_archon:GetModifierCastSpeed( params )
	if params.ability and not params.ability:IsItem() then return self.cooldown_stacks * self:GetStackCount() end 
end

modifier_item_yasha_and_kaya_2_archon_as = class({})
LinkLuaModifier( "modifier_item_yasha_and_kaya_2_archon_as", "items/item_yasha_and_kaya.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_yasha_and_kaya_2_archon_as:OnCreated()
	self:OnRefresh()
end

function modifier_item_yasha_and_kaya_2_archon_as:OnRefresh()
	self.attack_speed_buff = self:GetSpecialValueFor("attack_speed_buff")
end

function modifier_item_yasha_and_kaya_2_archon_as:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT}
end

function modifier_item_yasha_and_kaya_2_archon_as:GetModifierAttackSpeedBonus_Constant()
	return self.attack_speed_buff
end