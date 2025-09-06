arc_warden_balance_of_power = class({})

function arc_warden_balance_of_power:GetIntrinsicModifierName()
    return "modifier_arc_warden_balance_of_power_innate"
end

modifier_arc_warden_balance_of_power_innate = class({})
LinkLuaModifier( "modifier_arc_warden_balance_of_power_innate", "heroes/hero_arc_warden/arc_warden_balance_of_power", LUA_MODIFIER_MOTION_NONE )

function modifier_arc_warden_balance_of_power_innate:IsHidden()
    return true
end

function modifier_arc_warden_balance_of_power_innate:OnCreated()
    self:OnRefresh()
    if IsServer() then
        self:StartIntervalThink(self.interval)
    end
end

function modifier_arc_warden_balance_of_power_innate:OnRefresh()
    self.interval = self:GetSpecialValueFor("interval")
end

function modifier_arc_warden_balance_of_power_innate:OnIntervalThink()
    self:GetParent():AddNewModifier(self:GetCaster(), self:GetAbility(), "modifier_arc_warden_balance_of_power_buff", {})
end

function modifier_arc_warden_balance_of_power_innate:RemoveOnDeath()
    return false
end

modifier_arc_warden_balance_of_power_buff = class({})
LinkLuaModifier( "modifier_arc_warden_balance_of_power_buff", "heroes/hero_arc_warden/arc_warden_balance_of_power", LUA_MODIFIER_MOTION_NONE )

function modifier_arc_warden_balance_of_power_buff:OnCreated()
    self:OnRefresh()
    self:SetStackCount(self:GetSpecialValueFor("initial_bonus"))
end

function modifier_arc_warden_balance_of_power_buff:OnRefresh()
    self.bonus = self:GetSpecialValueFor("bonus")
    self.real_bonus = self.bonus * self:GetParent():GetHeroPowerAmplification(  )
	if IsServer() then
		self:IncrementStackCount()
		self:GetParent():CalculateGenericBonuses( )
		self:GetParent():CalculateStatBonus( true )
	end
end

function modifier_arc_warden_balance_of_power_buff:OnStackCountChanged()
    self.real_bonus = self.bonus * self:GetParent():GetHeroPowerAmplification()
end

function modifier_arc_warden_balance_of_power_buff:DeclareFunctions()
	return
    {
        MODIFIER_PROPERTY_STATS_STRENGTH_BONUS,
		MODIFIER_PROPERTY_STATS_AGILITY_BONUS,
		MODIFIER_PROPERTY_STATS_INTELLECT_BONUS
    }
end

function modifier_arc_warden_balance_of_power_buff:GetModifierBonusStats_Strength()
	return self.real_bonus * self:GetStackCount()
end

function modifier_arc_warden_balance_of_power_buff:GetModifierBonusStats_Agility()
	return self.real_bonus * self:GetStackCount()
end

function modifier_arc_warden_balance_of_power_buff:GetModifierBonusStats_Intellect()
	return self.real_bonus * self:GetStackCount()
end

function modifier_arc_warden_balance_of_power_buff:GetTexture()
	return "arc_warden_rune_forge"
end

function modifier_arc_warden_balance_of_power_buff:IsPermanent()
	return true
end

function modifier_arc_warden_balance_of_power_buff:RemoveOnDeath()
	return false
end

function modifier_arc_warden_balance_of_power_buff:IsPurgable()
	return false
end