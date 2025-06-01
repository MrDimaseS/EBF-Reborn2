antimage_blink = class ({})

function antimage_blink:GetBehavior()
	local behavior = bit.bor(DOTA_ABILITY_BEHAVIOR_POINT, DOTA_ABILITY_BEHAVIOR_ROOT_DISABLES)
	if self:GetSpecialValueFor("illusion_duration") > 0 then
		behavior = bit.bor(behavior, DOTA_ABILITY_BEHAVIOR_AUTOCAST)
	end
	return behavior
end

function antimage_blink:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorPosition()
	local position = caster:GetAbsOrigin() + math.min( self:GetSpecialValueFor("blink_distance"), CalculateDistance( target, caster ) ) * CalculateDirection( target, caster )
	
	local illusionDuration = self:GetSpecialValueFor("illusion_duration")
	if illusionDuration > 0 then
		local illusionDmgOut = self:GetSpecialValueFor("illusion_damage_dealt")
		local illusionDmgIn = self:GetSpecialValueFor("illusion_damage_taken")
		caster:ConjureImage( {outgoing_damage = illusionDmgOut, incoming_damage = illusionDmgIn, position = TernaryOperator( position, self:GetAutoCastState(), caster:GetAbsOrigin() )}, illusionDuration, caster, 1 )
	end
	
	if self:GetAutoCastState() then
		EmitSoundOn("DOTA_Item.BlinkDagger.Activate", self)
	else
		caster:Blink(position, {distance = self:GetSpecialValueFor("blink_distance")})
		local maxHPHeal = self:GetSpecialValueFor("max_hp_heal") / 100
		if maxHPHeal > 0 then
			caster:HealEvent( caster:GetMaxHealth() * maxHPHeal, self, caster )
		end
	end
	
end