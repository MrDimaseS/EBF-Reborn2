bristleback_bristleback = class({})

function bristleback_bristleback:GetIntrinsicModifierName()
	return "modifier_bristleback_bristleback_passive"
end
function bristleback_bristleback:GetBehavior()
	if self:GetSpecialValueFor("mettlehead_increase") ~= 0 then
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET
	else
		return DOTA_ABILITY_BEHAVIOR_POINT
	end
end
function bristleback_bristleback:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()

	if self:GetSpecialValueFor("hairball_speed") ~= 0 then
		self:DoHairball()
	elseif self:GetSpecialValueFor("activation_delay") ~= 0 then
		caster:AddNewModifier( caster, self, "modifier_bristleback_active_conical_quill_spray", { x = target.x, y = target.y, z = target.z } )
	else
		caster:AddNewModifier(caster, self, "modifier_bristleback_bristleback_mettlehead", { duration = self:GetSpecialValueFor("mettlehead_increase_duration") })
	end
	
	local warpath = caster:FindAbilityByName("bristleback_warpath")
	if IsEntitySafe(warpath) and warpath:IsTrained() then
		warpath:AddStack()
	end
end
function bristleback_bristleback:DoHairball()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()
	local direction = ((point - caster:GetAbsOrigin()) * Vector(1, 1, 0)):Normalized()
	local speed = self:GetSpecialValueFor("hairball_speed")

	local particle = "particles/units/heroes/hero_bristleback/bristleback_hairball.vpcf"
	ProjectileManager:CreateLinearProjectile({
		Source = caster,
		Ability = self,
		EffectName = particle,
		vSpawnOrigin = caster:GetOrigin(),
		vVelocity = direction * speed,
		fDistance = (point - caster:GetAbsOrigin()):Length2D()
	})

	-- sounds
	local sound = "Hero_Bristleback.Hairball.Cast"
	EmitSoundOn(sound, caster)
end
function bristleback_bristleback:OnProjectileHit(target, position)
	if target then return end

	local hairball_radius = self:GetSpecialValueFor("hairball_radius")
	local hairball_quills = self:GetSpecialValueFor("hairball_quills")
	local hairball_goos = self:GetSpecialValueFor("hairball_goos")
	local quill = self:GetCaster():FindAbilityByName("bristleback_quill_spray")
	local goo = self:GetCaster():FindAbilityByName("bristleback_viscous_nasal_goo")

	for i = 1, hairball_quills do
		quill:DoQuill({
			position = position,
			override_radius = hairball_radius
		})
	end
	for i = 1, hairball_goos do
		goo:DoGoo(position, nil, hairball_radius)
	end
end

modifier_bristleback_bristleback_mettlehead = class({})
LinkLuaModifier( "modifier_bristleback_bristleback_mettlehead", "heroes/hero_bristleback/bristleback_bristleback", LUA_MODIFIER_MOTION_NONE )

function modifier_bristleback_bristleback_mettlehead:IsHidden()
	return false
end
function modifier_bristleback_bristleback_mettlehead:IsDebuff()
	return false
end
function modifier_bristleback_bristleback_mettlehead:IsPurgable()
	return false
end

modifier_bristleback_bristleback_passive = class({})
LinkLuaModifier( "modifier_bristleback_bristleback_passive", "heroes/hero_bristleback/bristleback_bristleback", LUA_MODIFIER_MOTION_NONE )

function modifier_bristleback_bristleback_passive:IsHidden()
	return true
end
function modifier_bristleback_bristleback_passive:OnCreated()
	self:OnRefresh()
end
function modifier_bristleback_bristleback_passive:OnRefresh()
	self.min_damage_reduction = self:GetSpecialValueFor("min_damage_reduction")
	self.max_damage_reduction = self:GetSpecialValueFor("max_damage_reduction")
	self.mettlehead_increase = self:GetSpecialValueFor("mettlehead_increase")
end
function modifier_bristleback_bristleback_passive:DeclareFunctions()
	return {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE
	}
