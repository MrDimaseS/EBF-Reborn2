if IsClient() then -- Load clientside utility lib
	print("client-side has been initialized")
	require("libraries/client_util")
	
	
    SendToConsole("dota_health_high_threshold 10")
	
    SendToConsole("dota_health_high_marker_major_alpha 0")
	SendToConsole("dota_health_marker_major_alpha 0")
	SendToConsole("dota_health_marker_minor_alpha 0")
end