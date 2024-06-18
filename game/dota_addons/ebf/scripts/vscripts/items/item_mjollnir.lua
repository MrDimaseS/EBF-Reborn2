item_mjollnir_2 = class({})

function item_mjollnir_2:GetIntrinsicModifierName()
	return "modifier_item_mjollnir_ebf"
end

function item_mjollnir_2:ShouldUseResources()
	return true
end

function item_mjollnir_2:OnSpellStart()
	local caster = self:GetCaster()
	
	caster:AddNewModifier( caster, self, "modifier_item_mjollnir_active_ebf", {duration = self:GetSpecialValueFor("static_duration")} )
	EmitSoundOn( "DOTA_Item.Mjollnir.Activate", caster )
	
	local static_radius = self:GetSpecialValueFor("static_radius")
	if static_radius > 0 then
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), static_radius ) ) do
			ParticleManager:FireRopeParticle("particles/items_fx/chain_lightning.vpcf", PATTACH_POINT_FOLLOW, caster, enemy, {})
			EmitSoundOn( "Item.Maelstrom.Chain_Lightning.Jump", enemy )
			self:DealDamage( caster, enemy, self:GetSpecialValueFor("chain_damage") ) 
			enemy:AddNewModifier( caster, self, "modifier_item_mjollnir_rot_ebf", {duration = self:GetSpecialValueFor("debuff_duration")} )
		end
	end
end

item_mjollnir = class(item_mjollnir_2)
item_mjollnir_3 = class(item_mjollnir_2)
item_mjollnir_4 = class(item_mjollnir_2)
item_mjollnir_5 = class(item_mjollnir_2)

