
require("templates/persistent_modifier")
require("templates/toggle_modifier_base_class")

if IsClient() then -- Load clientside utility lib
	print("client-side has been initialized")
	require("libraries/client_util")
end