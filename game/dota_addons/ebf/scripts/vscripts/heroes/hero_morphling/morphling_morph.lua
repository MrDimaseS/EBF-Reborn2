morphling_morph = class({})

function morphling_morph:IsStealable()
    return false
end

function morphling_morph:IsHiddenWhenStolen()
    return false
end

function morphling_morph:GetBehavior()
	local behavior = DOTA_ABILITY_BEHAVIOR_NO_TARGET + DOTA_ABILITY_BEHAVIOR_TOGGLE + DOTA_ABILITY_BEHAVIOR_IMMEDIATE
	if self:GetSpecialValueFor("castable_while_stunned") == 1 then
		behavior = behavior + DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE
	end
	return behavior
end

morphling_morph_agi = class(morphling_morph)

function morphling_morph_agi:GetIntrinsicModifierName()
    return "modifier_morph_str_bonus"
end

function morphling_morph_agi:Spawn()
	self.linked_ability = self:GetCaster():FindAbilityByName("morphling_morph_str")
end

function morphling_morph_agi:OnToggle()
	local caster = self:GetCaster()
	
	if self:GetToggleState() then
		EmitSoundOn("Hero_Morphling.MorphAgility", caster)
		caster:AddNewModifier(caster, self, "modifier_morphling_morph_agi_shift", {})
		
		if not self.linked_ability then self.linked_ability = self:GetCaster():FindAbilityByName("morphling_morph_str") end
		if IsEntitySafe( self.linked_ability ) and self.linked_ability:GetToggleState() then
			self.linked_ability:ToggleAbility()
		end
	else
		StopSoundOn("Hero_Morphling.MorphAgility", caster)
		caster:RemoveModifierByName("modifier_morphling_morph_agi_shift")
	end
end

modifier_morphling_morph_agi_shift = class(toggleModifierBaseClass)
LinkLuaModifier( "modifier_morphling_morph_agi_shift", "heroes/hero_morphling/morphling_morph.lua" ,LUA_MODIFIER_MOTION_NONE )
function modifier_morphling_morph_agi_shift:OnCreated(table)
	if IsServer() then
		local caster = self:GetCaster()

		local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_morphling/morphling_morph_agi.vpcf", PATTACH_POINT_FOLLOW, caster)
					ParticleManager:SetParticleControlEnt(nfx, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)

		self:AttachEffect(nfx)
		
		self.points_per_tick = self:GetSpecialValueFor("points_per_tick")
		self.morph_cooldown = self:GetSpecialValueFor("morph_cooldown") 
		self.cooldown_rate = self:GetSpecialValueFor("cooldown_rate") * self.morph_cooldown
		self.morph_heal_rate = self:GetSpecialValueFor("morph_heal_rate") / 100
		self.mana_cost = self:GetSpecialValueFor("mana_cost") * self.morph_cooldown
		
		self:StartIntervalThink( self.morph_cooldown )
	end
end

function modifier_morphling_morph_agi_shift:OnIntervalThink()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if not caster:IsAlive() then return end
	if ability:GetToggleState() then
		local statsDiff = math.min( caster:GetBaseStrength() - 1, self.points_per_tick )
		if caster:GetBaseStrength() > 1 then
			local casterHealth = caster:GetHealth()
			local casterMaxHealth = caster:GetMaxHealth()
			caster:SetBaseStrength(caster:GetBaseStrength() - statsDiff)
			caster:SetBaseAgility(caster:GetBaseAgility() + statsDiff)
			caster:CalculateStatBonus(true)
			
			local bonusHP = (casterMaxHealth - caster:GetMaxHealth())*(1-self.morph_heal_rate)
			if bonusHP > 0 then
				caster:SetHealth( math.max( 1, casterHealth - bonusHP ) )
			end
		end
		-- for i = 0, caster:GetAbilityCount() - 1 do
			-- local abilityToCD = caster:GetAbilityByIndex( i )
			-- if abilityToCD and abilityToCD:GetCooldownTimeRemaining() > 0 then
				-- abilityToCD:ModifyCooldown(-self.cooldown_rate)
			-- end
		-- end
		caster:SpendMana(self.mana_cost, ability )
	else
		self:Destroy()
		return
	end

end

morphling_morph_str = class(morphling_morph)
LinkLuaModifier( "modifier_morphling_morph_str_shift", "heroes/hero_morphling/morphling_morph.lua" ,LUA_MODIFIER_MOTION_NONE )

function morphling_morph_str:Spawn()
	self.linked_ability = self:GetCaster():FindAbilityByName("morphling_morph_agi")
end

function morphling_morph_str:OnToggle()
	local caster = self:GetCaster()
	
	if self:GetToggleState() then
		EmitSoundOn("Hero_Morphling.MorphStrengh", caster)
		caster:AddNewModifier(caster, self, "modifier_morphling_morph_str_shift", {})
		
		if self.linked_ability then self.linked_ability = self:GetCaster():FindAbilityByName("morphling_morph_agi") end
		if IsEntitySafe( self.linked_ability ) and self.linked_ability:GetToggleState() then
			self.linked_ability:ToggleAbility()
		end
	else
		StopSoundOn("Hero_Morphling.MorphStrengh", caster)
		caster:RemoveModifierByName("modifier_morphling_morph_str_shift")
	end
end

modifier_morphling_morph_str_shift = class(toggleModifierBaseClass)
function modifier_morphling_morph_str_shift:OnCreated(table)
	if IsServer() then
		local caster = self:GetCaster()

		local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_morphling/morphling_morph_str.vpcf", PATTACH_POINT_FOLLOW, caster)
					ParticleManager:SetParticleControlEnt(nfx, 0, caster, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)

		self:AttachEffect(nfx)
		
		self.points_per_tick = self:GetSpecialValueFor("points_per_tick")
		self.morph_cooldown = self:GetSpecialValueFor("morph_cooldown") 
		self.mana_cost = self:GetSpecialValueFor("mana_cost") * self.morph_cooldown
		self.morph_heal_rate = self:GetSpecialValueFor("morph_heal_rate") / 100
		self.cooldown_rate = self:GetSpecialValueFor("cooldown_rate") * self.morph_cooldown
		self:StartIntervalThink( self.morph_cooldown )
	end
end

function modifier_morphling_morph_str_shift:OnIntervalThink()
	local caster = self:GetCaster()
	local ability = self:GetAbility() 
	if not caster:IsAlive() then return end
	if ability:GetToggleState() then
		local statsDiff = math.min( caster:GetBaseAgility() - 1, self.points_per_tick )
		if caster:GetBaseAgility() > 1 then
			local casterHealth = caster:GetHealth()
			local casterMaxHealth = caster:GetMaxHealth()
			caster:SetBaseStrength(caster:GetBaseStrength() + statsDiff)
			caster:SetBaseAgility(caster:GetBaseAgility() - statsDiff)
			caster:CalculateStatBonus(true)
			
			local bonusHP = caster:GetMaxHealth() - casterMaxHealth
			caster:SetHealth( math.max( 1, casterHealth + bonusHP ) )
		end
		if self.cooldown_rate > 0 then
			for i = 0, caster:GetAbilityCount() - 1 do
				local abilityToCD = caster:GetAbilityByIndex( i )
				if abilityToCD and abilityToCD:GetCooldownTimeRemaining() > 0 then
					abilityToCD:ModifyCooldown(-self.cooldown_rate)
				end
			end
		end
		caster:SpendMana(self.mana_cost, ability )
	else
		self:Destroy()
		return
	end

end