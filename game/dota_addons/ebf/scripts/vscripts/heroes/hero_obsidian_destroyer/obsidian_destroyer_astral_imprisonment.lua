obsidian_destroyer_astral_imprisonment = class({})

function obsidian_destroyer_astral_imprisonment:CastFilterResultTarget( target )
	return self:UnitFilter(target)
end

function obsidian_destroyer_astral_imprisonment:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	EmitSoundOn("Hero_ObsidianDestroyer.AstralImprisonment.Cast", caster)
	local flash = ParticleManager:FireParticle("particles/units/heroes/hero_obsidian_destroyer/obsidian_destroyer_prison_start.vpcf", PATTACH_ABSORIGIN , target)
	
	local duration = self:GetSpecialValueFor("prison_duration")
	if target:IsSameTeam( caster ) or not target:TriggerSpellAbsorb( self ) then
		target:AddNewModifier(caster, self, "modifier_obsidian_destroyer_astral_imprisonment_prison", {duration = duration})
	end
	if not target:IsSameTeam( caster ) then
		Timers:CreateTimer( duration, function()
			caster:AddNewModifier(caster, self, "modifier_obsidian_destroyer_astral_imprisonment_int_gain", {duration = self:GetSpecialValueFor("mana_capacity_duration")})
		end)
	end
end

modifier_obsidian_destroyer_astral_imprisonment_int_gain = class({})
LinkLuaModifier( "modifier_obsidian_destroyer_astral_imprisonment_int_gain", "heroes/hero_obsidian_destroyer/obsidian_destroyer_astral_imprisonment" ,LUA_MODIFIER_MOTION_NONE )

function modifier_obsidian_destroyer_astral_imprisonment_int_gain:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self:SetStackCount( 1 )
	end
end

function modifier_obsidian_destroyer_astral_imprisonment_int_gain:OnRefresh()
	self.mana_capacity_steal = self:GetAbility():GetSpecialValueFor("mana_capacity_steal")
	if IsServer() then
		self:AddIndependentStack( self:GetRemainingTime() )
		self:GetParent():CalculateGenericBonuses()
		self:GetParent():GiveMana( self.mana_capacity_steal )
		if self:GetParent():IsRealHero() then self:GetParent():CalculateStatBonus( true ) end
	end
end

function modifier_obsidian_destroyer_astral_imprisonment_int_gain:OnStackCountChanged()
	if IsServer() then
		self:GetParent():CalculateGenericBonuses()
		if self:GetParent():IsRealHero() then self:GetParent():CalculateStatBonus( true ) end
	end
end

function modifier_obsidian_destroyer_astral_imprisonment_int_gain:DeclareFunctions()
	funcs = {
				MODIFIER_PROPERTY_EXTRA_MANA_BONUS
			}
	return funcs
end

function modifier_obsidian_destroyer_astral_imprisonment_int_gain:GetModifierExtraManaBonus()
	return self.mana_capacity_steal * self:GetStackCount()
end