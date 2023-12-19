axe_culling_blade = class({})

function axe_culling_blade:GetIntrinsicModifierName()
	return "modifier_axe_culling_blade_permanent_armor"
end

--------------------------------------------------------------------------------
-- Ability Start
function axe_culling_blade:OnSpellStart()
	-- unit identifier
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	-- load data
	local damage = self:GetSpecialValueFor("damage")
	local threshold = self:GetSpecialValueFor("kill_threshold")
	local radius = self:GetSpecialValueFor("speed_aoe")
	local duration = self:GetSpecialValueFor("speed_duration")
	local heroMult = self:GetSpecialValueFor("hero_cd_reduction") / 100

	if target:TriggerSpellAbsorb( self ) then return end
	-- Check success / not
	self:DealDamage( caster, target, damage )
	local success = not target:IsAlive()

	-- effects
	self:PlayEffects( target, success )

	if success then
		for _, ally in ipairs( caster:FindFriendlyUnitsInRadius( target:GetAbsOrigin(), radius ) ) do
			ally:AddNewModifier( caster, self, "modifier_axe_culling_blade_kill", { duration = duration } )
		end
		
		local modifier = caster:AddNewModifier( caster, self, "modifier_axe_culling_blade_permanent_armor", {} )
		if modifier then
			modifier:IncrementStackCount()
			if target:IsConsideredHero() then
				local cooldown = self:GetCooldownTimeRemaining()
				self:EndCooldown()
				self:StartCooldown( cooldown * (1-heroMult) )
			end
		end
	else
		target:AddNewModifier( caster, self, "modifier_axe_culling_blade_grace_period", {duration = self:GetSpecialValueFor("grace_period")} )
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
	function modifier_axe_culling_blade_grace_period:OnDestroy()
		local caster = self:GetCaster()
		local parent = self:GetParent()
		local ability = self:GetAbility()
		
		local radius = ability:GetSpecialValueFor("speed_aoe")
		local duration = ability:GetSpecialValueFor("speed_duration")
		local heroMult = ability:GetSpecialValueFor("hero_cd_reduction") / 100
		if not parent:IsAlive() then
			ability:PlayEffects( parent, true )
			for _, ally in ipairs( caster:FindFriendlyUnitsInRadius( parent:GetAbsOrigin(), radius ) ) do
				ally:AddNewModifier( caster, ability, "modifier_axe_culling_blade_kill", { duration = duration } )
			end
			
			local modifier = caster:AddNewModifier( caster, ability, "modifier_axe_culling_blade_permanent_armor", {} )
			if modifier then
				modifier:IncrementStackCount()
				if parent:IsConsideredHero() then
					local cooldown = ability:GetCooldownTimeRemaining()
					ability:EndCooldown()
					ability:StartCooldown( cooldown * (1-heroMult) )
				end
			end
		end
	end
end

modifier_axe_culling_blade_permanent_armor = class({})
LinkLuaModifier( "modifier_axe_culling_blade_permanent_armor", "heroes/hero_axe/axe_culling_blade", LUA_MODIFIER_MOTION_NONE )
--------------------------------------------------------------------------------
-- Classifications
function modifier_axe_culling_blade_permanent_armor:IsHidden()
	return self:GetStackCount() <= 0
end

function modifier_axe_culling_blade_permanent_armor:IsDebuff()
	return false
end

function modifier_axe_culling_blade_permanent_armor:IsPurgable()
	return false
end

function modifier_axe_culling_blade_permanent_armor:IsPermanent()
	return true
end

function modifier_axe_culling_blade_permanent_armor:RemoveOnDeath()
	return false
end

--------------------------------------------------------------------------------
-- Initializations
function modifier_axe_culling_blade_permanent_armor:OnCreated( kv )
	self:OnRefresh()
end

function modifier_axe_culling_blade_permanent_armor:OnRefresh( kv )
	self.armor = self:GetAbility():GetSpecialValueFor( "armor_per_stack" )
end

--------------------------------------------------------------------------------
-- Modifier Effects
function modifier_axe_culling_blade_permanent_armor:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS,
	}

	return funcs
end

function modifier_axe_culling_blade_permanent_armor:GetModifierPhysicalArmorBonus()
	return self.armor * self:GetStackCount()
end