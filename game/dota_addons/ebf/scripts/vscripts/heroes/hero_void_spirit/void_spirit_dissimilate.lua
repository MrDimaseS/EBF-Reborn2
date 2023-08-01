void_spirit_dissimilate = class({})

function void_spirit_dissimilate:OnSpellStart()
	local caster = self:GetCaster()
	local position = caster:GetAbsOrigin()
	self.portals = {}
	self:CreatePortal( position, true )
	local portals = self:GetTalentSpecialValueFor("portals_per_ring")
	local angle = self:GetTalentSpecialValueFor("angle_per_ring_portal")
	local distance = self:GetTalentSpecialValueFor("first_ring_distance_offset")
	local direction = caster:GetForwardVector()
	
	local rings = self:GetSpecialValueFor("outer_rings")
	
	local currDist = 0
	for i = 1, rings do
		currDist = currDist + distance
		for i = 1, portals do
			direction = RotateVector2D( direction, ToRadians( angle ) )
			local newPos = position + direction * currDist
			self:CreatePortal( newPos, false )
		end
	end
	
	caster:Stop()
	caster:Interrupt()
	caster:Hold()
	self:SetActivated( false )
	self:EndCooldown()
	caster:AddNewModifier( caster, self, "modifier_void_spirit_dissimilate_oow", {duration = self:GetTalentSpecialValueFor("phase_duration")})
	EmitSoundOn( "Hero_VoidSpirit.Dissimilate.Cast", caster )
end

function void_spirit_dissimilate:CreatePortal( position, active )
	local caster = self:GetCaster()
	local radius = self:GetTalentSpecialValueFor("damage_radius")
	local fx = ParticleManager:CreateParticle( "particles/units/heroes/hero_void_spirit/dissimilate/void_spirit_dissimilate.vpcf", PATTACH_WORLDORIGIN, caster )
	ParticleManager:SetParticleControl( fx, 0, GetGroundPosition( position, caster ) )
	ParticleManager:SetParticleControl( fx, 1, Vector( radius, 0, 0 ) )
	ParticleManager:SetParticleControl( fx, 2, Vector( (active and 1) or 0, 0, 0 ) )
	self.portals[fx] = {position = GetGroundPosition( position, caster ), active = active}
end

void_spirit_greater_dissimilate = class(void_spirit_dissimilate)

modifier_void_spirit_dissimilate_oow = class({})
LinkLuaModifier( "modifier_void_spirit_dissimilate_oow", "heroes/hero_void_spirit/void_spirit_dissimilate", LUA_MODIFIER_MOTION_NONE )

if IsServer() then
	function modifier_void_spirit_dissimilate_oow:OnCreated()
		self:GetCaster():AddNoDraw()
		
		self.stun_duration = self:GetSpecialValueFor("")
	end

	function modifier_void_spirit_dissimilate_oow:OnDestroy()
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		caster:RemoveNoDraw()
		
		local radius = self:GetTalentSpecialValueFor("damage_radius")
		
		for portalFx, portalData in pairs( ability.portals ) do
			if portalData.active then
				for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( portalData.position, radius ) ) do
					ability:DealDamage( caster, enemy, ability:GetAbilityDamage() )
					if self.stun_duration > 0 then
						self:Stun(enemy, self.stun_duration)
					end
				end
				ParticleManager:FireParticle( "particles/units/heroes/hero_void_spirit/dissimilate/void_spirit_dissimilate_dmg.vpcf", PATTACH_CUSTOMORIGIN, caster, {[0] = portalData.position, [1] = Vector( radius/2, 1, 1 ) } )
				ParticleManager:FireParticle( "particles/units/heroes/hero_void_spirit/dissimilate/void_spirit_dissimilate_exit.vpcf", PATTACH_POINT_FOLLOW, caster )
				FindClearSpaceForUnit( caster, portalData.position, true)
				EmitSoundOn( "Hero_VoidSpirit.Dissimilate.TeleportIn", caster )
				
			end
			ParticleManager:ClearParticle( portalFx )
		end
		
		ability:SetActivated( true )
		ability:SetCooldown()
	end
end

function modifier_void_spirit_dissimilate_oow:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ORDER}
end

function modifier_void_spirit_dissimilate_oow:OnOrder( params )
	if params.unit == self:GetParent() then
		if params.new_pos ~= Vector(0, 0, 0) or params.target then
			local ability = self:GetAbility()
			local portals = ability.portals
			local position = params.new_pos
			if position == Vector(0, 0, 0) then
				position = params.target:GetAbsOrigin()
			end
			local nearestPortal
			local nearestDistance = 99999
			for fx, portalData in pairs( portals ) do
				ParticleManager:SetParticleControl( fx, 2, Vector( (active and 1) or 0, 0, 0 ) )
				portalData.active = false
				if CalculateDistance( portalData.position, position ) < nearestDistance then
					nearestPortal = fx
					nearestDistance = CalculateDistance( portalData.position, position )
				end
			end
			portals[nearestPortal].active = true
			ParticleManager:SetParticleControl( nearestPortal, 2, Vector( 1, 0, 0 ) )
		elseif params.order_type == DOTA_UNIT_ORDER_STOP or params.order_type == DOTA_UNIT_ORDER_HOLD_POSITION then
			self:Destroy()
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