abaddon_aphotic_shield = class({})

function abaddon_aphotic_shield:IsStealable()
	return true
end

function abaddon_aphotic_shield:IsHiddenWhenStolen()
	return false
end

function abaddon_aphotic_shield:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget() or caster
	target:Dispel(caster, true)
	target:RemoveModifierByName("modifier_abaddon_aphotic_shield_buff")
	
	target:AddNewModifier(caster, self, "modifier_abaddon_aphotic_shield_buff", {duration = self:GetSpecialValueFor("duration")})
end


modifier_abaddon_aphotic_shield_buff = class({})
LinkLuaModifier("modifier_abaddon_aphotic_shield_buff", "heroes/hero_abaddon/abaddon_aphotic_shield", LUA_MODIFIER_MOTION_NONE)

function modifier_abaddon_aphotic_shield_buff:OnCreated()
	self.radius = self:GetSpecialValueFor("radius")
	self.absorbed_to_damage = self:GetSpecialValueFor("absorbed_to_damage") / 100
	if IsServer() then
		self.absorb = self:GetSpecialValueFor("damage_absorb") * (1+self:GetCaster():GetSpellAmplification( false ))
		self.original_absorb = self.absorb
		local nFX = ParticleManager:CreateParticle("particles/units/heroes/hero_abaddon/abaddon_aphotic_shield.vpcf", PATTACH_POINT_FOLLOW, self:GetParent())
		local sRadius = self:GetParent():GetModelRadius() * 0.6 + 25
		local vFX = Vector(sRadius,0,sRadius)
		ParticleManager:SetParticleControlEnt(nFX, 0, self:GetParent(), PATTACH_POINT_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
		ParticleManager:SetParticleControl(nFX, 1, vFX)
		ParticleManager:SetParticleControl(nFX, 2, vFX)
		ParticleManager:SetParticleControl(nFX, 4, vFX)
		ParticleManager:SetParticleControl(nFX, 5, vFX)
		self:AddEffect(nFX)
		
		self:SetHasCustomTransmitterData(true)
	end
end

function modifier_abaddon_aphotic_shield_buff:OnDestroy()
	if IsServer() then
		local caster = self:GetCaster()
		local parent = self:GetParent()
		
		EmitSoundOn("Hero_Abaddon.AphoticShield.Destroy", parent)
		local enemies = caster:FindEnemyUnitsInRadius(parent:GetAbsOrigin(), self.radius)
		local damage = (self.original_absorb - self.absorb) * self.absorbed_to_damage
		for _, enemy in ipairs( enemies ) do
			if not enemy:TriggerSpellAbsorb(self:GetAbility()) then
				self:GetAbility():DealDamage(caster, enemy, damage, {damage_type = DAMAGE_TYPE_MAGICAL, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION})
			end
		end
	end
end

function modifier_abaddon_aphotic_shield_buff:DeclareFunctions(params)
	local funcs = {
		MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT
    }
    return funcs
end

function modifier_abaddon_aphotic_shield_buff:GetModifierIncomingDamageConstant( params )
	if IsServer() then
		local absorb = math.min( self.absorb, math.max( self.absorb, params.damage ) )
		self.absorb = math.max( self.absorb - params.damage, 0 )
		if self.absorb <= 0 then 
			self:Destroy()
			return
		end
		self:SendBuffRefreshToClients()
		return -absorb
	else
		return self.absorb
	end
end

function modifier_abaddon_aphotic_shield_buff:AddCustomTransmitterData()
	return {absorb = self.absorb}
end

function modifier_abaddon_aphotic_shield_buff:HandleCustomTransmitterData(data)
	self.absorb = data.absorb
end