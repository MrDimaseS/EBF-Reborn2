hoodwink_scurry = class({})

function hoodwink_scurry:GetIntrinsicModifierName()
	return "modifier_hoodwink_hoodwink_scurry_evasion"
end

function hoodwink_scurry:CastFilterResult( )
	if self:GetCaster():HasModifier("modifier_hoodwink_scurry_scurrying") then
		return UF_FAIL_CUSTOM
	else
		return UF_SUCCESS
	end
end

function hoodwink_scurry:GetCustomCastError( )
	return "#dota_hud_error_hoodwink_already_scurrying"
end

function hoodwink_scurry:OnSpellStart()
	local caster = self:GetCaster()
	
	local duration = self:GetTalentSpecialValueFor("duration")
	caster:AddNewModifier( caster, self, "modifier_hoodwink_scurry_scurrying", {duration = duration} )
	
	ProjectileManager:ProjectileDodge( caster )
end


modifier_hoodwink_hoodwink_scurry_evasion = class({})
LinkLuaModifier("modifier_hoodwink_hoodwink_scurry_evasion", "heroes/hero_hoodwink/hoodwink_scurry", LUA_MODIFIER_MOTION_NONE)

function modifier_hoodwink_hoodwink_scurry_evasion:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink( 0.25 )
	end
end

function modifier_hoodwink_hoodwink_scurry_evasion:OnStackCountChanged( stacks )
	if self:GetStackCount( ) ~= stacks and IsServer() then
		if self:GetStackCount() == 1 and not self.evasionFX then
			self.evasionFX = ParticleManager:CreateParticle("particles/units/heroes/hero_hoodwink/hoodwink_scurry_passive.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
		else
			ParticleManager:ClearParticle( self.evasionFX )
			self.evasionFX = nil
		end
	end
end

function modifier_hoodwink_hoodwink_scurry_evasion:OnRefresh()
	self.evasion = self:GetTalentSpecialValueFor("evasion")
	self.bonus_tree_evasion = self:GetTalentSpecialValueFor("bonus_tree_evasion")
	self.radius = self:GetTalentSpecialValueFor("radius")
end

function modifier_hoodwink_hoodwink_scurry_evasion:OnIntervalThink()
	if GridNav:IsNearbyTree( self:GetCaster():GetAbsOrigin(), self.radius, true ) then
		self:SetStackCount( 0 )
	else
		self:SetStackCount( 1 )
	end
end

function modifier_hoodwink_hoodwink_scurry_evasion:DeclareFunctions()
	return {MODIFIER_PROPERTY_EVASION_CONSTANT}
end

function modifier_hoodwink_hoodwink_scurry_evasion:GetModifierEvasion_Constant()
	return self.evasion + TernaryOperator( self.bonus_tree_evasion, self:GetStackCount() == 0, 0 ) + TernaryOperator( 0, self:GetParent():HasModifier("modifier_hoodwink_scurry_scurrying"), self:GetSpecialValueFor("bonus_active_evasion") )
end

function modifier_hoodwink_hoodwink_scurry_evasion:IsHidden()
	return self:GetStackCount() ~= 0
end

modifier_hoodwink_scurry_scurrying = class({})
LinkLuaModifier("modifier_hoodwink_scurry_scurrying", "heroes/hero_hoodwink/hoodwink_scurry", LUA_MODIFIER_MOTION_NONE)

function modifier_hoodwink_scurry_scurrying:OnCreated()
	self.movespeed = self:GetTalentSpecialValueFor("movement_speed_pct")
	self.cast_range = self:GetTalentSpecialValueFor("cast_range")
	self.attack_range = self:GetTalentSpecialValueFor("attack_range")
end

function modifier_hoodwink_scurry_scurrying:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS, MODIFIER_PROPERTY_CAST_RANGE_BONUS, MODIFIER_PROPERTY_ATTACK_RANGE_BONUS }
end

function modifier_hoodwink_scurry_scurrying:CheckState()
	local state = { [MODIFIER_STATE_ALLOW_PATHING_THROUGH_TREES] = true }
	return state
end

function modifier_hoodwink_scurry_scurrying:GetModifierMoveSpeedBonus_Percentage()
	return self.movespeed
end

function modifier_hoodwink_scurry_scurrying:GetModifierCastRangeBonus()
	return self.cast_range
end

function modifier_hoodwink_scurry_scurrying:GetModifierAttackRangeBonus()
	return self.attack_range
end

function modifier_hoodwink_scurry_scurrying:GetActivityTranslationModifiers()
	return "scurry"
end

function modifier_hoodwink_scurry_scurrying:GetEffectName()
	return "particles/units/heroes/hero_hoodwink/hoodwink_scurry_aura.vpcf"
end