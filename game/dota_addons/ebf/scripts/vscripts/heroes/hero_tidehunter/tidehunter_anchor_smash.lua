tidehunter_anchor_smash = class({})

function tidehunter_anchor_smash:IsStealable()
    return true
end

function tidehunter_anchor_smash:IsHiddenWhenStolen()
    return false
end

function tidehunter_anchor_smash:GetCastRange(target, position)
	return self:GetSpecialValueFor("radius")
end

function tidehunter_anchor_smash:GetIntrinsicModifierName()
	return	"modifier_tidehunter_anchor_smash_autocast"
end

function tidehunter_anchor_smash:OnSpellStart()
    local caster = self:GetCaster()
    local point = caster:GetAbsOrigin()

    EmitSoundOn("Hero_Tidehunter.AnchorSmash", caster)

    local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_tidehunter/tidehunter_anchor_hero.vpcf", PATTACH_POINT, caster)
    ParticleManager:SetParticleControl(nfx, 0, point)
    ParticleManager:ReleaseParticleIndex(nfx)
	
	local damage = self:GetSpecialValueFor("attack_damage")
	local radius = self:GetSpecialValueFor("radius")
	local duration = self:GetSpecialValueFor("reduction_duration")
    
	caster:AddNewModifier( caster, self, "modifier_tidehunter_anchor_smash_caster", {})
	caster:AddNewModifier( caster, self, "modifier_tidehunter_smash_attack", {})
    local enemies = caster:FindEnemyUnitsInRadius(point, radius, {})
    for _,enemy in pairs(enemies) do
		if not enemy:TriggerSpellAbsorb( self ) then
			caster:PerformAbilityAttack(enemy, true, ability, damage)
			enemy:AddNewModifier(caster, self, "modifier_tidehunter_anchor_smash", {Duration = duration})
		end
    end
	caster:RemoveModifierByName("modifier_tidehunter_anchor_smash_caster")
	caster:RemoveModifierByName("modifier_tidehunter_smash_attack")
end

modifier_tidehunter_anchor_smash_autocast = class({})
LinkLuaModifier("modifier_tidehunter_anchor_smash_autocast", "heroes/hero_tidehunter/tidehunter_anchor_smash", LUA_MODIFIER_MOTION_NONE)

function modifier_tidehunter_anchor_smash_autocast:OnCreated()
	if IsServer() then
		self:StartIntervalThink(0)
	end
end

function modifier_tidehunter_anchor_smash_autocast:OnIntervalThink()
	local caster = self:GetCaster()
	local target = caster:GetAttackTarget()
	if target and not caster:AttackReady() then
		local ability = self:GetAbility()
		if ability:GetAutoCastState() and ability:IsFullyCastable() then
			caster:CastAbilityNoTarget( ability, caster:GetPlayerOwnerID() )
		end
	end
end

function modifier_tidehunter_anchor_smash_autocast:IsHidden()
	return true
end
