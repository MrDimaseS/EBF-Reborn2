// Get the parent panels and find the boss info panels
const microHud = $.GetContextPanel().GetParent().GetParent().GetParent();
const bottomhud = microHud.FindChildTraverse("CustomUIRoot");
const bossInfoPanels = bottomhud.FindChildrenWithClassTraverse("Boss_info");

// Get map information
const mapInfo = Game.GetMapInfo();

// Map round number to boss text
const roundBossText = {
	1: "#npc_dota_money",
	2: "#npc_dota_boss_kobold_overseer",
	3: "#npc_dota_boss_gnoll_berserker",
	4: "#npc_dota_boss_zombie_lord",
	5: "#npc_dota_boss_slark_rogue",
	6: "#npc_dota_boss_lifestealer",
	7: "#npc_dota_boss_clockwerk_mecha",
	8: "#npc_dota_boss_tidehunter_ravager",
	9: "#npc_dota_boss_roshan_beast",
	10: "#npc_dota_boss_leshrac_destroyer",
	11: "#npc_dota_boss_granite_golem",
	12: "#npc_dota_boss_troll_warlord",
	13: "#npc_dota_boss_forest_summoner",
	14: "#npc_dota_boss_axe_reaver",
	15: "#npc_dota_boss22_vh",
	16: "#npc_dota_boss23_vh",
	17: "#npc_dota_boss25_vh",
	18: "#npc_dota_boss28",
	19: "#npc_dota_boss30",
	20: "#npc_dota_boss31_vh",
	21: "#npc_dota_boss32_vh",
	22: "#npc_dota_boss33_b_vh",
	23: "#npc_dota_boss34_vh",
	24: "#npc_dota_boss35_vh",
	25: "#npc_dota_boss36_guardian"
};

// Subscribe to the "CurrentRound" event
GameEvents.Subscribe("CurrentRound", function(msg) {
	// Get the current round number
	const roundsNumber = msg.roundCurrent;

	// Check if the round number has a corresponding boss text
	if (roundBossText.hasOwnProperty(roundsNumber)) {
		// Get the boss text for the current round
		const roundTitle = roundBossText[roundsNumber];

		// Update boss name and level labels in all boss info panels
		for (let i = 0; i < bossInfoPanels.length; i++) {
			const bossNameLabel = bossInfoPanels[i].FindChildTraverse("bossesNameLabel");
			const bossLevelLabel = bossInfoPanels[i].FindChildTraverse("bossesLevelLabel");

			bossNameLabel.text = $.Localize(roundTitle);
			bossLevelLabel.text = "" + roundsNumber;
		}
	}

  // Get the boss info panel and checkbox
  const bossInfoPanel = $.GetContextPanel().FindChildTraverse("Boss_info_wrapper");
  const checkbox = bottomhud.FindChildTraverse("bossinfovis");

  // Show or hide boss info panel based on checkbox state
  if (!checkbox.checked && roundsNumber && roundsNumber > 1) {
    bossInfoPanel.AddClass("visible");
    const scheduleTime = getScheduleTime();
    $.Schedule(scheduleTime, function() {
      bossInfoPanel.RemoveClass("visible");
    });
  }
});

// Function to determine the schedule time based on the current map
function getScheduleTime() {
	switch (mapInfo.map_display_name) {
		case "epic_boss_fight_nightmare":
			return 8; // Set the schedule time for nightmare map
		case "epic_boss_fight_challenger":
			return 10; // Set the schedule time for challenger map
		case "epic_boss_fight_hard":
			return 12; // Set the schedule time for hard map
		case "epic_boss_fight_normal":
		default:
			return 15; // Set the default schedule time for normal map
	}
}