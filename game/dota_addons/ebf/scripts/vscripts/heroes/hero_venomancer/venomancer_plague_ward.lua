venomancer_plague_ward_ebf = class({})


function venomancer_plague_ward_ebf:OnSpellStart()
	local caster = self:GetCaster()
	local position = self:GetCursorPosition()
	
	EmitSoundOn("Hero_Venomancer.Plague_Ward", caster)
	self:CreateWard(position)
end

function venomancer_plague_ward_ebf:CreateWard(position, duration)
	local caster = self:GetCaster()
	local fDur = duration or self:GetSpecialValueFor("duration")
	local hp = self:GetSpecialValueFor("ward_hp_tooltip")
	local damage = self:GetSpecialValueFor("ward_damage_tooltip")
	
	local ward = caster:CreateSummon("npc_dota_venomancer_plague_ward_1", position or caster:GetAbsOrigin(), fDur)
	ward:SetCoreHealth(hp)
	ward:SetBaseHealthRegen(0)
	ward:SetModelScale( 0.8 + (self:GetLevel()-1) * 0.1 )
	ward:SetHullRadius(8)
	ResolveNPCPositions(position, 64)
	ward:AddNewModifier( caster, self, "modifier_magic_immune", {})
	ward:SetAverageBaseDamage(damage, 15)
	
	ward:MoveToPositionAggressive(ward:GetAbsOrigin())
end