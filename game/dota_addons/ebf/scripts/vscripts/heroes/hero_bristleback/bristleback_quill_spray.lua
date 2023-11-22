bristleback_quill_spray = class({})

function bristleback_quill_spray:IsStealable()
	return true
end

function bristleback_quill_spray:IsHiddenWhenStolen()
	return false
end

function bristleback_quill_spray:GetIntrinsicModifierName()
	return "modifier_bristleback_bristleback_autocast"
end

function bristleback_quill_spray:OnSpellStart()
	self:Spray()
end

function bristleback_quill_spray:Spray(bCone, direction)
	local caster = self:GetCaster()
	local target = target or caster
	
	local radius = self:GetSpecialValueFor("radius")
	local baseDamage = self:GetSpecialValueFor("quill_base_damage")
	local stackDamage = self:GetSpecialValueFor("quill_stack_damage")
	local maxDamage = self:GetSpecialValueFor("max_damage")
	local duration = self:GetSpecialValueFor("quill_stack_duration")
	
	EmitSoundOn("Hero_Bristleback.QuillSpray.Cast", caster)
	
	local enemies
	if bCone then
		enemies = caster:FindEnemyUnitsInCone( direction, caster:GetAbsOrigin(), radius/2, radius)
		local quillFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_bristleback/bristleback_quill_spray_conical.vpcf", PATTACH_WORLDORIGIN, nil )
		ParticleManager:SetParticleControl( quillFX, 0, caster:GetAbsOrigin() ) 
		ParticleManager:SetParticleControlTransformForward( quillFX, 0, caster:GetAbsOrigin(), -direction )
		ParticleManager:ReleaseParticleIndex( quillFX )
	else
		enemies = caster:FindEnemyUnitsInRadius(target:GetAbsOrigin(), radius)
		ParticleManager:FireParticle("particles/units/heroes/hero_bristleback/bristleback_quill_spray.vpcf", PATTACH_POINT, target)
	end
	
	for _, enemy in ipairs( enemies ) do
		local quillsDebuff = enemy:FindModifierByName("modifier_bristleback_quill_spray")
		local dmgTaken = baseDamage
		if quillsDebuff then
			dmgTaken = math.min( maxDamage, dmgTaken + quillsDebuff:GetStackCount() * stackDamage )
		end
		self:DealDamage( caster, enemy, dmgTaken, {damage_type = DAMAGE_TYPE_PHYSICAL} )
		
		enemy:AddNewModifier( caster, self.quills, "modifier_bristleback_quill_spray", {duration = duration}):IncrementStackCount()
		enemy:AddNewModifier( caster, self.quills, "modifier_bristleback_quill_spray_stack", {duration = duration})
		
		EmitSoundOn( "Hero_Bristleback.QuillSpray.Target", enemy )
	end
end

modifier_bristleback_bristleback_autocast = class({})
LinkLuaModifier( "modifier_bristleback_bristleback_autocast", "heroes/hero_bristleback/bristleback_quill_spray", LUA_MODIFIER_MOTION_NONE )

function modifier_bristleback_bristleback_autocast:OnCreated()
	if IsServer() then
		self:StartIntervalThink(0)
	end
end

function modifier_bristleback_bristleback_autocast:OnIntervalThink()
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	if ability:GetAutoCastState() and ability:IsFullyCastable() then
		caster:CastAbilityNoTarget( ability, caster:GetPlayerOwnerID() )
	end
end

function modifier_bristleback_bristleback_autocast:IsHidden()
	return false
end