item_fallen_sky = class({})

function item_fallen_sky:GetIntrinsicModifierName()
	return "modifier_ebfr_fallen_sky_passive"
end

function item_fallen_sky:GetCastRange( position, target )
	if IsClient() then
		return self:GetSpecialValueFor("blink_range")
	else
		return 0
	end
end

function item_fallen_sky:GetAOERadius()
	return self:GetSpecialValueFor("impact_radius")
end

function item_fallen_sky:OnSpellStart()
	local caster = self:GetCaster()
	local position = self:GetCursorPosition()
	
	if caster:HasModifier("modifier_item_fallen_sky_broken") then
		position = caster:GetAbsOrigin()
	end
	
	local distance = CalculateDistance( caster, position )
	local clamp = self:GetSpecialValueFor("blink_range_clamp")
	local range = self:GetSpecialValueFor("blink_range")
	local realPos = caster:GetAbsOrigin() + CalculateDirection( position, caster ) * math.min( distance, TernaryOperator( clamp + caster:GetCastRangeBonus(), distance > range + caster:GetCastRangeBonus(), range + caster:GetCastRangeBonus() ) )
	
	local land_time = self:GetSpecialValueFor("land_time")
	local duration = self:GetSpecialValueFor("burn_duration")
	local stunDuration = self:GetSpecialValueFor("stun_duration")
	local damageRadius = self:GetSpecialValueFor("damage_radius")
	local stunRadius = self:GetSpecialValueFor("impact_radius")
	
	
	EmitSoundOn( "DOTA_Item.MeteorHammer.Cast", caster )
	
	-- BLINK
	ParticleManager:FireParticle( "particles/items3_fx/blink_overwhelming_start.vpcf", PATTACH_WORLDORIGIN, nil, {[0] = caster:GetAbsOrigin()})
	
	caster:AddNewModifier( caster, self, "modifier_invulnerable", {duration = land_time} )
	caster:AddNoDraw()
	
	Timers:CreateTimer( land_time, function()
		caster:Blink( realPos )
		ParticleManager:FireParticle( "particles/items3_fx/blink_overwhelming_end.vpcf", PATTACH_POINT, caster )
		EmitSoundOn( "Blink_Layer.Overwhelming", caster )
		-- EFFECTS
		local damage = self:GetSpecialValueFor("damage_base") * (1+caster:GetSpellAmplification(false)) + caster:GetStrength() * self:GetSpecialValueFor("damage_pct_instant") / 100
		
		for _, enemy in ipairs( caster:FindEnemyUnitsInRadius( caster:GetAbsOrigin(), damageRadius ) ) do
			self:DealDamage( caster, enemy, damage, {damage_type = DAMAGE_TYPE_MAGICAL, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION} )
			enemy:AddNewModifier( caster, self, "modifier_item_overwhelming_blink_debuff", {duration = duration} )
			if CalculateDistance( enemy, caster ) <= stunRadius then
				enemy:AddNewModifier( caster, self, "modifier_stunned", {duration = stunDuration} )
				enemy:AddNewModifier( caster, self, "modifier_item_fallen_sky_debuff_ebf", {duration = duration} )
			end
		end
		
		EmitSoundOn( "DOTA_Item.MeteorHammer.Impact", caster )
		ParticleManager:FireParticle( "particles/items3_fx/blink_overwhelming_burst.vpcf", PATTACH_POINT, caster, {[1] = Vector( damageRadius, damageRadius, damageRadius )} )
		
		local landFX = ParticleManager:CreateParticle("particles/items4_fx/meteor_hammer_aoe.vpcf", PATTACH_WORLDORIGIN, nil)
		ParticleManager:SetParticleControl( landFX, 0, realPos )
		ParticleManager:SetParticleControl( landFX, 1, Vector( stunRadius, stunRadius, stunRadius) )
		ParticleManager:ClearParticle( landFX, false )
		caster:RemoveNoDraw()
	end)
end

item_fallen_sky_2 = class(item_fallen_sky)
item_fallen_sky_3 = class(item_fallen_sky)
item_fallen_sky_4 = class(item_fallen_sky)
item_fallen_sky_5 = class(item_fallen_sky)

