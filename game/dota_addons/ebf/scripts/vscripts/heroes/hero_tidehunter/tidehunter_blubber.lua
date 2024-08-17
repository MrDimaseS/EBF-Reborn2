tidehunter_blubber = class({})

function tidehunter_blubber:GetIntrinsicModifierName()
	return "modifier_tidehunter_blubber_passive"
end

function tidehunter_blubber:ShouldUseResources()
	return true
end

LinkLuaModifier("modifier_tidehunter_blubber_passive", "heroes/hero_tidehunter/tidehunter_blubber", LUA_MODIFIER_MOTION_NONE)
modifier_tidehunter_blubber_passive = class({})

function modifier_tidehunter_blubber_passive:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink( 0.1 )
	end
end

function modifier_tidehunter_blubber_passive:OnRefresh()
	self.damage_cleanse = self:GetSpecialValueFor("damage_cleanse") / 100
	self.damage_reset_interval = self:GetSpecialValueFor("damage_reset_interval")
	self._damageTaken = 0
end

function modifier_tidehunter_blubber_passive:OnIntervalThink()
	self._damageTaken = 0
	self:StartIntervalThink( -1 )
end

function modifier_tidehunter_blubber_passive:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_tidehunter_blubber_passive:OnTakeDamage(params)
	if params.unit == self:GetParent() then
		if self._damageTaken > self.damage_cleanse * params.unit:GetMaxHealth() then
			EmitSoundOn( "Hero_Tidehunter.KrakenShell", self:GetParent() )
			self:GetCaster():Dispel( self:GetCaster(), true )
			ParticleManager:FireParticle("particles/units/heroes/hero_tidehunter/tidehunter_krakenshell_purge.vpcf", PATTACH_POINT_FOLLOW, params.unit)
			self:OnIntervalThink( )
		else
			self._damageTaken = self._damageTaken + params.damage
			self:StartIntervalThink( self.damage_reset_interval )
		end
	end
end

function modifier_tidehunter_blubber_passive:IsHidden()
	return true
end

function modifier_tidehunter_blubber_passive:IsPurgable()
	return false
end