GameEvents.Subscribe("ebf_error_message", function(data) {
	GameEvents.SendEventClientSide("dota_hud_error_message", {
		"splitscreenplayer": 0,
		"reason": data.reason || 80,
		"message": data.message
	})
})

GameUI.CustomUIConfig().team_colors = {}
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_GOODGUYS] = "#ffc821;";
GameUI.CustomUIConfig().team_colors[DOTATeam_t.DOTA_TEAM_BADGUYS] = "#ff1010;";

const dotaHud = GetDotaHud();
const hud = dotaHud.FindChildTraverse("HUDElements");

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

(function() {
    const guideflyout = hud.FindChildTraverse("GuideFlyout");
    if (guideflyout !== null && guideflyout !== undefined) {
        guideflyout.style.visibility = "collapse";
    }
})();

(function() {
    const glyphScan = hud.FindChildTraverse("GlyphScanContainer");
    if (glyphScan !== null && glyphScan !== undefined) {
		glyphScan.FindChildTraverse("RadiantRoot").style.visibility = "collapse";
    }
})();

(function() {
    const mainPanel = hud.FindChildTraverse("Main");
    if (mainPanel !== null && mainPanel !== undefined) {
        mainPanel.style.width = "510px";
    }
})();

(function() {

    function findShopPanel() {
        const shop = hud.FindChildTraverse("shop");
		const shopItemRowContainers = hud.FindChildrenWithClassTraverse("ShopItemRowContainer");
        if (!shop) {
            $.Schedule(0.1, findShopPanel); 
            return;
        } else {
            initializeShopItemRowContainerWidthAdjustment(shop, shopItemRowContainers);
        }
    }

    findShopPanel();

    function initializeShopItemRowContainerWidthAdjustment(shop, shopItemRowContainers) {
        if (shopItemRowContainers.length === 0) {
            return;
        }

        function updateShopItemRowContainerWidth() {
			const shopItemRowContainers = hud.FindChildrenWithClassTraverse("ShopItemRowContainer");
            const isShopLarge = shop.BHasClass("ShopLarge");
            const newWidth = isShopLarge ? "250px" : "60px";
            shopItemRowContainers.forEach(container => {
				if( shopItemRowContainers === undefined || shopItemRowContainers === null ){return}
				if(!( container === undefined || container === null)){container.style.width = newWidth;}
            });
        }

        // Initial update
        updateShopItemRowContainerWidth();

        // Listen for class changes on the shop
        $.RegisterEventHandler("StyleClassesChanged", shop, updateShopItemRowContainerWidth);
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
$.RegisterForUnhandledEvent("StyleClassesChanged", UpdatePanels);

function UpdatePanels(panel) {
	if (panel == null) {
		return;
	}
	CheckAbilityVectorTargeting(panel);
}

function CheckAbilityVectorTargeting( panel ){
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

function GetDotaHud() {
    let p = $.GetContextPanel();
    while (p !== null && p.id !== 'Hud') {
        p = p.GetParent();
    }
    if (p === null) {
        throw new HudNotFoundException('Could not find Hud root as parent of panel with id: ' + $.GetContextPanel().id);
    } else {
        return p;
    }
}