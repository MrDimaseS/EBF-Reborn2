witch_doctor_maledict = class({})

function witch_doctor_maledict:GetAOERadius()
	return self:GetTalentSpecialValueFor("radius")
end

function witch_doctor_maledict:OnSpellStart()
	local caster = self:GetCaster()
	
	local position = self:GetCursorPosition()
	local radius = self:GetTalentSpecialValueFor("radius")
	local duration = self:GetTalentSpecialValueFor("duration")
	
	EmitSoundOnLocationWithCaster(position, "Hero_WitchDoctor.Maledict_Cast", caster)

	ParticleManager:FireParticle("particles/units/heroes/hero_witchdoctor/witchdoctor_maledict_aoe.vpcf", PATTACH_WORLDORIGIN, nil, {[0] = position, [1] = Vector(radius,1,1)})
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( position, radius ) ) do
		enemy:AddNewModifier(caster, self, "modifier_witch_doctor_maledict_debuff", {duration = duration})
	end
end

modifier_witch_doctor_maledict_debuff = class({})
LinkLuaModifier("modifier_witch_doctor_maledict_debuff", "heroes/hero_witch_doctor/witch_doctor_maledict", LUA_MODIFIER_MOTION_NONE)

function modifier_witch_doctor_maledict_debuff:OnCreated()
	self.damage_taken = 0
	self.damage = self:GetTalentSpecialValueFor("damage")
	self.burst = self:GetTalentSpecialValueFor("bonus_damage") / 100
	if IsServer() then
		self.burstTimer = self:GetRemainingTime() / self:GetTalentSpecialValueFor("ticks")
		self.currentTime = GameRules:GetGameTime()
		self.hp = self:GetParent():GetHealth()
		self:StartIntervalThink( 1 )
		self:GetParent():EmitSound("Hero_WitchDoctor.Maledict_Loop")
		local maledictFX = ParticleManager:CreateParticle("particles/units/heroes/hero_witchdoctor/witchdoctor_maledict.vpcf", PATTACH_POINT_FOLLOW, self:GetParent())
		ParticleManager:SetParticleControl( maledictFX, 1, Vector(self.burstTimer,0,0) )
		self:AddEffect(maledictFX)
	end
end

function modifier_witch_doctor_maledict_debuff:OnIntervalThink()
	local ability = self:GetAbility()
	local parent = self:GetParent()
	local caster = self:GetCaster()
	
	ability:DealDamage( caster, parent, self.damage )
	if self.currentTime + self.burstTimer <= GameRules:GetGameTime() then
		self.currentTime = GameRules:GetGameTime()
		ability:DealDamage( caster, parent, self.damage_taken * self.burst, {damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_REFLECTION } )
		self.damage_taken = 0
		self:GetParent():EmitSound("Hero_WitchDoctor.Maledict_Tick")
	end
end

function modifier_witch_doctor_maledict_debuff:OnDestroy()
	if IsServer() then
		local ability = self:GetAbility()
		local parent = self:GetParent()
		local caster = self:GetCaster()
		self:GetParent():StopSound("Hero_WitchDoctor.Maledict_Loop")
		self:GetParent():EmitSound("Hero_WitchDoctor.Maledict_Tick")
		ability:DealDamage( caster, parent, self.damage_taken * self.burst, {damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION} )
	end
end

function modifier_witch_doctor_maledict_debuff:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_witch_doctor_maledict_debuff:OnTakeDamage( params )
	if params.unit == self:GetParent() and not HasBit( params.damage_flags, DOTA_DAMAGE_FLAG_REFLECTION ) then
		self.damage_taken = self.damage_taken + params.damage
	end
end

function modifier_witch_doctor_maledict_debuff:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_witch_doctor_maledict_debuff:IsPurgable()
	return false
end