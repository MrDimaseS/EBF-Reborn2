skywrath_mage_ancient_seal = class({})

function skywrath_mage_ancient_seal:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	EmitSoundOn("Hero_SkywrathMage.AncientSeal.Target", target)
	
	local duration = self:GetSpecialValueFor("seal_duration")
	if not	target:TriggerSpellAbsorb( self ) then
		target:AddNewModifier(caster, self, "modifier_skywrath_mage_ancient_seal_debuff", {Duration = duration})
	end
	if caster:HasScepter() then
        local enemies = caster:FindEnemyUnitsInRadius( target:GetAbsOrigin(), self:GetSpecialValueFor("scepter_radius") + caster:GetCastRangeBonus() )
		local creeps = {}
        for _,enemy in pairs(enemies) do
			if enemy ~= target then
				if enemy:IsConsideredHero() then
					scepterTarget = enemy
					break
				else
					table.insert( creeps, enemy )
				end
			end
        end
		scepterTarget = scepterTarget or creeps[1]
		if target then
			EmitSoundOn("Hero_SkywrathMage.AncientSeal.Target", scepterTarget)
			scepterTarget:AddNewModifier(caster, self, "modifier_skywrath_mage_ancient_seal_debuff", {Duration = duration})
		end
    end
end

modifier_skywrath_mage_ancient_seal_debuff = class({})
LinkLuaModifier( "modifier_skywrath_mage_ancient_seal_debuff","heroes/hero_skywrath_mage/skywrath_mage_ancient_seal.lua",LUA_MODIFIER_MOTION_NONE )
function modifier_skywrath_mage_ancient_seal_debuff:OnCreated(table)
	self:OnRefresh()
	if IsServer() then
		local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_skywrath_mage/skywrath_mage_ancient_seal_debuff.vpcf", PATTACH_OVERHEAD_FOLLOW, self:GetCaster())
   		ParticleManager:SetParticleControlEnt(nfx, 0, self:GetParent(), PATTACH_OVERHEAD_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
   		ParticleManager:SetParticleControlEnt(nfx, 1, self:GetParent(), PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", self:GetParent():GetAbsOrigin(), true)
		self:AddEffect( nfx )
	end
end

function modifier_skywrath_mage_ancient_seal_debuff:OnRefresh()
	self.mr = self:GetSpecialValueFor("resist_debuff")
end

function modifier_skywrath_mage_ancient_seal_debuff:CheckState()
	local state = { [MODIFIER_STATE_SILENCED] = true}
	return state
end

function modifier_skywrath_mage_ancient_seal_debuff:DeclareFunctions()
	local funcs = {MODIFIER_PROPERTY_MAGICAL_RESISTANCE_BONUS}
    return funcs
end

function modifier_skywrath_mage_ancient_seal_debuff:GetModifierMagicalResistanceBonus()
    return self.mr
end

function modifier_skywrath_mage_ancient_seal_debuff:IsDebuff()
    return true
end