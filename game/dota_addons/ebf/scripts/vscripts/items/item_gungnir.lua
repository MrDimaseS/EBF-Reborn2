LinkLuaModifier( "modifier_item_nullifier_dispel", "items/item_nullifier.lua" ,LUA_MODIFIER_MOTION_NONE )

item_gungnir = class({})

function item_gungnir:GetIntrinsicModifierName()
	return "modifier_gungnir_passive"
end

item_monkey_king_bar = class(item_gungnir)
item_gungnir_2 = class(item_gungnir)
item_gungnir_3 = class(item_gungnir)
item_gungifier_4 = class(item_gungnir)

function item_gungifier_4:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	
	for _, target in ipairs( caster:FindAllUnitsInRadius( point, self:GetSpecialValueFor("radius") ) ) do
		self:FireTrackingProjectile("particles/items4_fx/nullifier_proj.vpcf", target, self:GetSpecialValueFor("projectile_speed"))
	end
	EmitSoundOn( "DOTA_Item.Nullifier.Cast", caster )
end

function item_gungifier_4:OnProjectileHit( target, position )
	if target then
		local caster = self:GetCaster()
		
		target:AddNewModifier( caster, self, "modifier_item_nullifier_dispel", {duration = self:GetSpecialValueFor("duration")} )
		EmitSoundOn( "DOTA_Item.Nullifier.Target", target )
	end
end

modifier_gungnir_passive = class({})
LinkLuaModifier( "modifier_gungnir_passive", "items/item_gungnir.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_gungnir_passive:OnCreated()
	self.bonus_strength = self:GetSpecialValueFor("bonus_strength")
	self.bonus_agility = self:GetSpecialValueFor("bonus_agility")
	self.attack_damage = self:GetSpecialValueFor("bonus_damage")
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
	self.bonus_regen = self:GetSpecialValueFor("bonus_regen")
	
	self.proc_chance = self:GetSpecialValueFor("bonus_chance")
	self.proc_damage = self:GetSpecialValueFor("bonus_chance_damage")
	self.proc_pct = self:GetSpecialValueFor("bonus_attack_damage") / 100
	
	self.prngID = self:GetAbility():entindex()
	self.attacksOnRecord = {}
	self.keyToAttack = {}
end

function modifier_gungnir_passive:CheckState()
	if self.attacksOnRecord[1] then
		return {[MODIFIER_STATE_CANNOT_MISS] = true}
	end
end

function modifier_gungnir_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
			MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
			MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_PROCATTACK_BONUS_DAMAGE_PURE,
			MODIFIER_EVENT_ON_ATTACK_FINISHED,
			MODIFIER_EVENT_ON_ATTACK_START, 
			MODIFIER_EVENT_ON_ATTACK_CANCELLED, 
			}
end

function modifier_gungnir_passive:GetModifierBonusStats_Strength()
	return self.bonus_strength
end

function modifier_gungnir_passive:GetModifierBonusStats_Agility()
	return self.bonus_agility
end

function modifier_gungnir_passive:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_gungnir_passive:GetModifierConstantHealthRegen()
	return self.bonus_regen
end

function modifier_gungnir_passive:GetModifierPreAttack_BonusDamage()
	return self.attack_damage
end

function modifier_gungnir_passive:GetModifierProcAttack_BonusDamage_Pure( params )
	if params.attacker == self:GetParent() then
		local attackProc = self.attacksOnRecord[1]
		if attackProc then
			local damage = self.proc_damage + params.original_damage * self.proc_pct
			SendOverheadEventMessage(params.target, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE, params.target, damage, params.attacker)
			return damage
		end
	end
end

function modifier_gungnir_passive:OnAttackStart( params )
	if params.attacker == self:GetParent() then
		local prng = RollPseudoRandomPercentage( self.proc_chance, self.prngID, self:GetCaster() )
		table.insert( self.attacksOnRecord, prng )
	end
end

function modifier_gungnir_passive:OnAttackFinished( params )
	if params.attacker == self:GetParent() then
		Timers:CreateTimer( function() table.remove( self.attacksOnRecord, 1 ) end )
	end
end

function modifier_gungnir_passive:OnAttackCancelled( params )
	if params.attacker == self:GetParent() then
		table.remove( self.attacksOnRecord, #self.attacksOnRecord )
	end
end

function modifier_gungnir_passive:IsHidden()
	return true
end

function modifier_gungnir_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end