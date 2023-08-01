antimage_mana_break = class ({})

function antimage_mana_break:GetIntrinsicModifierName()
	return "modifier_antimage_mana_break_passive"
end

modifier_antimage_mana_break_passive = class({})
LinkLuaModifier( "modifier_antimage_mana_break_passive", "heroes/hero_antimage/antimage_mana_break", LUA_MODIFIER_MOTION_NONE )

function modifier_antimage_mana_break_passive:OnCreated()
	self:OnRefresh()
end

function modifier_antimage_mana_break_passive:OnRefresh()
	self.percent_damage_per_burn = self:GetTalentSpecialValueFor("percent_damage_per_burn") / 100
	self.mana_per_hit = self:GetTalentSpecialValueFor("mana_per_hit")
	self.illusion_percentage = self:GetTalentSpecialValueFor("illusion_percentage") / 100
	self.slow_duration = self:GetTalentSpecialValueFor("slow_duration")
end

function modifier_antimage_mana_break_passive:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ATTACK_LANDED}
end

function modifier_antimage_mana_break_passive:OnAttackLanded(params)
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if params.attacker ~= caster or caster:PassivesDisabled() then return end
	
	local mana_per_hit_pct = self:GetSpecialValueFor("mana_per_hit_pct") / 100
	local damageType = DAMAGE_TYPE_PHYSICAL
	
	local manaBurn =  params.target:GetMaxMana() * mana_per_hit_pct + self.mana_per_hit
	if params.attacker:IsIllusion() then
		manaBurn = manaBurn * self.illusion_percentage
	end
	params.target:ReduceMana( manaBurn )
	if params.target:GetMana() <= 0 then
		damageType = DAMAGE_TYPE_PURE
		params.target:AddNewModifier( caster, ability, "modifier_antimage_mana_break_full_drain", {duration = self.slow_duration} )
		ParticleManager:FireParticle("particles/units/heroes/hero_antimage/antimage_manabreak_slow.vpcf", PATTACH_POINT_FOLLOW, params.target, {[1] = "attach_hitloc"} )
	end
	ability:DealDamage(caster, params.target, manaBurn * self.percent_damage_per_burn, {damage_type = damageType, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION})
end

function modifier_antimage_mana_break_passive:IsHidden()
	return true
end

modifier_antimage_mana_break_full_drain = class({})
LinkLuaModifier( "modifier_antimage_mana_break_full_drain", "heroes/hero_antimage/antimage_mana_break", LUA_MODIFIER_MOTION_NONE )

function modifier_antimage_mana_break_full_drain:OnCreated()
	self.slow = self:GetSpecialValueFor("move_slow")
end

function modifier_antimage_mana_break_full_drain:OnRefresh()
	self.slow = self:GetSpecialValueFor("move_slow")
end

function modifier_antimage_mana_break_full_drain:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE, MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT }
end

function modifier_antimage_mana_break_full_drain:GetModifierMoveSpeedBonus_Percentage()
	return -self.slow
end

function modifier_antimage_mana_break_full_drain:GetModifierAttackSpeedBonus_Constant()
	return -self.slow
end