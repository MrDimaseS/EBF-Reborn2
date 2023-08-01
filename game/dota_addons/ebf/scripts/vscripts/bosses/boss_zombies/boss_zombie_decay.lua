boss_zombie_decay = class({})


function boss_zombie_decay:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function boss_zombie_decay:OnSpellStart()
	self:Decay( self:GetCursorPosition() )
end

function boss_zombie_decay:Decay( position )
	local caster = self:GetCaster()
	
	local radius = self:GetSpecialValueFor("radius")
	local damage = self:GetSpecialValueFor("decay_damage")
	local duration = self:GetSpecialValueFor("decay_duration")
	local str = self:GetSpecialValueFor("str_steal")
	local creepMult = self:GetSpecialValueFor("creep_damage_multiplier")
	
	local enemies = caster:FindEnemyUnitsInRadius( position, radius) 
	for _, enemy in ipairs( enemies ) do
		
		if enemy:IsHero() then enemy:AddNewModifier(caster, self, "modifier_boss_zombie_decay_str", {duration = duration}) end
		self:DealDamage( caster, enemy, TernaryOperator( damage, enemy:IsConsideredHero(), (damage + str*20) * creepMult ) )
		
		ParticleManager:FireRopeParticle("particles/units/heroes/hero_undying/undying_decay_strength_xfer.vpcf", PATTACH_POINT_FOLLOW, enemy, caster)
	end
	
	caster:HealEvent( str * 20 * #enemies, self, caster )
	
	ParticleManager:FireParticle("particles/units/heroes/hero_undying/undying_decay.vpcf", PATTACH_WORLDORIGIN, nil, {[0] = position, [1] = Vector(radius,0,0)})
	EmitSoundOnLocationWithCaster( position, "Hero_Undying.Decay.Cast", caster )
end

modifier_boss_zombie_decay_str = class({})
LinkLuaModifier("modifier_boss_zombie_decay_str", "bosses/boss_zombies/boss_zombie_decay", LUA_MODIFIER_MOTION_NONE)

if IsServer() then
	function modifier_boss_zombie_decay_str:OnCreated()
		self:OnRefresh()
	end
	
	function modifier_boss_zombie_decay_str:OnRefresh()
		self.str = -self:GetSpecialValueFor("str_steal")
		self:AddIndependentStack( self:GetRemainingTime() )
		self:GetParent():CalculateStatBonus( true )
	end
end

function modifier_boss_zombie_decay_str:DeclareFunctions()
	return {MODIFIER_PROPERTY_EXTRA_STRENGTH_BONUS}
end

function modifier_boss_zombie_decay_str:GetModifierExtraStrengthBonus()
	return self:GetStackCount() * self.str
end

function modifier_boss_zombie_decay_str:GetEffectName()
	return "particles/units/heroes/hero_undying/undying_decay_strength_buff.vpcf"
end

function modifier_boss_zombie_decay_str:IsPurgable()
	return false
end
