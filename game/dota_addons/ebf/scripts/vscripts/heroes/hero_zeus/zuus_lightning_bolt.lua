zuus_lightning_bolt = class({})

function zuus_lightning_bolt:GetAOERadius()
	if self:GetSpecialValueFor("aoe") > 0 then
		return self:GetSpecialValueFor("aoe")
	else
		return self:GetSpecialValueFor("spread_aoe")
	end
end

function zuus_lightning_bolt:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	local point = self:GetCursorPosition()

	if not target then
		local enemies = caster:FindEnemyUnitsInRadius(point, self:GetSpecialValueFor("spread_aoe"), {order=FIND_CLOSEST})
		if enemies[1] then
			target = enemies[1]
			point = target:GetAbsOrigin()
		end
	end
	if target then
		point = target:GetAbsOrigin()
	else
		target = point
	end
	
	EmitSoundOn("Hero_Zuus.LightningBolt.Cast", caster)
	EmitSoundOnLocationWithCaster(point, "Hero_Zuus.LightningBolt", caster)	
	
	local buffDur = self:GetSpecialValueFor("buff_duration")
	if buffDur > 0 then
		caster:AddNewModifier( caster, self, "modifier_zuus_lightning_bolt_brontaios", {duration = buffDur})
	end
	
	local cloudDur = self:GetSpecialValueFor("cloud_duration")
	if cloudDur > 0 then
		local cloud = caster:CreateSummon("npc_dota_zeus_cloud", self:GetCursorPosition(), cloudDur)
		cloud:AddNewModifier(caster, self, "modifier_zuus_lightning_bolt_olympios", {})
	end
	
	local cdr_on_hit = self:GetSpecialValueFor("cdr_on_hit")
	if cdr_on_hit > 0 then
		caster:AddNewModifier( caster, self, "modifier_zuus_lightning_bolt_areios", {duration = self:GetCooldownTimeRemaining() })
	end
	
	
	
	self:LightningBolt( target )
end

function zuus_lightning_bolt:LightningBolt( target, source, flDamage )
	local caster = self:GetCaster()
	local point = target
	
	-- unit was targeted
	if target.GetAbsOrigin then
		point = target:GetAbsOrigin()
		if target:TriggerSpellAbsorb( self ) then return end
		
		local damage = flDamage or self:GetSpecialValueFor("damage")
		local stunDur = self:GetSpecialValueFor("ministun_duration")
		local creep_damage_bonus_pct = 1 + self:GetSpecialValueFor("creep_damage_bonus_pct") / 100
		
		self:DealDamage( caster, target, damage * TernaryOperator( 1, target:IsConsideredHero(), creep_damage_bonus_pct ) )
		self:Stun(target, stunDur, false)
		
		local aoe = self:GetSpecialValueFor("aoe")
		if aoe > 0 then
			for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( point, aoe ) ) do
				if enemy ~= target then
					self:DealDamage( caster, enemy, damage * TernaryOperator( 1, target:IsConsideredHero(), creep_damage_bonus_pct ) )
					self:Stun(target, stunDur, false)
				end
			end
		end
	end
	
	ParticleManager:FireRopeParticle("particles/units/heroes/hero_zuus/zuus_smaller_lightning_bolt.vpcf", PATTACH_POINT, source or caster, point, {[0]=point+Vector(0,0,1000)})
	AddFOWViewer(caster:GetTeam(), point, self:GetSpecialValueFor("vision_radius"), self:GetSpecialValueFor("vision_duration"), false)
end

LinkLuaModifier("modifier_zuus_lightning_bolt_brontaios", "heroes/hero_zeus/zuus_lightning_bolt", LUA_MODIFIER_MOTION_NONE)
modifier_zuus_lightning_bolt_brontaios = class({})

function modifier_zuus_lightning_bolt_brontaios:OnCreated()
	self:OnRefresh()
end

function modifier_zuus_lightning_bolt_brontaios:OnRefresh()
	self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
