const microHud = $.GetContextPanel().GetParent().GetParent().GetParent();
const bottomhud = microHud.FindChildTraverse("CustomUIRoot");

(function () {
	const roundsElement = $("#Rounds"); // Reference to the "Rounds" element
	const timeElement = $("#RoundsTime"); // Reference to the "RoundsTime" element
	const bossRoundElement = $("#BossRound"); // Reference to the "BossRound" element

	// dotaHud.FindChildTraverse("minimap").style.backgroundImage = 'url("s2r://materials/overviews/peaks_of_screeauk_tga_fee32dc3.vtex")';
	
	const mapData = CustomNetTables.GetTableValue("game_state", "map_properties");
	
	if( mapData != undefined && mapData.result != undefined ){
		const difficultyLabel = $("#Retries")
		const difficultyIcon = $("#Life")
		difficultyLabel.text = $.Localize( '#ebf_gamemode_' + mapData.gamemode )
		difficultyLabel.style.fontSize = '24px';
		difficultyLabel.style.letterSpacing = '1px';
		difficultyLabel.style.textOverflow = 'noclip';
		difficultyLabel.style.padding = '1px';
		difficultyIcon.SetImage('file://{images}/rank_tier_icons/mini/rank'+(mapData.result*2)+'_psd.vtex');
		if(mapData.result == 1){
			difficultyIcon.style.padding = '4px';
			difficultyIcon.style.paddingLeft = '6px';
			difficultyIcon.style.paddingRight = '6px';
		} else {
			difficultyIcon.style.padding = '6px';
			difficultyIcon.style.paddingLeft = '8px';
			difficultyIcon.style.paddingRight = '8px';
		}
		let descriptionText = $.Localize("#ebf_difficulty_" + mapData.result + "_Description") + $.Localize("#ebf_" + mapData.gamemode + "_difficulty_" + mapData.result + "_Description")
		difficultyIcon.SetPanelEvent("onmouseover", () => { 
		$.DispatchEvent("DOTAShowTextTooltip", difficultyIcon, );
			$.DispatchEvent( "DOTAShowTitleTextTooltip", difficultyIcon, $.Localize("#ebf_difficulty_" + mapData.result), descriptionText )
		});
		difficultyIcon.SetPanelEvent("onmouseout", () => {
			$.DispatchEvent("DOTAHideTitleTextTooltip");
		}); 
	}
	

	let currentRound = 0; // variable to store the current round number
	let currentLife = 0; // variable to store the current life value
	
	const skipper = bottomhud.FindChildTraverse("skipper")
	if(Game.GetMapInfo().map_display_name == "mayhem_gamemode"){
		skipper.checked = true;
		skipper.style.visibility = "collapse"
	}
	GameEvents.Subscribe("UpdateRound", function (msg) {
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

		$.Schedule(wordToWrite.length * 0.2, function () {
			updateWord();
			timeElement.text = ""; // Clear the time text 
		});

		currentRound = msg.roundNumber; // Update the current round number
	});

	GameEvents.Subscribe("UpdateTimeLeft", function (msg) {
		const time = Math.round(msg.Time);
		if (roundsElement) {
			roundsElement.text = String(currentRound); // Display the stored round number
		}
		timeElement.text = String(time); // Update the time text
	});
	
	GameEvents.SendCustomGameEventToServer( "player_loaded_into_game_server", {shop: "yippie"} )
})();

GameEvents.Subscribe( "player_loaded_into_game_client", InitaliseShopData );

let savedShopData = {}
let ogShopData = {}

function InitaliseShopData( shopData )
{
	ogShopData = JSON.parse(JSON.stringify(shopData))
	savedShopData = JSON.parse(JSON.stringify(ogShopData))
	LoadShopItemData( savedShopData );
}

let shopItems = {}

function LoadShopItemData( shopData ){
	let mainShop = dotaHud.FindChildTraverse("GridMainShopContents")
	let basics = mainShop.FindChildTraverse("GridBasicItems")
	let upgrades = mainShop.FindChildTraverse("GridUpgradeItems")
	
	let updateFunction = function( panel ) {
		for (const category of panel.Children() ) {
			const items = category.FindChildTraverse("ShopItemsContainer")
			for (const item of items.Children() ) {
				UpdateShopItem( item )
			}
		}
	}
	updateFunction( basics )
	updateFunction( upgrades )
}

