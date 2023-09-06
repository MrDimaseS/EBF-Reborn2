skywrath_mage_concussive_shot = class({})

function skywrath_mage_concussive_shot:GetCastRange(vLocation, hTarget)
	if self:GetCaster():HasTalent("special_bonus_unique_skywrath_4") then
		return -1
	end
	return self:GetTalentSpecialValueFor("launch_radius")
end

function skywrath_mage_concussive_shot:OnSpellStart()
	local caster = self:GetCaster()

	EmitSoundOn("Hero_SkywrathMage.ConcussiveShot.Cast", caster)

	local targetsFound = 0
	local enemies = caster:FindEnemyUnitsInRadius(caster:GetAbsOrigin(), self:GetTrueCastRange(), {order=FIND_CLOSEST})
	for _,enemy in pairs(enemies) do
		self:FireTrackingProjectile("particles/units/heroes/hero_skywrath_mage/skywrath_mage_concussive_shot.vpcf", enemy, self:GetTalentSpecialValueFor("speed"), {}, DOTA_PROJECTILE_ATTACHMENT_HITLOCATION, false, true, self:GetTalentSpecialValueFor("vision"))
		targetsFound = targetsFound + 1
		if not caster:HasScepter() or targetsFound >= 2 then
			break
		end
	end
end

function skywrath_mage_concussive_shot:OnProjectileHit(hTarget, vLocation)
    local caster = self:GetCaster()

    if hTarget then
    	EmitSoundOn("Hero_SkywrathMage.ConcussiveShot.Target", hTarget)
		local radius = self:GetTalentSpecialValueFor("slow_radius")
        local enemies = caster:FindEnemyUnitsInRadius(hTarget:GetAbsOrigin(), radius)
		local damage = self:GetTalentSpecialValueFor("damage")
		local minion_mult = self:GetTalentSpecialValueFor("creep_damage_pct") / 100
        for _,enemy in pairs(enemies) do
        	enemy:AddNewModifier(caster, self, "modifier_skywrath_mage_concussive_shot", {Duration = self:GetTalentSpecialValueFor("slow_duration")})
			local endDamage = damage
			if not enemy:IsConsideredHero() then
				endDamage = damage * minion_mult
			end
        	self:DealDamage(caster, enemy, endDamage)
        end
    end
end

modifier_skywrath_mage_concussive_shot = class({})
LinkLuaModifier( "modifier_skywrath_mage_concussive_shot","heroes/hero_skywrath_mage/skywrath_mage_concussive_shot.lua",LUA_MODIFIER_MOTION_NONE )
function modifier_skywrath_mage_concussive_shot:OnCreated()
	self:OnRefresh()
end

function modifier_skywrath_mage_concussive_shot:OnRefresh()
	self.slow = self:GetTalentSpecialValueFor("movement_speed_pct")
end

function modifier_skywrath_mage_concussive_shot:DeclareFunctions()
    funcs = {MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE}
    return funcs
end

function modifier_skywrath_mage_concussive_shot:GetModifierMoveSpeedBonus_Percentage()
    return -self.slow
end

function modifier_skywrath_mage_concussive_shot:GetEffectAttachType()
    return PATTACH_OVERHEAD_FOLLOW
end

function modifier_skywrath_mage_concussive_shot:GetEffectName()
    return "particles/units/heroes/hero_skywrath_mage/skywrath_mage_concussive_shot_slow_debuff.vpcf"
end

function modifier_skywrath_mage_concussive_shot:IsDebuff()
    return true
end