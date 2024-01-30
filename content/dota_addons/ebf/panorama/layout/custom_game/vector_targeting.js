// ----------------------------------------------------------
// Vector Targeting Library
// ========================
// Version: 1.0
// Github: https://github.com/Nibuja05/dota_vector_targeting
// ----------------------------------------------------------


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
	GameEvents.SendCustomGameEventToServer( "request_hero_inventory", {unit: currentTarget} )
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


// ITEM TOOLTIPS
(function () {
    $.RegisterForUnhandledEvent( "DOTAShowAbilityTooltipForEntityIndex", RemoveAbilityChanges );
    $.RegisterForUnhandledEvent( "DOTAShowAbilityInventoryItemTooltip", UpdateItemTooltip );
    $.RegisterForUnhandledEvent( "DOTAHUDShowDamageArmorTooltip", UpdateStatsTooltip );
    $.RegisterForUnhandledEvent( "DOTAHideAbilityTooltip", ClearItemTooltip );
    GameEvents.Subscribe("client_update_ability_kvs", RegisterInventoryData);
})();

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

let abilityNameWeAreChecking
let unitWeAreChecking
let abilityIndexWeAreChecking
let abilityValues
function RemoveAbilityChanges( panel, abilityName ){
	abilityNameWeAreChecking = abilityName
	$.Schedule( 0, function(){
		const tooltipManager = dotaHud.FindChildTraverse('Tooltips');
		const tooltipPanel = tooltipManager.FindChildTraverse('DOTAAbilityTooltip');
		const abilityChanges = tooltipPanel.FindChildTraverse('AbilityGameplayChanges');
		
		let token = "#DOTA_Tooltip_Ability_" + abilityNameWeAreChecking + "_ebf_changes"
		let locale = $.Localize( token )
		abilityChanges.RemoveAndDeleteChildren()
		if(locale != token){
			abilityChanges.style.visibility = "visible";
			let noteContainer = abilityChanges.FindChildTraverse("AbilityPowerRow");
			if (!noteContainer) {
				noteContainer = $.CreatePanel("Panel", abilityChanges, `EBFChangesNoteContainer`);
				noteContainer.SetParent( abilityChanges )
				noteContainer.SetHasClass( "VersionedNoteContainer", true );
				noteContainer.SetHasClass( "HasInfo", true );
				noteContainer.SetHasClass( "NoIndent", true );
				
				notePrelude = $.CreatePanel("Label", noteContainer, `EBFChangesNoteContainerPrelude`);
				notePrelude.SetHasClass( "Version", true );
				notePrelude.text = $.Localize( "#prefix_ebf_changes" );
				
				noteDescription = $.CreatePanel("Label", noteContainer, `EBFChangesNoteContainerDescription`);
				noteDescription.SetHasClass( "NoteLine", true );
				noteDescription.text = locale;
			}
		}
	} )
}