function UpdateShopItem( item )
{
	let itemImage = item.FindChildTraverse("ItemImage")
	let purchaseOverlay = item.FindChildTraverse("CanPurchaseOverlay")
	
	let itemName = itemImage.itemname
	// load item into lookup table if not done before
	if( shopItems[itemName] == undefined ){
		shopItems[itemName] = item
	}
	
	let boxShadow = "inset 0px -10px 20px 1px";
	let border = "1px solid"
	purchaseOverlay.style.saturation = null;
	purchaseOverlay.style.hueRotation = null;
	purchaseOverlay.hittestchildren = false;
	let shopItemTier = savedShopData[itemName].AbilityTier || 1
	if(shopItemTier==1){
		boxShadow = boxShadow + " #A9A9A908";
		border = border + " #A9A9A944";
		if (purchaseOverlay != undefined){
			purchaseOverlay.style.saturation = "0";
		}
	} else if (shopItemTier==2){
		boxShadow = boxShadow + " #00008B55";
		border = border + " #00008B77";
		if (purchaseOverlay != undefined){
			purchaseOverlay.style.hueRotation = "180deg";
		}
	} else if (shopItemTier==3){
		boxShadow = boxShadow + " #77000066";
		border = border + " #77000066";
		if (purchaseOverlay != undefined){
			purchaseOverlay.style.hueRotation = "330deg";
		}
	} else if (shopItemTier==4){
		boxShadow = boxShadow + " #B5941033";
		border = border + " #B5941033";
	} else if (shopItemTier==5){
		boxShadow = boxShadow + " #7c2f6688";
		border = border + " #7c2f6688";
		if (purchaseOverlay != undefined){
			purchaseOverlay.style.hueRotation = "230deg";
		}
	} else {
		boxShadow = null;
		border = null;
	}
	if (Players.GetGold( Players.GetLocalPlayer() ) <= savedShopData[itemName].ItemCost){
		purchaseOverlay.style.visibility = "collapse";		
	} else {
		purchaseOverlay.style.visibility = "visible";
	}
	itemImage.style.boxShadow = boxShadow;
	itemImage.style.border = border;
}

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
	if (checkbox.checked ) {
		// Disable checkbox for 5 seconds to prevent multiple clicks
		checkbox.enabled = false;
		$.Schedule(60, function () {
			checkbox.enabled = true;
		});
		$("#Vote_Yes").visible = false;
		$("#voteStatus").visible = true;
		// Skip waiting time automatically
		let ID = Players.GetLocalPlayer();
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
$("#VoteSkip").visible = false;
$("#RoundsTime").visible = false;

function open() {
	if (open && Game.GetMapInfo().map_display_name != "mayhem_gamemode") {
		Skip();
	}
	$("#Vote_Yes").visible = Game.GetMapInfo().map_display_name != "mayhem_gamemode";
	$("#voteStatus").visible = false;
	$("#RoundOptions").visible = Game.GetMapInfo().map_display_name != "mayhem_gamemode";
	$("#VoteSkip").visible = Game.GetMapInfo().map_display_name != "mayhem_gamemode";
	$("#RoundsTime").visible = true;
}

function close() {
	$("#RoundOptions").visible = false;
	$("#VoteSkip").visible = false;
	$("#RoundsTime").visible = false;
	$("#voteStatus").visible = false;
}

(function () {
	GameEvents.Subscribe("RoundVoteResults", function (data) {
		let playerIDs = Game.GetAllPlayerIDs();
		let connectedPlayerCount = 0;

		for (let i = 0; i < playerIDs.length; i++) {
			let playerID = playerIDs[i];
			let playerInfo = Game.GetPlayerInfo(playerID);

			if (playerInfo && playerInfo.player_connection_state === DOTAConnectionState_t.DOTA_CONNECTION_STATE_CONNECTED) {
				connectedPlayerCount++;
			}
		}
		let votesLeft = connectedPlayerCount - data.Yes;

		const voteStatus = $("#voteStatus");
		voteStatus.text = votesLeft.toString() + " " + $.Localize("#vote_status_label");
	});
})();

(function () {
	const talents = hud.FindChildTraverse("UpgradeStatName");
	if (talents !== null && talents !== undefined) {
		talents.text = "+1% Hero Power/Level";
	}
	const pips = hud.FindChildTraverse("UpgradeStatLevelContainer");
	if (pips !== null && pips !== undefined) {
		for (i = 1; i < 4; i++) {
			let oldPip = pips.FindChildTraverse("StatUp" + (i + 6))
			if (oldPip !== null && oldPip !== undefined) {
				oldPip.SetParent(dotaHud)
				oldPip.DeleteAsync(0)
			}
			let levelPip = $.CreatePanel("Panel", dotaHud, "StatUp" + (i + 6));
			levelPip.SetHasClass("LevelPanel", true);
			levelPip.SetParent(pips)
		}
	}
	const shopContents = dotaHud.FindChildTraverse("GridMainShopContents")
	if ( shopContents != undefined ){
		shopContents.style.overflow = "scroll";
	}
	UpdateTalentPips()
	CheckTalentUpdates()
})();

function FixFacetTooltips( ){
	const facetInnateContainer = dotaHud.FindChildrenWithClassTraverse('RootInnateDisplay')[0];
	facetInnateContainer.hittest = false;
	
	facetInnateContainer.SetPanelEvent("onmouseover", () => {});
	facetInnateContainer.SetPanelEvent("onmouseout", () => {});
	
	const contentsContainer = facetInnateContainer.FindChildTraverse("ContentsContainer");
	contentsContainer.hittest = false;
	contentsContainer.hittestchildren = true;
	
	const facetHolder = contentsContainer.FindChildrenWithClassTraverse("FacetHolder")[0];
	const heroID = Players.GetSelectedHeroID( Entities.GetPlayerOwnerID( Players.GetLocalPlayerPortraitUnit() ) )
	const heroTable = CustomNetTables.GetTableValue( "hero_attributes", Players.GetLocalPlayerPortraitUnit() )
	
	facetHolder.SetPanelEvent("onmouseover", () => {$.DispatchEvent('DOTAShowFacetTooltip', facetHolder, heroID | heroTable.facetID )});
	facetHolder.SetPanelEvent("onmouseout", () => {$.DispatchEvent('DOTAHideFacetTooltip',facetHolder)});
	
	const innateHolder = contentsContainer.FindChildTraverse("InnateIcon");
	innateHolder.SetPanelEvent("onmouseover", () => {$.DispatchEvent("DOTAShowAbilityTooltipForEntityIndex", innateHolder, heroTable.innate, Players.GetLocalPlayerPortraitUnit())});
	innateHolder.SetPanelEvent("onmouseout", () => {$.DispatchEvent('DOTAHideAbilityTooltip',innateHolder)});
}

function PrintMessage( p1, p2, p3){
	
}

GameEvents.Subscribe("dota_player_update_query_unit", UpdateManaBar);
GameEvents.Subscribe("dota_player_update_selected_unit", UpdateManaBar);
$.RegisterForUnhandledEvent("DOTAShowAbilityTooltipForEntityIndex", RemoveAbilityChanges);
$.RegisterForUnhandledEvent("DOTAShowAbilityInventoryItemTooltip", UpdateItemTooltip);
$.RegisterForUnhandledEvent("DOTAShowAbilityShopItemTooltip", ManageShopItem);
$.RegisterForUnhandledEvent("DOTAShowAbilityTooltip", ManageItemAttributes);
$.RegisterForUnhandledEvent("DOTAShowAbilityTooltipForEntityIndex", ManageItemAttributes);
$.RegisterForUnhandledEvent("DOTAHUDShowDamageArmorTooltip", DelayUpdateStatsTooltip);
$.RegisterForUnhandledEvent("DOTAHideAbilityTooltip", ClearItemTooltip);
GameEvents.Subscribe("client_update_ability_kvs", RegisterInventoryData);
GameEvents.Subscribe("hero_leveled_up", HandleLevelUp);
GameEvents.Subscribe("update_talent_pips", UpdateTalentPips);

function UpdateManaBar() {
	const currentTarget = Players.GetLocalPlayerPortraitUnit();
	const manaNetTable = CustomNetTables.GetTableValue("hero_attributes", currentTarget)
	const health_mana = hud.FindChildTraverse("health_mana");
	if (health_mana !== null && health_mana !== undefined) {
		const mana_progress = health_mana.FindChildTraverse("ManaProgress");
		const mana_label = health_mana.FindChildTraverse("ManaRegenLabel");
		if (mana_progress !== null && mana_progress !== undefined && mana_label !== null && mana_label !== undefined) {
			const mana_left = mana_progress.FindChildTraverse("ManaProgress_Left");
			const mana_right = mana_progress.FindChildTraverse("ManaProgress_Right");
			const mana_burner = mana_progress.FindChildTraverse("ManaBurner");

			if (manaNetTable == null || manaNetTable == undefined) {
				mana_left.style.backgroundColor = "gradient( linear, 0% 0%, 0% 100%, from( #2b4287 ), color-stop( 0.2, #4165ce ), color-stop( .5, #4a73ea), to( #2b4287 ) );"
				mana_right.style.backgroundColor = "gradient( linear, 0% 0%, 0% 100%, from( #101932 ), color-stop( 0.2, #172447 ), color-stop( .5, #162244), to( #101932 ) );"
				mana_burner.style.hueRotation = "50deg;"
				mana_label.style.color = "#83C2FE";
			} else {
				switch (manaNetTable.mana_type) {
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
	// FixFacetTooltips()
	GameEvents.SendCustomGameEventToServer( "request_hero_inventory", {unit: currentTarget} )
}
(function () {
	UpdateManaBar()
})();

let shop_item
// ITEM TOOLTIPS
function ManageShopItem( abilityPanel, abilityName, empty, entindex, empty2 ){
	ManageItemAttributes( abilityPanel, abilityName );
	shop_item = abilityName
	unitWeAreChecking = entindex;
	lastRememberedState = null
	
	const tooltipManager = dotaHud.FindChildTraverse('Tooltips');
	const tooltipPanel = tooltipManager.FindChildTraverse('DOTAAbilityTooltip');
	if(tooltipPanel == undefined){
		return;
	}
	const abilityDetails = tooltipPanel.FindChildTraverse('AbilityCoreDetails');
	const abilityHeader = tooltipPanel.FindChildTraverse('Header');
	const abilityAttributes = tooltipPanel.FindChildTraverse('AbilityAttributes');
	
	let finalTextToken = ""
	
	if( abilityHeader != undefined ){
		let abilityImage = abilityHeader.FindChildTraverse('ItemImage');
		let abilityTier = abilityHeader.FindChildTraverse('AbilityLevel');
		let abilityUpgradeCostMain = abilityHeader.FindChildTraverse('ItemCost');
		let abilityTierTitle = abilityHeader.FindChildTraverse('ItemSubtitle');
		let abilityUpgradeCost = abilityHeader.FindChildTraverse('BuyCostLabel');
		let abilitySellPrice = abilityDetails.FindChildTraverse('SellPriceLabel');
		abilityTierTitle.style.visibility = "collapse"
		abilitySellPrice.style.visibility = "visible"
		
		if(savedShopData[shop_item] != undefined ){
			let boxShadow = "inset 0px -10px 20px 1px";
			if(savedShopData[shop_item].AbilityTier==1){
				boxShadow = boxShadow + " #A9A9A908";
				abilityTier.text = "Common";
				abilityTierTitle.text = "Common";
			} else if (savedShopData[shop_item].AbilityTier==2){
				boxShadow = boxShadow + " #00008B55";
				abilityTier.text = "Shadow";
				abilityTierTitle.text = "Shadow";
			} else if (savedShopData[shop_item].AbilityTier==3){
				boxShadow = boxShadow + " #77000066";
				abilityTier.text = "Demonic";
				abilityTierTitle.text = "Demonic";
			} else if (savedShopData[shop_item].AbilityTier==4){
				boxShadow = boxShadow + " #B5941033";
				abilityTier.text = "Divine";
				abilityTierTitle.text = "Divine";
			} else if (savedShopData[shop_item].AbilityTier==5){
				boxShadow = boxShadow + " #7c2f6688";
				abilityTier.text = "Otherworldly";
				abilityTierTitle.text = "Otherworldly";
			}
			abilityImage.style.boxShadow = boxShadow 
			
			abilityUpgradeCost.text = savedShopData[shop_item].ItemCost || 1000
			abilitySellPrice.text = "Sell Price: " + savedShopData[shop_item].ItemCost / 2
		} else {
			abilityTier.text = "Common";
			abilityTierTitle.text = "Common";
			abilitySellPrice.text = "Sell Price: 500"
			abilityUpgradeCost.text = "1000"
			abilityImage.style.boxShadow = null 
		}
	}
	
	$.Schedule(0, AlterShopDescriptions, abilityName)
}

function AlterShopDescriptions(abilityName) {
	lastState = GameUI.IsAltDown();
	if(shop_item == null){return}
	if(lastState == lastRememberedState){return}
	lastRememberedState = lastState
	const tooltipManager = dotaHud.FindChildTraverse('Tooltips');
	const tooltipPanel = tooltipManager.FindChildTraverse('DOTAAbilityTooltip');
	const abilityDescription = tooltipPanel.FindChildTraverse('AbilityDescriptionContainer');

	let description = $.Localize("#DOTA_Tooltip_Ability_" + shop_item + "_Description");
	const itemEffectsArray = description.split("\n\n");
	let itemEffects = []
	for(i=0;i<itemEffectsArray.length;i++){
		let itemEffectInArray = itemEffectsArray[i]
		let itemEffect = {}
		itemEffect.header = itemEffectInArray.substring( itemEffectInArray.indexOf("<h1>"), itemEffectInArray.indexOf("</h1>")+5 )
		itemEffect.description = itemEffectInArray.substring( itemEffectInArray.indexOf("</h1>")+5 )
		for(j=1;j<=5;j++){
			let token = "#DOTA_Tooltip_Ability_" + shop_item + "_" + j + "_Upgrade"
			let upgradeDescription = $.Localize(token);
			if(upgradeDescription != token){
				let lastHeader = 0
				let nextHeader = 0
				nextHeader = upgradeDescription.indexOf("<h1>", lastHeader)
				while(nextHeader != -1){
					lastHeader = upgradeDescription.indexOf("</h1>", nextHeader)
					let effectToUpdate = upgradeDescription.substring( nextHeader, lastHeader+5)
					nextHeader = upgradeDescription.indexOf("<h1>", lastHeader)
					if(effectToUpdate == itemEffect.header){
						let updateDescription
						if( nextHeader != -1){
						  updateDescription = upgradeDescription.substring( lastHeader+5, nextHeader)
						} else {
						  updateDescription = upgradeDescription.substring( lastHeader+5)
						}
						itemEffect.description = itemEffect.description + '<br>' + '<b>At Tier ' + j + ':</b> ' + updateDescription
					}
				}
			}
		}
		itemEffects.push(itemEffect)
	}
	let reconstructedDescription = "";
	for(i=0;i<itemEffects.length;i++){
		reconstructedDescription = reconstructedDescription + itemEffects[i].header
		let lines =  itemEffects[i].description.split("<br><br>");
		for(j=0;j<lines.length;j++){
			const line = lines[j]
			const replacedLine = GameUI.ReplaceDOTAAbilitySpecialValues(shop_item, line, abilityDescription)
			reconstructedDescription = reconstructedDescription + replacedLine
			if( j+1<lines.length){
				reconstructedDescription = reconstructedDescription + '<br><br>'
			}
		}
		if( i+1<itemEffects.length){
			reconstructedDescription = reconstructedDescription + '\n\n'
		}
	}
	abilityDescription.RemoveAndDeleteChildren();
	RemoveAbilityChanges(abilityDescription, shop_item, unitWeAreChecking);
	let split_text = "";
	if (reconstructedDescription != null) {
		split_text = reconstructedDescription.split(/[<]h1[>]|[<][/]h1[>] |[<][/]h1[>]/);
	}
	for (let h = 0; h < split_text.length; h++) { // Separate Label contents
		if (split_text[h].match("Active") || split_text[h].match("Aura")) {
			activeHeader_text = split_text[h];
			activeContents_text = split_text[h + 1];
			split_text[h] = "";
			split_text[h + 1] = "";

			let activeHeader = $.CreatePanel("Label", abilityDescription, `ActiveHeader`);
			let activeContents = $.CreatePanel("Label", abilityDescription, `ActiveContents`);

			activeHeader.html = true;
			activeContents.html = true;

			activeContents.SetHasClass("Active", true);
			activeHeader.SetHasClass("Active", true);
			activeHeader.SetHasClass("Header", true);
			activeHeader.style["font-weight"] = "bold";
			activeHeader.style["color"] = "#FFFFFF66"; 
			activeHeader.style["width"] = "100%"; 
			activeHeader.style["backgroundSize"] = "100% 100%"; 
			activeContents.style["width"] = "100%"; 
			
			activeHeader.text = activeHeader_text;
			activeContents.text = activeContents_text;

		} else if (split_text[h].match("Passive")) {
			passiveHeader_text = split_text[h];
			passiveContents_text = split_text[h + 1];
			split_text[h] = "";
			split_text[h + 1] = "";

			let passiveHeader = $.CreatePanel("Label", abilityDescription, `PassiveHeader`);
			let passiveContents = $.CreatePanel("Label", abilityDescription, `PassiveContents`);

			passiveHeader.html = true;
			passiveContents.html = true;

			passiveHeader.SetHasClass("Header", true);
			passiveHeader.style["font-weight"] = "bold";
			passiveHeader.style["color"] = "#FFFFFF66";
			passiveHeader.style["width"] = "100%"; 
			passiveHeader.style["backgroundSize"] = "100% 100%"; 
			passiveContents.style["width"] = "100%"; 

			passiveHeader.text = passiveHeader_text;
			passiveContents.text = passiveContents_text;
		} else if (split_text[h].match("Toggle")) {
			toggleHeader_text = split_text[h];
			toggleContents_text = split_text[h + 1];
			split_text[h] = "";
			split_text[h + 1] = "";

			let toggleHeader = $.CreatePanel("Label", abilityDescription, `ToggleHeader`);
			let toggleContents = $.CreatePanel("Label", abilityDescription, `ToggleContents`);

			toggleHeader.html = true;
			toggleContents.html = true;

			toggleHeader.SetHasClass("Header", true);
			toggleHeader.SetHasClass("Active", true);
			toggleContents.SetHasClass("Active", true);
			toggleHeader.style["font-weight"] = "bold";
			toggleHeader.style["color"] = "#FFFFFF66";
			toggleHeader.style["width"] = "100%"; 
			toggleHeader.style["backgroundSize"] = "100% 100%"; 
			toggleContents.style["width"] = "100%"; 

			toggleHeader.text = toggleHeader_text;
			toggleContents.text = toggleContents_text;

		} else if (split_text[h].match("Use")) {
			consumeHeader_text = split_text[h];
			consumeContents_text = split_text[h + 1];
			split_text[h] = "";
			split_text[h + 1] = "";

			let consumeHeader = $.CreatePanel("Label", abilityDescription, `ConsumeHeader`);
			let consumeContents = $.CreatePanel("Label", abilityDescription, `ConsumeContents`);

			consumeHeader.html = true;
			consumeContents.html = true;

			consumeHeader.SetHasClass("Header", true);
			consumeHeader.SetHasClass("Active", true);
			consumeContents.SetHasClass("Active", true);
			consumeHeader.style["font-weight"] = "bold";
			consumeHeader.style["color"] = "#FFFFFF66";
			consumeHeader.style["width"] = "100%"; 
			consumeHeader.style["backgroundSize"] = "100% 100%"; 
			consumeContents.style["width"] = "100%"; 

			consumeHeader.text = consumeHeader_text;
			consumeContents.text = consumeContents_text;
		} else if (split_text[h] != "") {
			genericText = split_text[h];
			let eachLine = genericText.split('\n');
			for (let z = 0, y = eachLine.length; z < y; z++) {
				let newLine = eachLine[z]
				let newLineContents = $.CreatePanel("Label", abilityDescription, `GenericContents`);
				newLineContents.html = true;
				if (h == 0 && z == 0) { newLineContents.SetHasClass("Active", true) };
				newLineContents.text = newLine;
			}

		}
	}
	if (shop_item != null) {
		scheduleHandle = $.Schedule(0, AlterShopDescriptions)
	}
}


function ManageItemAttributes(abilityPanel, abilityName) {
	const tooltipManager = dotaHud.FindChildTraverse('Tooltips');
	const tooltipPanel = tooltipManager.FindChildTraverse('DOTAAbilityTooltip');
	if (!tooltipPanel) { return }
	const abilityAttributes = tooltipPanel.FindChildTraverse('AbilityAttributes');

	if (abilityName.match("item")) {
		abilityAttributes.style.visibility = 'visible'
	} else {
		abilityAttributes.style.visibility = 'collapse'
	}
	
	// fix size
	const abilityContents = tooltipPanel.FindChildTraverse('Contents');
	const abilityDescriptionContainer = tooltipPanel.FindChildTraverse('AbilityDescriptionContainer');
	const abilityGameplayChanges = tooltipPanel.FindChildTraverse('AbilityGameplayChanges');
	const abilityLore = tooltipPanel.FindChildTraverse('AbilityLore');
	abilityContents.style.width = '450px';
	abilityAttributes.style.width = '450px';
	abilityDescriptionContainer.style.width = '450px';
	abilityGameplayChanges.style.width = '100%';
	abilityLore.style.width = '100%';
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

function ReplaceSpecialValuesInDescription(description, ability) {
	let split_specials = description.split(/[%%]/);
	for (let i in split_specials) { // REPLACE SPECIAL VALUES
		if (split_specials[i].match(" ")) {
		} else if (split_specials[i].length > 0) {
			let value = Abilities.GetSpecialValueFor(ability, split_specials[i])
			if (value == 0) {
				value = Abilities.GetSpecialValueFor(ability, split_specials[i].replace("shard_", ""))
			}
			if (value == 0) {
				value = Abilities.GetSpecialValueFor(ability, split_specials[i].replace("scepter_", ""))
			}
			let font_colour = "#EEEEEE"

			if (Number(value) === value && value % 1 !== 0) {
				value = Math.round((value * 100)) / 100;
			}

			if (description.match("%" + split_specials[i] + "%%%") && value != 0) {
				description = description.replace("%" + split_specials[i] + "%%%", "<b><font color='" + font_colour + "'>" + Math.abs(value) + "%</font></b>");
			} else if (value != 0) {
				description = description.replace("%" + split_specials[i] + "%", "<b><font color='" + font_colour + "'>" + Math.abs(value) + "</font></b>");
			} else {
			}
		}
	}
	return description
}

function RemoveAbilityChanges(panel, abilityName, unitID) {
	abilityNameWeAreChecking = abilityName

	let ability = Entities.GetAbilityByName(unitID, abilityName)
	$.Schedule(0, function () {
		const tooltipManager = dotaHud.FindChildTraverse('Tooltips');
		const tooltipPanel = tooltipManager.FindChildTraverse('DOTAAbilityTooltip');
		const abilityChanges = tooltipPanel.FindChildTraverse('AbilityGameplayChanges');
		const abilityScepter = tooltipPanel.FindChildTraverse('ScepterUpgradeDescription');
		const abilityShard = tooltipPanel.FindChildTraverse('ShardUpgradeDescription');
		const abilityScepterText = abilityScepter.FindChildrenWithClassTraverse('AbilityDescription')[0];
		const abilityShardText = abilityShard.FindChildrenWithClassTraverse('AbilityDescription')[0];

		if (abilityScepterText == undefined && abilityScepterText == null) {
			// $.Msg( "No Scepter" )
		} else {
			let token = "#DOTA_Tooltip_Ability_" + abilityNameWeAreChecking + "_scepter_description"
			let locale = $.Localize(token)

			locale = ReplaceSpecialValuesInDescription(locale, ability)
			locale = GameUI.ReplaceDOTAAbilitySpecialValues(abilityName, locale, abilityScepterText);
			abilityScepterText.text = locale;
		}
		if (abilityShardText == undefined && abilityShardText == null) {
			// $.Msg( "No Shard" )
		} else {
			let token = "#DOTA_Tooltip_Ability_" + abilityNameWeAreChecking + "_shard_description"
			let locale = $.Localize( token )
			
			locale = ReplaceSpecialValuesInDescription( locale, ability )
			locale = GameUI.ReplaceDOTAAbilitySpecialValues( abilityName, locale, abilityShardText );

			abilityShardText.text = locale;
		}

		let token = "#DOTA_Tooltip_Ability_" + abilityNameWeAreChecking + "_ebf_changes"
		let locale = $.Localize(token)
		abilityChanges.RemoveAndDeleteChildren()
		if (locale != token) {
			abilityChanges.style.visibility = "visible";
			let noteContainer = abilityChanges.FindChildTraverse("AbilityPowerRow");
			if (!noteContainer) {
				noteContainer = $.CreatePanel("Panel", abilityChanges, `EBFChangesNoteContainer`);
				noteContainer.SetParent(abilityChanges)
				noteContainer.SetHasClass("VersionedNoteContainer", true);
				noteContainer.SetHasClass("HasInfo", true);
				noteContainer.SetHasClass("NoIndent", true);

				notePrelude = $.CreatePanel("Label", noteContainer, `EBFChangesNoteContainerPrelude`);
				notePrelude.SetHasClass("Version", true);
				notePrelude.text = $.Localize("#prefix_ebf_changes");

				noteDescription = $.CreatePanel("Label", noteContainer, `EBFChangesNoteContainerDescription`);
				noteDescription.SetHasClass("NoteLine", true);
				noteDescription.text = locale;
			}
		}
	})
}

function DelayUpdateStatsTooltip()
{
	$.Schedule(0, UpdateStatsTooltip)
}

function UpdateStatsTooltip() {
	const currentUnit = Players.GetLocalPlayerPortraitUnit()
	const tooltipManager = dotaHud.FindChildTraverse('Tooltips');
	const tooltipPanel = tooltipManager.FindChildTraverse('DOTAHUDDamageArmorTooltip');
	if (!tooltipPanel) {
		$.Schedule(0, UpdateStatsTooltip)
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
	manaRegen.text = Math.round(Entities.GetManaThinkRegen(currentUnit) * 10) / 10
	bonusManaRegen.text = "";

	let abilityPowerRow = attackContainer.FindChildTraverse("AbilityPowerRow");
	if (!abilityPowerRow) {
		abilityPowerRow = $.CreatePanel("Panel", attackContainer, `AbilityPowerRow`);
		abilityPowerRow.SetParent(attackContainer)
		abilityPowerRow.MoveChildAfter(abilityPowerRow, manaRegenRow);
		abilityPowerRow.SetHasClass("StatRow", true);
		abilityPowerRow.SetHasClass("NoBonus", true);
	}
	let abilityPowerLabel = abilityPowerRow.FindChildTraverse("AbilityPowerLabel");
	if (!abilityPowerLabel) {
		abilityPowerLabel = $.CreatePanel("Label", abilityPowerRow, `AbilityPowerLabel`);
		abilityPowerLabel.SetHasClass("StatName", true);
		abilityPowerLabel.text = "Hero Power:"
	}
	let abilityPowerLeft = abilityPowerRow.FindChildTraverse("AbilityPowerLeftRight");
	if (!abilityPowerLeft) {
		abilityPowerLeft = $.CreatePanel("Panel", abilityPowerRow, `AbilityPowerLeftRight`);
		abilityPowerLeft.SetHasClass("LeftRightFlow", true);
	}
	let abilityPower = attackContainer.FindChildTraverse("AbilityPower");
	if (!abilityPower) {
		abilityPower = $.CreatePanel("Label", abilityPowerLeft, `AbilityPower`);
		abilityPower.SetHasClass("BaseValue", true);
	}
	let heroPower = 20 + Abilities.GetSpecialValueFor( Entities.GetAbilityByName( currentUnit, "special_bonus_attributes" ), "value" )
	abilityPower.text = ((Entities.GetLevel(currentUnit) - 1) * heroPower) + '%'

	// stat layer
	let stats = CustomNetTables.GetTableValue("hero_attributes", currentUnit)
	if (!stats) {
		return
	}
	const attributesContainer = tooltipPanel.FindChildTraverse('AttributesContainer');
	
	const primaryStat = stats.primaryStat
	
	const strContainer = attributesContainer.FindChildTraverse('StrengthContainer');
	const strGain = strContainer.FindChildTraverse('StrengthGainLabel');
	const strValues = strContainer.FindChildTraverse('StrengthDetails');
	const strDamage = strContainer.FindChildTraverse('StrengthDamageLabel');
	strGain.text = '(+' + Math.floor(stats.str_gain * 10 + 0.5) / 10 + ' next lvl)'
	strValues.text = (Math.floor((stats.strength * 22) * 10 + 0.5) / 10) + ' HP and ' + Math.floor((stats.strength * 0.008) * 10 + 0.5) / 10 + '% Restoration Amp'
	if (primaryStat == Attributes.DOTA_ATTRIBUTE_STRENGTH) {
		strDamage.text = (Math.floor((stats.strength * 1.5)*10 + 0.5)/10) + ' Damage, ' + (Math.floor((stats.strength * 0.025)*10 + 0.5)/10) + '% Base Spell Damage and ' + (Math.floor((stats.strength * 11)*10 + 0.5)/10) + ' HP';
		strContainer.SetHasClass("PrimaryAttribute", true)
	} else {
		strDamage.text = ""
		strContainer.SetHasClass("PrimaryAttribute", false)
		strContainer.RemoveClass("PrimaryAttribute")
	}

	const agiContainer = attributesContainer.FindChildTraverse('AgilityContainer');
	const agiGain = agiContainer.FindChildTraverse('AgilityGainLabel');
	const agiValues = agiContainer.FindChildTraverse('AgilityDetails');
	const agiDamage = agiContainer.FindChildTraverse('AgilityDamageLabel');
	agiGain.text = '(+' + Math.floor(stats.agi_gain * 10 + 0.5) / 10 + ' next lvl)'

	const agilityArmor = 0.008 * stats.agility
	const agilityAttackSpeed = Math.floor( 0.05 * stats.agility )
	agiValues.text = (Math.floor((stats.agility * 1.5) * 10 + 0.5) / 10) + ' Damage, ' + Math.floor(agilityArmor * 10 + 0.5) / 10 + ' Armor and ' + Math.floor(agilityAttackSpeed * 10 + 0.5) / 10 + ' Attack Speed'
	if (primaryStat == Attributes.DOTA_ATTRIBUTE_AGILITY) {
		agiDamage.text = (Math.floor((stats.agility * 1.5)*10 + 0.5)/10) + ' Damage, ' + (Math.floor((stats.agility * 0.025)*10 + 0.5)/10) + '% Base Spell Damage and ' + (Math.floor((stats.agility * 11)*10 + 0.5)/10) + ' HP';
		agiContainer.SetHasClass("PrimaryAttribute", true)
	} else {
		agiDamage.text = ""
		agiContainer.SetHasClass("PrimaryAttribute", false)
		agiContainer.RemoveClass("PrimaryAttribute")
	}

	const intContainer = attributesContainer.FindChildTraverse('IntelligenceContainer');
	const intGain = intContainer.FindChildTraverse('IntelligenceGainLabel');
	const intValues = intContainer.FindChildTraverse('IntelligenceDetails');
	const intDamage = intContainer.FindChildTraverse('IntelligenceDamageLabel');
	intGain.text = '(+' + Math.floor(stats.int_gain * 10 + 0.5) / 10 + ' next lvl)'

	const intMR = (1-(1-0.002)**(Math.floor(stats.intellect/10)) + 0.002 * (stats.intellect%10))*100
	intValues.text = (Math.floor((stats.intellect * 0.01) * 10 + 0.5) / 10) + '% MP Restore Amp, ' + (Math.floor((stats.intellect * 0.02) * 10 + 0.5) / 10) + '% Base Spell Damage and ' + Math.floor(intMR * 10 + 0.5) / 10 + '% Magic Resist'
	if (primaryStat == Attributes.DOTA_ATTRIBUTE_INTELLECT) {
		intDamage.text = (Math.floor((stats.intellect * 1.5)*10 + 0.5)/10) + ' Damage, ' + (Math.floor((stats.intellect * 0.025)*10 + 0.5)/10) + '% Base Spell Damage and ' + (Math.floor((stats.intellect * 11)*10 + 0.5)/10) + ' HP';
		intContainer.SetHasClass("PrimaryAttribute", true)
	} else {
		intDamage.text = ""
		intContainer.SetHasClass("PrimaryAttribute", false)
	}

	const allContainer = attributesContainer.FindChildTraverse('AllContainer');
	const allGain = allContainer.FindChildTraverse('AllGainLabel');
	const allDamage = allContainer.FindChildTraverse('AllDamageLabel');
	allGain.text = '(+' + Math.floor((stats.str_gain + stats.agi_gain + stats.int_gain) * 10 + 0.5) / 10 + ' next lvl)'
	if (primaryStat == Attributes.DOTA_ATTRIBUTE_ALL) {
		allDamage.text = (Math.floor(((stats.strength+stats.agility+stats.intellect))*10+ 0.5 )/10) + ' Damage, ' + (Math.floor((stats.strength+stats.agility+stats.intellect * 0.0133)*10 + 0.5)/10) + '% Base Spell Damage and ' + (Math.floor(((stats.strength+stats.agility+stats.intellect) * 4)*10 + 0.5)/10) + ' HP';
		allContainer.SetHasClass("PrimaryAttribute", true)
	} else {
		allDamage.text = ""
		allContainer.SetHasClass("PrimaryAttribute", false)
	}
}

function ClearItemTooltip(panel) {
	const tooltipManager = dotaHud.FindChildTraverse('Tooltips');
	if (!tooltipManager) { return }
	const tooltipPanel = tooltipManager.FindChildTraverse('DOTAAbilityTooltip');
	if (!tooltipPanel) { return }
	const abilityAttributes = tooltipPanel.FindChildTraverse('AbilityAttributes');
	const abilityDescription = tooltipPanel.FindChildTraverse('AbilityDescriptionContainer');

	abilityAttributes.text = "#DOTA_AbilityTooltip_Attributes";
	abilityDescription.text = "#DOTA_AbilityTooltip_Attributes";
	abilityDescription.RemoveAndDeleteChildren();

	unitWeAreChecking = -1
	abilityIndexWeAreChecking = -1
	shop_item = null
	scheduleHandle = null
}

let scheduleHandle
function UpdateItemTooltip(panel, unit, itemSlot) {
	let item = Entities.GetItemInSlot(unit, itemSlot);
	let item_name = Abilities.GetAbilityName(item);

	const tooltipManager = dotaHud.FindChildTraverse('Tooltips');
	const tooltipPanel = tooltipManager.FindChildTraverse('DOTAAbilityTooltip');
	const abilityDetails = tooltipPanel.FindChildTraverse('AbilityCoreDetails');
	const abilityHeader = tooltipPanel.FindChildTraverse('Header');
	const abilityAttributes = tooltipPanel.FindChildTraverse('AbilityAttributes');

	unitWeAreChecking = unit
	abilityIndexWeAreChecking = itemSlot
	abilityAttributes.style.visibility = 'collapse'
	
	let finalTextToken = ""
	if (panel.inventoryData == undefined || panel.inventoryData.AbilityValues == undefined) { return }
	
	if( abilityHeader != undefined ){
		let abilityImage = abilityHeader.FindChildTraverse('ItemImage');
		let abilityTier = abilityHeader.FindChildTraverse('AbilityLevel');
		let abilityUpgradeCostMain = abilityHeader.FindChildTraverse('ItemCost');
		let abilityTierTitle = abilityHeader.FindChildTraverse('ItemSubtitle');
		let abilityUpgradeCost = abilityHeader.FindChildTraverse('BuyCostLabel');
		let abilitySellPrice = abilityDetails.FindChildTraverse('SellPriceLabel');
		abilityTierTitle.style.visibility = "collapse"
		abilitySellPrice.style.visibility = "visible"
		if(abilityImage != undefined && abilityTier != undefined){
			let boxShadow = "inset 0px -10px 20px 1px";
			if(panel.inventoryData.AbilityTier==1){
				boxShadow = boxShadow + " #A9A9A908";
				abilityTier.text = "Common";
				abilityTierTitle.text = "Common";
				abilitySellPrice.text = "Sell Price: 500"
				abilityUpgradeCost.text = "1000"
			} else if (panel.inventoryData.AbilityTier==2){
				boxShadow = boxShadow + " #00008B55";
				abilityTier.text = "Shadow";
				abilityTierTitle.text = "Shadow";
				abilitySellPrice.text = "Sell Price: 1000"
				abilityUpgradeCost.text = "2000"
			} else if (panel.inventoryData.AbilityTier==3){
				boxShadow = boxShadow + " #77000066";
				abilityTier.text = "Demonic";
				abilityTierTitle.text = "Demonic";
				abilitySellPrice.text = "Sell Price: 2000"
				abilityUpgradeCost.text = "4000"
			} else if (panel.inventoryData.AbilityTier==4){
				boxShadow = boxShadow + " #B5941033";
				abilityTier.text = "Divine";
				abilityTierTitle.text = "Divine";
				abilitySellPrice.text = "Sell Price: 4000"
				abilityUpgradeCost.text = "8000"
			} else if (panel.inventoryData.AbilityTier==5){
				boxShadow = boxShadow + " #7c2f6688";
				abilityTier.text = "Otherworldly";
				abilityTierTitle.text = "Otherworldly";
				abilitySellPrice.text = "Sell Price: 8000"
			} else {
				boxShadow = null;
			}
			abilityImage.style.boxShadow = boxShadow 
		}
	}
	
	for (const key in panel.inventoryData.AbilityValues) {
		let localeToken = "#DOTA_Tooltip_Ability_" + item_name + "_" + key
		let localizedToken = $.Localize(localeToken)
		if (localeToken != localizedToken && localizedToken != "") {
			let attributeType = false;
			let percentageType = false;
			if (localizedToken.search(/\+/) != -1) {
				attributeType = true
				localizedToken = localizedToken.replace('+', '')
			}
			if (localizedToken.search(/\%/) != -1) {
				percentageType = true
				localizedToken = localizedToken.replace('%', '')
			}
			if (localizedToken.search(/\$/) != -1) {
				localizedToken = localizedToken.replace('$', '')
				localizedToken = $.Localize("#dota_ability_variable_" + localizedToken)
			}
			let specialValue = panel.inventoryData.AbilityValues[key].value
			if (!specialValue) {
				specialValue = panel.inventoryData.AbilityValues[key]
			}
			let specialValues = specialValue.split(" ");
			
			let tmpTextToken = ""
			if (attributeType) {
				attributeType = true
				tmpTextToken = tmpTextToken + '+ '
			}
			for(i=0;i<specialValues.length;i++){
				let tmpSpecialValue = specialValues[i]
				let activeValue = i == Abilities.GetLevel(item)-1
				if (tmpSpecialValue != "0") {
					tmpSpecialValue = Math.floor(tmpSpecialValue * 100 + 0.5) / 100
					let realValue = Math.floor(Abilities.GetLevelSpecialValueFor(item, key, i) * 100 + 0.5) / 100
					let font_colour = "#454552"
					if(activeValue){
						if (realValue != tmpSpecialValue) { 
							font_colour = "#3ed038" 
						} else {
							font_colour = "#EEEEEE"
						};
						tmpTextToken = tmpTextToken + '<b>'
					} else {
						if (realValue != tmpSpecialValue) { 
							font_colour = "#185316" 
						};
					}
					tmpTextToken = tmpTextToken + "<font color='" + font_colour + "'>" + realValue
					
					if (percentageType) {tmpTextToken = tmpTextToken + '%';}
					
					tmpTextToken = tmpTextToken + "</font>";
					if(activeValue){tmpTextToken = tmpTextToken + '</b>'}
					if(i+1<specialValues.length){
						tmpTextToken = tmpTextToken + " / "
					}
				} else {
					
				}
			}
			finalTextToken = finalTextToken + tmpTextToken + " " + localizedToken;
			finalTextToken = finalTextToken + '<br>';
		}
	}
	if (finalTextToken != "") {
		let lIndex = finalTextToken.lastIndexOf("<br>")
		finalTextToken = finalTextToken.substring(0, lIndex);
		abilityAttributes.text = finalTextToken
		abilityAttributes.style.visibility = 'visible'
	} else {
		abilityAttributes.style.visibility = 'collapse'
	}

	abilityValues = {}
	for (const key in panel.inventoryData) {
		if (key != "AbilityValues") {
			abilityValues[key.toLowerCase()] = panel.inventoryData[key]
		} else {
			for (const abilityKey in panel.inventoryData.AbilityValues) {
				abilityValues[abilityKey.toLowerCase()] = panel.inventoryData.AbilityValues[abilityKey]
			}
		}
	}
	lastRememberedState = null
	scheduleHandle = $.Schedule(0, AlterAbilityDescriptions)
	lastRememberedState = null
}

let lastState = false
let lastRememberedState
function AlterAbilityDescriptions(bImmediate) {
	const tooltipManager = dotaHud.FindChildTraverse('Tooltips');
	const tooltipPanel = tooltipManager.FindChildTraverse('DOTAAbilityTooltip');
	const abilityDescription = tooltipPanel.FindChildTraverse('AbilityDescriptionContainer');
	lastState = GameUI.IsAltDown();
	if (lastState != lastRememberedState || (abilityDescription.GetChild( 0 ) != undefined && abilityDescription.GetChild( 0 ).customMade == undefined) ) { // only update if button is toggled or dota updated after me

		let item = Entities.GetItemInSlot(unitWeAreChecking, abilityIndexWeAreChecking);
		let item_name = Abilities.GetAbilityName(item);
		let itemDescriptionToken = "#DOTA_Tooltip_Ability_" + item_name + "_Description"
		if(Abilities.GetLevel( item ) > 1){
			itemDescriptionTokenTest = "#DOTA_Tooltip_Ability_" + item_name + "_" + Abilities.GetLevel( item ) + "_Description"
			let descriptionTest = $.Localize(itemDescriptionTokenTest);
			if(itemDescriptionTokenTest != descriptionTest){
				itemDescriptionToken = itemDescriptionToken
			}
		}
		let description = $.Localize(itemDescriptionToken);
		let split_specials = description.split(/[%%]/);
		abilityDescription.RemoveAndDeleteChildren();
		RemoveAbilityChanges(abilityDescription, item_name, unitWeAreChecking);
		lastRememberedState = lastState;
		for (let id in split_specials) { // REPLACE SPECIAL VALUES
			let specialValueKey = split_specials[id]
			let key = split_specials[id].toLowerCase()
			if (key.match(" ")) {
			} else if (abilityValues[key] != undefined) {
				let specialValues = abilityValues[key]
				if (specialValues && specialValues.value != undefined) {
					specialValues = (specialValues.value).split(" ");
				} else {
					specialValues = specialValues.split(" ")
				}
				let tmpTextToken = ""
				for(i=0;i<specialValues.length;i++){
					let tmpSpecialValue = specialValues[i]
					let activeValue = i == Abilities.GetLevel(item)-1 || Abilities.GetLevel(item) > specialValues.length
					tmpSpecialValue = Math.floor(tmpSpecialValue * 100 + 0.5) / 100
					let realValue = Math.floor(Abilities.GetLevelSpecialValueFor(item, specialValueKey, i) * 100 + 0.5) / 100
					let font_colour = "#454552"
					if(activeValue){
						if (realValue != tmpSpecialValue) { 
							font_colour = "#3ed038" 
						} else {
							font_colour = "#EEEEEE"
						};
						tmpTextToken = tmpTextToken + '<b>'
					} else {
						if (realValue != tmpSpecialValue) { 
							font_colour = "#185316" 
						};
					}
					if (lastState && abilityValues[key] && abilityValues[key].CalculateSpellDamageTooltip) {
						let spell_amp = CustomNetTables.GetTableValue("hero_attributes", unitWeAreChecking)
						if (spell_amp != undefined) {
							realValue = realValue * (1 + spell_amp.spell_amp)
						}
					}
					if (Number(realValue) === realValue && realValue % 1 !== 0) {
						realValue = Math.round((realValue * 100)) / 100;
					}
					realValue = Math.abs( realValue )
					tmpTextToken = tmpTextToken + "<font color='" + font_colour + "'>" + realValue
					
					tmpTextToken = tmpTextToken + "</font>";
					if(activeValue){tmpTextToken = tmpTextToken + '</b>'}
					if(i+1<specialValues.length){
						tmpTextToken = tmpTextToken + " / "
					}
				}
				if (description.match("%" + specialValueKey + "%%%")) {
					tmpTextToken = tmpTextToken.replaceAll("</font>", "%</font>" );
					description = description.replace("%" + specialValueKey + "%%%", tmpTextToken );
				} else {
					description = description.replace("%" + specialValueKey + "%", tmpTextToken);
				}
			}
		}
		// description = GameUI.ReplaceDOTAAbilitySpecialValues(item_name, description, abilityDescription);
		let split_text = "";

		if (description != null) {
			split_text = description.split(/[<]h1[>]|[<][/]h1[>] |[<][/]h1[>]/);
		}
		for (let h = 0; h < split_text.length; h++) { // Separate Label contents
			if (split_text[h].match("Active") || split_text[h].match("Aura")) {
				activeHeader_text = split_text[h];
				activeContents_text = split_text[h + 1];
				split_text[h] = "";
				split_text[h + 1] = "";

				let activeHeader = $.CreatePanel("Label", abilityDescription, `ActiveHeader`);
				let activeContents = $.CreatePanel("Label", abilityDescription, `ActiveContents`);

				activeHeader.html = true;
				activeContents.html = true;

				activeContents.SetHasClass("Active", true);
				activeHeader.SetHasClass("Active", true);
				activeHeader.SetHasClass("Header", true);
				activeHeader.style["font-weight"] = "bold";
				activeHeader.style["color"] = "#FFFFFF66"; 
				activeHeader.style["width"] = "100%"; 
				activeHeader.style["backgroundSize"] = "100% 100%"; 
				activeContents.style["width"] = "100%"; 

				activeHeader.text = activeHeader_text;
				activeContents.text = activeContents_text;

				activeHeader.customMade = true
			} else if (split_text[h].match("Passive")) {
				passiveHeader_text = split_text[h];
				passiveContents_text = split_text[h + 1];
				split_text[h] = "";
				split_text[h + 1] = "";

				let passiveHeader = $.CreatePanel("Label", abilityDescription, `PassiveHeader`);
				let passiveContents = $.CreatePanel("Label", abilityDescription, `PassiveContents`);

				passiveHeader.html = true;
				passiveContents.html = true;

				passiveHeader.SetHasClass("Header", true);
				passiveHeader.style["font-weight"] = "bold";
				passiveHeader.style["color"] = "#FFFFFF66";
				passiveHeader.style["width"] = "100%"; 
				passiveHeader.style["backgroundSize"] = "100% 100%"; 
				passiveContents.style["width"] = "100%"; 

				passiveHeader.text = passiveHeader_text;
				passiveContents.text = passiveContents_text;
				
				passiveHeader.customMade = true
			} else if (split_text[h].match("Toggle")) {
				toggleHeader_text = split_text[h];
				toggleContents_text = split_text[h + 1];
				split_text[h] = "";
				split_text[h + 1] = "";

				let toggleHeader = $.CreatePanel("Label", abilityDescription, `ToggleHeader`);
				let toggleContents = $.CreatePanel("Label", abilityDescription, `ToggleContents`);

				toggleHeader.html = true;
				toggleContents.html = true;

				toggleHeader.SetHasClass("Header", true);
				toggleHeader.SetHasClass("Active", true);
				toggleContents.SetHasClass("Active", true);
				toggleHeader.style["font-weight"] = "bold";
				toggleHeader.style["color"] = "#FFFFFF66";
				toggleHeader.style["width"] = "100%"; 
				toggleHeader.style["backgroundSize"] = "100% 100%"; 
				toggleContents.style["width"] = "100%"; 


				toggleHeader.text = toggleHeader_text;
				toggleContents.text = toggleContents_text;

				toggleHeader.customMade = true
			} else if (split_text[h].match("Use")) {
				consumeHeader_text = split_text[h];
				consumeContents_text = split_text[h + 1];
				split_text[h] = "";
				split_text[h + 1] = "";

				let consumeHeader = $.CreatePanel("Label", abilityDescription, `ConsumeHeader`);
				let consumeContents = $.CreatePanel("Label", abilityDescription, `ConsumeContents`);

				consumeHeader.html = true;
				consumeContents.html = true;

				consumeHeader.SetHasClass("Header", true);
				consumeHeader.SetHasClass("Active", true);
				consumeContents.SetHasClass("Active", true);
				consumeHeader.style["font-weight"] = "bold";
				consumeHeader.style["color"] = "#FFFFFF66";
				consumeHeader.style["width"] = "100%"; 
				consumeHeader.style["backgroundSize"] = "100% 100%"; 
				consumeContents.style["width"] = "100%"; 

				consumeHeader.text = consumeHeader_text;
				consumeContents.text = consumeContents_text;
				
				consumeHeader.customMade = true
			} else if (split_text[h] != "") {
				genericText = split_text[h];
				let eachLine = genericText.split('\n');
				for (let z = 0, y = eachLine.length; z < y; z++) {
					let newLine = eachLine[z]
					let newLineContents = $.CreatePanel("Label", abilityDescription, `GenericContents`);
					newLineContents.html = true;
					newLineContents.customMade = true;
					if (h == 0 && z == 0) { newLineContents.SetHasClass("Active", true) };
					newLineContents.text = newLine;
				}

			} else {
			}
		}
	}
	if( bImmediate == true ){return}
	if (unitWeAreChecking != -1 && abilityIndexWeAreChecking != -1) {
		scheduleHandle = $.Schedule(0, AlterAbilityDescriptions)
	}
}

let previousInventoryState = {}

function RegisterInventoryData(data) {
	if (data.unit == Players.GetLocalPlayerPortraitUnit()) {
		let updateShop = false
		let currentInventoryState = {}
		for (let i = 0; i <= 9; i++) {
			if (i < 9) {
				let inventorySlotPanel = dotaHud.FindChildTraverse("inventory_slot_" + i);
				let inventorySlotButton = inventorySlotPanel.FindChildTraverse("AbilityButton");
				let inventorySlotImage = inventorySlotPanel.FindChildTraverse("ItemImage");
				inventorySlotButton.inventoryData = null;
				let boxShadow = "inset 0px -10px 20px 1px";
				let border = "1px solid"
				if(data.inventory[i] != -1 && data.inventory[i].IsCombineLocked == false){
					currentInventoryState[data.inventory[i].AbilityName] = Math.max( data.inventory[i].AbilityTier, currentInventoryState[data.inventory[i].AbilityName] || 0 )
					if (currentInventoryState[data.inventory[i].AbilityName] == 5){
						currentInventoryState[data.inventory[i].AbilityName] = ogShopData[data.inventory[i].AbilityName].AbilityTier
					}
				}
				if(data.inventory[i].AbilityTier==1){
					boxShadow = boxShadow + " #A9A9A944";
					border = border + " #A9A9A944";
				} else if (data.inventory[i].AbilityTier==2){
					boxShadow = boxShadow + " #00008B77";
					border = border + " #00008B77";
				} else if (data.inventory[i].AbilityTier==3){
					boxShadow = boxShadow + " #77000066";
					border = border + " #77000066";
				} else if (data.inventory[i].AbilityTier==4){
					boxShadow = boxShadow + " #B5941033";
					border = border + " #B5941033";
				} else if (data.inventory[i].AbilityTier==5){
					boxShadow = boxShadow + " #7c2f6688";
					border = border + " #7c2f6688";
				} else {
					border = null;
				}
				inventorySlotButton.style.boxShadow = boxShadow 
				inventorySlotButton.style.border = border 
				inventorySlotButton.inventoryData = data.inventory[i]
			} else {
				let inventoryNeutralPanel = dotaHud.FindChildTraverse("inventory_neutral_slot");
				let inventorySlotButton = inventoryNeutralPanel.FindChildTraverse("AbilityButton");
				inventorySlotButton.style.boxShadow = null;
				inventorySlotButton.style.border = null;
				inventorySlotButton.inventoryData = null;
				inventorySlotButton.inventoryData = data.inventory[i]
			}
		}
		if (data.unit == Players.GetPlayerHeroEntityIndex( Players.GetLocalPlayer() ) ){
			let itemsToUpdate = []
			for (const item in currentInventoryState ) {
				let itemTier = currentInventoryState[item]
				let equivalentTier = previousInventoryState[item] || 0
				if(equivalentTier != itemTier){
					itemsToUpdate.push(item)
				}
			}
			for (const item in previousInventoryState ) {
				let itemTier = previousInventoryState[item]
				let equivalentTier = currentInventoryState[item] || 0
				if(equivalentTier != itemTier){
					itemsToUpdate.push(item)
				}
			}
			if(itemsToUpdate.length > 0){
				savedShopData = JSON.parse(JSON.stringify(ogShopData))
			}
			for (const item of itemsToUpdate){
				savedShopData[item].AbilityTier = currentInventoryState[item] || previousInventoryState[item] || 1
				
				let originalCost = ogShopData[item].ItemCost
				let tierDifference = savedShopData[item].AbilityTier - ogShopData[item].AbilityTier
				savedShopData[item].ItemCost = originalCost * 2 ** tierDifference
				UpdateShopItem( shopItems[item] )
			}
			previousInventoryState = currentInventoryState
		}
	}
}

function HandleLevelUp(data) {
	if (data.unit == Players.GetLocalPlayerPortraitUnit()) {
		UpdateTalentPips()
		CheckTalentUpdates();
	}
}


function UpdateTalentPips() {
	const pips = hud.FindChildTraverse("UpgradeStatLevelContainer");
	let upgrader = Entities.GetAbilityByName(Players.GetLocalPlayerPortraitUnit(), "special_bonus_attributes")
	let upgraderLevel = Abilities.GetLevel(upgrader)
	let casterLevel = Entities.GetLevel(Players.GetLocalPlayerPortraitUnit())
	if (pips !== null && pips !== undefined) {
		for (i = 0; i < 10; i++) {
			let levelPip = pips.FindChildTraverse("StatUp" + i)
			if (levelPip !== null && levelPip !== undefined) {
				levelPip.SetHasClass("active_level", upgraderLevel > i)
				levelPip.SetHasClass("next_level", upgraderLevel <= i && casterLevel >= 3 * (i + 1) && upgraderLevel == i)
			}
		}
	}
}

function CheckTalentUpdates() {
	let talentMain = dotaHud.FindChildTraverse("DOTAStatBranch")
	let talentCont = talentMain.FindChildTraverse("StatBranchColumn")
	if (talentCont && !talentCont.BHasClass("Override")) {
		let talents = talentCont.FindChildrenWithClassTraverse("StatBonusLabel")
		let firstTalentIndex = -1
		let currentTalentTier = 0
		let talentsLocalized = 0
		for (i = 0; i < 25; i++) {
			let abilityIndex = Entities.GetAbility(Players.GetLocalPlayerPortraitUnit(), i)
			let abilityName = Abilities.GetAbilityName(abilityIndex)
			if (abilityName.search("special_bonus") != -1 && abilityName != "special_bonus_attributes") {
				if (firstTalentIndex == -1) {
					firstTalentIndex = abilityIndex
				}
				talentsLocalized++;
				let talentNameCont = talentCont.FindChildTraverse("UpgradeName" + talentsLocalized)
				let talentParent = talentNameCont.GetParent()
				let customTitle = talentParent.FindChildTraverse(talentNameCont.id + "Override")
				if (!customTitle) {
					customTitle = $.CreatePanel("Label", talentParent, talentNameCont.id + "Override");
					customTitle.SetParent(talentParent)
					customTitle.SetHasClass("StatBonusLabel", true);
					customTitle.SetHasClass("Override", true);
				}
				let talentTitle = $.Localize("#DOTA_Tooltip_Ability_" + abilityName, customTitle)
				if (talentTitle.search(/\[!s:value]/) != -1) {
					customTitle.style.visibility = "visible"
					talentNameCont.style.visibility = "collapse"
					let specialValue = Math.round(Abilities.GetLevelSpecialValueFor(abilityIndex, "value", 1) * 100) / 100
					let specialEnd = +parseFloat(specialValue).toFixed(2);

					customTitle.text = talentTitle.replace(/\[!s:value]/, specialEnd)
				} else {
					talentNameCont.style.visibility = "visible"
					customTitle.style.visibility = "collapse"
				}
			}
		}
	}
}