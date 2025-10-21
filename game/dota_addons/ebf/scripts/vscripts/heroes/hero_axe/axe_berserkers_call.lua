axe_berserkers_call = class({})

function axe_berserkers_call:OnSpellStart()
	local caster = self:GetCaster()
	caster._callHungerApplicationTable = {}
	
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
	self.bonus_axe_bonus = self:GetSpecialValueFor("bonus_axe_bonus")
	self.radius = self:GetSpecialValueFor("radius")
	
	self.bonus_movement_speed = self:GetSpecialValueFor("bonus_movement_speed")
	self.bonus_evasion = self:GetSpecialValueFor("bonus_evasion")
	self.allies_benefit = self:GetSpecialValueFor("allies_benefit") == 1
	self.taunts = self:GetSpecialValueFor("taunts") == 1
	self.feel_no_pain = self:GetSpecialValueFor("feel_no_pain") == 1
	
	if self.feel_no_pain then
		self._damage_resistance = 100
		self:StartIntervalThink(0.5)
	end
	
	self:GetCaster()._berserkersCall = self
end

function modifier_axe_berserkers_call_aura:OnIntervalThink()
	self._damage_resistance = self._damage_resistance * 0.75
end

function modifier_axe_berserkers_call_aura:DeclareFunctions()
	return {MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS, MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_EVASION_CONSTANT, MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

function modifier_axe_berserkers_call_aura:GetModifierPhysicalArmorBonus()
	return self.bonus_armor
end

function modifier_axe_berserkers_call_aura:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_movement_speed
end

function modifier_axe_berserkers_call_aura:GetModifierEvasion_Constant()
	return self.bonus_evasion
end

function modifier_axe_berserkers_call_aura:GetModifierIncomingDamage_Percentage()
	return self._damage_resistance
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
	self.applies_bettlehunger = self:GetSpecialValueFor("applies_bettlehunger") == 1
	if not IsServer() then return end
	local parent = self:GetParent()
	local caster = self:GetCaster()
	
	if parent:IsSameTeam( caster ) then
		parent:AddNewModifier(caster, self:GetAbility(), "modifier_axe_berserkers_call_aura", {duration = self:GetRemainingTime()} )
		self:Destroy()
		return
	elseif self.applies_bettlehunger and caster._callHungerApplicationTable then
		if not caster._callHungerApplicationTable[parent:entindex()] then
			local battleHunger = caster:FindAbilityByName("axe_battle_hunger")
			if battleHunger and battleHunger:IsTrained() then
				parent:AddNewModifier(caster, battleHunger, "modifier_axe_battle_hunger_debuff", {Duration = battleHunger:GetSpecialValueFor("duration")})
			end
			caster._callHungerApplicationTable[parent:entindex()] = true
		end
	end
	
	if self.taunts then
		if parent:IsNeutralUnitType() then
			parent:SetForceAttackTarget( caster )
		else
			parent:MoveToTargetToAttack( caster )
			parent:SetAttacking( caster )
			
			ExecuteOrderFromTable({
				UnitIndex = caster:entindex(),
				OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
				TargetIndex = parent:entindex()
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