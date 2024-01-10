riki_smoke_screen = class({})

function riki_smoke_screen:IsStealable()
    return true
end

function riki_smoke_screen:IsHiddenWhenStolen()
    return false
end

function riki_smoke_screen:GetBehavior()
	if self:GetCaster():HasModifier("modifier_riki_tricks_of_the_trade_handler") then
		return DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING + DOTA_ABILITY_BEHAVIOR_IMMEDIATE + DOTA_ABILITY_BEHAVIOR_UNRESTRICTED + DOTA_ABILITY_BEHAVIOR_DONT_CANCEL_CHANNEL
	else
		return DOTA_ABILITY_BEHAVIOR_AOE + DOTA_ABILITY_BEHAVIOR_POINT + DOTA_ABILITY_BEHAVIOR_IGNORE_BACKSWING
	end
end

function riki_smoke_screen:GetCastPoint()
	if self:GetCaster():HasModifier("modifier_riki_tricks_of_the_trade_handler") then
		return 0
	else
		return self.BaseClass.GetCastPoint( self )
	end
end

function riki_smoke_screen:OnSpellStart()
    local caster = self:GetCaster()
    local point = self:GetCursorPosition()

    CreateModifierThinker(caster, self, "modifier_riki_smoke_screen_aura_thinker", {Duration = self:GetSpecialValueFor("AbilityDuration")}, point, caster:GetTeam(), false)
end

modifier_riki_smoke_screen_aura_thinker = class({})
LinkLuaModifier( "modifier_riki_smoke_screen_aura_thinker", "heroes/hero_riki/riki_smoke_screen.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_riki_smoke_screen_aura_thinker:OnCreated(table)
    if IsServer() then
        EmitSoundOn("Hero_Riki.Smoke_Screen", self:GetParent())

		self.radius = self:GetSpecialValueFor("radius")
        self.nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_riki/riki_smokebomb.vpcf", PATTACH_POINT, self:GetParent())
        ParticleManager:SetParticleControl(self.nfx, 0, self:GetParent():GetAbsOrigin())
        ParticleManager:SetParticleControl(self.nfx, 1, Vector(self.radius, self.radius, self.radius))
		
		self:AddEffect( self.nfx )

        self:StartIntervalThink(1.0)
    end
end

function modifier_riki_smoke_screen_aura_thinker:OnRemoved()
    if IsServer() then
        StopSoundOn( "Hero_Riki.Smoke_Screen", self:GetParent() )
        ParticleManager:DestroyParticle(self.nfx, false)
    end
end

function modifier_riki_smoke_screen_aura_thinker:IsAura()
	return true
end

function modifier_riki_smoke_screen_aura_thinker:GetModifierAura()
	return "modifier_riki_smoke_screen_aura_debuff"
end

function modifier_riki_smoke_screen_aura_thinker:GetAuraRadius()
	return self.radius
end

function modifier_riki_smoke_screen_aura_thinker:GetAuraDuration()
	return 0.5
end

function modifier_riki_smoke_screen_aura_thinker:GetAuraSearchTeam()    
	return DOTA_UNIT_TARGET_TEAM_ENEMY
end

function modifier_riki_smoke_screen_aura_thinker:GetAuraSearchType()    
	return DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
end

modifier_riki_smoke_screen_aura_debuff = class({})
LinkLuaModifier( "modifier_riki_smoke_screen_aura_debuff", "heroes/hero_riki/riki_smoke_screen.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_riki_smoke_screen_aura_debuff:OnCreated()
	self.miss_rate = self:GetSpecialValueFor("miss_rate")
	self.block_targeting = self:GetSpecialValueFor("block_targeting") == 1
	self.armor_reduction = self:GetSpecialValueFor("armor_reduction")
end

function modifier_riki_smoke_screen_aura_debuff:CheckState()
	local states = {[MODIFIER_STATE_SILENCED] = true}
	if self.block_targeting then
		states[MODIFIER_STATE_UNTARGETABLE_ALLIED] = true
	end
	return states
end

function modifier_riki_smoke_screen_aura_debuff:DeclareFunctions()
	return { MODIFIER_PROPERTY_MISS_PERCENTAGE,
			 MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
end

function modifier_riki_smoke_screen_aura_debuff:GetModifierMiss_Percentage()    
	return self.miss_rate
end

function modifier_riki_smoke_screen_aura_debuff:GetModifierPhysicalArmorBonus()    
	return -self.armor_reduction
end