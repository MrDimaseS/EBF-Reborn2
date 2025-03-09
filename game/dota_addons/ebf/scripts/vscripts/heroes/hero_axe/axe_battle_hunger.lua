axe_battle_hunger = class({})

function axe_battle_hunger:IsStealable()
	return true
end

function axe_battle_hunger:IsHiddenWhenStolen()
	return false
end

function axe_battle_hunger:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	EmitSoundOn("Hero_Axe.Battle_Hunger", target)
	if target:TriggerSpellAbsorb( self ) then return end
	target:AddNewModifier(caster, self, "modifier_axe_battle_hunger_debuff", {Duration = self:GetSpecialValueFor("duration")})
end

modifier_axe_battle_hunger_debuff = class({})
LinkLuaModifier( "modifier_axe_battle_hunger_debuff", "heroes/hero_axe/axe_battle_hunger.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_axe_battle_hunger_debuff:OnCreated()
	if IsServer() then
		self:StartIntervalThink(1)
		self.nFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_axe/axe_battle_hunger_stacks.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetParent() )
		ParticleManager:SetParticleControlEnt(self.nFX, 3, self:GetParent(), PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
	end
	self:OnRefresh()
end

function modifier_axe_battle_hunger_debuff:OnRefresh()
	self.slow = -self:GetSpecialValueFor("slow")
	self.damage_per_second = self:GetSpecialValueFor("damage_per_second")
	
	self.lifesteal_base = self:GetSpecialValueFor("lifesteal_base")
	self.lifesteal_stack = self:GetSpecialValueFor("lifesteal_stack")
	
	self.crit_chance = self:GetSpecialValueFor("crit_chance")
	self.crit_base = self:GetSpecialValueFor("crit_base")
	self.crit_stack = self:GetSpecialValueFor("crit_stack")
	
	self.armor_base = self:GetSpecialValueFor("armor_base")
	self.armor_stack = self:GetSpecialValueFor("armor_stack")
	if IsServer() then
		self:AddIndependentStack( )
	end
end

function modifier_axe_battle_hunger_debuff:OnDestroy()
	if not IsServer() then return end
	ParticleManager:ClearParticle( self.nFX )
end

function modifier_axe_battle_hunger_debuff:OnStackCountChanged()
	if not IsServer() then return end
	ParticleManager:SetParticleControl( self.nFX, 2, Vector( self:GetStackCount(), 0, 0 ) )
end

function modifier_axe_battle_hunger_debuff:OnIntervalThink()
	if not self or self:IsNull() then return end
	local caster = self:GetCaster()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	if not caster or caster:IsNull() then self:Destroy() return end
	if not parent or parent:IsNull() then self:Destroy() return end
	if not ability or ability:IsNull() then self:Destroy() return end
	
	for i = 1, self:GetStackCount() do
		Timers:CreateTimer( (i-1)*0.1, function() ability:DealDamage(caster, parent, self.damage_per_second) end)
	end
end

function modifier_axe_battle_hunger_debuff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
		MODIFIER_PROPERTY_PREATTACK_TARGET_CRITICALSTRIKE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS 
	}
	return funcs
end

function modifier_axe_battle_hunger_debuff:OnTakeDamage(params)
	if params.attacker == self:GetCaster() then
		local lifesteal = params.damage * ( self.lifesteal_base + self.lifesteal_stack * self:GetStackCount() ) / 100
		
		if params.inflictor and not params.unit:IsConsideredHero() then
			lifesteal = lifesteal / 5
		end
		
		local preHP = params.attacker:GetHealth()
		params.attacker:HealWithParams( lifesteal, self:GetAbility(), true, true, self:GetCaster(), false )
		local postHP = params.attacker:GetHealth()
		
		if (postHP - preHP) > 0 then
			SendOverheadEventMessage( params.attacker:GetPlayerOwner(), OVERHEAD_ALERT_HEAL, params.attacker, postHP - preHP, params.attacker:GetPlayerOwner() )
		end
	end
end

function modifier_axe_battle_hunger_debuff:GetModifierPreAttack_Target_CriticalStrike( params )
	if params.attacker == self:GetCaster() and self:RollPRNG( self.crit_chance ) then
		return self.crit_base + self.crit_chance * self:GetStackCount()
	end
end

function modifier_axe_battle_hunger_debuff:GetModifierPhysicalArmorBonus()
	return self.armor_base + self.armor_stack * self:GetStackCount() 
end

function modifier_axe_battle_hunger_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.slow
end

function modifier_axe_battle_hunger_debuff:GetStatusEffectName()
	return "particles/status_fx/status_effect_battle_hunger.vpcf"
end

function modifier_axe_battle_hunger_debuff:StatusEffectPriority()
	return 12
end

function modifier_axe_battle_hunger_debuff:IsDebuff()
	return true
end