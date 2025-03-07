riki_tricks_of_the_trade = class({})

function riki_tricks_of_the_trade:IsStealable()
    return true
end

function riki_tricks_of_the_trade:IsHiddenWhenStolen()
    return false
end

function riki_tricks_of_the_trade:GetChannelTime()
	return self:GetSpecialValueFor("duration")
end

function riki_tricks_of_the_trade:GetAOERadius()
	return self:GetSpecialValueFor("radius")
end

function riki_tricks_of_the_trade:GetBehavior()
	local behavior = DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_CHANNELLED
	if self:GetSpecialValueFor("target_allies") == 1 then
		behavior = behavior + DOTA_ABILITY_BEHAVIOR_UNIT_TARGET + DOTA_ABILITY_BEHAVIOR_OPTIONAL_UNIT_TARGET 
	end
	if self:GetSpecialValueFor("dispel") == 1 then
		behavior = behavior + DOTA_ABILITY_BEHAVIOR_IGNORE_PSEUDO_QUEUE
	end
	return behavior
end

function riki_tricks_of_the_trade:GetIntrinsicModifierName()
	return "modifier_riki_tricks_of_the_trade_passive"
end

function riki_tricks_of_the_trade:OnSpellStart()
    local caster = self:GetCaster()
    local target = self:GetCursorTarget()
	local position = self:GetCursorPosition()
	
	local blinkData = {FX = false}
	caster:Blink( position, blinkData )

	local duration = self:GetSpecialValueFor("duration")
    caster:AddNewModifier(caster, self, "modifier_riki_tricks_of_the_trade_handler", {Duration = duration, target = (target or caster):entindex()})
	
	if target then
		target:AddNewModifier(caster, self, "modifier_riki_tricks_of_the_trade_revolutionary", {Duration = duration})
	end
    EmitSoundOn("Hero_Riki.TricksOfTheTrade.Cast", caster)
    local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_tricks_cast.vpcf", PATTACH_WORLDORIGIN, nil)
    ParticleManager:SetParticleControl(nfx, 0, caster:GetAbsOrigin())
    ParticleManager:ReleaseParticleIndex(nfx)
	
	if self:GetSpecialValueFor("dispel") == 1 then
		caster:Dispel( caster, true )
	end
end

function riki_tricks_of_the_trade:OnChannelFinish( bInterrupt )
	self:GetCaster():RemoveModifierByName("modifier_riki_tricks_of_the_trade_handler")
end

