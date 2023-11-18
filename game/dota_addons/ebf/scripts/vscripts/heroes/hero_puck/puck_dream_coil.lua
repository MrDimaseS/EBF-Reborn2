puck_dream_coil = class({})

function puck_dream_coil:OnSpellStart()
	local caster = self:GetCaster()
	local position = self:GetCursorPosition()
	self:DreamCoil(position)
end

function puck_dream_coil:OnProjectileHit(target, position)
	if target then
		self:GetCaster():PerformGenericAttack(target, true)
	end
end

function puck_dream_coil:DreamCoil(position)
	local caster = self:GetCaster()
	local vPos = GetGroundPosition(position, caster)
	
	EmitSoundOnLocationWithCaster(vPos, "Hero_Puck.Dream_Coil", caster)
	CreateModifierThinker(caster, self, "modifier_puck_dream_coil_coil", {duration = self:GetSpecialValueFor("coil_duration")}, vPos, caster:GetTeam(), false)
end

modifier_puck_dream_coil_coil = class({})
LinkLuaModifier("modifier_puck_dream_coil_coil", "heroes/hero_puck/puck_dream_coil", LUA_MODIFIER_MOTION_NONE)

if IsServer() then
	function modifier_puck_dream_coil_coil:OnCreated()
		self.radius = self:GetSpecialValueFor("coil_break_radius")
		self.damage = self:GetSpecialValueFor("coil_break_damage")
		self.duration = self:GetSpecialValueFor("coil_stun_duration")
		
		local ability = self:GetAbility()
		local parent = self:GetParent()
		local caster = self:GetCaster()
		
		if caster:HasScepter() then
			self.attackRate = caster:GetSecondsPerAttack()
		end
		
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius(parent:GetAbsOrigin(), self.radius) ) do
			if not enemy:TriggerSpellAbsorb( self ) then
				enemy:AddNewModifier(caster, ability, "modifier_puck_dream_coil_tether", {duration = self:GetSpecialValueFor("coil_duration"), entindex = parent:entindex()})
			end
		end
		self:StartIntervalThink(0)
	end
	
	function modifier_puck_dream_coil_coil:OnIntervalThink()
		local ability = self:GetAbility()
		local parent = self:GetParent()
		local caster = self:GetCaster()
		
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius(parent:GetAbsOrigin(), -1) ) do
			if enemy:HasModifier("modifier_puck_dream_coil_tether") and CalculateDistance(enemy, parent) > self.radius then
				EmitSoundOn("Hero_Puck.Dream_Coil_Snap", enemy)
				enemy:RemoveModifierByName("modifier_puck_dream_coil_tether")
				ability:Stun(enemy, self.duration)
				ability:DealDamage(caster, enemy, self.damage)
			end
		end
		
		if self.attackRate then
			self.attackRate = self.attackRate - FrameTime()
			if self.attackRate <= 0 then
				self.attackRate = caster:GetSecondsPerAttack()
				for _, enemy in ipairs( caster:FindEnemyUnitsInRadius(parent:GetAbsOrigin(), self.radius) ) do
					ability:FireTrackingProjectile(caster:GetRangedProjectileName(), enemy, caster:GetProjectileSpeed(), {source = parent, origin = parent:GetAbsOrigin()})
				end
			end
		end
	end
end

modifier_puck_dream_coil_tether = class({})
LinkLuaModifier("modifier_puck_dream_coil_tether", "heroes/hero_puck/puck_dream_coil", LUA_MODIFIER_MOTION_NONE)

function modifier_puck_dream_coil_tether:OnCreated(kv)
	if IsServer() then
		local caster = EntIndexToHScript(tonumber(kv.entindex))
		local parent = self:GetParent()
		local ability = self:GetAbility()
		
		ability:Stun(parent, self:GetSpecialValueFor("stun_duration"))
		ability:DealDamage(caster, parent, self:GetSpecialValueFor("coil_initial_damage"))
		
		local FX = ParticleManager:CreateParticle("particles/units/heroes/hero_puck/puck_dreamcoil_tether.vpcf", PATTACH_POINT_FOLLOW, caster)
		ParticleManager:SetParticleControlEnt(FX, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(FX, 1, parent, PATTACH_POINT_FOLLOW, "attach_hitloc", parent:GetAbsOrigin(), true)
		self:AddEffect(FX)
	end
end