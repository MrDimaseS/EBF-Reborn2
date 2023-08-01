axe_berserkers_call = class({})

function axe_berserkers_call:OnSpellStart()
	local caster = self:GetCaster()
	
	EmitSoundOn("Hero_Axe.Berserkers_Call", caster)

	local nfx = ParticleManager:FireParticle("particles/units/heroes/hero_axe/axe_beserkers_call_owner.vpcf", PATTACH_POINT_FOLLOW, caster, {[0] = caster:GetAbsOrigin(), [1] = "attach_mouth", [2] = Vector(self:GetTalentSpecialValueFor("radius"),0,0)})
	
	for _, unit in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), -1 ) ) do
		unit:RemoveModifierByName("modifier_axe_berserkers_call_taunt")
	end
	
	caster:AddNewModifier( caster, self, "modifier_axe_berserkers_call_aura", {duration = self:GetSpecialValueFor("duration")} )
end

modifier_axe_berserkers_call_aura = class({})
LinkLuaModifier( "modifier_axe_berserkers_call_aura", "heroes/hero_axe/axe_berserkers_call", LUA_MODIFIER_MOTION_NONE )

function modifier_axe_berserkers_call_aura:OnCreated(table)
	self.armor = self:GetTalentSpecialValueFor("bonus_armor")
	self.radius = self:GetTalentSpecialValueFor("radius")
end

function modifier_axe_berserkers_call_aura:DeclareFunctions()
	return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS}
end

function modifier_axe_berserkers_call_aura:GetModifierPhysicalArmorBonus()
	return self.armor
end

function modifier_axe_berserkers_call_aura:IsAura()
	return true
end

function modifier_axe_berserkers_call_aura:GetModifierAura()
	return "modifier_axe_berserkers_call_taunt"
end

function modifier_axe_berserkers_call_aura:GetAuraRadius()
	return self.radius
end

function modifier_axe_berserkers_call_aura:GetAuraDuration()
	return self:GetRemainingTime()
end

function modifier_axe_berserkers_call_aura:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_axe_berserkers_call_aura:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_axe_berserkers_call_aura:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_axe_berserkers_call_aura:GetHeroEffectName()
	return "particles/units/heroes/hero_axe/axe_beserkers_call_hero_effect.vpcf"
end

modifier_axe_berserkers_call_taunt = class({})
LinkLuaModifier( "modifier_axe_berserkers_call_taunt", "heroes/hero_axe/axe_berserkers_call", LUA_MODIFIER_MOTION_NONE )

function modifier_axe_berserkers_call_taunt:OnCreated()
	if IsServer() then 
		self:GetParent():MoveToTargetToAttack( self:GetCaster() ) 
		self:StartIntervalThink( 0.1 )
		if self:GetSpecialValueFor("applies_battle_hunger") > 0 then
			self.battle_hunger = self:GetCaster():FindAbilityByName("axe_battle_hunger")
			self:GetCaster():SetCursorCastTarget( self:GetParent() )
			if self.battle_hunger then self.battle_hunger:OnSpellStart() end
		end
	end
end

function modifier_axe_berserkers_call_taunt:OnIntervalThink()
	if not self:GetParent():IsAttackingEntity( self:GetCaster() ) and not self:GetParent():HasActiveAbility() then
		self:GetParent():MoveToTargetToAttack( self:GetCaster() ) 
	end
end

function modifier_axe_berserkers_call_taunt:CheckState()
	return {[MODIFIER_STATE_IGNORING_MOVE_AND_ATTACK_ORDERS] = true}
end

function modifier_axe_berserkers_call_taunt:GetEffectName()
	return "particles/units/heroes/hero_axe/axe_beserkers_call.vpcf"
end

function modifier_axe_berserkers_call_taunt:GetStatusEffectName()
	return "particles/status_fx/status_effect_beserkers_call.vpcf"
end

function modifier_axe_berserkers_call_taunt:StatusEffectPriority()
	return 1
end