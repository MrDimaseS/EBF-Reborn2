item_ninja_gear = class({})

function item_ninja_gear:GetIntrinsicModifierName()
	return "modifier_item_ninja_gear_passive"
end

function item_ninja_gear:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	caster:AddNewModifier( caster, self, "modifier_item_ninja_gear_solitary_disguise", {duration = self:GetSpecialValueFor("duration")} )
	
	ParticleManager:FireParticle("particles/items2_fx/smoke_of_deceit.vpcf", PATTACH_POINT_FOLLOW, caster)
	EmitSoundOn( "DOTA_Item.SmokeOfDeceit.Activate", caster )
end

modifier_item_ninja_gear_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_ninja_gear_passive", "items/item_ninja_gear.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_ninja_gear_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_ninja_gear_passive:OnRefresh()
	self.bonus_agility = self:GetSpecialValueFor("bonus_agility")
	self.bonus_damage = self:GetSpecialValueFor("bonus_damage")
	self.bonus_spell_amp = self:GetSpecialValueFor("bonus_spell_amp")
	self.passive_movement_bonus = self:GetSpecialValueFor("passive_movement_bonus")
end

function modifier_item_ninja_gear_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
			MODIFIER_PROPERTY_PREATTACK_BONUS_DAMAGE,
			MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
			}
end

function modifier_item_ninja_gear_passive:GetModifierPreAttack_BonusDamage()
	return self.bonus_damage
end

function modifier_item_ninja_gear_passive:GetModifierBonusStats_Agility()
	return self.bonus_agility
end

function modifier_item_ninja_gear_passive:GetModifierSpellAmplify_Percentage()
	return self.bonus_spell_amp
end

function modifier_item_ninja_gear_passive:GetModifierMoveSpeedBonus_Constant()
	return self.passive_movement_bonus
end

modifier_item_ninja_gear_solitary_disguise = class({})
LinkLuaModifier( "modifier_item_ninja_gear_solitary_disguise", "items/item_ninja_gear.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_ninja_gear_solitary_disguise:OnCreated()
	self:OnRefresh()
end

function modifier_item_ninja_gear_solitary_disguise:OnRefresh()
	self.visibility_radius = self:GetSpecialValueFor("visibility_radius")
	self.visibility_duration = self:GetSpecialValueFor("visibility_duration")
	
	self.tick = 0.1
	self.tick_removal = (100 / self.visibility_duration) * self.tick
	self._internalStacks = 100
	
	self.bonus_movement_speed = self:GetSpecialValueFor("bonus_movement_speed")
	if IsServer() then
		self:StartIntervalThink( self.tick )
		self:SetStackCount( self._internalStacks )
	end
end

function modifier_item_ninja_gear_solitary_disguise:OnIntervalThink()
	local enemies = self:GetCaster():FindEnemyUnitsInRadius( self:GetParent():GetAbsOrigin(), self.visibility_radius )
	local stacks = self:GetStackCount()
	if #enemies > 0 then
		self._internalStacks = self._internalStacks - self.tick_removal
		self:SetStackCount( math.floor( self._internalStacks + 0.5 ) )
		if self._internalStacks <= 0 then
			self:Destroy()
		end
	elseif self._internalStacks < 100 then
		self._internalStacks = math.min( 100, self._internalStacks + self.tick_removal )
		self:SetStackCount( math.floor( self._internalStacks + 0.5 ) )
	end
end

function modifier_item_ninja_gear_solitary_disguise:CheckState()
	return {[MODIFIER_STATE_INVISIBLE] = true}
end

function modifier_item_ninja_gear_solitary_disguise:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_EVENT_ON_TAKEDAMAGE,
			MODIFIER_PROPERTY_INVISIBILITY_LEVEL,
			MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT,
			}
end

function modifier_item_ninja_gear_solitary_disguise:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_movement_speed
end

function modifier_item_ninja_gear_solitary_disguise:OnTakeDamage( params )
	if params.attacker == self:GetParent() then self:Destroy() end
end

function modifier_item_ninja_gear_solitary_disguise:GetModifierInvisibilityLevel()
	return 1.0
end

function modifier_item_ninja_gear_solitary_disguise:GetEffectName()
	return "particles/items2_fx/smoke_of_deceit_buff.vpcf"
end