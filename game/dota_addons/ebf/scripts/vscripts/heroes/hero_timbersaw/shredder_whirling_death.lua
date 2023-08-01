shredder_whirling_death = class({})

function shredder_whirling_death:GetIntrinsicModifierName()
	return "modifier_shredder_whirling_death"
end

function shredder_whirling_death:IsStealable()
	return true
end

function shredder_whirling_death:IsHiddenWhenStolen()
	return false
end

function shredder_whirling_death:OnSpellStart()
	self:Spray()
end

function shredder_whirling_death:Spray()
	local caster = self:GetCaster()
	local position = caster:GetAbsOrigin()
	
	local radius = self:GetSpecialValueFor("whirling_radius")
	local duration = self:GetSpecialValueFor("duration")
	local baseDamage = self:GetSpecialValueFor("whirling_damage")
	local treeDamage = self:GetSpecialValueFor("tree_damage_scale")
	
	local treesCut = 0
	local trees = GridNav:GetAllTreesAroundPoint(position, radius, false)
	for _, tree in ipairs( trees ) do
		if tree:IsStanding() then
			tree:CutDown( caster:GetTeamNumber() )
			treesCut = treesCut + 1
		end
	end

	local enemies = self:GetCaster():FindEnemyUnitsInRadius(position, radius)
	for _,enemy in pairs(enemies) do
		enemy:RemoveModifierByName("modifier_shredder_whirling_death_enemy")
		enemy:AddNewModifier(caster, self, "modifier_shredder_whirling_death_enemy", {Duration = duration})
		self:DealDamage(caster, enemy, baseDamage + treeDamage * treesCut)
	end
	
	EmitSoundOn("Hero_Shredder.WhirlingDeath.Cast", caster)
	ParticleManager:FireParticle("particles/units/heroes/hero_shredder/shredder_whirling_death.vpcf", PATTACH_POINT_FOLLOW, caster, {[0]="attach_hitloc",[1]="attach_hitloc", [2]=Vector(radius,radius,radius), [3]=position})
end

modifier_shredder_whirling_death_enemy = class({})
LinkLuaModifier( "modifier_shredder_whirling_death_enemy", "heroes/hero_timbersaw/shredder_whirling_death.lua",LUA_MODIFIER_MOTION_NONE )
function modifier_shredder_whirling_death_enemy:OnCreated()
	self:OnRefresh()
end

function modifier_shredder_whirling_death_enemy:OnRefresh()
	self.stat_loss_pct = self:GetSpecialValueFor("stat_loss_pct")
	self.armor = -self:GetParent():GetPhysicalArmorValue(false) * self.stat_loss_pct / 100
end

function modifier_shredder_whirling_death_enemy:DeclareFunctions()
    local funcs = {MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE,
				   MODIFIER_PROPERTY_EXTRA_HEALTH_PERCENTAGE,
				   MODIFIER_PROPERTY_HP_REGEN_AMPLIFY_PERCENTAGE,
				   MODIFIER_PROPERTY_PHYSICAL_ARMOR_BONUS }
    return funcs
end

function modifier_shredder_whirling_death_enemy:GetModifierDamageOutgoing_Percentage()
    return -self.stat_loss_pct
end

function modifier_shredder_whirling_death_enemy:GetModifierPhysicalArmorBonus()
    return self.armor
end

function modifier_shredder_whirling_death_enemy:GetModifierExtraHealthPercentage()
    return -self.stat_loss_pct
end

function modifier_shredder_whirling_death_enemy:GetModifierHPRegenAmplify_Percentage()
    return -self.stat_loss_pct
end

function modifier_shredder_whirling_death_enemy:IsDebuff()
	return true
end

function modifier_shredder_whirling_death_enemy:GetEffectName()
	return "particles/units/heroes/hero_shredder/shredder_whirling_death_debuff.vpcf"
end