healthBooster = class({})

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