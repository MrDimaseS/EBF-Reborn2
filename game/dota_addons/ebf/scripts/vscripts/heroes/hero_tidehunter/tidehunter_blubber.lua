tidehunter_blubber = class({})

function tidehunter_blubber:OnHeroLevelUp()
	if IsServer() and self:GetSpecialValueFor("base_model_size") ~= 0 then
		self.scale = self:GetCaster():GetModelScale()
		self.model_increase = self:GetSpecialValueFor("model_size")

		self:GetCaster():SetModelScale(self.scale + self.model_increase)
	end
end

function tidehunter_blubber:Spawn()
	if IsServer() and self:GetSpecialValueFor("base_model_size") ~= 0 then
		self:GetCaster():SetModelScale(self:GetSpecialValueFor("base_model_size"))
	end
end


function tidehunter_blubber:GetIntrinsicModifierName()
	return "modifier_tidehunter_blubber_passive"
end

function tidehunter_blubber:ShouldUseResources()
	return true
end

LinkLuaModifier("modifier_tidehunter_blubber_passive", "heroes/hero_tidehunter/tidehunter_blubber", LUA_MODIFIER_MOTION_NONE)
modifier_tidehunter_blubber_passive = class({})

function modifier_tidehunter_blubber_passive:OnCreated()
	self:OnRefresh()
	self.attack_range_bonus = self:GetSpecialValueFor("attack_range_bonus")
	self.spell_amp_bonus = self:GetSpecialValueFor("spell_amp_bonus")
	self.cooldown_reduction = self:GetSpecialValueFor("cooldown_reduction") / 100
	if IsServer() then
		self:StartIntervalThink( 0.1 )
	end
end

function modifier_tidehunter_blubber_passive:OnRefresh()
	self.damage_cleanse = self:GetSpecialValueFor("damage_cleanse") / 100
	self.damage_reset_interval = self:GetSpecialValueFor("damage_reset_interval")
	self._damageTaken = 0
end

function modifier_tidehunter_blubber_passive:OnIntervalThink()
	self._damageTaken = 0
	self:StartIntervalThink( -1 )
end

function modifier_tidehunter_blubber_passive:DeclareFunctions()
	return
	{
		MODIFIER_EVENT_ON_TAKEDAMAGE, 
		MODIFIER_PROPERTY_ATTACK_RANGE_BONUS,
		MODIFIER_PROPERTY_SPELL_AMPLIFY_PERCENTAGE
	}
end

function modifier_tidehunter_blubber_passive:OnTakeDamage(params)
	local parent = self:GetParent()
	local caster = self:GetCaster()
	if params.unit == parent then
		if self._damageTaken > self.damage_cleanse * params.unit:GetMaxHealth() then
			if self.cooldown_reduction == 0 then
				EmitSoundOn( "Hero_Tidehunter.KrakenShell", parent)
				caster:Dispel( caster, true )
				ParticleManager:FireParticle("particles/units/heroes/hero_tidehunter/tidehunter_krakenshell_purge.vpcf", PATTACH_POINT_FOLLOW, params.unit)
				self:OnIntervalThink()
			else
				EmitSoundOn( "Hero_Tidehunter.KrakenShell", parent)
				caster:Dispel( caster, true )
				for i = 0, self:GetParent():GetAbilityCount() - 1 do
					local ability = parent:GetAbilityByIndex(i)
					if ability and ability:GetCooldownTimeRemaining() > 0 and ability ~= nil and not ability:IsInnateAbility() then
						ability:ModifyCooldown(-ability:GetCooldownTimeRemaining() * self.cooldown_reduction)
					end
				end
				ParticleManager:FireParticle("particles/units/heroes/hero_tidehunter/tidehunter_krakenshell_purge.vpcf", PATTACH_POINT_FOLLOW, params.unit)
				self:OnIntervalThink()
			end
		else
			self._damageTaken = self._damageTaken + params.damage
			self:StartIntervalThink( self.damage_reset_interval )
		end
	end
end

function modifier_tidehunter_blubber_passive:IsHidden()
	return true
end

function modifier_tidehunter_blubber_passive:IsPurgable()
	return false
end

function modifier_tidehunter_blubber_passive:GetModifierAttackRangeBonus()
	if self.attack_range_bonus ~= 0 and self:GetParent():GetLevel() > 1 then
		return self.attack_range_bonus * self:GetParent():GetLevel()
	end
end

function modifier_tidehunter_blubber_passive:GetModifierSpellAmplify_Percentage()
	if self.spell_amp_bonus ~= 0 and self:GetParent():GetLevel() > 1 then
		return self.spell_amp_bonus * self:GetParent():GetLevel()
	end
end