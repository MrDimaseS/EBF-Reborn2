enemy_minion = class({})

function enemy_minion:GetIntrinsicModifierName()
	return "modifier_enemy_minion_passive"
end

modifier_enemy_minion_passive = class({})
LinkLuaModifier("modifier_enemy_minion_passive", "bosses/enemy_minion", 0)

function modifier_enemy_minion_passive:OnCreated()
	self:OnRefresh()
end

function modifier_enemy_minion_passive:OnRefresh()
	self.dmg_taken_from_aoe = -self:GetSpecialValueFor("dmg_taken_from_aoe")
	self.reduction_duration = self:GetSpecialValueFor("reduction_duration")
	self:GetParent()._minionAbilitiesTracked = {}
end

function modifier_enemy_minion_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE, MODIFIER_EVENT_ON_TAKEDAMAGE}
end

function modifier_enemy_minion_passive:OnTakeDamage( params )
	if IsClient() then return end
	if params.inflictor and params.unit ~= self:GetParent() and params.unit:IsSameTeam( self:GetParent() ) and (not (params.unit._minionAbilitiesTracked and params.unit._minionAbilitiesTracked[params.inflictor]) or GameRules:GetGameTime() < params.unit._minionAbilitiesTracked[params.inflictor] + self.reduction_duration) then
		self:GetParent()._minionAbilitiesTracked[params.inflictor] = GameRules:GetGameTime()
	end
end

function modifier_enemy_minion_passive:GetModifierIncomingDamage_Percentage( params )
	if IsClient() then return end
	if params.inflictor and self:GetParent()._minionAbilitiesTracked[params.inflictor] then
		if GameRules:GetGameTime() < self:GetParent()._minionAbilitiesTracked[params.inflictor] + self.reduction_duration then
			return self.dmg_taken_from_aoe 
		else
		end
	end
end

function modifier_enemy_minion_passive:IsHidden()
	return true
end

function modifier_enemy_minion_passive:IsPurgable()
	return false
end