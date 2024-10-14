mirana_starfall = class({})

function mirana_starfall:IsStealable()
    return true
end

function mirana_starfall:IsHiddenWhenStolen()
    return false
end

function mirana_starfall:OnSpellStart()
    local caster = self:GetCaster()
	
	EmitSoundOn("Ability.Starfall", caster)
	
    local damage = self:GetSpecialValueFor("damage")
	local radius = caster:GetAttackRange() + self:GetSpecialValueFor("starfall_radius")
	self.castAbility = true
	for _,enemy in pairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), radius ) ) do
		self:StarDrop( enemy, damage )
	end
	self.castAbility = false
end

function mirana_starfall:StarDrop(target, flDamage, bLesser)
	local caster = self:GetCaster()
	local damage = flDamage or self:GetSpecialValueFor("damage")
	local abilityCast = self.castAbility
	ParticleManager:FireParticle("particles/units/heroes/hero_mirana/mirana_starfall_attack.vpcf", PATTACH_POINT_FOLLOW, target, {[0]=target:GetAbsOrigin()})
	Timers:CreateTimer(0.5, function() --particle delay
		EmitSoundOn("Ability.StarfallImpact", target)
		self:DealDamage(caster, target, damage, {damage_flags = TernaryOperator( DOTA_DAMAGE_FLAG_PROPERTY_FIRE, not abilityCast, DOTA_DAMAGE_FLAG_NONE )})
		if not bLesser then target:AddNewModifier( caster, self, "modifier_mirana_starfall_debuff", {duration = self:GetSpecialValueFor("debuff_duration")}) end
		local bonus_duration = self:GetSpecialValueFor("bonus_duration")
		if self:GetSpecialValueFor("starfall_bonus_dmg") > 0 then
			target:AddNewModifier( caster, self, "modifier_mirana_starfall_new_moon", {duration = bonus_duration})
		end
		if self:GetSpecialValueFor("starfall_lifesteal") > 0 then
			target:AddNewModifier( caster, self, "modifier_mirana_starfall_full_moon", {duration = bonus_duration})
		end
	end)
end

modifier_mirana_starfall_new_moon = class({})
LinkLuaModifier("modifier_mirana_starfall_new_moon", "heroes/hero_mirana/mirana_starfall", LUA_MODIFIER_MOTION_NONE)

function modifier_mirana_starfall_new_moon:OnCreated()
	self:OnRefresh()
end

function modifier_mirana_starfall_new_moon:OnRefresh()
	self.starfall_bonus_dmg = self:GetAbility():GetSpecialValueFor("starfall_bonus_dmg")
	if IsServer() then
		self:AddIndependentStack()
	end
end

function modifier_mirana_starfall_new_moon:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

function modifier_mirana_starfall_new_moon:GetModifierIncomingDamage_Percentage( )
	return self.starfall_bonus_dmg * self:GetStackCount() 
end

modifier_mirana_starfall_full_moon = class({})
LinkLuaModifier("modifier_mirana_starfall_full_moon", "heroes/hero_mirana/mirana_starfall", LUA_MODIFIER_MOTION_NONE)


function modifier_mirana_starfall_full_moon:OnCreated()
	self:OnRefresh()
end

function modifier_mirana_starfall_full_moon:OnRefresh()
	self.starfall_lifesteal = self:GetAbility():GetSpecialValueFor("starfall_lifesteal") / 100
	if IsServer() then
		self:AddIndependentStack()
	end
end

function modifier_mirana_starfall_full_moon:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE, MODIFIER_PROPERTY_TOOLTIP }
end

function modifier_mirana_starfall_full_moon:OnTooltip( )
	return self.starfall_lifesteal * self:GetStackCount()
end

function modifier_mirana_starfall_full_moon:OnTakeDamage( params )
	if params.attacker == self:GetCaster() and params.unit == self:GetParent() then
		local lifesteal = params.damage * self.starfall_lifesteal * self:GetStackCount()
		
		self.lifeToGive = (self.lifeToGive or 0) + lifesteal
		if self.lifeToGive > 1 then
			local lifeGained = self.lifeToGive
			local preHP = self:GetCaster():GetHealth()
			self:GetCaster():HealWithParams( lifeGained, params.inflictor, false, true, self, true )
			self.lifeToGive = self.lifeToGive - math.floor(self.lifeToGive)
			local postHP = self:GetCaster():GetHealth()
			
			
			local actualLifeGained = postHP - preHP
			if actualLifeGained > 0 then
				ParticleManager:FireParticle( "particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
				if params.inflictor then
					ParticleManager:FireParticle( "particles/items3_fx/octarine_core_lifesteal.vpcf", PATTACH_POINT_FOLLOW, self:GetCaster() )
				end
			end
		end
	end
end

modifier_mirana_starfall_debuff = class({})
LinkLuaModifier("modifier_mirana_starfall_debuff", "heroes/hero_mirana/mirana_starfall", LUA_MODIFIER_MOTION_NONE)

function modifier_mirana_starfall_debuff:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_mirana_starfall_debuff:OnTakeDamage( params )
	if params.attacker == self:GetCaster() and params.unit == self:GetParent() and not HasBit( params.damage_flags, DOTA_DAMAGE_FLAG_PROPERTY_FIRE ) then
		local ability = self:GetAbility()
		local damage = self:GetSpecialValueFor("damage")
		local triggerDamage = params.inflictor and self:GetCaster():HasAbility( params.inflictor:GetAbilityName() )
		ability:StarDrop( params.unit, damage * TernaryOperator( 1, triggerDamage, self:GetSpecialValueFor("secondary_starfall_damage_percent") / 100 ), not triggerDamage )
		self:Destroy()
	end
end

modifier_mirana_starfall_starfall_immunity = class({})
LinkLuaModifier("modifier_mirana_starfall_starfall_immunity", "heroes/hero_mirana/mirana_starfall", LUA_MODIFIER_MOTION_NONE)