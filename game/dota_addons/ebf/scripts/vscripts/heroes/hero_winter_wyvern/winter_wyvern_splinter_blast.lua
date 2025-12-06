winter_wyvern_splinter_blast = class({})

function winter_wyvern_splinter_blast:OnSpellStart()
    local target = self:GetCursorTarget()
    self:SplinterBlast( target )
end

function winter_wyvern_splinter_blast:SplinterBlast(target, source)
    local caster = self:GetCaster()
	
	local projectileSource = (source or caster)
	local secondary = projectileSource ~= caster
    local speed = math.max( self:GetSpecialValueFor("projectile_speed"), CalculateDistance( target, caster ) / self:GetSpecialValueFor("projectile_max_time") )
	local projectileFX = "particles/units/heroes/hero_winter_wyvern/wyvern_splinter.vpcf"
	if secondary then
		projectileFX = "particles/units/heroes/hero_winter_wyvern/wyvern_splinter_blast.vpcf"
		speed = self:GetSpecialValueFor("secondary_projectile_speed")
	end
    local projectile = self:FireTrackingProjectile(projectileFX, target, speed, {source = projectileSource})
	self._projectiles = self._projectiles or {}
	self._projectiles[projectile] = {secondary = secondary}
    EmitSoundOn("Hero_Winter_Wyvern.SplinterBlast.Cast", caster)
    EmitSoundOn("Hero_Winter_Wyvern.SplinterBlast.Projectile", caster)
end

function winter_wyvern_splinter_blast:OnProjectileHitHandle(target, position, projectile)
	if target then
		local caster = self:GetCaster()
		local projectileData = self._projectiles[projectile]
		if not projectileData then return end
		local damage = self:GetSpecialValueFor("damage")
		local duration = self:GetSpecialValueFor("duration")
		local stunDuration = self:GetSpecialValueFor("stun_duration")
		local primaryDamage = damage * self:GetSpecialValueFor("primary_target_dmg") / 100
		if projectileData.secondary then
			self:DealDamage( caster, target, damage )
			target:AddNewModifier(caster, self, "modifier_winter_wyvern_splinter_blast_debuff", {duration = duration})
			if stunDuration > 0 then self:Stun( target, stunDuration ) end
			EmitSoundOn("Hero_Winter_Wyvern.SplinterBlast.Splinter", target )
		else
			local splitRadius = self:GetSpecialValueFor("split_radius")
			local coldEmbraceDuration = self:GetSpecialValueFor("cold_embrace_duration")
			EmitSoundOn("Hero_Winter_Wyvern.SplinterBlast.Target", target )
			for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), splitRadius ) ) do
				if enemy ~= target then
					self:SplinterBlast( enemy, target )
				elseif primaryDamage > 0 then
					self:DealDmage( caster, target, primaryDamage )
					target:AddNewModifier(caster, self, "modifier_winter_wyvern_splinter_blast_debuff", {duration = duration})
					if stunDuration > 0 then self:Stun( target, stunDuration ) end
				end
			end
			if coldEmbraceDuration > 0 and target:IsSameTeam( caster ) then
				self._coldEmbrace = self._coldEmbrace or caster:FindAbilityByName("winter_wyvern_cold_embrace")
				if IsEntitySafe( self._coldEmbrace ) and self._coldEmbrace:IsTrained() then
					self._coldEmbrace:ColdEmbrace( target, coldEmbraceDuration )
				else
					self._coldEmbrace = nil
				end
			end
		end
	end
end

modifier_winter_wyvern_splinter_blast_debuff = class({})
LinkLuaModifier("modifier_winter_wyvern_splinter_blast_debuff", "heroes/hero_winter_wyvern/winter_wyvern_splinter_blast", LUA_MODIFIER_MOTION_NONE)

function modifier_winter_wyvern_splinter_blast_debuff:OnCreated()
	self.bonus_movespeed = self:GetSpecialValueFor("bonus_movespeed")
	
	self.proc_splinter_on_death = self:GetSpecialValueFor("proc_splinter_on_death") == 1
	
	self.bonus_damage_proc = self:GetSpecialValueFor("bonus_damage_proc")
	self.bonus_damage_proc_cd = self:GetSpecialValueFor("bonus_damage_proc_cd")
	self.last_damage_proc = 0
end

function modifier_winter_wyvern_splinter_blast_debuff:OnDestroy()
	if IsClient() then return end
	if not self.proc_splinter_on_death then return end
	local parent = self:GetParent()
	if parent:IsAlive() then return end
	self:GetAbility():SplinterBlast( parent, parent )
end

function modifier_winter_wyvern_splinter_blast_debuff:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
			MODIFIER_EVENT_ON_TAKEDAMAGE}
end
	
function modifier_winter_wyvern_splinter_blast_debuff:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_movespeed
end

function modifier_winter_wyvern_splinter_blast_debuff:OnTakeDamage( params )
	if self.bonus_damage_proc_cd == 0 then return end
	if GameRules:GetGameTime() < self.last_damage_proc + self.bonus_damage_proc_cd then return end
	local parent = self:GetParent()
	if params.unit ~= parent then return end
	self.last_damage_proc = GameRules:GetGameTime()
	self:GetAbility():DealDamage( self:GetCaster(), parent, self.bonus_damage_proc, {}, OVERHEAD_ALERT_BONUS_SPELL_DAMAGE )
end
