item_hand_of_midas_ebf = class({})

function item_hand_of_midas_ebf:GetIntrinsicModifierName()
	return "modifier_hand_of_midas_passive"
end

function item_hand_of_midas_ebf:OnSpellStart()
	local caster = self:GetCaster()
	local target = self:GetCursorTarget()
	
	EmitSoundOn( "DOTA_Item.Hand_Of_Midas", target )
	ParticleManager:FireRopeParticle( "particles/items2_fx/hand_of_midas.vpcf", PATTACH_POINT_FOLLOW, target, caster )
	self:DealDamage( caster, target, target:GetMaxHealth(), {damage_type = DAMAGE_TYPE_PURE, damage_flags = DOTA_DAMAGE_FLAG_NO_DAMAGE_MULTIPLIERS + DOTA_DAMAGE_FLAG_NO_SPELL_AMPLIFICATION + DOTA_DAMAGE_FLAG_NO_SPELL_LIFESTEAL + DOTA_DAMAGE_FLAG_HPLOSS } )
	caster:AddGold( self:GetSpecialValueFor("bonus_gold") )
end

modifier_hand_of_midas_passive = class({})
LinkLuaModifier( "modifier_hand_of_midas_passive", "items/item_hand_of_midas.lua" ,LUA_MODIFIER_MOTION_NONE )

function modifier_hand_of_midas_passive:OnCreated()
	self:OnRefresh()
end

function modifier_hand_of_midas_passive:OnRefresh()
	self.bonus_attack_speed = self:GetSpecialValueFor("bonus_attack_speed")
	self.bonus_gold = self:GetSpecialValueFor("bonus_gold") / 100
end

function modifier_hand_of_midas_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_ATTACKSPEED_BONUS_CONSTANT}
end


function modifier_hand_of_midas_passive:GetModifierAttackSpeedBonus_Constant()
	return self.bonus_attack_speed
end

function modifier_hand_of_midas_passive:IsHidden()
	return true
end

function modifier_hand_of_midas_passive:IsPurgable()
	return false
end

function modifier_hand_of_midas_passive:GetAttributes()
	return MODIFIER_ATTRIBUTE_MULTIPLE
end