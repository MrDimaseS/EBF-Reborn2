skywrath_mage_concussive_shot = class({})

function skywrath_mage_concussive_shot:GetCastRange(vLocation, hTarget)
	return self:GetSpecialValueFor("launch_radius")
end

function skywrath_mage_concussive_shot:OnSpellStart()
	local caster = self:GetCaster()

	EmitSoundOn("Hero_SkywrathMage.ConcussiveShot.Cast", caster)

	local targetsFound = 0
	local radius = TernaryOperator( -1, self:GetSpecialValueFor("launch_radius") == 0, self:GetSpecialValueFor("launch_radius") )
	local enemies = caster:FindEnemyUnitsInRadius(caster:GetAbsOrigin(), radius, {order=FIND_CLOSEST})
	for _,enemy in pairs(enemies) do
		self:FireTrackingProjectile("particles/units/heroes/hero_skywrath_mage/skywrath_mage_concussive_shot.vpcf", enemy, self:GetSpecialValueFor("speed"), {}, DOTA_PROJECTILE_ATTACHMENT_HITLOCATION, false, true, self:GetSpecialValueFor("vision"))
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
		local radius = self:GetSpecialValueFor("slow_radius")
        local enemies = caster:FindEnemyUnitsInRadius(hTarget:GetAbsOrigin(), radius)
		local damage = self:GetSpecialValueFor("damage")
		local minion_mult = self:GetSpecialValueFor("creep_damage_pct") / 100
        for _,enemy in pairs(enemies) do
        	enemy:AddNewModifier(caster, self, "modifier_skywrath_mage_concussive_shot", {Duration = self:GetSpecialValueFor("slow_duration")})
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
	self.slow = self:GetSpecialValueFor("movement_speed_pct")
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