// ----------------------------------------------------------
// Vector Targeting Library
// ========================
// Version: 1.0
// Github: https://github.com/Nibuja05/dota_vector_targeting
// ----------------------------------------------------------


GameEvents.Subscribe("ebf_error_message", function(data) {
	$.Msg(data)
	GameEvents.SendEventClientSide("dota_hud_error_message", {
		"splitscreenplayer": 0,
		"reason": data.reason || 80,
		"message": data.message
	})
})


GameUI.CustomUIConfig().team_colors = {}
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_GOODGUYS] = "#ffc821;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_BADGUYS] = "#ff1010;";

const dotaHud = $.GetContextPanel().GetParent().GetParent().GetParent();
const hud = dotaHud.FindChildTraverse("HUDElements");

(function() {
    const talents = hud.FindChildTraverse("UpgradeStatName");
    if (talents !== null && talents !== undefined) {
        talents.text = "+25% to Base Attributes";
    }
})();

(function() {
    const topbar = hud.FindChildTraverse("topbar");
    if (topbar !== null && topbar !== undefined) {
        topbar.style.marginTop = "105px";
    }
})();

(function() {
    const timeofdaybg = hud.FindChildTraverse("TimeOfDayBG");
    if (timeofdaybg !== null && timeofdaybg !== undefined) {
        timeofdaybg.style.backgroundImage = "url('file://{images}/hud/top_scorboard_center.psd')";
    }
})();

(function() {
    const quickstats = hud.FindChildTraverse("quickstats");
    if (quickstats !== null && quickstats !== undefined) {
        quickstats.style.visibility = "collapse";
    }
})();


GameEvents.Subscribe("dota_player_update_query_unit", UpdateManaBar);
GameEvents.Subscribe("dota_player_update_selected_unit", UpdateManaBar);

function UpdateManaBar(){
	const currentTarget = Players.GetLocalPlayerPortraitUnit();
	const manaNetTable = CustomNetTables.GetTableValue( "hero_attributes", currentTarget )
	const health_mana = hud.FindChildTraverse("health_mana");
    if (health_mana !== null && health_mana !== undefined ) {
		const mana_progress = health_mana.FindChildTraverse("ManaProgress");
		const mana_label = health_mana.FindChildTraverse("ManaRegenLabel");
		if (mana_progress !== null && mana_progress !== undefined && mana_label !== null && mana_label !== undefined) {
			const mana_left = mana_progress.FindChildTraverse("ManaProgress_Left");
			const mana_right = mana_progress.FindChildTraverse("ManaProgress_Right");
			const mana_burner = mana_progress.FindChildTraverse("ManaBurner");
			
			if (manaNetTable == null || manaNetTable == undefined ) {
				mana_left.style.backgroundColor = "gradient( linear, 0% 0%, 0% 100%, from( #2b4287 ), color-stop( 0.2, #4165ce ), color-stop( .5, #4a73ea), to( #2b4287 ) );"
				mana_right.style.backgroundColor = "gradient( linear, 0% 0%, 0% 100%, from( #101932 ), color-stop( 0.2, #172447 ), color-stop( .5, #162244), to( #101932 ) );"
				mana_burner.style.hueRotation = "50deg;"
				mana_label.style.color = "#83C2FE";
			} else {
				switch(manaNetTable.mana_type) {
				  case "Rage":
					mana_left.style.backgroundColor = "gradient( linear, 0% 0%, 0% 100%, from( #3f0000 ), color-stop( 0.2, #8b0000 ), color-stop( .5, #8b0000), to( #3f0000 ) );"
					mana_right.style.backgroundColor = "gradient( linear, 0% 0%, 0% 100%, from( #100000 ), color-stop( 0.2, #260000 ), color-stop( .5, #100000), to( #260000  ) );"
					mana_burner.style.hueRotation = "-120deg;"
					mana_label.style.visibility = "collapse";
					break;
				  case "Stamina":
					mana_left.style.backgroundColor = "gradient( linear, 0% 0%, 0% 100%, from( #755800 ), color-stop( 0.2, #dba400 ), color-stop( .5, #dba400 ), to( #755800 ) );"
					mana_right.style.backgroundColor = "gradient( linear, 0% 0%, 0% 100%, from( #100000 ), color-stop( 0.2, #260000 ), color-stop( .5, #100000), to( #260000  ) );"
					mana_burner.style.hueRotation = "290deg;"
					mana_label.style.visibility = "collapse";
					break;
				  default:
					mana_left.style.backgroundColor = "gradient( linear, 0% 0%, 0% 100%, from( #2b4287 ), color-stop( 0.2, #4165ce ), color-stop( .5, #4a73ea), to( #2b4287 ) );"
					mana_right.style.backgroundColor = "gradient( linear, 0% 0%, 0% 100%, from( #101932 ), color-stop( 0.2, #172447 ), color-stop( .5, #162244), to( #101932 ) );"
					mana_burner.style.hueRotation = "50deg;"
					mana_label.style.color = "#83C2FE";
				}
			}
		}
    }
}
(function() {
    UpdateManaBar()
})();

