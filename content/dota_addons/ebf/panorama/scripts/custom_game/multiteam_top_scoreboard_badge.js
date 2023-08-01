(function () {
    var patreonBadge = $.GetContextPanel().FindChildTraverse("PatronBadge_top");
    var rankMedal = $.GetContextPanel().FindChildTraverse("RankMedal");
    
    var playerId = $.GetContextPanel().GetAttributeInt("player_id", -1);
    var patTable = CustomNetTables.GetTableValue("patrons", String(playerId));
    
    if (patTable && patTable.tier !== null && patTable.tier >= 0) {
        if (rankMedal) {
            rankMedal.style.visibility = patreonBadge ? "collapse" : "visible";
        }
        
        if (patreonBadge) {
            patreonBadge.style.visibility = "visible";
            patreonBadge.SetImage("file://{resources}/images/hud/tier" + patTable.tier + ".png");
            patreonBadge.AddClass("animated");
        }
    } else {
        if (rankMedal) {
            rankMedal.style.visibility = "visible";
        }
        
        if (patreonBadge) {
            patreonBadge.style.visibility = "collapse";
        }
    }
})();
