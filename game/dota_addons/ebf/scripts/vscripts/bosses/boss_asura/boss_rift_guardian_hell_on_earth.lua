boss_rift_guardian_hell_on_earth = class({})

function boss_rift_guardian_hell_on_earth:OnSpellStart()
	local caster = self:GetCaster()
	caster:AddNewModifier( caster, self, "modifier_boss_rift_guardian_hell_on_earth", {duration = self:GetChannelTime()} )
end

function boss_rift_guardian_hell_on_earth:OnChannelFinish( bInterrupt )
	local caster = self:GetCaster()
	caster:RemoveModifierByName("modifier_boss_rift_guardian_hell_on_earth")
end

modifier_boss_rift_guardian_hell_on_earth = class({})
LinkLuaModifier( "modifier_boss_rift_guardian_hell_on_earth", "bosses/boss_asura/boss_rift_guardian_hell_on_earth", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_rift_guardian_hell_on_earth:OnCreated()
	
end