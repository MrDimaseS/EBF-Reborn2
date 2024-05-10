modifier_generic_suppress_cleave = class({})

function modifier_generic_suppress_cleave:DeclareFunctions()
    return { MODIFIER_PROPERTY_SUPPRESS_CLEAVE}
end

function modifier_generic_suppress_cleave:GetSuppressCleave( params )
    return 1
end

function modifier_generic_suppress_cleave:IsHidden()
    return true
end