end

function modifier_zuus_lightning_bolt_brontaios:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT}
end

function modifier_zuus_lightning_bolt_brontaios:GetModifierAttackSpeedBonus_Constant() 
	return self.bonus_attack_speed
end

LinkLuaModifier("modifier_zuus_lightning_bolt_areios", "heroes/hero_zeus/zuus_lightning_bolt", LUA_MODIFIER_MOTION_NONE)
modifier_zuus_lightning_bolt_areios = class({})

function modifier_zuus_lightning_bolt_areios:OnCreated()
	self:OnRefresh()
end

function modifier_zuus_lightning_bolt_areios:OnRefresh()
	self.cdr_on_hit = self:GetSpecialValueFor("cdr_on_hit")
end

function modifier_zuus_lightning_bolt_areios:DeclareFunctions()
	return {MODIFIER_EVENT_ON_TAKEDAMAGE, MODIFIER_PROPERTY_TOOLTIP }
end

function modifier_zuus_lightning_bolt_areios:OnTakeDamage(params) 
	if params.unit ~= self:GetParent() then return end
	self:GetAbility():ModifyCooldown( -self.cdr_on_hit )
end

function modifier_zuus_lightning_bolt_areios:OnTooltip(params) 
	return self.cdr_on_hit
end

LinkLuaModifier("modifier_zuus_lightning_bolt_olympios", "heroes/hero_zeus/zuus_lightning_bolt", LUA_MODIFIER_MOTION_NONE)
modifier_zuus_lightning_bolt_olympios = class({})

function modifier_zuus_lightning_bolt_olympios:OnCreated(table)
	if IsServer() then
		local caster = self:GetCaster()
		local cloud = self:GetParent()
		local radius = self:GetSpecialValueFor("spread_aoe")
		
		self.damage = self:GetSpecialValueFor("damage") * self:GetSpecialValueFor("cloud_dmg_pct") / 100
		self.radius = radius
		
		local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_zeus/zeus_cloud.vpcf", PATTACH_POINT_FOLLOW, cloud)
		ParticleManager:SetParticleControl(nfx, 0, cloud:GetAbsOrigin())
		ParticleManager:SetParticleControl(nfx, 1, Vector(radius,radius,radius))
		ParticleManager:SetParticleControlEnt(nfx, 2, cloud, PATTACH_POINT_FOLLOW, "attach_hitloc", cloud:GetAbsOrigin(), true)
		ParticleManager:SetParticleControl(nfx, 5, cloud:GetAbsOrigin())
		self:AttachEffect(nfx)

		self:StartIntervalThink( self:GetSpecialValueFor("cloud_bolt_interval") )
	end
end

function modifier_zuus_lightning_bolt_olympios:OnIntervalThink()
	local caster = self:GetCaster()
	local cloud = self:GetParent()

	local enemies = caster:FindEnemyUnitsInRadius(cloud:GetAbsOrigin(), self.radius)
	EmitSoundOn("Hero_Zuus.LightningBolt.Cloud", cloud)
	for _,enemy in pairs(enemies) do
		self:GetAbility():LightningBolt( enemy, cloud, self.damage )
		return
	end
	self:GetAbility():LightningBolt( cloud:GetAbsOrigin() + ActualRandomVector( self.radius ) )
end

function modifier_zuus_lightning_bolt_olympios:CheckState()
	local state = { [MODIFIER_STATE_INVULNERABLE] = true,
					[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
					[MODIFIER_STATE_INVISIBLE] = true,
					[MODIFIER_STATE_COMMAND_RESTRICTED] = true,
					[MODIFIER_STATE_UNSELECTABLE] = true,
					[MODIFIER_STATE_NO_HEALTH_BAR] = true,
					[MODIFIER_STATE_UNTARGETABLE] = true,}
	return state
end

function modifier_zuus_lightning_bolt_olympios:IsHidden()
	return true
end