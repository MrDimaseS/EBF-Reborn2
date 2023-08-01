hoodwink_sharpshooter_release = class({})
function hoodwink_sharpshooter_release:OnSpellStart()
	-- find modifier
	local mod = self:GetCaster():FindModifierByName( "modifier_hoodwink_sharpshooter_ebf" )
	if not mod then return end

	mod:Destroy()
end