item_lotus_orb = class({})

function item_lotus_orb:GetIntrinsicModifierName()
	return "modifier_ebfr_lotus_orb_passive"
end

function item_lotus_orb:GetAOERadius()
	return self:GetSpecialValueFor("active_radius")
end

function item_lotus_orb:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	target:AddNewModifier( caster, self, "modifier_ebfr_lotus_orb_active", {duration = self:GetSpecialValueFor("active_duration")} )
	
	EmitSoundOn("Item.LotusOrb.Target", target )
end

item_lotus_orb_2 = class(item_lotus_orb)
item_lotus_orb_3 = class(item_lotus_orb)
item_lotus_orb_4 = class(item_lotus_orb)
item_lotus_orb_5 = class(item_lotus_orb)

modifier_ebfr_lotus_orb_active = class({})
LinkLuaModifier( "modifier_ebfr_lotus_orb_active", "items/item_lotus_orb.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_ebfr_lotus_orb_active:OnCreated()
	self:OnRefresh()
end

function modifier_ebfr_lotus_orb_active:OnRefresh()
	self.active_radius = self:GetSpecialValueFor("active_radius")
end

function modifier_ebfr_lotus_orb_active:DeclareFunctions(params)
	return{MODIFIER_EVENT_ON_ABILITY_EXECUTED}
end

function modifier_ebfr_lotus_orb_active:OnAbilityExecuted( params )
	if params.unit == self:GetCaster() and params.target == self:GetParent() then
		if params.ability:GetName() == "item_ultimate_scepter" then return end
		
		local recast = self:GetSpecialValueFor("recast") or 1
		
		for i = 1, recast do
			local newTarget
			local targetSelection = params.target:FindFriendlyUnitsInRadius( params.target:GetAbsOrigin(), self.active_radius, {flag = params.ability:GetAbilityTargetFlags(), type = params.ability:GetAbilityTargetType() } )
			for _, unit in ipairs( targetSelection ) do	
				if unit:IsConsideredHero() and unit ~= params.target then
					newTarget = unit
					break
				end
			end
			if not newTarget then
				for _, unit in ipairs( targetSelection ) do
					if unit ~= params.target then
						newTarget = unit
						break
					end
				end
			end
			if not newTarget then newTarget = params.target end
			if newTarget then
				params.unit:SetCursorCastTarget( newTarget )
				params.ability:OnSpellStart()
				
				ParticleManager:FireParticle("particles/items3_fx/lotus_orb_reflect.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
				EmitSoundOn( "Item.LotusOrb.Activate", newTarget )
			end
		end
		
		params.unit:SetCursorCastTarget( params.target )
		self:Destroy()
	end
end

function modifier_ebfr_lotus_orb_active:GetEffectName()
	return "particles/items3_fx/lotus_orb_shield.vpcf"
end

function modifier_ebfr_lotus_orb_active:IsHidden()
	return false
end

function modifier_ebfr_lotus_orb_active:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

modifier_ebfr_lotus_orb_passive = class({})
LinkLuaModifier( "modifier_ebfr_lotus_orb_passive", "items/item_lotus_orb.lua" ,LUA_MODIFIER_MOTION_NONE )
function modifier_ebfr_lotus_orb_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ebfr_lotus_orb_passive:OnCreated()
	self.bonus_armor = self:GetAbility():GetSpecialValueFor("bonus_armor")
	self.bonus_all = self:GetAbility():GetSpecialValueFor("bonus_all")
	self.bonus_health_regen = self:GetAbility():GetSpecialValueFor("bonus_health_regen")
	self.bonus_mana_regen = self:GetAbility():GetSpecialValueFor("bonus_mana_regen")
end

function modifier_ebfr_lotus_orb_passive:DeclareFunctions(params)
	local funcs = {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_MANA_REGEN_CONSTANT,
		MODIFIER_PROPERTY_HEALTH_REGEN_CONSTANT,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
		}
    return funcs
end

function modifier_ebfr_lotus_orb_passive:OnTakeDamage(params)
	if params.unit == self:GetParent() and params.attacker:IsConsideredHero() and self:GetAbility():GetCooldownTimeRemaining() < self.damage_cd then
		self:GetAbility():SetCooldown( self.damage_cd )
	end
end

function modifier_ebfr_lotus_orb_passive:GetModifierBonusStats_Strength()
	return self.bonus_all
end

function modifier_ebfr_lotus_orb_passive:GetModifierBonusStats_Intellect()
	return self.bonus_all
end

function modifier_ebfr_lotus_orb_passive:GetModifierBonusStats_Agility()
	return self.bonus_all
end

function modifier_ebfr_lotus_orb_passive:GetModifierConstantHealthRegen()
	return self.bonus_health_regen
end

function modifier_ebfr_lotus_orb_passive:GetModifierConstantManaRegen()
	return self.bonus_mana_regen
end

function modifier_ebfr_lotus_orb_passive:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_ebfr_lotus_orb_passive:IsHidden()
	return true
end