(function() {
    const guideflyout = hud.FindChildTraverse("GuideFlyout");
    if (guideflyout !== null && guideflyout !== undefined) {
        guideflyout.style.visibility = "collapse";
    }
})();

(function() {
    const glyphScan = hud.FindChildTraverse("GlyphScanContainer");
    if (glyphScan !== null && glyphScan !== undefined) {
        glyphScan.style.visibility = "collapse";
    }
})();

/// Vector Targeting
const CONSUME_EVENT = true;
const CONTINUE_PROCESSING_EVENT = false;

//main variables
var vectorTargetParticle;
var vectorTargetUnit;
var vectorStartPosition;
var vectorRange = 800;
var useDual = false;
var currentlyActiveVectorTargetAbility;

const defaultAbilities = ["pangolier_swashbuckle", "clinkz_burning_army", "dark_seer_wall_of_replica", "void_spirit_aether_remnant", "broodmother_sticky_snare"];
const ignoreAbilites = ["tusk_walrus_kick", "marci_companion_run"]

//Mouse Callback to check whever this ability was quick casted or not
GameUI.SetMouseCallback(function(eventName, arg, arg2, arg3) {
	if (GameUI.GetClickBehaviors() == 3 && currentlyActiveVectorTargetAbility != undefined) {
		const netTable = CustomNetTables.GetTableValue("vector_targeting", currentlyActiveVectorTargetAbility)
		OnVectorTargetingStart(netTable.startWidth, netTable.endWidth, netTable.castLength, netTable.dual, netTable.ignoreArrow);
		currentlyActiveVectorTargetAbility = undefined;
	}
	return CONTINUE_PROCESSING_EVENT;
});

//Listen for class changes
$.RegisterForUnhandledEvent("StyleClassesChanged", CheckAbilityVectorTargeting);

function CheckAbilityVectorTargeting(panel) {
	if (panel == null) {
		return;
	}

	//Check if the panel is an ability or item panel
	const abilityIndex = GetAbilityFromPanel(panel)
	if (abilityIndex >= 0) {

		//Check if the ability/item is vector targeted
		const netTable = CustomNetTables.GetTableValue("vector_targeting", abilityIndex);
		if (netTable == undefined) {
			let behavior = Abilities.GetBehavior(abilityIndex);
			if ((behavior & DOTA_ABILITY_BEHAVIOR.DOTA_ABILITY_BEHAVIOR_VECTOR_TARGETING) !== 0) {
				GameEvents.SendCustomGameEventToServer("check_ability", {
					"abilityIndex": abilityIndex
				});
			}
			return;
		}

		//Check if the ability/item gets activated or is finished
		if (panel.BHasClass("is_active")) {
			currentlyActiveVectorTargetAbility = abilityIndex;
			if (GameUI.GetClickBehaviors() == 9) {
				OnVectorTargetingStart(netTable.startWidth, netTable.endWidth, netTable.castLength, netTable.dual, netTable.ignoreArrow);
			}
		} else {
			OnVectorTargetingEnd();
		}
	}
}