modifier_riki_tricks_of_the_trade_passive = class({})
LinkLuaModifier( "modifier_riki_tricks_of_the_trade_passive", "heroes/hero_riki/riki_tricks_of_the_trade.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_riki_tricks_of_the_trade_passive:OnCreated(kv)
	self.creep_kill_cdr = self:GetSpecialValueFor("creep_kill_cdr")
end

function modifier_riki_tricks_of_the_trade_passive:DeclareFunctions()
	return {MODIFIER_EVENT_ON_DEATH}
end

function modifier_riki_tricks_of_the_trade_passive:OnDeath( params )
	if self.creep_kill_cdr <= 0 then return end
	if not params.unit:IsConsideredHero() and params.attacker == self:GetParent() then
		self:GetAbility():ModifyCooldown( -self.creep_kill_cdr )
	end
end

function modifier_riki_tricks_of_the_trade_passive:IsHidden()
	return true
end

modifier_riki_tricks_of_the_trade_handler = class({})
LinkLuaModifier( "modifier_riki_tricks_of_the_trade_handler", "heroes/hero_riki/riki_tricks_of_the_trade.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_riki_tricks_of_the_trade_handler:OnCreated(kv)
	local caster = self:GetCaster()
		
	self.radius = self:GetSpecialValueFor("radius")
	self.attack_rate = self:GetSpecialValueFor("attack_rate")
	self.agility_pct = self:GetSpecialValueFor("agility_pct")
	
    if IsServer() then
		self.origin = EntIndexToHScript( kv.target )
		if self.origin == caster then
			local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_tricks.vpcf", PATTACH_WORLDORIGIN, nil)
			ParticleManager:SetParticleControl(nfx, 0, caster:GetAbsOrigin())
			ParticleManager:SetParticleControl(nfx, 1, Vector(self.radius, self.radius, self.radius))
			self:AddEffect( nfx )
		else
			local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_tricks.vpcf", PATTACH_ABSORIGIN_FOLLOW, self.origin)
			ParticleManager:SetParticleControl(nfx, 1, Vector(self.radius, self.radius, self.radius))
			self:AddEffect( nfx )
		end
		EmitSoundOn("Hero_Riki.TricksOfTheTrade", caster)
		
		self:OnIntervalThink(true)
        self:StartIntervalThink( self.attack_rate )
		caster:AddNoDraw()
    end
end

function modifier_riki_tricks_of_the_trade_handler:OnIntervalThink(bNoFX)
	local caster = self:GetCaster()
	local ability = self:GetAbility()
	
    local enemies = caster:FindEnemyUnitsInRadius( self.origin:GetAbsOrigin(), self.radius )
    for _,enemy in pairs(enemies) do
        caster:PerformGenericAttack(enemy, true, {ability = ability})
    end
	if not bNoFX then
		ParticleManager:FireParticle("particles/units/heroes/hero_riki/riki_tricks_backstab_ring.vpcf", PATTACH_WORLDORIGIN, nil, {[0] = self.origin:GetAbsOrigin(), [1] = Vector(self.radius,self.radius,self.radius)})
	end
end

function modifier_riki_tricks_of_the_trade_handler:OnRemoved()
    if IsServer() then
        StopSoundOn("Hero_Riki.TricksOfTheTrade.Cast", self:GetCaster())
        StopSoundOn("Hero_Riki.TricksOfTheTrade", self:GetCaster())

		self:GetCaster():RemoveNoDraw()
		
        local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_tricks_end.vpcf", PATTACH_POINT, self:GetCaster())
        ParticleManager:SetParticleControl(nfx, 0, self:GetCaster():GetAbsOrigin())
        ParticleManager:ReleaseParticleIndex(nfx)
		
    end
end

function modifier_riki_tricks_of_the_trade_handler:CheckState()
	return {[MODIFIER_STATE_UNSELECTABLE] = true,
			[MODIFIER_STATE_NO_UNIT_COLLISION] = true,
			[MODIFIER_STATE_OUT_OF_GAME ] = true,
			[MODIFIER_STATE_UNTARGETABLE] = true,
			[MODIFIER_STATE_INVISIBLE] = true,
			[MODIFIER_STATE_INVULNERABLE] = true,
			[MODIFIER_STATE_NOT_ON_MINIMAP] = true,
			[MODIFIER_STATE_NO_HEALTH_BAR] = true}
end

function modifier_riki_tricks_of_the_trade_handler:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_AGILITY_BONUS,MODIFIER_PROPERTY_IGNORE_CAST_ANGLE }
end

function modifier_riki_tricks_of_the_trade_handler:GetModifierBonusStats_Agility()
	return self.agility_pct
end

function modifier_riki_tricks_of_the_trade_handler:GetModifierIgnoreCastAngle()
	return 1
end

modifier_riki_tricks_of_the_trade_revolutionary = class({})
LinkLuaModifier( "modifier_riki_tricks_of_the_trade_revolutionary", "heroes/hero_riki/riki_tricks_of_the_trade.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_riki_tricks_of_the_trade_revolutionary:OnCreated(kv)
	self.agility_pct = self:GetSpecialValueFor("agility_pct")
end

function modifier_riki_tricks_of_the_trade_revolutionary:DeclareFunctions()
	return { MODIFIER_PROPERTY_STATS_AGILITY_BONUS }
end

function modifier_riki_tricks_of_the_trade_revolutionary:GetModifierBonusStats_Agility()
	return self.agility_pct
end