end
function modifier_bristleback_bristleback_passive:GetModifierIncomingDamage_Percentage(params)
	if self:GetParent():PassivesDisabled() then return end

	local min_damage_reduction = self.min_damage_reduction
	local max_damage_reduction = self.max_damage_reduction

	if self:GetParent():HasModifier("modifier_bristleback_bristleback_mettlehead") then
		min_damage_reduction = min_damage_reduction + self.mettlehead_increase
		max_damage_reduction = max_damage_reduction + self.mettlehead_increase
	end

	local red_scale = max_damage_reduction - min_damage_reduction
	local dotPr = DotProduct( params.target:GetForwardVector(), params.attacker:GetForwardVector() )
	local scaling = (dotPr + 1) / 2
	local total_reduction = min_damage_reduction + red_scale * scaling

	return -total_reduction
end

--[[
function bristleback_bristleback:GetIntrinsicModifierName()
	return "modifier_bristleback_bristleback_passive"
end

function bristleback_bristleback:GetBehavior( )
	if false then
		return DOTA_ABILITY_BEHAVIOR_NO_TARGET
	else
		return DOTA_ABILITY_BEHAVIOR_POINT
	end
end

function bristleback_bristleback:GetCooldown( iLvl )
	if self:GetCaster():HasScepter() then
		return self:GetSpecialValueFor("activation_cooldown")
	end
end

function bristleback_bristleback:GetManaCost( iLvl )
	if self:GetCaster():HasScepter() then
		return self:GetSpecialValueFor("activation_manacost")
	end
end

function bristleback_bristleback:GetCastPoint()
	if self:GetCaster():HasScepter() then
		return self:GetSpecialValueFor("activation_delay")
	end
end

function bristleback_bristleback:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
	
	caster:AddNewModifier( caster, self, "modifier_bristleback_active_conical_quill_spray", {duration = self:GetSpecialValueFor("activation_spray_interval") * self:GetSpecialValueFor("activation_num_quill_sprays"), x = target.x, y = target.y} )
end
	
modifier_bristleback_bristleback_passive = class({})
LinkLuaModifier( "modifier_bristleback_bristleback_passive", "heroes/hero_bristleback/bristleback_bristleback", LUA_MODIFIER_MOTION_NONE )

function modifier_bristleback_bristleback_passive:OnCreated()
	if IsServer() then
		self.quills = self:GetCaster():FindAbilityByName("bristleback_quill_spray")
		self.snot = self:GetCaster():FindAbilityByName("bristleback_viscous_nasal_goo")
		self.goo_radius = self:GetSpecialValueFor("goo_radius")
	end
end

function modifier_bristleback_bristleback_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE}
end

function modifier_bristleback_bristleback_passive:GetModifierIncomingDamage_Percentage( params )
	if self:GetParent():PassivesDisabled() then return end
	if not IsEntitySafe( self.quills ) then return end
	local parent = self:GetParent()
	
	local max_reduction = self:GetSpecialValueFor("max_damage_reduction")
	local min_reduction = self:GetSpecialValueFor("min_damage_reduction")
	local red_scale = max_reduction - min_reduction
	
	local dotPr = DotProduct( params.target:GetForwardVector(), params.attacker:GetForwardVector() )
	local scaling = (dotPr + 1) / 2
	
	local total_reduction = min_reduction + red_scale * scaling
	
	self.damageTaken = (self.damageTaken or 0) + params.damage * total_reduction/100
	local hpThreshold = self:GetCaster():GetHealth() * self:GetSpecialValueFor("quill_release_threshold") / 100
	
	if hpThreshold == 0 then return end
	if parent:GetHealth() == 0 then return end
	if parent:GetHealth() < params.damage then return end
	
	if hpThreshold < self.damageTaken then
		local damageTaken = self.damageTaken
		self.damageTaken = 0
		Timers:CreateTimer( function()
			if parent:GetHealth() == 0 then return end
			if self.goo_radius > 0 then
				if not self.snot:IsTrained() then return end
				for _, enemy in ipairs( parent:FindEnemyUnitsInRadius( parent:GetAbsOrigin(), self.goo_radius ) ) do
					self.snot:FireTrackingProjectile("particles/units/heroes/hero_bristleback/bristleback_viscous_nasal_goo.vpcf", enemy, self.snot:GetSpecialValueFor("goo_speed") )
				end
			else
				if not self.quills:IsTrained() then return end
				self.quills:Spray( true )
			end
		end)
	end

	return -total_reduction
end
]]