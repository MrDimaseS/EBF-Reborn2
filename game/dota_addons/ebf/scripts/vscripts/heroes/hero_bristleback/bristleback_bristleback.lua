bristleback_bristleback = class({})

function bristleback_bristleback:GetIntrinsicModifierName()
	return "modifier_bristleback_bristleback_passive"
end

modifier_bristleback_bristleback_passive = class({})
LinkLuaModifier( "modifier_bristleback_bristleback_passive", "heroes/hero_bristleback/bristleback_bristleback", LUA_MODIFIER_MOTION_NONE )

function modifier_bristleback_bristleback_passive:OnCreated()
	if IsServer() then
		self.quills = self:GetCaster():FindAbilityByName("bristleback_quill_spray")
	end
end

function modifier_bristleback_bristleback_passive:DeclareFunctions()
	return {MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE}
end

function modifier_bristleback_bristleback_passive:GetModifierIncomingDamage_Percentage( params )
	if self:GetParent():PassivesDisabled() then return end
	if not IsEntitySafe( self.quills ) then return end
	local parent = self:GetParent()
	
	local max_reduction = self:GetSpecialValueFor("max_damage_reduction")
	local min_reduction = self:GetSpecialValueFor("min_damage_reduction")
	local red_scale = max_reduction - min_reduction
	
	local dotPr = DotProduct( params.target:GetForwardVector(), params.attacker:GetForwardVector() )
	local scaling = (dotPr + 1) / 2
	
	local total_reduction = min_reduction + red_scale * scaling
	
	self.damageTaken = (self.damageTaken or 0) + params.damage * total_reduction/100
	local hpThreshold = self:GetCaster():GetHealth() * self:GetSpecialValueFor("quill_release_threshold") / 100
	
	if hpThreshold == 0 then return end
	if parent:GetHealth() == 0 then return end
	if parent:GetHealth() < params.damage then return end
	
	if hpThreshold < self.damageTaken then
		local damageTaken = self.damageTaken
		self.damageTaken = 0
		Timers:CreateTimer( function()
			if parent:GetHealth() == 0 then return end
			if not self.quills:IsTrained() then return end
			if parent:HasScepter() then
				self.quills:OnSpellStart()
			else
				local direction = CalculateDirection( params.attacker, parent )
				local damage = self.quills:GetSpecialValueFor("quill_base_damage")
				local stackDamage = self.quills:GetSpecialValueFor("quill_stack_damage")
				local distance = self.quills:GetSpecialValueFor("radius")
				local duration = self.quills:GetSpecialValueFor("quill_stack_duration")
				local maxDamage = self.quills:GetSpecialValueFor("max_damage")
				
				for _, enemy in ipairs( parent:FindEnemyUnitsInCone( direction, parent:GetAbsOrigin(), distance/2, distance) ) do
					local quillsDebuff = enemy:FindModifierByName("modifier_bristleback_quill_spray")
					local dmgTaken = damage
					if quillsDebuff then
						dmgTaken = math.min( maxDamage, dmgTaken + quillsDebuff:GetStackCount() * stackDamage )
					end
					self.quills:DealDamage( parent, enemy, dmgTaken, {damage_type = DAMAGE_TYPE_PHYSICAL} )
					
					enemy:AddNewModifier( parent, self.quills, "modifier_bristleback_quill_spray", {duration = duration}):IncrementStackCount()
					enemy:AddNewModifier( parent, self.quills, "modifier_bristleback_quill_spray_stack", {duration = duration})
					
					EmitSoundOn( "Hero_Bristleback.QuillSpray.Target", enemy )
				end
				
				local quillFX = ParticleManager:CreateParticle( "particles/units/heroes/hero_bristleback/bristleback_quill_spray_conical.vpcf", PATTACH_WORLDORIGIN, nil )
				ParticleManager:SetParticleControl( quillFX, 0, parent:GetAbsOrigin() ) 
				ParticleManager:SetParticleControlTransformForward( quillFX, 0, parent:GetAbsOrigin(), -direction )
				
				EmitSoundOn( "Hero_Bristleback.QuillSpray.Cast", parent )
			end
		
			-- damageTaken = damageTaken - hpThreshold
			-- if damageTaken >= hpThreshold and damageTaken > 0 and hpThreshold > 0 then
				-- return 0.1
			-- end
		end)
	end

	return -total_reduction
end