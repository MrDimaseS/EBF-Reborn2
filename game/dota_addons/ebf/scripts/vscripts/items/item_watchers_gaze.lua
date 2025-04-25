item_watchers_gaze = class({})

function item_watchers_gaze:GetIntrinsicModifierName()
	return "modifier_item_watchers_gaze_passive"
end

function item_watchers_gaze:OnSpellStart()
	local caster = self:GetCaster()
	local position = self:GetCursorPosition()

	local direction = caster:GetForwardVector()

	local angle = self:GetSpecialValueFor("petrify_distance")	
	local distance = self:GetSpecialValueFor("petrify_distance")	
	local knockback_duration = self:GetSpecialValueFor("knockback_duration")	
	local knockback_distance = self:GetSpecialValueFor("knockback_distance")

	local nfx = ParticleManager:CreateParticle("particles/items_fx/watchers_gaze_petrify.vpcf", PATTACH_POINT_FOLLOW, caster)
				ParticleManager:SetParticleControlForward(nfx, 0, direction)
				ParticleManager:SetParticleControl( nfx, 0, caster:GetAbsOrigin() )
				ParticleManager:SetParticleControl(nfx, 1, Vector(distance, distance, distance))
				ParticleManager:ReleaseParticleIndex(nfx)

	local enemies = caster:FindEnemyUnitsInCone(direction, caster:GetAbsOrigin(), distance, distance)
	local petrify_duration = self:GetSpecialValueFor("petrify_duration")
	EmitSoundOn( "Hero_EarthSpirit.Petrify", caster )
	for _,enemy in pairs(enemies) do
		local nfx2 = ParticleManager:FireParticle("particles/units/heroes/hero_tiny/tiny_death_rocks.vpcf", PATTACH_POINT_FOLLOW, enemy)
		enemy:AddNewModifier( caster, self, "modifier_item_watchers_gaze_active", {duration = petrify_duration} )
	end
end

modifier_item_watchers_gaze_passive = class(persistentModifier)
LinkLuaModifier( "modifier_item_watchers_gaze_passive", "items/item_watchers_gaze.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_watchers_gaze_passive:OnCreated()
	self:OnRefresh()
end

function modifier_item_watchers_gaze_passive:OnRefresh()
	self.bonus_all = self:GetSpecialValueFor("bonus_all")
end

function modifier_item_watchers_gaze_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
			MODIFIER_PROPERTY_STATS_AGILITY_BONUS,				
			MODIFIER_PROPERTY_STATS_INTELLECT_BONUS }
end

function modifier_item_watchers_gaze_passive:GetModifierBonusStats_Strength()
	return self.bonus_all
end

function modifier_item_watchers_gaze_passive:GetModifierBonusStats_Agility()
	return self.bonus_all
end

function modifier_item_watchers_gaze_passive:GetModifierBonusStats_Intellect()
	return self.bonus_all
end

modifier_item_watchers_gaze_active = class({})
LinkLuaModifier( "modifier_item_watchers_gaze_active", "items/item_watchers_gaze.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_item_watchers_gaze_active:OnCreated()
	self:OnRefresh()
end

function modifier_item_watchers_gaze_active:OnRefresh()
	self.petrify_amp = self:GetSpecialValueFor("petrify_amp")
end

function modifier_item_watchers_gaze_active:CheckState()
	return {[MODIFIER_STATE_STUNNED] = true,
			[MODIFIER_STATE_FROZEN] = true,
			[MODIFIER_STATE_PASSIVES_DISABLED] = true,}
end

function modifier_item_watchers_gaze_active:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE}
end

function modifier_item_watchers_gaze_active:GetModifierIncomingDamage_Percentage( params )
	if params.damage_type ~= DAMAGE_TYPE_PHYSICAL then return end
	return self.petrify_amp
end

function modifier_item_watchers_gaze_active:GetEffectName()
	return "particles/units/heroes/hero_earth_spirit/earthspirit_petrify_debuff_stoned.vpcf"
end

function modifier_item_watchers_gaze_active:GetStatusEffectName()
	return "particles/status_fx/status_effect_earth_spirit_petrify.vpcf"
end

function modifier_item_watchers_gaze_active:StatusEffectPriority()
	return 10
end