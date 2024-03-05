boss_demonic_cultist_upheaval = class({})

function boss_demonic_cultist_upheaval:GetAOERadius()
	return self:GetSpecialValueFor("aoe")
end

function boss_demonic_cultist_upheaval:OnSpellStart()
	local caster = self:GetCaster()
	local position = self:GetCursorPosition()
	
	CreateModifierThinker( caster, self, "modifier_boss_demonic_cultist_upheaval", {duration = self:GetChannelTime()}, position, caster:GetTeamNumber(), false)
end

modifier_boss_demonic_cultist_upheaval = class({})
LinkLuaModifier( "modifier_boss_demonic_cultist_upheaval", "bosses/boss_warlocks/boss_demonic_cultist_upheaval", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_demonic_cultist_upheaval:OnCreated()
	self.radius = self:GetAbility():GetAOERadius()
	self.duration = self:GetSpecialValueFor("duration")
	self.damage_tick_interval = self:GetSpecialValueFor("damage_tick_interval")
	self.imps_interval = self:GetSpecialValueFor("imps_interval")
	self.time_to_imp = self.imps_interval
	if IsServer() then
		local nfx = ParticleManager:CreateParticle( "particles/units/heroes/hero_warlock/warlock_upheaval.vpcf", PATTACH_ABSORIGIN_FOLLOW, self:GetParent() )
		ParticleManager:SetParticleControl( nfx, 0, self:GetParent():GetAbsOrigin() )
		ParticleManager:SetParticleControl( nfx, 1, Vector( self.radius, 0, 0 ) )
		self:AddEffect( nfx )
		self:StartIntervalThink( self.damage_tick_interval )
		
		EmitSoundOn( "Hero_Warlock.Upheaval", self:GetParent() )
	end
end

function modifier_boss_demonic_cultist_upheaval:OnIntervalThink()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	if not caster:IsChanneling() then
		self:Destroy()
		return
	end
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( parent:GetAbsOrigin(), self.radius ) ) do
		local debuff = enemy:FindModifierByName( "modifier_boss_demonic_cultist_upheaval_debuff" )
		if debuff then
			debuff:IncrementStackCount()
		end
	end
	self.time_to_imp = self.time_to_imp - self.damage_tick_interval
	if self.time_to_imp <= 0 then
		self.time_to_imp = self.imps_interval
		for _, enemy in ipairs( HeroList:GetActiveHeroes() ) do
			CreateUnitByNameAsync( "npc_dota_minion_demonic_imp", parent:GetAbsOrigin() + ActualRandomVector( self.radius ), true, nil, nil, caster:GetTeamNumber(),
			function(entUnit)
				entUnit:MoveToTargetToAttack( enemy )
			end)
		end
	end
end

function modifier_boss_demonic_cultist_upheaval:OnDestroy()
	if not IsServer() then return end
	StopSoundOn( "Hero_Warlock.Upheaval", self:GetParent() )
end

function modifier_boss_demonic_cultist_upheaval:IsAura()
	return true
end

function modifier_boss_demonic_cultist_upheaval:GetModifierAura()
	return "modifier_boss_demonic_cultist_upheaval_debuff"
end

function modifier_boss_demonic_cultist_upheaval:GetAuraRadius()
	return self.radius
end

function modifier_boss_demonic_cultist_upheaval:GetAuraSearchTeam()
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_boss_demonic_cultist_upheaval:GetAuraSearchType()
	return DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
end

modifier_boss_demonic_cultist_upheaval_debuff = class({})
LinkLuaModifier( "modifier_boss_demonic_cultist_upheaval_debuff", "bosses/boss_warlocks/boss_demonic_cultist_upheaval", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_demonic_cultist_upheaval_debuff:OnCreated()
	self.damage_per_second = self:GetSpecialValueFor("damage_per_second")
	self.max_damage = self:GetSpecialValueFor("max_damage")
	self.slow_per_second = self:GetSpecialValueFor("slow_per_second")
	self.max_slow = self:GetSpecialValueFor("max_slow")
	self.damage_tick_interval = self:GetSpecialValueFor("damage_tick_interval")
	if IsServer() then
		self:StartIntervalThink( self.damage_tick_interval )
	end
end

function modifier_boss_demonic_cultist_upheaval_debuff:OnIntervalThink()
	self:GetAbility():DealDamage( self:GetCaster(), self:GetParent(), math.min( self.damage_per_second * self:GetStackCount(), self.max_damage ) )
end

function modifier_boss_demonic_cultist_upheaval_debuff:DeclareFunctions()
	return {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
end

function modifier_boss_demonic_cultist_upheaval_debuff:GetModifierMoveSpeedBonus_Percentage()
	return -math.min( self.slow_per_second * self:GetStackCount(), self.max_slow )
end