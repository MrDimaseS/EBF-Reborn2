nevermore_frenzy = class({})

function nevermore_frenzy:CastFilterResult()
	if IsClient() then return end
	local souls = self:GetCaster():FindModifierByName("modifier_nevermore_necromastery_passive")
	if not souls or souls:GetStackCount() < self:GetSpecialValueFor("soul_cost") then
		return UF_FAIL_CUSTOM
	end
	return UF_SUCCESS
end
function nevermore_frenzy:GetCustomCastError()
	return "Not Enough Souls"
end
function nevermore_frenzy:OnSpellStart()
	local caster = self:GetCaster()
	EmitSoundOn("Hero_Nevermore.Frenzy", caster)
	caster:AddNewModifier(caster, self, "modifier_nevermore_frenzy_base", { duration = self:GetSpecialValueFor("duration") })
	
	self.heal = self:GetSpecialValueFor("heal_amount")
	if self.heal > 0 then
		caster:HealWithParams(self.heal, self, false, true, self, false)
	end

	self.cooldown_reduction = self:GetSpecialValueFor("cooldown_reduction")
	if self.cooldown_reduction > 0 then
		local count = caster:GetAbilityCount()
		for i = 0, count - 1, 1 do
			local ability = caster:GetAbilityByIndex(i)
			if ability and ability ~= self then
				ability:ModifyCooldown(-self.cooldown_reduction)
			end
		end
	end
end

modifier_nevermore_frenzy_base = class({})
LinkLuaModifier("modifier_nevermore_frenzy_base", "heroes/hero_shadow_fiend/nevermore_frenzy.lua", LUA_MODIFIER_MOTION_NONE)
function modifier_nevermore_frenzy_base:OnCreated()
	self:OnRefresh()
end
function modifier_nevermore_frenzy_base:OnRefresh()
	self.soul_cost = self:GetSpecialValueFor("soul_cost")
	
	self.crit_chance = self:GetSpecialValueFor("crit_chance")
	self.crit_damage = self:GetSpecialValueFor("crit_damage")
	self.guaranteed_crits = self:GetSpecialValueFor("guaranteed_crits")

	self.aoe_bonus = self:GetSpecialValueFor("aoe_bonus")

	self.lifeleech = self:GetSpecialValueFor("lifeleech")

	self:GetCaster()._aoeModifiersList = self:GetCaster()._aoeModifiersList or {}
	self:GetCaster()._aoeModifiersList[self] = true
end
function modifier_nevermore_frenzy_base:OnRemoved()
	if IsClient() then return end
	local parent = self:GetParent()
	local souls = parent:FindModifierByName("modifier_nevermore_necromastery_passive")
	if souls then
		souls:SetStackCount(math.max(0, souls:GetStackCount() - self.soul_cost))
	end
	self:GetCaster()._aoeModifiersList[self] = nil
end
function modifier_nevermore_frenzy_base:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_PREATTACK_CRITICALSTRIKE,
		MODIFIER_PROPERTY_AOE_BONUS_CONSTANT_STACKING,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
	}
end
function modifier_nevermore_frenzy_base:GetModifierPreAttack_CriticalStrike(params)
	if self:GetSpecialValueFor("guaranteed_crits") == 0 then return end
	if self.guaranteed_crits > 0 then
		self.guaranteed_crits = self.guaranteed_crits - 1
		return self.crit_damage
	end

	local roll = RollPseudoRandomPercentage(self.crit_chance, DOTA_PSEUDO_RANDOM_CUSTOM_GENERIC, params.attacker)
	if roll then
		return self.crit_damage
	end
end
function modifier_nevermore_frenzy_base:GetCritDamage()
	return self.crit_damage / 100
end
function modifier_nevermore_frenzy_base:GetModifierAoEBonusConstantStacking()
	return self.aoe_bonus
end
function modifier_nevermore_frenzy_base:OnTakeDamage(params)
	if params.attacker ~= self:GetParent() then return end

	local is_lifesteal = params.damage_category == DOTA_DAMAGE_CATEGORY_ATTACK
	local is_spell_lifesteal = params.damage_category == DOTA_DAMAGE_CATEGORY_SPELL

	if is_spell_lifesteal and 
	  (HasBit(params.damage_flags, DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL)
	or HasBit(params.damage_flags, DOTA_DAMAGE_FLAG_HPLOSS)
	or HasBit(params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION)) then return end

	local ehp_mult = self:GetParent().EHP_MULT or 1
	local lifesteal = params.damage * self.lifeleech / 100 * math.max(1, ehp_mult)
	if lifesteal > 1 then
		local heal = math.floor(lifesteal)
		local before_hp = params.attacker:GetHealth()
		params.attacker:HealWithParams(
			heal, 
			params.inflictor, 
			is_lifesteal, 
			true, 
			self, 
			is_spell_lifesteal
		)
		local after_hp = params.attacker:GetHealth()

		local hp_gained = after_hp - before_hp
		if hp_gained > 0 then
			if is_lifesteal then
				ParticleManager:FireParticle(
					"particles/generic_gameplay/generic_lifesteal.vpcf", 
					PATTACH_POINT_FOLLOW, 
					params.attacker
				)
			end
			if is_spell_lifesteal then
				ParticleManager:FireParticle(
					"particles/items3_fx/octarine_core_lifesteal.vpcf",
					PATTACH_POINT_FOLLOW,
					params.attacker
				)
			end
		end
	end
end
function modifier_nevermore_frenzy_base:GetEffectName()
	return "particles/items2_fx/mask_of_madness.vpcf"
end