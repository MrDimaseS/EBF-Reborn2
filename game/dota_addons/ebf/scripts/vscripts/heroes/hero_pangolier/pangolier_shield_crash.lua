pangolier_shield_crash = class({})

function pangolier_shield_crash:IsStealable()
	return true
end

function pangolier_shield_crash:IsHiddenWhenStolen()
	return false
end

function pangolier_shield_crash:GetCooldown( iLvl )
	if self:GetSpecialValueFor("rolling_thunder_cooldown") > 0 then
		if self:GetCaster():HasModifier("modifier_pangolier_gyroshell") then
			return self:GetSpecialValueFor("rolling_thunder_cooldown")
		end
	end
	return self.BaseClass.GetCooldown( self, iLvl )
end

function pangolier_shield_crash:OnSpellStart()
	local caster = self:GetCaster()

	EmitSoundOn("Hero_Pangolier.TailThump.Cast", caster)
	
	local duration = TernaryOperator( self:GetSpecialValueFor("jump_duration_gyroshell"), caster:HasModifier("modifier_pangolier_gyroshell"), self:GetSpecialValueFor("jump_duration") )
	caster:AddNewModifier(caster, self, "modifier_pangolier_shield_crash_jump", {})
	caster:AddNewModifier(caster, self, "modifier_pangolier_shield_crash_movement", {Duration = duration+0.5})
	
	if caster:HasScepter() then
		self:Strike(caster:GetForwardVector())
		self:Strike(-caster:GetForwardVector())
		self:Strike(caster:GetLeftVector())
		self:Strike(-caster:GetLeftVector())
		Timers:CreateTimer( 0.1, function()
		self:Strike(caster:GetForwardVector())
		self:Strike(-caster:GetForwardVector())
			self:Strike(caster:GetLeftVector())
			self:Strike(-caster:GetLeftVector())
		end)
	end
end

function pangolier_shield_crash:OnProjectileHit(hTarget, vLocation)
	local caster = self:GetCaster()

	if hTarget then
		local swashbuckle = caster:FindAbilityByName("pangolier_swashbuckle")
		if swashbuckle and not hTarget:IsAttackImmune() and not hTarget:IsMagicImmune() then
			EmitSoundOn("Hero_Pangolier.Swashbuckle.Damage", hTarget)
			caster:AddNewModifier( caster, swashbuckle, "modifier_pangolier_swashbuckle_attack", {} )
			caster:PerformAbilityAttack(hTarget, true, swashbuckle)
			caster:RemoveModifierByName("modifier_pangolier_swashbuckle_attack")
		end
	end
end


function pangolier_shield_crash:Strike(vDir)
	local caster = self:GetCaster()
	local swashbuckle = caster:FindAbilityByName("pangolier_swashbuckle")
	if not swashbuckle or swashbuckle:GetLevel() <= 0 then return end
	--Ability specials
	local range = swashbuckle:GetTalentSpecialValueFor("range")
	local width = swashbuckle:GetTalentSpecialValueFor("start_radius")

	local direction = vDir or caster:GetForwardVector()
	
	local startPos = caster:GetAbsOrigin() + direction * 100

	local endPos = startPos + direction * range

	EmitSoundOn("Hero_Pangolier.Swashbuckle", caster)
	EmitSoundOn("Hero_Pangolier.Swashbuckle.Attack", caster)

	--play slashing particle
	local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_pangolier/pangolier_swashbuckler.vpcf", PATTACH_POINT, caster)
				ParticleManager:SetParticleControl(nfx, 0, startPos)
				ParticleManager:SetParticleControl(nfx, 1, direction * range)

	self:FireLinearProjectile("", direction * 3000, range, width, {}, false, true, width)

	Timers:CreateTimer(0.45, function()
		ParticleManager:ClearParticle(nfx)
	end)
end

modifier_pangolier_shield_crash_movement = class({})
LinkLuaModifier("modifier_pangolier_shield_crash_movement", "heroes/hero_pangolier/pangolier_shield_crash", LUA_MODIFIER_MOTION_NONE)

function modifier_pangolier_shield_crash_movement:OnCreated()
	self.creep_shield = self:GetSpecialValueFor("creep_shield")
	self.hero_shield = self:GetSpecialValueFor("hero_shield")
	if IsServer() then
		local caster = self:GetCaster()
		local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_pangolier/pangolier_tailthump_cast.vpcf", PATTACH_POINT_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(nfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		self:AttachEffect(nfx)
		
		caster:RemoveModifierByName("modifier_pangolier_shield_crash_barrier")
		caster:RemoveModifierByName("modifier_pangolier_shield_crash_buff")
	end
end

function modifier_pangolier_shield_crash_movement:OnDestroy()
	local caster = self:GetCaster()
	if IsServer() then caster:RemoveModifierByName("modifier_pangolier_shield_crash_buff") end
end

function modifier_pangolier_shield_crash_movement:DeclareFunctions()
	return {MODIFIER_PROPERTY_OVERRIDE_ANIMATION, MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_pangolier_shield_crash_movement:OnTakeDamage(params)
	if params.inflictor == self:GetAbility() then
		local caster = self:GetCaster()
		local duration = self:GetTalentSpecialValueFor("duration")
		
		local damageBlock = TernaryOperator( self.hero_shield, params.unit:IsConsideredHero(), self.creep_shield )
		
		local buff = caster:AddNewModifier(caster, self:GetAbility(), "modifier_pangolier_shield_crash_barrier", {Duration = duration, damage_block = damageBlock})
	end
end

function modifier_pangolier_shield_crash_movement:GetOverrideAnimation()
	return ACT_DOTA_CAST_ABILITY_2
end

function modifier_pangolier_shield_crash_movement:IsHidden()
	return true
end

modifier_pangolier_shield_crash_barrier = class({})
LinkLuaModifier( "modifier_pangolier_shield_crash_barrier", "heroes/hero_pangolier/pangolier_shield_crash", LUA_MODIFIER_MOTION_NONE )

function modifier_pangolier_shield_crash_barrier:OnCreated(kv)
	if IsServer() then
		self.barrier = kv.damage_block
	end
	if IsServer() then self:SetHasCustomTransmitterData(true) end
end

function modifier_pangolier_shield_crash_barrier:OnRefresh(kv)
	if IsServer() then
		self.barrier = self.barrier + kv.damage_block
		self:SendBuffRefreshToClients()
	end
end

function modifier_pangolier_shield_crash_barrier:CheckState()
	return {[MODIFIER_STATE_DEBUFF_IMMUNE] = true}
end

function modifier_pangolier_shield_crash_barrier:DeclareFunctions()
	return { MODIFIER_PROPERTY_INCOMING_DAMAGE_CONSTANT }
end

function modifier_pangolier_shield_crash_barrier:GetModifierIncomingDamageConstant( params )
	if IsServer() then
		local barrier = math.min( self.barrier, math.max( self.barrier, params.damage ) )
		self.barrier = self.barrier - params.damage
		self:SendBuffRefreshToClients()
		EmitSoundOn( "Hero_Antimage.Counterspell.Absorb", self:GetParent() )
		return -barrier
	else
		return self.barrier
	end
end

function modifier_pangolier_shield_crash_barrier:AddCustomTransmitterData()
	return {barrier = self.barrier}
end

function modifier_pangolier_shield_crash_barrier:HandleCustomTransmitterData(data)
	self.barrier = data.barrier
end

function modifier_pangolier_shield_crash_barrier:GetEffectName()
	return "particles/units/heroes/hero_pangolier/pangolier_tailthump_buff.vpcf"
end