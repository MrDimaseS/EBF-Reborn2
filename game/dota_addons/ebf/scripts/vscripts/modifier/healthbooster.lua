healthBooster = class({})

function healthBooster:OnCreated()
	self.HpPerStr=self:GetAbility():GetSpecialValueFor("health_per_str")
	if IsServer() then
		self:GetParent():CalculateGenericBonuses()
		self:GetParent():CalculateStatBonus( true )
		
		self:StartIntervalThink(0)
	end
end

function healthBooster:OnIntervalThink()
	if self.linkedModifier == nil or self.linkedModifier:IsNull() then
		self:Destroy()
	end
end

function healthBooster:OnRefresh()
   self.HpPerStr=math.max(self.HpPerStr, self:GetAbility():GetSpecialValueFor("health_per_str") )
end

function healthBooster:DeclareFunctions()
  local funcs = {
   MODIFIER_PROPERTY_EXTRA_HEALTH_BONUS
  }
  return funcs
end


function healthBooster:GetModifierExtraHealthBonus()
  return self.HpPerStr*math.floor( self:GetParent():GetStrength() + 0.5 )
end

function healthBooster:IsHidden()
  return true 
end

function healthBooster:IsDebuff()
  return false
end

function healthBooster:IsPurgable()
  return false
end

function healthBooster:GetAttributes()
  return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE --+ MODIFIER_ATTRIBUTE_MULTIPLE
end