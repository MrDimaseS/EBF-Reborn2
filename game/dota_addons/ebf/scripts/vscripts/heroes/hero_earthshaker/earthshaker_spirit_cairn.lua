earthshaker_spirit_cairn = class({})

function earthshaker_spirit_cairn:IsStealable()
	return true
end

function earthshaker_spirit_cairn:IsHiddenWhenStolen()
	return false
end

function earthshaker_spirit_cairn:GetIntrinsicModifierName()
	return "modifier_earthshaker_spirit_cairn_handler"
end

function earthshaker_spirit_cairn:CreateSpiritCairn( flDur )
	local caster = self:GetCaster()
	local duration = flDur or self:GetSpecialValueFor("fissure_duration")
	local radius = self:GetSpecialValueFor("fissure_radius")
	if self.cairn then
		UTIL_Remove( self.cairn )
		self.cairn = nil
	end
	self.cairn = caster:CreateSummon("npc_dummy_unit", caster:GetAbsOrigin(), duration)
	self.cairn:AddNewModifier( caster, self, "modifier_earthshaker_spirit_cairn_cairn", {duration = duration} )
	self.cairn:SetHullRadius( radius )
	
	Timers:CreateTimer( 0.1, function() ResolveNPCPositions( caster:GetAbsOrigin(), radius * 2 ) end )
end

LinkLuaModifier("modifier_earthshaker_spirit_cairn_handler", "heroes/hero_earthshaker/earthshaker_spirit_cairn", LUA_MODIFIER_MOTION_NONE)
modifier_earthshaker_spirit_cairn_handler = class({})

function modifier_earthshaker_spirit_cairn_handler:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ABILITY_FULLY_CAST}
end

function modifier_earthshaker_spirit_cairn_handler:OnAbilityFullyCast(params)
	if params.ability:IsItem() then return end
	if params.unit ~= self:GetCaster() then return end
	self:GetAbility():CreateSpiritCairn( )
end

function modifier_earthshaker_spirit_cairn_handler:IsHidden()
	return true
end

LinkLuaModifier("modifier_earthshaker_spirit_cairn_cairn", "heroes/hero_earthshaker/earthshaker_spirit_cairn", LUA_MODIFIER_MOTION_NONE)
modifier_earthshaker_spirit_cairn_cairn = class({})

function modifier_earthshaker_spirit_cairn_cairn:OnCreated()
	self:OnRefresh()
	if IsServer() then
		local FX = ParticleManager:CreateParticle("particles/units/heroes/hero_earthshaker/earthshaker_fissure.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
		ParticleManager:SetParticleControl( FX, 0, self:GetParent():GetAbsOrigin() )
		ParticleManager:SetParticleControl( FX, 1, self:GetParent():GetAbsOrigin() )
		ParticleManager:SetParticleControl( FX, 2, Vector( self.duration, 0, 0 ) )
		self:AddEffect(FX)
		
		local FX2 = ParticleManager:CreateParticle("particles/units/heroes/hero_earthshaker/earthshaker_spirit_cairn_aura.vpcf", PATTACH_POINT_FOLLOW, self:GetParent() )
		ParticleManager:SetParticleControl( FX2, 3, Vector( self.radius, 0, 0 ) )
		self:AddEffect(FX2)
	end
end

function modifier_earthshaker_spirit_cairn_cairn:OnRefresh()
	self.duration = self:GetSpecialValueFor("fissure_duration")
	self.radius = self:GetSpecialValueFor("bonus_radius")
end

function modifier_earthshaker_spirit_cairn_cairn:OnDestroy()
	if not IsServer() then return end
	self:GetAbility().cairn = nil
end

function modifier_earthshaker_spirit_cairn_cairn:CheckState()
	return {[MODIFIER_STATE_INVULNERABLE] = true,
			[MODIFIER_STATE_NO_HEALTH_BAR] = true,
			[MODIFIER_STATE_STUNNED] = true,
			[MODIFIER_STATE_FROZEN] = true,
			}
end

function modifier_earthshaker_spirit_cairn_cairn:IsAura()
	return true
end

function modifier_earthshaker_spirit_cairn_cairn:GetModifierAura()
	return "modifier_earthshaker_spirit_cairn_aura"
end

function modifier_earthshaker_spirit_cairn_cairn:GetAuraRadius()
	return self.radius
end

function modifier_earthshaker_spirit_cairn_cairn:GetAuraDuration()
	return 0.5
end

function modifier_earthshaker_spirit_cairn_cairn:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_FRIENDLY
end

function modifier_earthshaker_spirit_cairn_cairn:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_earthshaker_spirit_cairn_cairn:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

LinkLuaModifier("modifier_earthshaker_spirit_cairn_aura", "heroes/hero_earthshaker/earthshaker_spirit_cairn", LUA_MODIFIER_MOTION_NONE)
modifier_earthshaker_spirit_cairn_aura = class({})

function modifier_earthshaker_spirit_cairn_aura:OnCreated()
	self:OnRefresh()
end

function modifier_earthshaker_spirit_cairn_aura:OnRefresh()
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
end

function modifier_earthshaker_spirit_cairn_aura:DeclareFunctions()
	return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS}
end
function modifier_earthshaker_spirit_cairn_aura:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end