function UpdateStatsTooltip(){
	const currentUnit = Players.GetLocalPlayerPortraitUnit()
	const tooltipManager = dotaHud.FindChildTraverse('Tooltips');
	const tooltipPanel = tooltipManager.FindChildTraverse('DOTAHUDDamageArmorTooltip');
	if(!tooltipPanel){ 
		$.Schedule( 0, UpdateStatsTooltip )
		return
	}
	// attribute layer
	const attackContainer = tooltipPanel.FindChildTraverse('AttackContainer');
	const damageRow = attackContainer.FindChildTraverse('DamageRow');
	const baseDamage = damageRow.FindChildTraverse('Damage');
	const bonusDamage = damageRow.FindChildTraverse('DamageBonus');
	baseDamage.text = (Entities.GetDamageMax(currentUnit) + Entities.GetDamageMin(currentUnit)) / 2
	bonusDamage.text = "+ " + Entities.GetDamageBonus(currentUnit)
	
	const manaRegenRow = attackContainer.FindChildTraverse('ManaRegenRow');
	const manaRegen = manaRegenRow.FindChildTraverse('ManaRegen');
	const bonusManaRegen = manaRegenRow.FindChildTraverse('ManaRegenBonus');
	manaRegen.text = Math.round(Entities.GetManaThinkRegen( currentUnit ) * 10) / 10
	bonusManaRegen.text = "";
	
	let abilityPowerRow = attackContainer.FindChildTraverse("AbilityPowerRow");
	if (!abilityPowerRow) {
		abilityPowerRow = $.CreatePanel("Panel", attackContainer, `AbilityPowerRow`);
		abilityPowerRow.SetParent( attackContainer )
		abilityPowerRow.MoveChildAfter( abilityPowerRow, manaRegenRow );
		abilityPowerRow.SetHasClass( "StatRow", true );
		abilityPowerRow.SetHasClass( "NoBonus", true );
	}
	let abilityPowerLabel = abilityPowerRow.FindChildTraverse("AbilityPowerLabel");
	if (!abilityPowerLabel) {
		abilityPowerLabel = $.CreatePanel("Label", abilityPowerRow, `AbilityPowerLabel`);
		abilityPowerLabel.SetHasClass( "StatName", true );
		abilityPowerLabel.text = "Ability Power:"
		abilityPowerLabel.style.width = 'fill-parent-flow( 1.0 )';
	}
	let abilityPowerLeft = abilityPowerRow.FindChildTraverse("AbilityPowerLeftRight");
	if (!abilityPowerLeft) {
		abilityPowerLeft = $.CreatePanel("Panel", abilityPowerLabel, `AbilityPowerLeftRight`);
		abilityPowerLeft.SetHasClass( "LeftRightFlow", true );
	}
	let abilityPower = attackContainer.FindChildTraverse("AbilityPower");
	if (!abilityPower) {
		abilityPower = $.CreatePanel("Label", abilityPowerLeft, `AbilityPower`);
		abilityPower.SetHasClass( "BaseValue", true );
		abilityPower.style.marginLeft = '110px';
	}
	abilityPower.text = ((Entities.GetLevel( currentUnit )-1) * 20) + '%'
	
	// stat layer
	let stats = CustomNetTables.GetTableValue( "hero_attributes", currentUnit )
	if(!stats){
		return
	}
	const attributesContainer = tooltipPanel.FindChildTraverse('AttributesContainer');
	
	const strContainer = attributesContainer.FindChildTraverse('StrengthContainer');
	const strGain = strContainer.FindChildTraverse('StrengthGainLabel');
	const strValues = strContainer.FindChildTraverse('StrengthDetails');
	strGain.text = '(+' + Math.floor(stats.str_gain*10 + 0.5) / 10 + ' next lvl)'
	strValues.text = (Math.floor((stats.strength)*10 + 0.5)/10) * 22 + ' HP and ' + Math.floor((stats.strength * 0.15)*10 + 0.5) / 10 + ' HP Regen'
	if(strContainer.BHasClass( "PrimaryAttribute") ){
		const strDamage = strContainer.FindChildTraverse('StrengthDamageLabel');
		strDamage.text = (Math.floor((stats.strength * 1.5)*10 + 0.5)/10) + ' Damage, ' + (Math.floor((stats.strength * 0.6)*10 + 0.5)/10) + '% Spell Amp and ' + (Math.floor((stats.strength * 11)*10 + 0.5)/10) + ' HP';
	}
	
	const agiContainer = attributesContainer.FindChildTraverse('AgilityContainer');
	const agiGain = agiContainer.FindChildTraverse('AgilityGainLabel');
	const agiValues = agiContainer.FindChildTraverse('AgilityDetails');
	agiGain.text = '(+' + Math.floor(stats.agi_gain*10 + 0.5) / 10 + ' next lvl)'
	
	const agilityArmor = Math.min( 0.065 * stats.agility, 0.9*stats.agility**(Math.log(2)/Math.log(5)) )
	const agilityAttackSpeed = Math.floor( Math.min( 0.75 * stats.agility, 10.32*stats.agility**(Math.log(2)/Math.log(5)) ) )
	agiValues.text = (Math.floor((stats.agility * 1.5)*10 + 0.5)/10) + ' Damage, ' + Math.floor(agilityArmor*10 + 0.5)/10 + ' Armor and ' + Math.floor(agilityAttackSpeed*10 + 0.5)/10 + ' Attack Speed'
	if( agiContainer.BHasClass( "PrimaryAttribute") ){
		const agiDamage = agiContainer.FindChildTraverse('AgilityDamageLabel');
		agiDamage.text = (Math.floor((stats.agility * 1.5)*10 + 0.5)/10) + ' Damage, ' + (Math.floor((stats.agility * 0.06)*10 + 0.5)/10) + '% Spell Amp and ' + (Math.floor((stats.agility * 11)*10 + 0.5)/10) + ' HP';
	}
	
	const intContainer = attributesContainer.FindChildTraverse('IntelligenceContainer');
	const intGain = intContainer.FindChildTraverse('IntelligenceGainLabel');
	const intValues = intContainer.FindChildTraverse('IntelligenceDetails');
	intGain.text =  '(+' + Math.floor(stats.int_gain*10 + 0.5) / 10 + ' next lvl)'
	
	const intMR = Math.min( 0.04 * stats.intellect, 0.55*stats.intellect**(Math.log(2)/Math.log(5)) )
	intValues.text = (Math.floor((stats.intellect*2)*10 + 0.5)/10) + ' MP, ' + (Math.floor((stats.intellect*0.01)*10 + 0.5)/10) + ' MP Regen, ' + (Math.floor((stats.intellect*0.03)*10 + 0.5)/10) + '% Spell Amp and ' + Math.floor(intMR*10 + 0.5)/10 + '% Magic Resist'
	if(intContainer.BHasClass( "PrimaryAttribute") ){
		const intDamage = intContainer.FindChildTraverse('IntelligenceDamageLabel');
		intDamage.text = (Math.floor((stats.intellect * 1.5)*10 + 0.5)/10) + ' Damage, ' + (Math.floor((stats.intellect * 0.06)*10 + 0.5)/10) + '% Spell Amp and ' + (Math.floor((stats.intellect * 11)*10 + 0.5)/10) + ' HP';
	}
	
	const allContainer = attributesContainer.FindChildTraverse('AllContainer');
	const allGain = allContainer.FindChildTraverse('AllGainLabel');
	allGain.text = '(+' + Math.floor((stats.str_gain+stats.agi_gain+stats.int_gain)*10 + 0.5 ) / 10 + ' next lvl)'
	if(allContainer.BHasClass( "PrimaryAttribute") ){
		const allDamage = allContainer.FindChildTraverse('AllDamageLabel');
		allDamage.text = (Math.floor(((stats.strength+stats.agility+stats.intellect))*10+ 0.5 )/10) + ' Damage, ' + (Math.floor(((stats.strength+stats.agility+stats.intellect) * 0.03)*10 + 0.5)/10) + '% Spell Amp and ' + (Math.floor(((stats.strength+stats.agility+stats.intellect) * 4)*10 + 0.5)/10) + ' HP';
	}
}

