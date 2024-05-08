boss_winter_wyvern_cold_embrace = class({})

function boss_winter_wyvern_cold_embrace:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	target:AddNewModifier( caster, self, "modifier_boss_winter_wyvern_cold_embrace", {duration = self:GetSpecialValueFor("duration")} )
	
	EmitSoundOn( "Hero_Winter_Wyvern.ColdEmbrace.Cast", caster )
	EmitSoundOn( "Hero_Winter_Wyvern.ColdEmbrace", target )
end

modifier_boss_winter_wyvern_cold_embrace = class({})
LinkLuaModifier( "modifier_boss_winter_wyvern_cold_embrace", "bosses/boss_wyvern/boss_winter_wyvern_cold_embrace", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_winter_wyvern_cold_embrace:OnCreated()
	self.heal_percentage = self:GetSpecialValueFor("heal_percentage") / 100
	
	if IsServer() then
		self:StartIntervalThink( 1 )
	end
end

function modifier_boss_winter_wyvern_cold_embrace:OnIntervalThink()
	local caster = self:GetCaster()
	local target = self:GetParent()
	local ability = self:GetAbility()
	if caster:IsSameTeam(target) then
		target:HealEvent( target:GetMaxHealth() * self.heal_percentage, ability, caster )
	else
		ability:DealDamage( caster, target, target:GetMaxHealth() * self.heal_percentage, {damage_type = DAMAGE_TYPE_PURE} )
	end
end

function modifier_boss_winter_wyvern_cold_embrace:CheckState()
	return {[MODIFIER_STATE_STUNNED] = true,
			[MODIFIER_STATE_FROZEN] = true}
end

function modifier_boss_winter_wyvern_cold_embrace:DeclareFunctions()
	return {MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL}
end

function modifier_boss_winter_wyvern_cold_embrace:GetAbsoluteNoDamagePhysical()
	return 1
end

function modifier_boss_winter_wyvern_cold_embrace:GetEffectName()
	return "particles/units/heroes/hero_winter_wyvern/wyvern_cold_embrace_buff.vpcf"
end