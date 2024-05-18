const microHud = $.GetContextPanel().GetParent().GetParent().GetParent();
const bottomhud = microHud.FindChildTraverse("CustomUIRoot");

(function() {
	const roundsElement = $("#Rounds"); // Reference to the "Rounds" element
	const timeElement = $("#RoundsTime"); // Reference to the "RoundsTime" element
	const bossRoundElement = $("#BossRound"); // Reference to the "BossRound" element


	let currentRound = 0; // Variable to store the current round number
	let currentLife = 0; // Variable to store the current life value

	GameEvents.Subscribe("UpdateRound", function(msg) {
		if (bossRoundElement) {
			bossRoundElement.visible = true; // Show the "BossRound" element
		}

		const wordToWrite = String(msg.roundNumber);
		let count = 0;

		function updateWord() {
			if (roundsElement) {
				roundsElement.text = wordToWrite.substring(0, count); // Update the displayed round number
			}

			if (count < wordToWrite.length) {
				count++;
				$.Schedule(0, updateWord);
			}
		}

		$.Schedule(wordToWrite.length * 0.2, function() {
			updateWord();
			timeElement.text = ""; // Clear the time text 
		});

		currentRound = msg.roundNumber; // Update the current round number
	});

	GameEvents.Subscribe("UpdateTimeLeft", function(msg) {
		const time = Math.round(msg.Time);
		if (roundsElement) {
			roundsElement.text = String(currentRound); // Display the stored round number
		}
		timeElement.text = String(time); // Update the time text
	});

	GameEvents.Subscribe("UpdateLife", function(msg) {
		currentLife = msg.life; // Update the current life value
		$("#Life").text = String(currentLife); // Update the "Life" text
	});
})();

function Yes() {
	HideButtons();
	const ID = Players.GetLocalPlayer();
	GameEvents.SendCustomGameEventToServer("Vote_Round", {
		pID: ID,
		vote: true
	});
}

function Skip() {
  const checkbox = bottomhud.FindChildTraverse("skipper");
	if (checkbox.checked) {
		// Disable checkbox for 5 seconds to prevent multiple clicks
		checkbox.enabled = false;
		$.Schedule(60, function() {
			checkbox.enabled = true;
		});
		$("#Vote_Yes").visible = false;
		$("#voteStatus").visible = true;
		// Skip waiting time automatically
		var ID = Players.GetLocalPlayer();
		GameEvents.SendCustomGameEventToServer("Vote_Round", {
			pID: ID,
			vote: true
		});
	} else {
		$("#Vote_Yes").visible = true;
	}
}

function HideButtons(text) {
	$("#Vote_Yes").visible = false;
	$("#voteStatus").visible = true;
}

GameEvents.Subscribe("Display_RoundVote", open);
GameEvents.Subscribe("Close_RoundVote", close);

$("#RoundOptions").visible = false;
$("#RoundsTime").visible = false;

function open() {
  if (open) {
		Skip();
	}
	$("#Vote_Yes").visible = true;
	$("#voteStatus").visible = false;
	$("#RoundOptions").visible = true;
	$("#RoundsTime").visible = true;
}

function close() {
	$("#RoundOptions").visible = false;
	$("#RoundsTime").visible = false;
	$("#voteStatus").visible = false;
}

(function() {
    GameEvents.Subscribe("RoundVoteResults", function(data) {
        var playerIDs = Game.GetAllPlayerIDs();
        var connectedPlayerCount = 0;

        for (var i = 0; i < playerIDs.length; i++) {
            var playerID = playerIDs[i];
            var playerInfo = Game.GetPlayerInfo(playerID);

            if (playerInfo && playerInfo.player_connection_state === DOTAConnectionState_t.DOTA_CONNECTION_STATE_CONNECTED) {
                connectedPlayerCount++;
            }
        }
        var votesLeft = connectedPlayerCount - data.Yes;

        const voteStatus = $("#voteStatus");
        voteStatus.text = votesLeft.toString() + " " + $.Localize("#vote_status_label");
    });
})();