modifier_item_mjollnir_ebf = class({})
LinkLuaModifier( "modifier_item_mjollnir_ebf", "items/item_mjollnir.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_mjollnir_ebf:OnCreated()
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.bonus_all = self:GetSpecialValueFor("bonus_all_stats")
	self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	self.bonus_int = self:GetSpecialValueFor("bonus_intelligence")
	
	self.chain_chance = self:GetSpecialValueFor("chain_chance")
	self.static_chance = self:GetSpecialValueFor("static_chance")
	
	self.chain_damage = self:GetSpecialValueFor("chain_damage")
	self.chain_strikes = self:GetSpecialValueFor("chain_strikes")
	self.chain_radius = self:GetSpecialValueFor("chain_radius")
	self.chain_delay = self:GetSpecialValueFor("chain_delay")
	self.chain_cooldown = self:GetSpecialValueFor("chain_cooldown")
	self.bounce_penalty = self:GetSpecialValueFor("bounce_penalty")
	
	self.debuff_duration = self:GetSpecialValueFor("resist_linger_duration")

	self.aura_radius = self:GetSpecialValueFor("aura_radius")
	
	self:GetParent()._internalLastMjollnirChain = 0
	self.records = {}
end

function modifier_item_mjollnir_ebf:DeclareFunctions(params)
local funcs = {
		MODIFIER_EVENT_ON_ATTACK_RECORD,
		MODIFIER_EVENT_ON_ATTACK_LANDED,
		MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
		MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
    }
    return funcs
end

function modifier_item_mjollnir_ebf:CheckState()
	if self.bash then
		return {[MODIFIER_STATE_CANNOT_MISS ] = true}
	end
end

function modifier_item_mjollnir_ebf:OnAttackRecord(params)
	if params.attacker == self:GetParent() and not params.attacker:IsIllusion() then
		local chain_chance = self.chain_chance
		if params.attacker:HasModifier("modifier_item_mjollnir_active_ebf") then
			chain_chance = chain_chance + self.static_chance
		end
		self.records[params.record] = RollPercentage( chain_chance )
		
		if self.records[params.record] then
			self.bash = true
		end
	end
end

function modifier_item_mjollnir_ebf:OnAttackRecordDestroy(params)
	if params.attacker == self:GetParent() and not params.attacker:IsIllusion() then
		self.records[params.record] = nil
	end
end

function modifier_item_mjollnir_ebf:OnAttackLanded(params)
	if IsServer() then
		if params.attacker == self:GetParent() and not params.attacker:IsIllusion() then
			local ability = self:GetAbility()
			local itemIsActive = params.attacker:FindModifierByNameAndAbility("modifier_item_mjollnir_active_ebf", ability )
			if params.target:IsAlive() and self.records[params.record] and (self:GetParent()._internalLastMjollnirChain <= GameRules:GetGameTime() or itemIsActive) then
				local caster = params.attacker
				local target = params.target
				
				local strikes = self.chain_strikes
				local strikes = self.chain_strikes
				local lastTarget = params.attacker
				local currentTarget = params.target
				local strike_cost = 1
				
				
				self:GetParent()._internalLastMjollnirChain = GameRules:GetGameTime() + self.chain_cooldown
				EmitSoundOn( "Item.Maelstrom.Chain_Lightning", caster )
				if itemIsActive then 
					ParticleManager:FireParticle( "particles/units/heroes/hero_zuus/zuus_static_field.vpcf", PATTACH_POINT_FOLLOW, caster )
				end
				local targets = {[currentTarget] = true}
				Timers:CreateTimer( function()
					
					ParticleManager:FireRopeParticle("particles/items_fx/chain_lightning.vpcf", PATTACH_POINT_FOLLOW, lastTarget, currentTarget, {})
					EmitSoundOn( "Item.Maelstrom.Chain_Lightning.Jump", currentTarget )
					if not currentTarget:IsSameTeam( caster ) then 
						ability:DealDamage( caster, currentTarget, self.chain_damage ) 
						if self.debuff_duration > 0 then
							currentTarget:AddNewModifier( caster, ability, "modifier_item_mjollnir_rot_ebf", {duration = self.debuff_duration} )
						end
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
			self.records[params.record] = nil
			self.bash = false
		end
	end
end

function modifier_item_mjollnir_ebf:GetModifierBonusStats_Strength()
	return self.bonus_all
end

function modifier_item_mjollnir_ebf:GetModifierBonusStats_Intellect()
	return self.bonus_all
end

function modifier_item_mjollnir_ebf:GetModifierBonusStats_Agility()
	return self.bonus_all
end

function modifier_item_mjollnir_ebf:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

function modifier_item_mjollnir_ebf:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_mjollnir_ebf:IsHidden()
	return true
end

function modifier_item_mjollnir_ebf:IsPurgable()
	return false
end

function modifier_item_mjollnir_ebf:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

modifier_item_mjollnir_active_ebf = class({})
LinkLuaModifier( "modifier_item_mjollnir_active_ebf", "items/item_mjollnir.lua" ,LUA_MODIFIER_MOTION_NONE )


function modifier_item_mjollnir_active_ebf:OnCreated()
end

function modifier_item_mjollnir_active_ebf:GetEffectName()
	return "particles/econ/items/razor/razor_arcana/razor_arcana_static_link_buff.vpcf"
end

modifier_item_mjollnir_rot_ebf = class({})
LinkLuaModifier( "modifier_item_mjollnir_rot_ebf", "items/item_mjollnir.lua" ,LUA_MODIFIER_MOTION_NONE )


function modifier_item_mjollnir_rot_ebf:OnCreated()
	self.spell_amp = self:GetSpecialValueFor("spell_amp")
end

function modifier_item_mjollnir_rot_ebf:DeclareFunctions(params)
local funcs = {
    MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE 
    }
    return funcs
end

function modifier_item_mjollnir_rot_ebf:GetModifierIncomingDamage_Percentage(params)
	if IsServer() then
		if params.damage_category == DOTA_DAMAGE_CATEGORY_SPELL then
			local dmgAmp = self.spell_amp * ( 1 / ( self:GetParent().EHP_MULT or 1) )
			return dmgAmp
		end
	else
		return self.spell_amp
	end
end