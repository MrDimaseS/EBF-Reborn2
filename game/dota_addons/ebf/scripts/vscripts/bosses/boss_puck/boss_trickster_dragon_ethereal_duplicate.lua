boss_trickster_dragon_ethereal_duplicate = class({})

function boss_trickster_dragon_ethereal_duplicate:GetIntrinsicModifierName()
	return "modifier_boss_trickster_dragon_ethereal_duplicate"
end

modifier_boss_trickster_dragon_ethereal_duplicate = class({})
LinkLuaModifier( "modifier_boss_trickster_dragon_ethereal_duplicate", "bosses/boss_puck/boss_trickster_dragon_ethereal_duplicate", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_trickster_dragon_ethereal_duplicate:OnCreated()
	self:OnRefresh()
end

function modifier_boss_trickster_dragon_ethereal_duplicate:OnRefresh()
	self.duration = self:GetSpecialValueFor("duration")
	self.incoming_damage = self:GetSpecialValueFor("incoming_damage") / 100
end

function modifier_boss_trickster_dragon_ethereal_duplicate:DeclareFunctions()
	return {MODIFIER_EVENT_ON_ABILITY_FULLY_CAST}
end

function modifier_boss_trickster_dragon_ethereal_duplicate:OnAbilityFullyCast( params )
	if self:GetParent():PassivesDisabled() then return end
	if params.unit == self:GetParent() then
		local illusion = CreateUnitByName( params.unit:GetUnitName(), params.unit:GetAbsOrigin(), true, nil, nil, self:GetCaster():GetTeam() )
		params.unit:Blink( params.unit:GetAbsOrigin() + RandomVector( 600 ) )
		illusion:Blink( illusion:GetAbsOrigin() + RandomVector( 600 ) )
		
		for i = 0, illusion:GetAbilityCount() - 1 do
			local ability = illusion:GetAbilityByIndex( i )
			if ability then
				ability:SetActivated( false )
			end
		end
		illusion:SetCoreHealth( params.unit:GetMaxHealth() / self.incoming_damage )
		illusion:SetHealth( math.ceil( illusion:GetMaxHealth() * (params.unit:GetHealthPercent() / 100) ) )
		illusion.hasBeenProcessed = true
		Timers:CreateTimer( function()
			if not IsEntitySafe( params.unit ) or params.unit:IsAlive() or params.unit:GetHealth() <= 0 then return end
			illusion:SetHealth( math.ceil( illusion:GetMaxHealth() * (params.unit:GetHealthPercent() / 100) ) )
		end)
		Timers:CreateTimer( 0.1, function()
			if not IsEntitySafe( params.unit ) or params.unit:IsAlive() or params.unit:GetHealth() <= 0 then return end
			illusion:SetHealth( math.ceil( illusion:GetMaxHealth() * (params.unit:GetHealthPercent() / 100) ) )
		end)
		
		illusion:AddNewModifier( params.unit, self:GetAbility(), "modifier_boss_trickster_dragon_ethereal_duplicate_illusion", {duration = self.duration} )
	end
end

function modifier_boss_trickster_dragon_ethereal_duplicate:IsHidden()
	return true
end

modifier_boss_trickster_dragon_ethereal_duplicate_illusion = class({})
LinkLuaModifier( "modifier_boss_trickster_dragon_ethereal_duplicate_illusion", "bosses/boss_puck/boss_trickster_dragon_ethereal_duplicate", LUA_MODIFIER_MOTION_NONE )

function modifier_boss_trickster_dragon_ethereal_duplicate_illusion:OnCreated()
	self:OnRefresh()
end

function modifier_boss_trickster_dragon_ethereal_duplicate_illusion:OnRefresh()
	self.outgoing_damage = self:GetSpecialValueFor("outgoing_damage") - 100
end

function modifier_boss_trickster_dragon_ethereal_duplicate_illusion:OnDestroy()
	if IsServer() and self:GetParent():IsAlive() then
		local parent = self:GetParent()
		parent:ForceKill( false )
		Timers:CreateTimer( 0.1, function() if IsEntitySafe(parent) then UTIL_Remove( parent ) end end )
	end
end

function modifier_boss_trickster_dragon_ethereal_duplicate_illusion:DeclareFunctions()
	return {MODIFIER_PROPERTY_DISABLE_HEALING, MODIFIER_PROPERTY_BONUSDAMAGEOUTGOING_PERCENTAGE, MODIFIER_PROPERTY_BASEDAMAGEOUTGOING_PERCENTAGE, MODIFIER_PROPERTY_IS_ILLUSION, MODIFIER_PROPERTY_ILLUSION_LABEL }
end

function modifier_boss_trickster_dragon_ethereal_duplicate_illusion:GetDisableHealing()
	return 1
end

function modifier_boss_trickster_dragon_ethereal_duplicate_illusion:GetIsIllusion()
	return 1
end

function modifier_boss_trickster_dragon_ethereal_duplicate_illusion:GetModifierIllusionLabel()
	return 1
end

function modifier_boss_trickster_dragon_ethereal_duplicate_illusion:GetModifierBonusDamageOutgoing_Percentage()
	return -100
end
function modifier_boss_trickster_dragon_ethereal_duplicate_illusion:GetModifierBaseDamageOutgoing_Percentage()
	return self.outgoing_damage
end

function modifier_boss_trickster_dragon_ethereal_duplicate_illusion:IsHidden()
	return true
end