(function() {
    const talents = hud.FindChildTraverse("UpgradeStatName");
    if (talents !== null && talents !== undefined) {
        talents.text = "+35% to Base Attributes";
    }
	const pips = hud.FindChildTraverse("UpgradeStatLevelContainer");
    if (pips !== null && pips !== undefined) {
		for( i=1;i<4;i++){
			let oldPip = pips.FindChildTraverse( "StatUp" + (i + 6) )
			if(oldPip !== null && oldPip !== undefined){
				oldPip.SetParent( dotaHud )
				oldPip.DeleteAsync(0)
			}
			let levelPip = $.CreatePanel("Panel", dotaHud, "StatUp" + (i + 6) );
			levelPip.SetHasClass( "LevelPanel", true );
			levelPip.SetParent( pips )
		}
    }
	UpdateTalentPips()
	CheckTalentUpdates()
})();

$.Msg("this is loaded")

GameEvents.Subscribe("dota_player_update_query_unit", UpdateManaBar);
GameEvents.Subscribe("dota_player_update_selected_unit", UpdateManaBar);
$.RegisterForUnhandledEvent( "DOTAShowAbilityTooltipForEntityIndex", RemoveAbilityChanges );
$.RegisterForUnhandledEvent( "DOTAShowAbilityInventoryItemTooltip", UpdateItemTooltip );
$.RegisterForUnhandledEvent( "DOTAShowAbilityShopItemTooltip", ManageItemAttributes );
$.RegisterForUnhandledEvent( "DOTAShowAbilityTooltip", ManageItemAttributes );
$.RegisterForUnhandledEvent( "DOTAShowAbilityTooltipForEntityIndex", ManageItemAttributes );
$.RegisterForUnhandledEvent( "DOTAHUDShowDamageArmorTooltip", UpdateStatsTooltip );
$.RegisterForUnhandledEvent( "DOTAHideAbilityTooltip", ClearItemTooltip );
GameEvents.Subscribe("client_update_ability_kvs", RegisterInventoryData);
GameEvents.Subscribe("hero_leveled_up", HandleLevelUp);
GameEvents.Subscribe("update_talent_pips", UpdateTalentPips);

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
	UpdateTalentPips()
	CheckTalentUpdates();
	GameEvents.SendCustomGameEventToServer( "request_hero_inventory", {unit: currentTarget} )
}
(function() {
    UpdateManaBar()
})();

