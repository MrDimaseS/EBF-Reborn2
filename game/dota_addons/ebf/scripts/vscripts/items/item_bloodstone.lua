item_bloodstone2 = class({})

function item_bloodstone2:GetIntrinsicModifierName()
	return "modifier_item_bloodstone_ebf"
end

function item_bloodstone2:OnSpellStart()
	local caster = self:GetCaster()
	
	self:DealDamage( caster, caster, caster:GetMaxHealth() * self:GetSpecialValueFor("hp_cost") / 100, {damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_HPLOSS + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NON_LETHAL } )
	
	caster:AddNewModifier( caster, self, "modifier_item_bloodstone_ebf_active", {duration = self:GetSpecialValueFor("buff_duration")} )
end

item_bloodstone = class(item_bloodstone2)
item_voodoo_mask = class(item_bloodstone)
item_bloodstone3 = class(item_bloodstone2)
item_bloodstone4 = class(item_bloodstone2)
item_bloodstone5 = class(item_bloodstone2)

modifier_item_bloodstone_ebf_active = class({})
LinkLuaModifier( "modifier_item_bloodstone_ebf_active", "items/item_bloodstone.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_bloodstone_ebf_active:OnCreated()
	self.magic_immune = self:GetSpecialValueFor("magic_immunity") == 1
	self.magic_resist = self:GetSpecialValueFor("magic_resist")
	if IsServer() and self.magic_immune then
		self.magicFX = ParticleManager:CreateParticle( "particles/items_fx/black_king_bar_avatar.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
		self:AddEffect( self.magicFX )
	end
end

function modifier_item_bloodstone_ebf_active:OnDestroy()
	if IsServer() then
		local parent = self:GetParent()
		parent:AddNewModifier( parent, self:GetAbility(), "modifier_item_bloodstone_ebf_drained", {duration = self:GetSpecialValueFor("buff_duration")} )
		-- ParticleManager:ClearParticle( self.magicFX )
	end
end

function modifier_item_bloodstone_ebf_active:CheckState()
	if self.magic_immune then
		return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
	end
end

function modifier_item_bloodstone_ebf_active:DeclareFunctions()
	return {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS}
end

function modifier_item_bloodstone_ebf_active:GetModifierMagicalResistanceBonus()
	return self.magic_resist
end

function modifier_item_bloodstone_ebf_active:GetEffectName()
	return "particles/items_fx/bloodstone_heal.vpcf"
end

function modifier_item_bloodstone_ebf_active:GetEffectAttachType()
	return PATTACH_OVERHEAD_FOLLOW
end

modifier_item_bloodstone_ebf_drained = class({})
LinkLuaModifier( "modifier_item_bloodstone_ebf_drained", "items/item_bloodstone.lua" ,LUA_MODIFIER_MOTION_NONE )

modifier_item_bloodstone_ebf = class({})
LinkLuaModifier( "modifier_item_bloodstone_ebf", "items/item_bloodstone.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_bloodstone_ebf:OnCreated()
	self:OnRefresh()
end

function modifier_item_bloodstone_ebf:OnRefresh()
	self.bonus_mana = self:GetAbility():GetSpecialValueFor("bonus_mana")
	self.bonus_health = self:GetAbility():GetSpecialValueFor("bonus_health")
	self.bonus_all = self:GetAbility():GetSpecialValueFor("bonus_all")
	
	self.spell_lifesteal = self:GetAbility():GetSpecialValueFor("spell_lifesteal")
	self.active_multiplier = self:GetAbility():GetSpecialValueFor("lifesteal_multiplier")
	self.mana_steal = self:GetAbility():GetSpecialValueFor("mana_steal") / 100
end

function modifier_item_bloodstone_ebf:DeclareFunctions(params)
local funcs = {
		MODIFIER_PROPERTY_HEALTH_BONUS,
		MODIFIER_PROPERTY_MANA_BONUS,
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_EVENT_ON_TAKEDAMAGE
    }
    return funcs
end

function modifier_item_bloodstone_ebf:GetModifierManaBonus()
	return self.bonus_mana
end

function modifier_item_bloodstone_ebf:GetModifierHealthBonus()
	return self.bonus_health
end

function modifier_item_bloodstone_ebf:GetModifierBonusStats_Strength()
	return self.bonus_all
end

function modifier_item_bloodstone_ebf:GetModifierBonusStats_Intellect()
	return self.bonus_all
end

function modifier_item_bloodstone_ebf:GetModifierBonusStats_Agility()
	return self.bonus_all
end

function modifier_item_bloodstone_ebf:OnTakeDamage(params)
	if params.attacker == self:GetParent() and params.damage_category == DOTA_DAMAGE_CATEGORY_SPELL and params.inflictor 
	and not ( HasBit( params.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL ) or HasBit( params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS ) or HasBit( params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION )) then
		local bloodstoneActive = params.attacker:HasModifier("modifier_item_bloodstone_ebf_active") and not params.attacker:HasModifier("modifier_item_bloodstone_ebf_drained") 
		local spell_lifesteal = self.spell_lifesteal
		if bloodstoneActive then
			spell_lifesteal =  self.spell_lifesteal * self.active_multiplier
		end
		
		if not params.unit:IsConsideredHero() then
			spell_lifesteal =  spell_lifesteal / 5
		end
		
		local EHPMult = self:GetParent().EHP_MULT or 1
		local lifesteal = params.damage * spell_lifesteal / 100 * math.max( 1, EHPMult )
		
		self.lifeToGive = (self.lifeToGive or 0) + lifesteal
		if self.lifeToGive > 1 then
			local preHP = params.attacker:GetHealth()
			params.attacker:HealWithParams( lifesteal, params.inflictor, false, true, self, true )
			self.lifeToGive = self.lifeToGive - math.floor(self.lifeToGive)
			local postHP = params.attacker:GetHealth()
		
			if postHP - preHP ~= 0 then
				ParticleManager:FireParticle( "particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_POINT_FOLLOW, params.attacker )
			end
		end
		
		if bloodstoneActive then
			self.manaToGive = (self.manaToGive or 0) + lifesteal * self.mana_steal
			if self.manaToGive > 1 then
				params.attacker:GiveMana( math.floor(self.manaToGive) ) 
			self.manaToGive = self.manaToGive - math.floor(self.manaToGive)
			end
		end
	end
end

function modifier_item_bloodstone_ebf:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_item_bloodstone_ebf:IsHidden()
	return true
end