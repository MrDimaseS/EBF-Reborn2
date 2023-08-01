function UpdateHealthBar() {
  var playerId = $.GetContextPanel().GetAttributeInt("player_id", -1);
  var healthBar = $.GetContextPanel().FindChildTraverse("HealthBar");
  var manaBar = $.GetContextPanel().FindChildTraverse("ManaBar");
  if (playerId >= 0) {
    var heroEntIndex = Players.GetPlayerHeroEntityIndex(playerId);
    var healthPercent = Entities.GetHealthPercent(heroEntIndex);
    var manaPercent = Entities.ManaFraction(heroEntIndex) * 100;

    healthBar.value = healthPercent;
    manaBar.value = manaPercent;

    // Change bar color if health is lower than 0.01%
    var isLowHealth = healthPercent < 0.01;
    var color = isLowHealth ? "#363636" : "#ffffff";
    var saturation = isLowHealth ? "0" : "1";
    manaBar.style.washColor = color;
    manaBar.style.saturation = saturation;
  }

  // Call the function again after a delay
  $.Schedule(0.1, UpdateHealthBar);
}

// Call the function initially to set up the health bar
UpdateHealthBar();
