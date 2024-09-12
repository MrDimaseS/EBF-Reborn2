axe_culling_blade = class({})
--------------------------------------------------------------------------------
-- Ability Start
function axe_culling_blade:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- load data
	local damage = self:GetSpecialValueFor("damage")
	local debuff_immune = self:GetSpecialValueFor("debuff_immune") == 1
	local critical_damage = self:GetSpecialValueFor("critical_damage")
	local grace_period = self:GetSpecialValueFor("grace_period")

	if target:TriggerSpellAbsorb( self ) then return end
	if debuff_immune then
		caster:AddNewModifier( caster, self, "modifier_black_king_bar_immune", {duration = grace_period} )
	end
	target:RemoveModifierByName( "modifier_axe_culling_blade_grace_period" )
	target:AddNewModifier( caster, self, "modifier_axe_culling_blade_grace_period", {duration = grace_period} )
	if critical_damage > 0 then
		local trueCrit = critical_damage
		local hunger = target:FindModifierByName("modifier_axe_battle_hunger_debuff")
		if hunger then
			trueCrit = trueCrit + (hunger:GetAbility():GetSpecialValueFor("crit_base")-100) + hunger:GetAbility():GetSpecialValueFor("crit_stack") * hunger:GetStackCount()
		end
		local bonusSpellDamage = damage * (1+caster:GetSpellAmplification( false ))
		damage = caster:GetAverageTrueAttackDamage( target ) * (trueCrit / 100)
		self:DealDamage( caster, target, damage + bonusSpellDamage, {damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION}, OVERHEAD_ALERT_CRITICAL )
		caster:PerformAttack(target, true, true, true, true, false, true, true)
	else
		self:DealDamage( caster, target, damage )
	end
	
	if target:IsAlive() then
		self:PlayEffects( target, false )
	end
end

--------------------------------------------------------------------------------
function axe_culling_blade:PlayEffects( target, success )
	-- Get Resources
	local particle_cast = ""
	local sound_cast = ""
	if success then
		particle_cast = "particles/units/heroes/hero_axe/axe_culling_blade_kill.vpcf"
		sound_cast = "Hero_Axe.Culling_Blade_Success"
	else
		particle_cast = "particles/units/heroes/hero_axe/axe_culling_blade.vpcf"
		sound_cast = "Hero_Axe.Culling_Blade_Fail"
	end

	-- load data
	local direction = (target:GetOrigin()-self:GetCaster():GetOrigin()):Normalized()

	-- Create Particle
	local effect_cast = ParticleManager:CreateParticle( particle_cast, PATTACH_ABSORIGIN_FOLLOW, target )
	ParticleManager:SetParticleControl( effect_cast, 4, target:GetOrigin() )
	ParticleManager:SetParticleControlForward( effect_cast, 3, direction )
	ParticleManager:SetParticleControlForward( effect_cast, 4, direction )
	-- assert(loadfile("lua_abilities/rubick_spell_steal/rubick_spell_steal_color"))(self,effect_target)
	ParticleManager:ReleaseParticleIndex( effect_cast )

	-- Create Sound
	EmitSoundOn( sound_cast, target )
end

modifier_axe_culling_blade_kill = class({})
LinkLuaModifier( "modifier_axe_culling_blade_kill", "heroes/hero_axe/axe_culling_blade", LUA_MODIFIER_MOTION_NONE )

--------------------------------------------------------------------------------
-- Classifications
function modifier_axe_culling_blade_kill:IsHidden()
	return false
end

function modifier_axe_culling_blade_kill:IsDebuff()
	return false
end

function modifier_axe_culling_blade_kill:IsPurgable()
	return true
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_axe_culling_blade_kill:OnCreated( kv )
	self:OnRefresh()
end

function modifier_axe_culling_blade_kill:OnRefresh( kv )
	self.armor_bonus = self:GetAbility():GetSpecialValueFor( "armor_bonus" ) -- special value
	self.ms_bonus = self:GetAbility():GetSpecialValueFor( "speed_bonus" ) -- special value
end

function modifier_axe_culling_blade_kill:OnDestroy( kv )

end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_axe_culling_blade_kill:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}

	return funcs
end
function modifier_axe_culling_blade_kill:GetModifierMoveSpeedBonus_Percentage()
	return self.ms_bonus
end
function modifier_axe_culling_blade_kill:GetModifierPhysicalArmorBonus()
	return self.armor_bonus