function ClearItemTooltip( panel ){
	const tooltipManager = dotaHud.FindChildTraverse('Tooltips');
	const tooltipPanel = tooltipManager.FindChildTraverse('DOTAAbilityTooltip');
	const abilityAttributes = tooltipPanel.FindChildTraverse('AbilityAttributes');
	const abilityDescription = tooltipPanel.FindChildTraverse('AbilityDescriptionContainer');
	
	abilityAttributes.text = "#DOTA_AbilityTooltip_Attributes";
	abilityDescription.text = "#DOTA_AbilityTooltip_Attributes";
	abilityDescription.RemoveAndDeleteChildren();
	
	unitWeAreChecking = -1
	abilityIndexWeAreChecking = -1
}

function UpdateItemTooltip( panel, unit, itemSlot ){
	let item = Entities.GetItemInSlot( unit, itemSlot );
	let item_name = Abilities.GetAbilityName( item );
	
	const tooltipManager = dotaHud.FindChildTraverse('Tooltips');
	const tooltipPanel = tooltipManager.FindChildTraverse('DOTAAbilityTooltip');
	const abilityDetails = tooltipPanel.FindChildTraverse('AbilityCoreDetails');
	const abilityAttributes = tooltipPanel.FindChildTraverse('AbilityAttributes');
	
	let finalTextToken = ""
	if (panel.inventoryData == undefined || panel.inventoryData.AbilityValues == undefined){ return }
	for (const key in panel.inventoryData.AbilityValues) {
		let localeToken  = "#DOTA_Tooltip_Ability_" + item_name + "_" + key
		let localizedToken = $.Localize(localeToken)
		if( localeToken != localizedToken ){
			let attributeType = false;
			let percentageType = false;
			if( localizedToken.search( /\+/ ) != -1 ){
				attributeType = true
				localizedToken = localizedToken.replace( '+', '' )
			}
			if( localizedToken.search( /\%/  ) != -1 ){
				percentageType = true
				localizedToken = localizedToken.replace( '%', '' )
			}
			if( localizedToken.search( /\$/  ) != -1 ){
				localizedToken = localizedToken.replace( '$', '')
				localizedToken = $.Localize("#dota_ability_variable_" + localizedToken )
			}
			let specialValue = panel.inventoryData.AbilityValues[key].value
			if( !specialValue ){
				specialValue = panel.inventoryData.AbilityValues[key]
			}
			if( specialValue != "0" ){ 
				if( attributeType ){
					attributeType = true
					finalTextToken = finalTextToken + '+ '
				}
				let font_colour = "#EEEEEE"
				if( Abilities.GetSpecialValueFor( item, key ) != specialValue){font_colour = "#3ed038"};
				finalTextToken = finalTextToken + "<b><font color='"+font_colour+"'>" + Abilities.GetSpecialValueFor( item, key )
				if( percentageType ){
					finalTextToken = finalTextToken + '%' + "</font></b>";
				} else {
					finalTextToken = finalTextToken + "</font></b>";
				}
				finalTextToken = finalTextToken + " " + localizedToken;
				finalTextToken = finalTextToken + '<br>'
			}
		}
	}
	if( finalTextToken != "" ){
		var lIndex = finalTextToken.lastIndexOf("<br>")
		finalTextToken = finalTextToken.substring(0, lIndex);
		abilityAttributes.text = finalTextToken
		abilityAttributes.style["visibility"] = "visible";
	}
	unitWeAreChecking = unit
	abilityIndexWeAreChecking = itemSlot
	
	abilityValues = {}
	for (const key in panel.inventoryData){
		if(key != "AbilityValues"){
			abilityValues[key.toLowerCase()] = panel.inventoryData[key]
		} else {
			for (const abilityKey in panel.inventoryData.AbilityValues){
				abilityValues[abilityKey.toLowerCase()] = panel.inventoryData.AbilityValues[abilityKey]
			}
		}
	}
	
	lastRememberedState = null
	$.Schedule( 0, AlterAbilityDescriptions )
}

