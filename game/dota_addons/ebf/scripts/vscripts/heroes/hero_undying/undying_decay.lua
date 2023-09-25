undying_decay = class({})

function undying_decay:GetAOERadius()
	return self:GetTalentSpecialValueFor("radius")
end

function undying_decay:OnSpellStart()
	self:Decay( self:GetCursorPosition() )
end

function undying_decay:Decay( position )
	local caster = self:GetCaster()
	
	local radius = self:GetTalentSpecialValueFor("radius")
	local damage = self:GetTalentSpecialValueFor("decay_damage")
	local duration = self:GetTalentSpecialValueFor("decay_duration")
	local creep_mult = self:GetTalentSpecialValueFor("creep_damage_multiplier")
	local str = self:GetTalentSpecialValueFor("str_steal")
	
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( position, radius) ) do
		local endDamage = damage
		if enemy:IsConsideredHero() then
			caster:AddNewModifier(caster, self, "modifier_undying_decay_str", {duration = duration})
			ParticleManager:FireRopeParticle("particles/units/heroes/hero_undying/undying_decay_strength_xfer.vpcf", PATTACH_POINT_FOLLOW, enemy, caster)
		else
			endDamage = damage * creep_mult
		end
		self:DealDamage( caster, enemy, endDamage )
	end
	
	ParticleManager:FireParticle("particles/units/heroes/hero_undying/undying_decay.vpcf", PATTACH_WORLDORIGIN, nil, {[0] = position, [1] = Vector(radius,0,0)})
	EmitSoundOnLocationWithCaster( position, "Hero_Undying.Decay.Cast", caster )
end

modifier_undying_decay_str = class({})
LinkLuaModifier("modifier_undying_decay_str", "heroes/hero_undying/undying_decay", LUA_MODIFIER_MOTION_NONE)

if IsServer() then
	function modifier_undying_decay_str:OnCreated()
		self:OnRefresh()
	end
	
	function modifier_undying_decay_str:OnRefresh()
		self:AddIndependentStack( self:GetRemainingTime() )
		self:GetParent():CalculateStatBonus( true )
		
		self:GetParent():HealEvent( self:GetSpecialValueFor("str_steal") * 20, self:GetAbility(), self:GetCaster() )
	end
end

function modifier_undying_decay_str:DeclareFunctions()
	return {MODIFIER_PROPERTY_EXTRA_STRENGTH_BONUS}
end

function modifier_undying_decay_str:GetModifierExtraStrengthBonus()
	return self:GetStackCount() * self:GetSpecialValueFor("str_steal")
end

function modifier_undying_decay_str:GetEffectName()
	return "particles/units/heroes/hero_undying/undying_decay_strength_buff.vpcf"
end

function modifier_undying_decay_str:IsPurgable()
	return false
end