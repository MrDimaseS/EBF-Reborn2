tinker_rearm = tinker_rearm or class({})

function tinker_rearm:IsStealable()
	return false
end

function tinker_rearm:GetIntrinsicModifierName()
	return "modifier_tinker_rearm_debuff"
end

function tinker_rearm:OnSpellStart()
	local caster = self:GetCaster()
	if not caster or caster:IsNull() then return end

	caster:AddNewModifier(caster, self, "modifier_tinker_rearm_hidden", { duration = self:GetChannelTime() })
end

function tinker_rearm:OnChannelFinish(bInterrupted)
	local caster = self:GetCaster()
	caster:RemoveModifierByName("modifier_tinker_rearm_hidden")
	if not bInterrupted then
		local refresh = function(func, min_idx, max_idx)
			for ent_idx = min_idx, max_idx do
				local ent = caster[func](caster, ent_idx)
				if IsEntitySafe( ent ) and ( ent.IsRearmable == nil or ent:IsRearmable() ) and not ( ent.IsNeutralDrop and ent:IsNeutralDrop() ) then
					ent:EndCooldown()
				end
			end
		end
		refresh("GetItemInSlot", DOTA_ITEM_SLOT_1, DOTA_ITEM_SLOT_9)
		refresh("GetAbilityByIndex", 0, 5)
		
		caster:AddNewModifier( caster, self, "modifier_tinker_rearm_debuff", { duration = self:GetSpecialValueFor("debuff_duration") })
	else
		caster:FadeGesture(_G["ACT_DOTA_TINKER_REARM" .. math.min(self:GetLevel(), 3)])
	end
end

modifier_tinker_rearm_debuff = class({})
LinkLuaModifier("modifier_tinker_rearm_debuff", 'heroes/hero_tinker/tinker_rearm', LUA_MODIFIER_MOTION_NONE)

function modifier_tinker_rearm_debuff:OnCreated()
	self:OnRefresh()
	if IsServer() then
		self.modifiersToTrack = {}
		self:StartIntervalThink( 0 )
	end
end

function modifier_tinker_rearm_debuff:OnRefresh()
	self.duration_debuff = self:GetSpecialValueFor("duration_debuff")
	self.debuff_max = self:GetSpecialValueFor("debuff_max")
	if IsServer() then
		self:AddIndependentStack( self:GetRemainingTime(), self.debuff_max )
	end
end

function modifier_tinker_rearm_debuff:OnIntervalThink()
	if self:GetStackCount() <= 0 then return end
	for modifier, lastTime in pairs( self.modifiersToTrack ) do
		if not IsModifierSafe(modifier) then
			self.modifiersToTrack[modifier] = nil
		elseif modifier:GetLastAppliedTime() ~= lastTime then
			self.modifiersToTrack[modifier] = modifier:GetLastAppliedTime()
			print( modifier:GetName(), modifier:GetDuration(), (1 - self:OnTooltip()/100 ) )
			modifier:SetDuration( modifier:GetDuration() * (1 - self:OnTooltip()/100 ), true )
		end
	end
end

function modifier_tinker_rearm_debuff:DeclareFunctions()
	return {MODIFIER_PROPERTY_TOOLTIP, MODIFIER_EVENT_ON_MODIFIER_ADDED }
end

function modifier_tinker_rearm_debuff:OnTooltip()
	return self.duration_debuff * self:GetStackCount()
end

function modifier_tinker_rearm_debuff:OnModifierAdded( params )
	if params.added_buff:GetCaster() == self:GetCaster() and params.added_buff:GetAbility() ~= self:GetAbility() and params.added_buff:GetDuration() > 0 then
		self.modifiersToTrack[params.added_buff] = 0
	end
end

function modifier_tinker_rearm_debuff:IsHidden()
	return self:GetStackCount() <= 0
end

function modifier_tinker_rearm_debuff:DestroyOnExpire()
	return false
end

function modifier_tinker_rearm_debuff:IsPermanent()
	return true
end

function modifier_tinker_rearm_debuff:IsDebuff()
	return true
end

function modifier_tinker_rearm_debuff:IsPurgable()
	return false
end

modifier_tinker_rearm_hidden = modifier_tinker_rearm_hidden or class({})
LinkLuaModifier("modifier_tinker_rearm_hidden", 'heroes/hero_tinker/tinker_rearm', LUA_MODIFIER_MOTION_NONE)

function modifier_tinker_rearm_hidden:OnCreated()
	if not IsServer() then return end
	
	local level = math.min(self:GetAbility():GetLevel(), 3)
	local caster = self:GetParent()

	if not level or not caster then return end
	
	caster:EmitSound("Hero_Tinker.RearmStart")
	caster:EmitSound("Hero_Tinker.Rearm")

	self.pfx = ParticleManager:CreateParticle("particles/units/heroes/hero_tinker/tinker_rearm.vpcf", PATTACH_POINT_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(self.pfx, 0, caster, PATTACH_POINT_FOLLOW, "attach_attack2", caster:GetOrigin(), true)
	
	caster:StartGesture(_G["ACT_DOTA_TINKER_REARM" .. level])
end

function modifier_tinker_rearm_hidden:OnDestroy()
	if not IsServer() then return end
	
	ParticleManager:DestroyParticle(self.pfx, false)
	ParticleManager:ReleaseParticleIndex(self.pfx)
end

function modifier_tinker_rearm_hidden:IsHidden()
	return true
end