modifier_item_fallen_sky_debuff_ebf = class({})
LinkLuaModifier( "modifier_item_fallen_sky_debuff_ebf", "items/item_fallen_sky.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_fallen_sky_debuff_ebf:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:StartIntervalThink( self.burn_interval )
	end
end

function modifier_item_fallen_sky_debuff_ebf:OnRefresh()
	self.burn_dps = self:GetSpecialValueFor("burn_dps")
	self.burn_dps_pct = (self:GetSpecialValueFor("damage_pct_over_time")/100) / self:GetRemainingTime()
	self.burn_interval = self:GetSpecialValueFor("burn_interval")
end

function modifier_item_fallen_sky_debuff_ebf:OnIntervalThink()
	local caster = self:GetCaster()
	local parent = self:GetParent()
	local ability = self:GetAbility()
	
	local damage = self.burn_dps * (1+caster:GetSpellAmplification(false)) + self:GetCaster():GetStrength() * self.burn_dps_pct
	ability:DealDamage( caster, parent, damage * self.burn_interval, {damage_type = DAMAGE_TYPE_MAGICAL, damage_flags = DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION} )
end

function modifier_item_fallen_sky_debuff_ebf:GetEffectName()
	return "particles/items4_fx/meteor_hammer_spell_debuff.vpcf"
end

function modifier_item_fallen_sky_debuff_ebf:IsHidden()
	return true
end

modifier_item_fallen_sky_broken = class({})
LinkLuaModifier( "modifier_item_fallen_sky_broken", "items/item_fallen_sky.lua" ,LUA_MODIFIER_MOTION_NONE )

modifier_ebfr_fallen_sky_passive = class({})
LinkLuaModifier( "modifier_ebfr_fallen_sky_passive", "items/item_fallen_sky.lua" ,LUA_MODIFIER_MOTION_NONE )
function modifier_ebfr_fallen_sky_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_ebfr_fallen_sky_passive:OnCreated()
	self.bonus_strength = self:GetAbility():GetSpecialValueFor("bonus_strength")
	self.bonus_agility = self:GetAbility():GetSpecialValueFor("bonus_agility")
	self.bonus_intellect = self:GetAbility():GetSpecialValueFor("bonus_intellect")
	self.spell_amp = self:GetAbility():GetSpecialValueFor("spell_amp")
	self.mana_regen_multiplier = self:GetAbility():GetSpecialValueFor("mana_regen_multiplier")
	self.spell_lifesteal_amp = self:GetAbility():GetSpecialValueFor("spell_lifesteal_amp")
	
	self.damage_cd = self:GetSpecialValueFor("blink_damage_cooldown")
end

function modifier_ebfr_fallen_sky_passive:DeclareFunctions(params)
local funcs = {
		MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_SPELL_LIFESTEAL_AMPLIFY_PERCENTAGE,
		MODIFIER_PROPERTY_MP_REGEN_AMPLIFY_PERCENTAGE,
		MODIFIER_EVENT_ON_TAKEDAMAGE,
    }
    return funcs
end

function modifier_ebfr_fallen_sky_passive:OnTakeDamage(params)
	if params.unit == self:GetParent() and params.attacker:IsConsideredHero() and self:GetAbility():GetCooldownTimeRemaining() < self.damage_cd then
		self:GetParent():AddNewModifier( self:GetCaster(), self:GetAbility(), "modifier_item_fallen_sky_broken", {duration = self.damage_cd } )
	end
end

function modifier_ebfr_fallen_sky_passive:GetModifierBonusStats_Strength()
	return self.bonus_strength
end

function modifier_ebfr_fallen_sky_passive:GetModifierBonusStats_Intellect()
	return self.bonus_intellect
end

function modifier_ebfr_fallen_sky_passive:GetModifierBonusStats_Agility()
	return self.bonus_agility
end

function modifier_ebfr_fallen_sky_passive:GetModifierSpellAmplify_Percentage()
	return self.spell_amp
end

function modifier_ebfr_fallen_sky_passive:GetModifierMPRegenAmplify_Percentage()
	return self.mana_regen_multiplier
end

function modifier_ebfr_fallen_sky_passive:GetModifierSpellLifestealRegenAmplify_Percentage()
	return self.spell_lifesteal_amp
end

function modifier_ebfr_fallen_sky_passive:IsHidden()
	return true
end