//Find the ability/item entindex from the panorama panel
function GetAbilityFromPanel(panel) {
	if (panel.paneltype == "DOTAAbilityPanel") {

		// Be sure that it is a default ability Button
		const parent = panel.GetParent();
		if (parent != undefined && (parent.id == "abilities" || parent.id == "inventory_list")) {
			const abilityImage = panel.FindChildTraverse("AbilityImage")
			let abilityIndex = abilityImage.contextEntityIndex;
			let abilityName = abilityImage.abilityname

			//Will be undefined for items
			if (abilityName) {
				return abilityIndex;
			}

			//Return item entindex instead
			const itemImage = panel.FindChildTraverse("ItemImage")
			abilityIndex = itemImage.contextEntityIndex;
			return abilityIndex;
		}
	}
	return -1;
}

// Start the vector targeting
function OnVectorTargetingStart(fStartWidth, fEndWidth, fCastLength, bDual, bIgnoreArrow) {
	if (vectorTargetParticle) {
		Particles.DestroyParticleEffect(vectorTargetParticle, true)
		vectorTargetParticle = undefined;
		vectorTargetUnit = undefined;
	}

	const iPlayerID = Players.GetLocalPlayer();
	const selectedEntities = Players.GetSelectedEntities(iPlayerID);
	const mainSelected = Players.GetLocalPlayerPortraitUnit();
	const mainSelectedName = Entities.GetUnitName(mainSelected);
	vectorTargetUnit = mainSelected;
	const cursor = GameUI.GetCursorPosition();
	const worldPosition = GameUI.GetScreenWorldPosition(cursor);

	// particle variables
	let startWidth = fStartWidth || 125;
	let endWidth = fEndWidth || startWidth;
	vectorRange = fCastLength || 800;
	let ignoreArrowWidth = bIgnoreArrow;
	useDual = bDual == 1;

	// redo dota's default particles
	const abilityName = Abilities.GetAbilityName(currentlyActiveVectorTargetAbility);
	if (ignoreAbilites.includes(abilityName)) return;
	if (defaultAbilities.includes(abilityName)) {
		if (abilityName == "void_spirit_aether_remnant") {
			startWidth = Abilities.GetSpecialValueFor(currentlyActiveVectorTargetAbility, "start_radius");
			endWidth = Abilities.GetSpecialValueFor(currentlyActiveVectorTargetAbility, "end_radius");
			vectorRange = Abilities.GetSpecialValueFor(currentlyActiveVectorTargetAbility, "remnant_watch_distance");
			ignoreArrowWidth = 1;
		} else if (abilityName == "dark_seer_wall_of_replica") {
			vectorRange = Abilities.GetSpecialValueFor(currentlyActiveVectorTargetAbility, "width");
			let multiplier = 1
			if (Entities.HasScepter(mainSelected)) {
				multiplier = Abilities.GetSpecialValueFor(currentlyActiveVectorTargetAbility, "scepter_length_multiplier");
			}
			vectorRange = vectorRange * multiplier
			useDual = true;
		} else if (abilityName == "broodmother_sticky_snare") {
			useDual = true;
		} else {
			vectorRange = Abilities.GetSpecialValueFor(currentlyActiveVectorTargetAbility, "range");
		}
	}

	if (useDual) {
		vectorRange = vectorRange / 2;
	}

	let particleName = "particles/ui_mouseactions/custom_range_finder_cone.vpcf";
	if (useDual) {
		particleName = "particles/ui_mouseactions/custom_range_finder_cone_dual.vpcf"
	}

	//Initialize the particle
	vectorTargetParticle = Particles.CreateParticle(particleName, ParticleAttachment_t.PATTACH_CUSTOMORIGIN, mainSelected);
	vectorTargetUnit = mainSelected
	Particles.SetParticleControl(vectorTargetParticle, 1, Vector_raiseZ(worldPosition, 100));
	Particles.SetParticleControl(vectorTargetParticle, 3, [endWidth, startWidth, ignoreArrowWidth]);
	Particles.SetParticleControl(vectorTargetParticle, 4, [0, 255, 0]);

	//Calculate initial particle CPs
	vectorStartPosition = worldPosition;
	const unitPosition = Entities.GetAbsOrigin(mainSelected);
	const direction = Vector_normalize(Vector_sub(vectorStartPosition, unitPosition));
	const newPosition = Vector_add(vectorStartPosition, Vector_mult(direction, vectorRange));
	if (!useDual) {
		Particles.SetParticleControl(vectorTargetParticle, 2, newPosition);
	} else {
		Particles.SetParticleControl(vectorTargetParticle, 7, newPosition);
		const secondPosition = Vector_add(vectorStartPosition, Vector_mult(Vector_negate(direction), vectorRange));
		Particles.SetParticleControl(vectorTargetParticle, 8, secondPosition);
	}


	//Start position updates
	ShowVectorTargetingParticle();
	return CONTINUE_PROCESSING_EVENT;
}

