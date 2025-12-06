boss_troll_warlord_dance_of_axes = class({})

function boss_troll_warlord_dance_of_axes:OnSpellStart()
	local caster = self:GetCaster()
	
	local axes = self:GetSpecialValueFor("base_axes") + (HeroList:GetActiveHeroCount() - 1) * self:GetSpecialValueFor("bonus_axe_per_player")
	
	local radius = self:GetSpecialValueFor("hit_radius")
	for i = 1, axes do
		self:SummonWhirlingAxe( TernaryOperator( caster:GetForwardVector() * (-1)^(i), math.ceil(i/2)%2 == 0, caster:GetRightVector() * (-1)^(i)), ( radius + caster:GetPaddedCollisionRadius() ) * math.ceil(i/2) )
	end
	caster:EmitSound("Hero_TrollWarlord.WhirlingAxes.Melee")
	caster:StartGesture(ACT_DOTA_CAST_ABILITY_3)
end

function boss_troll_warlord_dance_of_axes:SummonWhirlingAxe( direction, fDistance )
	local caster = self:GetCaster()
	
	local radius = self:GetSpecialValueFor("hit_radius")
	local speed = self:GetSpecialValueFor("axe_movement_speed") 
	local distance = fDistance or ( radius + caster:GetPaddedCollisionRadius() )
	local maxRange = distance + self:GetSpecialValueFor("max_range")
	local damage = self:GetSpecialValueFor("damage")
	local blind = self:GetSpecialValueFor("blind_duration")
	
	local vDir = direction or RandomVector( 1 ):Normalized()
	local duration = 3
	
	local ProjectileHit = 	function(self, target, position)
								if not target then return end
								if target ~= nil and ( not target:IsMagicImmune() ) and ( not target:IsInvulnerable() ) and target:GetTeam() ~= self:GetCaster():GetTeam() then
									if not self.hitUnits[target:entindex()] then
										self:GetAbility():DealDamage( self:GetCaster(), target, self.damage )
										target:AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_boss_troll_warlord_dance_of_axes", {duration = self.blind})
										EmitSoundOn("Hero_TrollWarlord.WhirlingAxes.Target", target)
										
										self.hitUnits[target:entindex()] = true
									end
								end
								return true
							end
	
	local ProjectileThink = function(self, target, position)
								local position = self:GetPosition()
								local velocity = self:GetVelocity()
								if velocity.z > 0 then velocity.z = 0 end
								local angularVel = ( self.speed / self.range )
								direction = CalculateDirection( position, self:GetCaster() )
								
								self.range = self.range + self.radialSpeed * FrameTime()
								
								self.angle = self.angle + angularVel
								
								local newPosition = caster:GetAbsOrigin() + RotateVector2D(self:GetVelocity(), ToRadians( self.angle ) ) * self.range
								self:SetPosition( newPosition + Vector(0,0,128) )
							end
	ProjectileHandler:CreateProjectile(ProjectileThink, ProjectileHit, { FX = "particles/units/heroes/hero_troll_warlord/troll_warlord_whirling_axe_melee.vpcf",
																	  position = caster:GetAbsOrigin() + vDir * distance,
																	  caster = self:GetCaster(),
																	  ability = self,
																	  speed = speed,
																	  radius = radius,
																	  velocity = -vDir,
																	  duration = duration,
																	  hitUnits = {},
																	  range = distance,
																	  radialSpeed = maxRange / duration,
																	  angle = 0,
																	  damage = damage,
																	  blind = blind})
end

modifier_boss_troll_warlord_dance_of_axes = class({})
LinkLuaModifier("modifier_boss_troll_warlord_dance_of_axes", "bosses/boss_troll_warlord/boss_troll_warlord_dance_of_axes", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_troll_warlord_dance_of_axes:OnCreated()
	self.blind = self:GetSpecialValueFor("blind_pct")
end

function modifier_boss_troll_warlord_dance_of_axes:OnRefresh()
	self.blind = self:GetSpecialValueFor("blind_pct")
end

function modifier_boss_troll_warlord_dance_of_axes:DeclareFunctions()
	return {MODIFIER_PROPERTY_MISS_PERCENTAGE}
end

function modifier_boss_troll_warlord_dance_of_axes:GetModifierMiss_Percentage()
	return self.blind
end