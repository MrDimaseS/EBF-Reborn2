void_spirit_dissimilate = class({})

function void_spirit_dissimilate:OnSpellStart()
	local caster = self:GetCaster()
	local position = caster:GetAbsOrigin()
	
	local portals = self:GetSpecialValueFor("portals_per_ring")
	local angle = self:GetSpecialValueFor("angle_per_ring_portal")
	local distance = self:GetSpecialValueFor("first_ring_distance_offset")
	local direction = caster:GetForwardVector()
	local rings = self:GetSpecialValueFor("outer_rings")
	local phaseDuration = self:GetSpecialValueFor("phase_duration")
	
	local createsAetherRemnant = self:GetSpecialValueFor("creates_aether_remnant") == 1
	local massAetherRemnant = self:GetSpecialValueFor("mass_aether_remnants") == 1
	local aetherRemnant = caster:FindAbilityByName("void_spirit_aether_remnant")
	
	self.portals = {}
	self:CreatePortal( position, true )
	local remnants = {}
	if createsAetherRemnant and aetherRemnant and aetherRemnant:IsTrained() then
		local remnant = aetherRemnant:CreateAetherRemnant( position, caster:GetForwardVector() )
		table.insert( remnants, remnant )
	end
	local currDist = 0
	for i = 1, rings do
		currDist = currDist + distance
		for i = 1, portals do
			direction = RotateVector2D( direction, ToRadians( angle ) )
			local newPos = position + direction * currDist
			self:CreatePortal( newPos, false )
			if massAetherRemnant and aetherRemnant and aetherRemnant:IsTrained() then
				local remnant = aetherRemnant:CreateAetherRemnant( newPos, CalculateDirection( newPos, position ) )
				table.insert( remnants, remnant )
			end
		end
	end

	caster:Stop()
	caster:Interrupt()
	caster:Hold()
	self:SetFrozenCooldown( true )
	Timers:CreateTimer( function()
		if caster:HasModifier("modifier_void_spirit_dissimilate_oow") then
			return 0.01
		else
			self:SetFrozenCooldown( false )
		end
	end)
	caster:AddNewModifier( caster, self, "modifier_void_spirit_dissimilate_oow", {duration = phaseDuration})
	EmitSoundOn( "Hero_VoidSpirit.Dissimilate.Cast", caster )
	
	if #remnants > 0 then
		Timers:CreateTimer( 0.01, function()
			if caster:HasModifier("modifier_void_spirit_dissimilate_oow") then
				return 0.01
			else
				for _, remnant in ipairs( remnants ) do
					remnant:Destroy()
				end
			end
		end)
	end
end

function void_spirit_dissimilate:CreatePortal( position, active )
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("damage_radius")
	local fx = ParticleManager:CreateParticle( "particles/units/heroes/hero_void_spirit/dissimilate/void_spirit_dissimilate.vpcf", PATTACH_WORLDORIGIN, caster )
	ParticleManager:SetParticleControl( fx, 0, GetGroundPosition( position, caster ) )
	ParticleManager:SetParticleControl( fx, 1, Vector( radius, 0, 0 ) )
	ParticleManager:SetParticleControl( fx, 2, Vector( (active and 1) or 0, 0, 0 ) )
	self.portals[fx] = {position = GetGroundPosition( position, caster ), active = active}
end

function void_spirit_dissimilate:PhaseIn( position, parent, bTeleport )
	local caster = self:GetCaster()
	local radius = self:GetSpecialValueFor("damage_radius")
	local damage = self:GetSpecialValueFor("damage")
	local disarmDuration = self:GetSpecialValueFor("disarm_duration")
	local dissimilateStuns = self:GetSpecialValueFor("dissimilate_stuns") == 1
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( position, radius ) ) do
		self:DealDamage( caster, enemy, damage )
		if disarmDuration > 0 then
			if dissimilateStuns then
				self:Stun(enemy, disarmDuration)
			else
				self:Disarm(enemy, disarmDuration)
			end
		end
	end
	ParticleManager:FireParticle( "particles/units/heroes/hero_void_spirit/dissimilate/void_spirit_dissimilate_dmg.vpcf", PATTACH_CUSTOMORIGIN, caster, {[0] = position, [1] = Vector( radius/2, 1, 1 ) } )
	ParticleManager:FireParticle( "particles/units/heroes/hero_void_spirit/dissimilate/void_spirit_dissimilate_exit.vpcf", PATTACH_POINT_FOLLOW, parent or caster )
	if bTeleport == true or bTeleport == nil then
		FindClearSpaceForUnit( parent or caster, position, true)
		EmitSoundOn( "Hero_VoidSpirit.Dissimilate.TeleportIn", parent or caster )
	end
end

modifier_void_spirit_dissimilate_oow = class({})
LinkLuaModifier( "modifier_void_spirit_dissimilate_oow", "heroes/hero_void_spirit/void_spirit_dissimilate", LUA_MODIFIER_MOTION_NONE )

function modifier_void_spirit_dissimilate_oow:OnCreated()
	self.phased_hp_regen = self:GetSpecialValueFor("phased_hp_regen") / self:GetDuration()
	if IsClient() then return end
	self:GetCaster():AddNoDraw()
end

function modifier_void_spirit_dissimilate_oow:OnDestroy()
	if IsClient() then return end
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	caster:RemoveNoDraw()
	
	for portalFx, portalData in pairs( ability.portals ) do
		if portalData.active then
			ability:PhaseIn( portalData.position )
		end
		ParticleManager:ClearParticle( portalFx, true )
	end
	ability:SetFrozenCooldown( false )
end

function modifier_void_spirit_dissimilate_oow:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ORDER, MODIFIER_PROPERTY_HEALTH_REGEN_PERCENTAGE }
end

function modifier_void_spirit_dissimilate_oow:GetModifierHealthRegenPercentage( params )
	return self.phased_hp_regen
end

function modifier_void_spirit_dissimilate_oow:OnOrder( params )
	if params.unit == self:GetParent() then
		if params.order_type == DOTA_UNIT_ORDER_STOP or params.order_type == DOTA_UNIT_ORDER_HOLD_POSITION then
			self:Destroy()
		elseif params.new_pos ~= Vector(0, 0, 0) or params.target then
			local ability = self:GetAbility()
			local portals = ability.portals
			local position = params.unit:GetLastMovePosition()
			local nearestPortal
			local nearestDistance = 99999
			for fx, portalData in pairs( portals ) do
				portalData.active = false
				ParticleManager:SetParticleControl( fx, 2, Vector( 0, 0, 0 ) )
				if CalculateDistance( portalData.position, position ) < nearestDistance then
					nearestPortal = fx
					nearestDistance = CalculateDistance( portalData.position, position )
				end
			end
			portals[nearestPortal].active = true
			ParticleManager:SetParticleControl( nearestPortal, 2, Vector( 1, 0, 0 ) )
		end
	end
end

function modifier_void_spirit_dissimilate_oow:CheckState()
	return {[MODIFIER_STATE_ROOTED] = true,
			[MODIFIER_STATE_SILENCED] = true,
			[MODIFIER_STATE_DISARMED] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			[MODIFIER_STATE_OUT_OF_GAME] = true,
			[MODIFIER_STATE_UNTARGETABLE] = true,
			[MODIFIER_STATE_NOT_ON_MINIMAP_FOR_ENEMIES] = true,
			[MODIFIER_STATE_INVULNERABLE] = true,
			}
end

function modifier_void_spirit_dissimilate_oow:IsHidden()
	return true
end