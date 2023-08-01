ogre_magi_bloodlust = class({})

function ogre_magi_bloodlust:GetIntrinsicModifierName()
	return "modifier_ogre_magi_bloodlust_passive"
end

function ogre_magi_bloodlust:IsStealable()
	return true
end

function ogre_magi_bloodlust:IsHiddenWhenStolen()
	return false
end

function ogre_magi_bloodlust:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	self:Bloodlust( target )
	EmitSoundOn( "Hero_OgreMagi.Bloodlust.Cast", self:GetCaster() )
end

function ogre_magi_bloodlust:Bloodlust( hTarget )
	local caster = self:GetCaster()
	local target = hTarget or self:GetCursorTarget()

	EmitSoundOn("Hero_OgreMagi.Bloodlust.Target", target)
	EmitSoundOn("Hero_OgreMagi.Bloodlust.Target.FP", target)
	local nfx = ParticleManager:CreateParticle("particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_cast.vpcf", PATTACH_POINT, caster)
				ParticleManager:SetParticleControlEnt(nfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack3", caster:GetAbsOrigin(), true)
				ParticleManager:SetParticleControlEnt(nfx, 2, target, PATTACH_POINT, "attach_hitloc", target:GetAbsOrigin(), true)
				ParticleManager:SetParticleControl(nfx, 3, target:GetAbsOrigin())
				ParticleManager:ReleaseParticleIndex(nfx)
	
	local duration = self:GetSpecialValueFor("duration")
	local bloodlust = target:FindModifierByName("modifier_ogre_magi_bloodlust_buff")
	if bloodlust then duration = duration + bloodlust:GetRemainingTime() end
	
	target:AddNewModifier(caster, self, "modifier_ogre_magi_bloodlust_buff", {Duration = duration})
end

modifier_ogre_magi_bloodlust_passive = class({})
LinkLuaModifier( "modifier_ogre_magi_bloodlust_passive", "heroes/hero_ogre_magi/ogre_magi_bloodlust.lua",LUA_MODIFIER_MOTION_NONE )

if IsServer() then
	function modifier_ogre_magi_bloodlust_passive:OnCreated(kv)
		self:StartIntervalThink(1)
	end

	function modifier_ogre_magi_bloodlust_passive:OnRemoved()
	end

	function modifier_ogre_magi_bloodlust_passive:OnIntervalThink()
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		if ability:GetAutoCastState() and caster:IsAlive() and ability:IsFullyCastable() and ability:IsOwnersManaEnough() and not caster:HasActiveAbility() and not caster:IsMoving() then
			local friends = caster:FindFriendlyUnitsInRadius(caster:GetAbsOrigin(), self:GetAbility():GetCastRange(caster:GetAbsOrigin(), caster), {order = FIND_CLOSEST})
			for _,friend in ipairs(friends) do
				if not friend:HasModifier("modifier_ogre_magi_bloodlust_buff") then
					caster:SetCursorCastTarget(friend)
					caster:CastAbilityOnTarget(friend, ability, caster:GetPlayerOwnerID() )
				end
			end
		elseif not ability:IsOwnersManaEnough() and ability:GetAutoCastState() then
			ability:ToggleAutoCast()
		end
	end
end

function modifier_ogre_magi_bloodlust_passive:IsHidden() return true end

modifier_ogre_magi_bloodlust_buff = class({})
LinkLuaModifier( "modifier_ogre_magi_bloodlust_buff", "heroes/hero_ogre_magi/ogre_magi_bloodlust.lua",LUA_MODIFIER_MOTION_NONE )

function modifier_ogre_magi_bloodlust_buff:OnCreated()
	self:OnRefresh()
end

function modifier_ogre_magi_bloodlust_buff:OnRefresh()
	self.bonus_movement_speed = self:GetSpecialValueFor("bonus_movement_speed")
	self.self_bonus = self:GetSpecialValueFor("self_bonus")
	self.attack_speed = TernaryOperator( self.self_bonus, self:GetCaster() == self:GetParent(), self:GetSpecialValueFor("bonus_attack_speed") )
	self.modelscale = self:GetSpecialValueFor("modelscale")
end

function modifier_ogre_magi_bloodlust_buff:DeclareFunctions()
	local funcs = {
		MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE,
		MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT,
		MODIFIER_PROPERTY_MODEL_SCALE,
	}
	return funcs
end

function modifier_ogre_magi_bloodlust_buff:GetModifierMoveSpeedBonus_Percentage()
	return self.bonus_movement_speed
end

function modifier_ogre_magi_bloodlust_buff:GetModifierAttackSpeedBonus_Constant()
	return self.attack_speed
end

function modifier_ogre_magi_bloodlust_buff:GetModifierModelScale()
	return self.modelscale
end

function modifier_ogre_magi_bloodlust_buff:GetEffectName()
	return "particles/units/heroes/hero_ogre_magi/ogre_magi_bloodlust_buff.vpcf"
end

function modifier_ogre_magi_bloodlust_buff:IsDebuff()
	return false
end