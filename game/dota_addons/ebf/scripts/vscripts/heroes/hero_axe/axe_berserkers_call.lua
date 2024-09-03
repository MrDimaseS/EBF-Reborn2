axe_berserkers_call = class({})

function axe_berserkers_call:OnSpellStart()
	local caster = self:GetCaster()
	
	EmitSoundOn("Hero_Axe.Berserkers_Call", caster)

	local nfx = ParticleManager:FireParticle("particles/units/heroes/hero_axe/axe_beserkers_call_owner.vpcf", PATTACH_POINT_FOLLOW, caster, {[0] = caster:GetAbsOrigin(), [1] = "attach_mouth", [2] = Vector(self:GetSpecialValueFor("radius"),0,0)})
	caster:AddNewModifier( caster, self, "modifier_axe_berserkers_call_aura", {duration = self:GetSpecialValueFor("duration")} )
end

modifier_axe_berserkers_call_aura = class({})
LinkLuaModifier( "modifier_axe_berserkers_call_aura", "heroes/hero_axe/axe_berserkers_call", LUA_MODIFIER_MOTION_NONE )

function modifier_axe_berserkers_call_aura:OnCreated()
	self:OnRefresh()
end

function modifier_axe_berserkers_call_aura:OnRefresh()
	self.bonus_armor = self:GetSpecialValueFor("bonus_armor")
	self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	self.radius = self:GetSpecialValueFor("radius")
	self.allies_benefit = self:GetSpecialValueFor("allies_benefit") == 1
	self.taunts = self:GetSpecialValueFor("taunts") == 1
end

function modifier_axe_berserkers_call_aura:DeclareFunctions()
	return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

function modifier_axe_berserkers_call_aura:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_axe_berserkers_call_aura:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

function modifier_axe_berserkers_call_aura:IsAura()
	return self:GetParent() == self:GetCaster() and self.radius > 0
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
	local teams = DOTA_UNIT_TARGET_TEAM_ENEMY
	if self.allies_benefit then
		teams = teams + DOTA_UNIT_TARGET_TEAM_FRIENDLY
	end
	return teams
end

function modifier_axe_berserkers_call_aura:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

function modifier_axe_berserkers_call_aura:GetAuraSearchFlags()    
	return DOTA_UNIT_TARGET_FLAG_NONE
end

function modifier_axe_berserkers_call_aura:GetAuraEntityReject( target )
	return target:HasModifier("modifier_axe_berserkers_call_aura")
end

function modifier_axe_berserkers_call_aura:GetHeroEffectName()
	return "particles/units/heroes/hero_axe/axe_beserkers_call_hero_effect.vpcf"
end

modifier_axe_berserkers_call_taunt = class({})
LinkLuaModifier( "modifier_axe_berserkers_call_taunt", "heroes/hero_axe/axe_berserkers_call", LUA_MODIFIER_MOTION_NONE )

function modifier_axe_berserkers_call_taunt:OnCreated()
	self:OnRefresh()
end

function modifier_axe_berserkers_call_taunt:OnRefresh()
	self.taunts = self:GetSpecialValueFor("taunts") == 1
	self.battle_hunger_freeze_duration = self:GetSpecialValueFor("battle_hunger_freeze_duration") == 1
	if not IsServer() then return end
	if self:GetParent():IsSameTeam( self:GetCaster() ) then
		self:GetParent():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_axe_berserkers_call_aura", {duration = self:GetRemainingTime()} )
		self:Destroy()
		return
	end
	if self.taunts then
		if self:GetParent():IsNeutralUnitType() then
			self:GetParent():SetForceAttackTarget( self:GetCaster() )
		else
			self:GetParent():MoveToTargetToAttack( self:GetCaster() )
			self:GetParent():SetAttacking( self:GetCaster() )
			
			ExecuteOrderFromTable({
				UnitIndex = self:GetCaster():entindex(),
				OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
				TargetIndex = self:GetParent():entindex()
			})
		end
	end
	if self.battle_hunger_freeze_duration then
		self:StartIntervalThink( 0.1 )
	end
end

function modifier_axe_berserkers_call_taunt:OnIntervalThink()
	local battleHunger = self:GetParent():FindModifierByName("modifier_axe_battle_hunger_debuff")
	if not battleHunger then return end
	battleHunger:SetDuration( battleHunger:GetRemainingTime() + 0.1, true )
	for ID, data in ipairs( battleHunger._stackFollowList ) do
		battleHunger._stackFollowList[ID].expireTime = data.expireTime + 0.1
	end
end

function modifier_axe_berserkers_call_taunt:OnDestroy()
	if IsServer() then
		if self:GetParent():IsNeutralUnitType() then
			self:GetParent():SetForceAttackTarget( nil )
		end
	end
end

function modifier_axe_berserkers_call_taunt:CheckState()
	return {[MODIFIER_STATE_TAUNTED] = self.taunts}
end

function modifier_axe_berserkers_call_taunt:GetTauntTarget()
	if self.taunts then
		return self:GetCaster()
	end
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