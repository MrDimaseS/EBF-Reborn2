boss_naga_mirror_image = class({})

function boss_naga_mirror_image:OnSpellStart()
	local caster = self:GetCaster()

	caster:Stop()
	ProjectileManager:ProjectileDodge( caster )
	caster:Dispel( caster )

	caster:AddNewModifier( caster, self, "modifier_boss_naga_mirror_image", { duration = self:GetSpecialValueFor( "invuln_duration" ) })

	EmitSoundOn( "Hero_NagaSiren.MirrorImage", caster )
end


LinkLuaModifier( "modifier_boss_naga_mirror_image", "bosses/boss_slardars/boss_naga_mirror_image", LUA_MODIFIER_MOTION_NONE )
modifier_boss_naga_mirror_image = class({})

function modifier_boss_naga_mirror_image:OnCreated( kv )
	self.count = self:GetAbility():GetSpecialValueFor( "images_count" )
	self.illusion_duration = self:GetAbility():GetSpecialValueFor( "illusion_duration" )
	self.outgoing = 1 + self:GetAbility():GetSpecialValueFor( "outgoing_damage" ) / 100
	self.incoming = self:GetAbility():GetSpecialValueFor( "incoming_damage" ) / 100
	self.distance = 128
end

function modifier_boss_naga_mirror_image:OnDestroy()
	if not IsServer() then return end
	local caster = self:GetCaster()
	local possiblePositions = {}
	table.insert( possiblePositions, caster:GetAbsOrigin() )
	for i = 1, self.count do
		local possiblePosition = caster:GetAbsOrigin() + RotateVector2D( caster:GetRightVector(), ToRadians( 90 * (i-1) ) ) * self.distance
		table.insert( possiblePositions, possiblePosition )
	end
	table.shuffle( possiblePositions )
	caster:SetAbsOrigin( possiblePositions[1] )
	table.remove( possiblePositions, 1 )
	for _, position in ipairs( possiblePositions ) do
		local unit = CreateUnitByName( "npc_dota_boss_naga_illusionist", position, true, nil, nil, caster:GetTeam() )
		unit:SetBaseMaxHealth( math.ceil( caster:GetBaseMaxHealth() / self.incoming ) )
		unit:SetMaxHealth( math.ceil( caster:GetMaxHealth() / self.incoming ) )
		unit:SetHealth( math.max( 1, math.ceil( unit:GetMaxHealth() * caster:GetHealthPercent() / 100 ) ) )
		
		unit:SetAverageBaseDamage( caster:GetAverageBaseDamage() * self.outgoing )
		
		unit:FindAbilityByName("boss_naga_mirror_image"):SetActivated( false )
		unit:FindAbilityByName("boss_naga_ensnare"):SetActivated( false )
		
		unit:SetMaximumGoldBounty( 0 )
		unit:SetMinimumGoldBounty( 0 )
		unit:SetDeathXP( 0 )
		
		unit.hasBeenProcessed = true
		
		unit:AddNewModifier(self, nil, "modifier_kill", {duration = self.illusion_duration})
	end
	ResolveNPCPositions( caster:GetAbsOrigin(), 350 )
end

--------------------------------------------------------------------------------
-- Status Effects
function modifier_boss_naga_mirror_image:CheckState()
	local state = {
		[MODIFIER_STATE_INVULNERABLE] = true,
		[MODIFIER_STATE_STUNNED] = true,
	}

	return state
end

function modifier_boss_naga_mirror_image:GetEffectName()
	return "particles/units/heroes/hero_siren/naga_siren_mirror_image.vpcf"
end

function modifier_boss_naga_mirror_image:GetEffectAttachType()
	return PATTACH_ABSORIGIN_FOLLOW
end

function modifier_boss_naga_mirror_image:IsHidden()
	return true
end

function modifier_boss_naga_mirror_image:IsDebuff()
	return false
end

function modifier_boss_naga_mirror_image:IsStunDebuff()
	return false
end

function modifier_boss_naga_mirror_image:IsPurgable()
	return false
end