end

--------------------------------------------------------------------------------
-- Graphics & Animations
function modifier_axe_culling_blade_kill:GetEffectName()
	return "particles/units/heroes/hero_axe/axe_cullingblade_sprint.vpcf"
end

function modifier_axe_culling_blade_kill:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

modifier_axe_culling_blade_grace_period = class({})
LinkLuaModifier( "modifier_axe_culling_blade_grace_period", "heroes/hero_axe/axe_culling_blade", LUA_MODIFIER_MOTION_NONE )

if IsServer() then
	function modifier_axe_culling_blade_grace_period:OnCreated()
		self.coat_stacks = self:GetSpecialValueFor("coat_stacks")
		self.speed_aoe = self:GetSpecialValueFor("speed_aoe")
		self.speed_duration = self:GetSpecialValueFor("speed_duration")
		self.grace_period = self:GetSpecialValueFor("grace_period")
		self.always_grant_allies = self:GetSpecialValueFor("always_grant_allies") == 1
		self.debuff_immune = self:GetSpecialValueFor("debuff_immune") == 1
		self.coat = self:GetCaster():FindAbilityByName("axe_coat_of_blood")
		
		self:GetCaster():AddNewModifier( self:GetCaster(), self.coat, "modifier_axe_coat_of_blood_buff", {duration = self.grace_period, hero = #self:GetParent():IsConsideredHero(), stacks = self.coat_stacks } )
		if self.always_grant_allies then
			for _, ally in ipairs( self:GetCaster():FindFriendlyUnitsInRadius( self:GetParent():GetAbsOrigin(), self.speed_aoe ) ) do
				ally:AddNewModifier( self:GetCaster(), self.coat, "modifier_axe_coat_of_blood_buff", {duration = self.grace_period, hero = #self:GetParent():IsConsideredHero(), stacks = self.coat_stacks } )
			end
		end
	end
	
	function modifier_axe_culling_blade_grace_period:OnDestroy()
		local caster = self:GetCaster()
		local parent = self:GetParent()
		local ability = self:GetAbility()
		
		if not parent:IsAlive() then
			ability:PlayEffects( parent, true )
			-- increase all of Axe's Coat of Blood durations
			local coatOfBlood = caster:FindModifierByName("modifier_axe_coat_of_blood_buff")
			if not IsModifierSafe( coatOfBlood ) then
				coatOfBlood = caster:AddNewModifier( caster, self.coat, "modifier_axe_coat_of_blood_buff", {duration = self.grace_period, hero = #parent:IsConsideredHero(), stacks = self.coat_stacks } )
			end
			local maxTime = 0
			if not coatOfBlood then return end
			for i = 1, #coatOfBlood.heroStacks do
				coatOfBlood.heroStacks[i] = coatOfBlood.heroStacks[i] + self.speed_duration
				maxTime = math.max( maxTime, coatOfBlood.heroStacks[i] )
			end
			for i = 1, #coatOfBlood.creepStacks do
				coatOfBlood.creepStacks[i] = coatOfBlood.creepStacks[i] + self.speed_duration
				maxTime = math.max( maxTime, coatOfBlood.creepStacks[i] )
			end
			local newDuration = maxTime - GameRules:GetGameTime()
			coatOfBlood:SetDuration( newDuration, true )
			for _, ally in ipairs( caster:FindFriendlyUnitsInRadius( parent:GetAbsOrigin(), self.speed_aoe ) ) do
				if ally ~= caster then
					local allyCoat = ally:AddNewModifier( caster, self.coat, "modifier_axe_coat_of_blood_buff", {duration = newDuration} )
					allyCoat.heroStacks = {}
					allyCoat.creepStacks = {}
					for i, expire in ipairs( coatOfBlood.heroStacks ) do
						table.insert( allyCoat.heroStacks, expire )
					end
					for i, expire in ipairs( coatOfBlood.creepStacks ) do
						table.insert( allyCoat.creepStacks, expire )
					end
					allyCoat:ForceRefresh()
				end
			end
			
			if debuff_immune then
				caster:AddNewModifierStacking( caster, self, "modifier_black_king_bar_immune", {duration = self.speed_duration} )
			end
			
			ability:Refresh()
			if parent:IsConsideredHero() then
				caster:SetRage( caster:GetMaxRage() )
			end
		end
	end
end