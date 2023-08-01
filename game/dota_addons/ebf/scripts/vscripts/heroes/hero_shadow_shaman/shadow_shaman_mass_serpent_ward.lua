shadow_shaman_mass_serpent_ward = class({})

function shadow_shaman_mass_serpent_ward:OnSpellStart()
	local caster = self:GetCaster()
	local position = self:GetCursorPosition()
	
	local wards = self:GetSpecialValueFor("ward_count")
	local spawnRadius = self:GetSpecialValueFor("spawn_radius")
	local duration = self:GetSpecialValueFor("duration")
	local direction = caster:GetForwardVector()
	local angle = 360 / wards
	for i = 1, wards do
		local spawnPos = position + RotateVector2D( direction, ToRadians( angle * (i-1) ) ) * spawnRadius 
		self:CreateWard( spawnPos, duration )
	end
end

function shadow_shaman_mass_serpent_ward:CreateWard( position, duration )
	local caster = self:GetCaster()
	local ward = caster:CreateSummon( "npc_dota_shadow_shaman_ward_"..self:GetLevel(), position, duration )
	ward:AddNewModifier( caster, self, "modifier_shadow_shaman_serpent_ward", {duration = duration} )
end