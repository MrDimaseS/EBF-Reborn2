bristleback_bristleback = class({})

function bristleback_bristleback:GetIntrinsicModifierName()
	return "modifier_bristleback_bristleback_passive"
end

function bristleback_bristleback:OnSpawn()
	self:GetCaster():AddNewModifier("modifier_bristleback_bristleback_autocast")
end

function bristleback_bristleback:GetBehavior( )
	if self:GetCaster():HasScepter() then
		return DOTA_ABILITY_BEHAVIOR_POINT
	else
		return DOTA_ABILITY_BEHAVIOR_PASSIVE
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
				self.quills:Spray( )
			end
		end)
	end

	return -total_reduction
end