let lastState = false
let lastRememberedState
function AlterAbilityDescriptions( ){
	lastState = GameUI.IsAltDown();
	if (lastState != lastRememberedState ){ // only update if button is toggled
		const tooltipManager = dotaHud.FindChildTraverse('Tooltips');
		const tooltipPanel = tooltipManager.FindChildTraverse('DOTAAbilityTooltip');
		const abilityDescription = tooltipPanel.FindChildTraverse('AbilityDescriptionContainer');
		
		let item = Entities.GetItemInSlot( unitWeAreChecking, abilityIndexWeAreChecking );
		let item_name = Abilities.GetAbilityName( item );
		
		var description = $.Localize("#DOTA_Tooltip_Ability_" + item_name + "_Description");
		let split_specials = description.split(/[%%]/);
		abilityDescription.RemoveAndDeleteChildren();
		RemoveAbilityChanges();
		lastRememberedState = lastState;
		for (var i in split_specials ) { // REPLACE SPECIAL VALUES
			if ( split_specials[i].match(" ") ) {
			} else if ( split_specials[i].length > 0 ) {
				var value = Abilities.GetSpecialValueFor( item, split_specials[i] )
				let specialValue = abilityValues[split_specials[i]]
				if( specialValue && specialValue.value != undefined ){
					specialValue = specialValue.value
				}
				let font_colour = "#EEEEEE"
				if(specialValue && Math.floor(specialValue*100 + 0.5)/100 != Math.floor(value*100 + 0.5)/100){font_colour = "#3ed038"};
				if ( lastState && abilityValues[split_specials[i]] && abilityValues[split_specials[i]].CalculateSpellDamageTooltip ){
					let spell_amp = CustomNetTables.GetTableValue( "hero_attributes", unitWeAreChecking )
					if( spell_amp != undefined ){
						value = value * (1+spell_amp.spell_amp)
					}
				}
				if ( Number(value) === value && value % 1 !== 0 ) {
					value = Math.round( (value*100) ) / 100;
				}
				
				if ( description.match( "%" + split_specials[i] + "%%%") && value!=0 ) {
					description = description.replace( "%" + split_specials[i] + "%%%","<b><font color='"+font_colour+"'>" + Math.abs(value) + "%</font></b>" );
				} else if (value!=0) {
					description = description.replace( "%" + split_specials[i] + "%","<b><font color='"+font_colour+"'>" + Math.abs(value) + "</font></b>" );
				} else {
				}
			}
		}
		description = GameUI.ReplaceDOTAAbilitySpecialValues( item_name, description, abilityDescription );
		let split_text = "";
		
		if (description!=null) {
			split_text = description.split( /[<]h1[>]|[<][/]h1[>] |[<][/]h1[>]/ );
		}

		for (let h = 0; h < split_text.length; h++ ) { // Separate Label contents
			if ( split_text[h].match("Active") ) {
				activeHeader_text = split_text[h];
				activeContents_text = split_text[h+1];
				split_text[h] = "";
				split_text[h+1] = "";

				let activeHeader = $.CreatePanel("Label", abilityDescription, `ActiveHeader`);
				let activeContents = $.CreatePanel("Label", abilityDescription, `ActiveContents`);

				activeHeader.html = true;
				activeContents.html = true;

				activeContents.SetHasClass( "Active", true );
				activeHeader.SetHasClass( "Active", true );
				activeHeader.SetHasClass( "Header", true );
				activeHeader.style["font-weight"] = "bold";
				activeHeader.style["color"] = "#FFFFFF66";

				activeHeader.text = activeHeader_text;
				activeContents.text = activeContents_text;
				
			} else if ( split_text[h].match("Passive") ) {
				passiveHeader_text = split_text[h];
				passiveContents_text = split_text[h+1];
				split_text[h] = "";
				split_text[h+1] = "";
				
				let passiveHeader = $.CreatePanel("Label", abilityDescription, `PassiveHeader`);
				let passiveContents = $.CreatePanel("Label", abilityDescription, `PassiveContents`);

				passiveHeader.html = true;
				passiveContents.html = true;
				
				passiveHeader.SetHasClass( "Header", true );
				passiveHeader.style["font-weight"] = "bold";
				passiveHeader.style["color"] = "#FFFFFF66";

				passiveHeader.text = passiveHeader_text;
				passiveContents.text = passiveContents_text;
			} else if ( split_text[h].match("Toggle") ) {
				toggleHeader_text = split_text[h];
				toggleContents_text = split_text[h+1];
				split_text[h] = "";
				split_text[h+1] = "";
				
				let toggleHeader = $.CreatePanel("Label", abilityDescription, `ToggleHeader`);
				let toggleContents = $.CreatePanel("Label", abilityDescription, `ToggleContents`);

				toggleHeader.html = true;
				toggleContents.html = true;
				
				toggleHeader.SetHasClass( "Header", true );
				toggleHeader.SetHasClass( "Active", true );
				toggleContents.SetHasClass( "Active", true );
				toggleHeader.style["font-weight"] = "bold";
				toggleHeader.style["color"] = "#FFFFFF66";

				toggleHeader.text = toggleHeader_text;
				toggleContents.text = toggleContents_text;

			} else if ( split_text[h].match("Use") ) {
				consumeHeader_text = split_text[h];
				consumeContents_text = split_text[h+1];
				split_text[h] = "";
				split_text[h+1] = "";
				
				let consumeHeader = $.CreatePanel("Label", abilityDescription, `ConsumeHeader`);
				let consumeContents = $.CreatePanel("Label", abilityDescription, `ConsumeContents`);

				consumeHeader.html = true;
				consumeContents.html = true;
				
				consumeHeader.SetHasClass( "Header", true );
				consumeHeader.SetHasClass( "Active", true );
				consumeContents.SetHasClass( "Active", true );
				consumeHeader.style["font-weight"] = "bold";
				consumeHeader.style["color"] = "#FFFFFF66";

				consumeHeader.text = consumeHeader_text;
				consumeContents.text = consumeContents_text;
			} else if (split_text[h] != "" ) {
				genericText = split_text[h];
				let eachLine = genericText.split('\n');
				for(var z = 0, y = eachLine.length; z < y; z++) {
					let newLine = eachLine[z]
					let newLineContents = $.CreatePanel("Label", abilityDescription, `GenericContents`);
					newLineContents.html = true;
					if(h == 0 && z == 0) {newLineContents.SetHasClass( "Active", true )};
					newLineContents.text = newLine;
				}
				
			}
		}
	}
	if( unitWeAreChecking != -1 || abilityIndexWeAreChecking != -1 ){
		$.Schedule( 0, AlterAbilityDescriptions )
	}
}

function RegisterInventoryData(data) {
    for (let i=0;i<=9;i++) {
        if ( i<9 ) {
            let inventorySlotPanel = dotaHud.FindChildTraverse("inventory_slot_"+i);
            let inventorySlotButton = inventorySlotPanel.FindChildTraverse("AbilityButton");
			inventorySlotButton.inventoryData = null;
			inventorySlotButton.inventoryData = data.inventory[i]
        } else {
            let inventoryNeutralPanel = dotaHud.FindChildTraverse("inventory_neutral_slot");
            let inventorySlotButton = inventoryNeutralPanel.FindChildTraverse("AbilityButton");
			inventorySlotButton.inventoryData = null;
			inventorySlotButton.inventoryData = data.inventory[i]
        }
    }
}

function ThinkItemDescription( ){
	if(currentItemSlot != -1){
		let inventorySlotPanel = inventoryPanels.FindChildTraverse("inventory_slot_" + currentItemSlot);
		if (currentItemSlot == 16){
			inventorySlotPanel = inventoryPanels.FindChildTraverse("inventory_neutral_slot");
		}
		$.Schedule( 0.03, ThinkItemDescription )
	}
}