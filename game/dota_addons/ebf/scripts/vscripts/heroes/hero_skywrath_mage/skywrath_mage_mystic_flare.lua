skywrath_mage_mystic_flare = class({})

function skywrath_mage_mystic_flare:GetAOERadius()
	return self:GetTalentSpecialValueFor("radius")
end

function skywrath_mage_mystic_flare:OnSpellStart()
	local caster = self:GetCaster()
	local point = self:GetCursorPosition()

	local radius = self:GetTalentSpecialValueFor("radius")

	local damage_interval = self:GetTalentSpecialValueFor("damage_interval")
	local duration = self:GetTalentSpecialValueFor("duration")

	EmitSoundOn("Hero_SkywrathMage.MysticFlare.Cast", caster)

	local enemiesHit = {} 
	for _, enemy in ipairs( caster:FindEnemyUnitsInRadius(point, radius, {order=FIND_CLOSEST}) ) do
		enemiesHit[enemy] = true
	end

	CreateModifierThinker(caster, self, "modifier_skywrath_mage_mystic_flare_thinker", {duration = duration, ignoreStatusAmp = true}, point, caster:GetTeam(), false)

	if caster:HasScepter() then
		local scepter_radius = self:GetTalentSpecialValueFor("scepter_radius")
		local enemies = caster:FindEnemyUnitsInRadius(caster:GetAbsOrigin(), self:GetTrueCastRange(), {order=FIND_CLOSEST})
		for _,enemy in pairs(enemies) do
			if not enemiesHit[enemy] then
				CreateModifierThinker(caster, self, "modifier_skywrath_mage_mystic_flare_thinker", {duration = duration}, enemy:GetAbsOrigin(), caster:GetTeam(), false)
				return
			end
		end
        local pointRando = point + ActualRandomVector(125, scepter_radius)
        CreateModifierThinker(caster, self, "modifier_skywrath_mage_mystic_flare_thinker", {duration = duration}, pointRando, caster:GetTeam(), false)
    end
end

modifier_skywrath_mage_mystic_flare_thinker = class({})
LinkLuaModifier( "modifier_skywrath_mage_mystic_flare_thinker","heroes/hero_skywrath_mage/skywrath_mage_mystic_flare.lua",LUA_MODIFIER_MOTION_NONE )
function modifier_skywrath_mage_mystic_flare_thinker:OnCreated(table)
	self.damage_interval = self:GetTalentSpecialValueFor("damage_interval")
	self.damage = self:GetTalentSpecialValueFor("damage") / self:GetTalentSpecialValueFor("duration")
	self.radius = self:GetTalentSpecialValueFor("radius")
	
	if IsServer() then
		EmitSoundOn("Hero_SkywrathMage.MysticFlare", self:GetParent())
		self:StartIntervalThink(self.damage_interval)
		
		self.point = self:GetParent():GetAbsOrigin()
		
		self.nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_skywrath_mage/skywrath_mage_mystic_flare_ambient.vpcf", PATTACH_POINT, self:GetParent() )
		ParticleManager:SetParticleControl( self.nfx, 1, Vector( self.radius, 30, self.damage_interval ) )
		
	end
end

function modifier_skywrath_mage_mystic_flare_thinker:OnRemoved()
	if IsServer() then
		StopSoundOn("Hero_SkywrathMage.MysticFlare", self:GetParent())
		ParticleManager:ClearParticle( self.nfx )
	end
end

function modifier_skywrath_mage_mystic_flare_thinker:OnIntervalThink()
    local enemies = self:GetCaster():FindEnemyUnitsInRadius(self:GetParent():GetAbsOrigin(), self.radius)
	local caster = self:GetCaster()
	local ability = self:GetAbility()
    for _,enemy in pairs(enemies) do
    	EmitSoundOn("Hero_SkywrathMage.MysticFlare.Target", enemy)
		ability:DealDamage(caster, enemy, self.damage * self.damage_interval / #enemies)
    end
end

function modifier_skywrath_mage_mystic_flare_thinker:DeclareFunctions()
	if self:GetCaster():HasTalent("special_bonus_unique_skywrath_mage_mystic_flare_2") then
		return {MODIFIER_EVENT_ON_TAKEDAMAGE}
	end
end

function modifier_skywrath_mage_mystic_flare_thinker:OnTakeDamage( params )
	if params.unit == self:GetCaster() then
		local damage = params.original_damage
		local modifiedDuration = params.original_damage/(self.damage)
		self:SetDuration( self:GetRemainingTime() + modifiedDuration, false )
	end
end