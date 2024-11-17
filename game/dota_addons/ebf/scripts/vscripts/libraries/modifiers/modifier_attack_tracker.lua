modifier_attack_tracker = class({})

function modifier_attack_tracker:DeclareFunctions()
    return {MODIFIER_EVENT_ON_ATTACK,
			MODIFIER_EVENT_ON_ATTACK_RECORD_DESTROY,
			 }
end

function modifier_attack_tracker:OnAttack( params )
	if params.attacker == self:GetParent() and params.no_attack_cooldown then
		params.attacker._instantAttackRecordHistory = params.attacker._instantAttackRecordHistory or {}
		params.attacker._instantAttackRecordHistory[params.record] = table.copy(params.attacker.autoAttackFromAbilityState) or {}
	end
end

function modifier_attack_tracker:OnAttackRecordDestroy( params )
	if params.attacker._instantAttackRecordHistory and params.attacker._instantAttackRecordHistory[params.record] then
		params.attacker._instantAttackRecordHistory[params.record] = nil
		for k,v in ipairs(params.attacker._instantAttackRecordHistory ) do
			return
		end
		self:Destroy()
	end
end

function modifier_attack_tracker:IsHidden()
    return true
end