//End the particle effect
function OnVectorTargetingEnd() {
	if (vectorTargetParticle) {
		Particles.DestroyParticleEffect(vectorTargetParticle, true)
		vectorTargetParticle = undefined;
		vectorTargetUnit = undefined;
		currentlyActiveVectorTargetAbility = undefined;
	}
}

//Updates the particle effect and detects when the ability is actually casted
function ShowVectorTargetingParticle() {
	if (vectorTargetParticle !== undefined) {
		const mainSelected = Players.GetLocalPlayerPortraitUnit();
		const cursor = GameUI.GetCursorPosition();
		const worldPosition = GameUI.GetScreenWorldPosition(cursor);

		if (worldPosition == null) {
			$.Schedule(1 / 144, ShowVectorTargetingParticle);
			return;
		}
		const testVec = Vector_sub(worldPosition, vectorStartPosition);
		if (!(testVec[0] == 0 && testVec[1] == 0 && testVec[2] == 0)) {
			let direction = Vector_normalize(Vector_sub(vectorStartPosition, worldPosition));
			direction = Vector_flatten(Vector_negate(direction));
			const newPosition = Vector_add(vectorStartPosition, Vector_mult(direction, vectorRange));

			if (!useDual) {
				Particles.SetParticleControl(vectorTargetParticle, 2, newPosition);
			} else {
				Particles.SetParticleControl(vectorTargetParticle, 7, newPosition);
				const secondPosition = Vector_add(vectorStartPosition, Vector_mult(Vector_negate(direction), vectorRange));
				Particles.SetParticleControl(vectorTargetParticle, 8, secondPosition);
			}
		}
		if (mainSelected != vectorTargetUnit) {
			GameUI.SelectUnit(vectorTargetUnit, false)
		}
		$.Schedule(1 / 144, ShowVectorTargetingParticle);
	}
}

//Some Vector Functions here:
function Vector_normalize(vec) {
	const val = 1 / Math.sqrt(Math.pow(vec[0], 2) + Math.pow(vec[1], 2) + Math.pow(vec[2], 2));
	return [vec[0] * val, vec[1] * val, vec[2] * val];
}

function Vector_mult(vec, mult) {
	return [vec[0] * mult, vec[1] * mult, vec[2] * mult];
}

function Vector_add(vec1, vec2) {
	return [vec1[0] + vec2[0], vec1[1] + vec2[1], vec1[2] + vec2[2]];
}

function Vector_sub(vec1, vec2) {
	return [vec1[0] - vec2[0], vec1[1] - vec2[1], vec1[2] - vec2[2]];
}

function Vector_negate(vec) {
	return [-vec[0], -vec[1], -vec[2]];
}

function Vector_flatten(vec) {
	return [vec[0], vec[1], 0];
}

function Vector_raiseZ(vec, inc) {
	return [vec[0], vec[1], vec[2] + inc];
}