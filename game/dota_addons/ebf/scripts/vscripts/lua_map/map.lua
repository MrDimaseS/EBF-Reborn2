require( "libraries/Timers" )
if map == nil then
   map = class({})
end

function HeroPositionsCheck()
   -- local heroes = HeroList:GetAllHeroes()
   -- for _, hero in pairs(heroes) do
      -- local position = hero:GetAbsOrigin()

      -- if (position.x < -5000 or position.x > 5000 or position.y < -5000 or position.y > 5000 or position.z < 0 or position.z > 9000) then
         -- -- Teleport hero back to center of map if they move outside the boundaries and below ground level
         -- hero:SetAbsOrigin(Vector(0, 0, 0))
         -- FindClearSpaceForUnit(hero, hero:GetAbsOrigin(), true)
         -- position = hero:GetAbsOrigin() -- Update the local position variable
         -- print(hero:GetName() .. " is teleported back to " .. tostring(position))
      -- elseif (position.z < 0 or position.z > 9000) then
         -- -- Set hero's Z-coordinate to 0 if they move below ground level
         -- position.z = 0
         -- hero:SetAbsOrigin(position)
         -- print(hero:GetName() .. " is teleported back to " .. tostring(position))
      -- end
	  -- print( position.x, position.y )
   -- end
end

-- Timers:CreateTimer(1, function()
-- HeroPositionsCheck()
-- return 1
-- end)

function OnWaterEnter(trigger)
   local ent = trigger.activator
   print (ent:GetName())
   ent.InWater = true
   print (ent.InWater)
end

function OnWaterExit(trigger)
   local ent = trigger.activator
   if not ent then return end
   ent.InWater = false
   return
end

function LeftBoundingBox(trigger)
	local ent = trigger.activator
	if not ent then return end
	if ent:GetAbsOrigin().x == 0 and ent:GetAbsOrigin().y == 0 then return end
	ent:StopMotionControllers()
	ent:InterruptMotionControllers(true)

	local x = ent:GetAbsOrigin().x
	local y = ent:GetAbsOrigin().y
	if x < 0 then
		x = math.max( x, trigger.caller:GetBoundingMins().x + 1 )
	else
		x = math.min( x, trigger.caller:GetBoundingMaxs().x -1 )
	end
	if y < 0 then
		y = math.max( y, trigger.caller:GetBoundingMins().y + 1 )
	else
		y = math.min( y, trigger.caller:GetBoundingMaxs().y - 1 )
	end
	FindClearSpaceForUnit(ent, Vector(x, y, GetGroundHeight( ent:GetAbsOrigin(), ent ) ), true )
end