// ITEM TOOLTIPS
function ManageItemAttributes( abilityPanel, abilityName ){
	const tooltipManager = dotaHud.FindChildTraverse('Tooltips');
	const tooltipPanel = tooltipManager.FindChildTraverse('DOTAAbilityTooltip');
	if( !tooltipPanel ){return}
	const abilityAttributes = tooltipPanel.FindChildTraverse('AbilityAttributes');

	if ( abilityName.match("item") ){ 
		abilityAttributes.style.visibility = 'visible' 
	} else {
		abilityAttributes.style.visibility = 'collapse'
	}
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

let abilityNameWeAreChecking
let unitWeAreChecking
let abilityIndexWeAreChecking
let abilityValues

function ReplaceSpecialValuesInDescription( description, ability )
{
	let split_specials = description.split(/[%%]/);
	for (var i in split_specials ) { // REPLACE SPECIAL VALUES
		if ( split_specials[i].match(" ") ) {
		} else if ( split_specials[i].length > 0 ) {
			var value = Abilities.GetSpecialValueFor( ability, split_specials[i] )
			let font_colour = "#EEEEEE"
			
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
	return description
}

function RemoveAbilityChanges( panel, abilityName, unitID ){
	abilityNameWeAreChecking = abilityName
	
	let ability = Entities.GetAbilityByName( unitID, abilityName )
	
	$.Schedule( 0, function(){
		const tooltipManager = dotaHud.FindChildTraverse('Tooltips');
		const tooltipPanel = tooltipManager.FindChildTraverse('DOTAAbilityTooltip');
		const abilityChanges = tooltipPanel.FindChildTraverse('AbilityGameplayChanges');
		const abilityScepter = tooltipPanel.FindChildTraverse('ScepterUpgradeDescription');
		const abilityShard = tooltipPanel.FindChildTraverse('ShardUpgradeDescription');
		const abilityScepterText = abilityScepter.FindChildrenWithClassTraverse('AbilityDescription')[0];
		const abilityShardText = abilityShard.FindChildrenWithClassTraverse('AbilityDescription')[0];
		
		if (abilityScepterText == undefined && abilityScepterText == null){
			// $.Msg( "No Scepter" )
		} else {
			let token = "#DOTA_Tooltip_Ability_" + abilityNameWeAreChecking + "_scepter_description"
			let locale = $.Localize( token )
			
			locale = ReplaceSpecialValuesInDescription( locale, ability )
			locale = GameUI.ReplaceDOTAAbilitySpecialValues( abilityName, locale, abilityScepterText );
			abilityScepterText.text = locale;
		}
		if (abilityShardText == undefined && abilityShardText == null){
			// $.Msg( "No Shard" )
		} else {
			let token = "#DOTA_Tooltip_Ability_" + abilityNameWeAreChecking + "_shard_description"
			let locale = $.Localize( token )
			
			locale = ReplaceSpecialValuesInDescription( locale, ability )
			locale = GameUI.ReplaceDOTAAbilitySpecialValues( abilityName, locale, abilityShardText );
			abilityShardText.text = locale;
		}
		
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
	strValues.text = (Math.floor((stats.strength * 22)*10 + 0.5)/10) + ' HP and ' + Math.floor((stats.strength * 0.008)*10 + 0.5) / 10 + '% Incoming Healing Amp'
	if(strContainer.BHasClass( "PrimaryAttribute") ){
		const strDamage = strContainer.FindChildTraverse('StrengthDamageLabel');
		strDamage.text = (Math.floor((stats.strength * 1.5)*10 + 0.5)/10) + ' Damage, ' + (Math.floor((stats.strength * 0.06)*10 + 0.5)/10) + '% Spell Amp and ' + (Math.floor((stats.strength * 11)*10 + 0.5)/10) + ' HP';
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
	intValues.text = (Math.floor((stats.intellect*0.01)*10 + 0.5)/10) + '% MP Restore Amp, ' + (Math.floor((stats.intellect*0.03)*10 + 0.5)/10) + '% Spell Amp and ' + Math.floor(intMR*10 + 0.5)/10 + '% Magic Resist'
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
	if( !tooltipManager ){return}
	const tooltipPanel = tooltipManager.FindChildTraverse('DOTAAbilityTooltip');
	if( !tooltipPanel ){return}
	const abilityAttributes = tooltipPanel.FindChildTraverse('AbilityAttributes');
	const abilityDescription = tooltipPanel.FindChildTraverse('AbilityDescriptionContainer');
	
	abilityAttributes.text = "#DOTA_AbilityTooltip_Attributes";
	abilityDescription.text = "#DOTA_AbilityTooltip_Attributes";
	abilityDescription.RemoveAndDeleteChildren();
	
	unitWeAreChecking = -1
	abilityIndexWeAreChecking = -1
	scheduleHandle = null
}

let scheduleHandle
function UpdateItemTooltip( panel, unit, itemSlot ){
	let item = Entities.GetItemInSlot( unit, itemSlot );
	let item_name = Abilities.GetAbilityName( item );
	
	const tooltipManager = dotaHud.FindChildTraverse('Tooltips');
	const tooltipPanel = tooltipManager.FindChildTraverse('DOTAAbilityTooltip');
	const abilityDetails = tooltipPanel.FindChildTraverse('AbilityCoreDetails');
	const abilityAttributes = tooltipPanel.FindChildTraverse('AbilityAttributes');
	
	unitWeAreChecking = unit
	abilityIndexWeAreChecking = itemSlot
	abilityAttributes.style.visibility = 'collapse'
	
	let finalTextToken = ""
	if (panel.inventoryData == undefined && panel.inventoryData.AbilityValues == undefined){ return }
	for (const key in panel.inventoryData.AbilityValues) {
		let localeToken  = "#DOTA_Tooltip_Ability_" + item_name + "_" + key
		let localizedToken = $.Localize(localeToken)
		if( localeToken != localizedToken && localizedToken != "" ){
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
				specialValue = Math.floor( specialValue * 100 + 0.5 )/100
				let realValue = Math.floor( Abilities.GetSpecialValueFor( item, key ) * 100 + 0.5 )/100
				let font_colour = "#EEEEEE"
				if( realValue != specialValue){font_colour = "#3ed038"};
				finalTextToken = finalTextToken + "<b><font color='"+font_colour+"'>" + realValue
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
		abilityAttributes.style.visibility = 'visible'
	} else {
		abilityAttributes.style.visibility = 'collapse'
	}
	
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
	scheduleHandle = $.Schedule( 0, AlterAbilityDescriptions )
	lastRememberedState = null
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
		RemoveAbilityChanges( abilityDescription, item_name, unitWeAreChecking );
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
	if( unitWeAreChecking != -1 && abilityIndexWeAreChecking != -1 ){
		scheduleHandle = $.Schedule( 0, AlterAbilityDescriptions )
	}
}

function RegisterInventoryData(data) {
	if( data.unit == Players.GetLocalPlayerPortraitUnit() )
	{
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
}

function HandleLevelUp(data) {
	if( data.unit == Players.GetLocalPlayerPortraitUnit() )
	{
		UpdateTalentPips()
		CheckTalentUpdates();
	}
}


function UpdateTalentPips() {
	const pips = hud.FindChildTraverse("UpgradeStatLevelContainer");
	let upgrader = Entities.GetAbilityByName( Players.GetLocalPlayerPortraitUnit(), "special_bonus_attributes" )
	let upgraderLevel = Abilities.GetLevel( upgrader )
	let casterLevel = Entities.GetLevel( Players.GetLocalPlayerPortraitUnit() )
	if (pips !== null && pips !== undefined) {
		for( i=0;i<10;i++){
			let levelPip = pips.FindChildTraverse( "StatUp" + i )
			if (levelPip !== null && levelPip !== undefined) {
				levelPip.SetHasClass( "active_level", upgraderLevel > i )
				levelPip.SetHasClass( "next_level", upgraderLevel <= i && casterLevel >= 3 * (i+1) && upgraderLevel == i )
			}
		}
	}
}

function CheckTalentUpdates( ){
	let talentMain = dotaHud.FindChildTraverse( "DOTAStatBranch")
	let talentCont = talentMain.FindChildTraverse( "StatBranchColumn" )
	if( talentCont && !talentCont.BHasClass("Override") ){
		let talents = talentCont.FindChildrenWithClassTraverse( "StatBonusLabel" )
		let firstTalentIndex = -1
		let currentTalentTier = 0
		let talentsLocalized = 0
		for( i=0;i<25;i++){
			let abilityIndex = Entities.GetAbility( Players.GetLocalPlayerPortraitUnit(), i )
			let abilityName = Abilities.GetAbilityName( abilityIndex )
			if( abilityName.search("special_bonus") != -1 && abilityName != "special_bonus_attributes" ){
				if(firstTalentIndex == -1){
					firstTalentIndex = abilityIndex
				}
				talentsLocalized++;
				let talentNameCont = talentCont.FindChildTraverse("UpgradeName" + talentsLocalized)
				let talentParent = talentNameCont.GetParent()
				let customTitle = talentParent.FindChildTraverse( talentNameCont.id + "Override" )
				if(!customTitle){
					customTitle = $.CreatePanel("Label", talentParent, talentNameCont.id + "Override" );
					customTitle.SetParent( talentParent )
					customTitle.SetHasClass( "StatBonusLabel", true );
					customTitle.SetHasClass( "Override", true );
				}
				let talentTitle = $.Localize( "#DOTA_Tooltip_Ability_" + abilityName, customTitle )
				if( talentTitle.search(/\[!s:value]/) != -1){
					customTitle.style.visibility = "visible"
					talentNameCont.style.visibility = "collapse"
					let specialValue = Math.round(Abilities.GetLevelSpecialValueFor(abilityIndex, "value", 1) * 100) / 100
					let specialEnd = +parseFloat(specialValue).toFixed( 2 );
					
					customTitle.text = talentTitle.replace( /\[!s:value]/, specialEnd )
				} else {
					talentNameCont.style.visibility = "visible"
					customTitle.style.visibility = "collapse"
				}
			}
		}
	}
}


