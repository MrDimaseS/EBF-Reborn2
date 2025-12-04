venomancer_venomous_gale = class({})

function venomancer_venomous_gale:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget() or self:GetCursorPosition()
	local speed = self:GetSpecialValueFor( "speed" )
	local width = self:GetSpecialValueFor( "radius" )
	local distance = self:GetTrueCastRange()

	EmitSoundOn( "Hero_Venomancer.VenomousGale", self:GetCaster() )

	local direction = CalculateDirection( target, caster )
	vDirection.z = 0.0
	vDirection = vDirection:Normalized()
	
	self:FireLinearProjectile( "particles/units/heroes/hero_venomancer/venomancer_venomous_gale.vpcf", direction * speed, )
end

--------------------------------------------------------------------------------

function venomancer_venomous_gale:OnProjectileHit( target, position )
	if target then
		local caster = self:GetCaster()
		target:RemoveModifierByName("modifier_venomancer_venomous_gale_cancer")
		target:AddNewModifier(self:GetCaster(), self, "modifier_venomancer_venomous_gale_cancer", {duration = self:GetSpecialValueFor("duration")})
		target:AddPoison(caster, self:GetSpecialValueFor("tick_damage") )
		EmitSoundOn( "Hero_Venomancer.VenomousGaleImpact", target )
		
		local damage = self:GetSpecialValueFor("strike_damage")
		local bonusPoisonDamage = self:GetSpecialValueFor("bonus_poison_strike_damage")
		if caster:IsRealHero( ) and self:GetSpecialValueFor("create_wards") > 0 and target:IsChampion() then
			local ward = caster:FindAbilityByName("venomancer_plague_ward")
			if ward and ward:IsTrained() then
				for i = 1, self:GetSpecialValueFor("create_wards") do
					local position  = target:GetAbsOrigin() + RandomVector(250)
					caster:SetCursorPosition( position )
					ward:OnSpellStart( )
				end
			end
		end
		
		local nFXIndex = ParticleManager:CreateParticle( "particles/units/heroes/hero_venomancer/venomancer_venomous_gale_impact.vpcf", PATTACH_ABSORIGIN_FOLLOW, target )
		ParticleManager:SetParticleControlForward( nFXIndex, 1, vDirection )
		ParticleManager:ReleaseParticleIndex( nFXIndex )
		
		self:DealDamage( caster, target, damage + bonusPoisonDamage * target:GetPoison(), {damage_type = DAMAGE_TYPE_MAGICAL} )
	end
	return false
end

LinkLuaModifier( "modifier_venomancer_venomous_gale_cancer", "heroes/hero_venomancer/venomancer_venomous_gale", LUA_MODIFIER_MOTION_NONE )
modifier_venomancer_venomous_gale_cancer = class({})

function modifier_venomancer_venomous_gale_cancer:OnCreated()
	self:OnRefresh()
	self:StartIntervalThink( self.tick )
end

function modifier_venomancer_venomous_gale_cancer:OnRefresh()
	self.movespeed = self:GetSpecialValueFor("movement_slow")
	self.msReduction = self.tick * self.movespeed / self:GetRemainingTime()
end

function modifier_venomancer_venomous_gale_cancer:OnDestroy()
	if IsServer() then
		local caster = self:GetCaster()
		local parent = self:GetParent()
		local ability = self:GetAbility()
		local damage = self:GetSpecialValueFor("explosion_damage") / 100
		if damage > 0 then
			ability:DealDamage( caster, parent, parent:GetPoison() * damage, {damage_type = DAMAGE_TYPE_MAGICAL} )
			ability:Stun( parent, self:GetSpecialValueFor("explosion_stun_duration") )
		end
	end
end

function modifier_venomancer_venomous_gale_cancer:OnIntervalThink()
	self.movespeed = math.min( self.movespeed - self.msReduction, 0 )
end

function modifier_venomancer_venomous_gale_cancer:DeclareFunctions()
	funcs = {
				MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE
			}
	return funcs
end

function modifier_venomancer_venomous_gale_cancer:GetModifierMoveSpeedBonus_Percentage()
	return self.movespeed
end

function modifier_venomancer_venomous_gale_cancer:GetEffectName()
	return "particles/units/heroes/hero_venomancer/venomancer_gale_poison_debuff.vpcf"
end