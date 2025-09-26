item_azureblood_bowl = class({})

function item_azureblood_bowl:GetIntrinsicModifierName()
	return "modifier_item_azureblood_bowl_passive"
end

function item_azureblood_bowl:RequiresCharges()
	return true
end

function item_azureblood_bowl:OnSpellStart( )
	local caster = self:GetCaster()
	
	local maxCharges = self:GetSpecialValueFor("max_charges_applied")
	local searchRadius = self:GetSpecialValueFor("search_radius")
	local duration = self:GetSpecialValueFor("invulnerability_duration")

	EmitSoundOn( "item_outworld_staff", caster )
	local alliedLogicTable = {}
	Timers:CreateTimer( function()
		if not IsEntitySafe( caster ) then return end
		if not IsEntitySafe( self ) then return end
		for _, hero in ipairs( caster:FindFriendlyUnitsInRadius( caster:GetAbsOrigin(), searchRadius, {type=DOTA_UNIT_TARGET_HERO, flag=DOTA_UNIT_TARGET_FLAG_INVULNERABLE } ) ) do
			if not hero:IsIllusion() then
				alliedLogicTable[hero] = alliedLogicTable[hero] or 0
				if alliedLogicTable[hero] < maxCharges then
					alliedLogicTable[hero] = alliedLogicTable[hero] + 1
					hero:AddNewModifierStacking( caster, self, "modifier_item_azureblood_bowl_invulnerability", {duration = duration})
					ParticleManager:FireRopeParticle("particles/items2_fx/urn_of_shadows.vpcf", PATTACH_POINT_FOLLOW, caster, hero )
					local charges = self:GetCurrentCharges()
					if charges > 0 then
						self:SetCurrentCharges( charges - 1 )
						return 0.1
					end
				end
			end
		end
	end)
end

modifier_item_azureblood_bowl_invulnerability = class({})
LinkLuaModifier( "modifier_item_azureblood_bowl_invulnerability", "items/item_azureblood_bowl.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_azureblood_bowl_invulnerability:CheckState()
	return {[MODIFIER_STATE_INVULNERABLE] = true}
end

modifier_item_azureblood_bowl_passive = class({})
LinkLuaModifier( "modifier_item_azureblood_bowl_passive", "items/item_azureblood_bowl.lua", LUA_MODIFIER_MOTION_NONE )

function modifier_item_azureblood_bowl_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_azureblood_bowl_passive:OnRefresh()
	self.bonus_all = self:GetSpecialValueFor("bonus_all")
end

function modifier_item_azureblood_bowl_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
			MODIFIER_EVENT_ON_HEAL_RECEIVED }
end

function modifier_item_azureblood_bowl_passive:GetModifierBonusStats_Strength()
	return self.bonus_all
end

function modifier_item_azureblood_bowl_passive:GetModifierBonusStats_Agility()
	return self.bonus_all
end

function modifier_item_azureblood_bowl_passive:GetModifierBonusStats_Intellect()
	return self.bonus_all
end

function modifier_item_azureblood_bowl_passive:OnHealReceived( params )
	local parent = self:GetParent()
	if not params.inflictor then return end -- no health regen
	if params.fail_type == 0 then return end -- no lifesteal
	if not params.attacker:IsSameTeam( parent ) then return end
	if not params.unit:IsRealHero( ) then return end
	local ability = self:GetAbility()
	ability:SetCurrentCharges( ability:GetCurrentCharges() + 1 )
end

function modifier_item_azureblood_bowl_passive:IsHidden()
	return true
end

function modifier_item_azureblood_bowl_passive:IsPurgable()
	return false
end

function modifier_item_azureblood_bowl_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end