(function() {

    function CheckPatronLevel() {
        const playerId = Game.GetLocalPlayerID();
        const patronData = CustomNetTables.GetTableValue("patrons", playerId.toString());
        if (patronData) {
            const patronLevel = patronData.tier;
            if (patronLevel >= 2 && patronLevel <= 5) {
                $("#voiceChatButton").style.visibility = "visible";
            } else {
                $("#voiceChatButton").style.visibility = "collapse";
            }
        } else {
            $("#voiceChatButton").style.visibility = "collapse";
        }
    }

    CustomNetTables.SubscribeNetTableListener("patrons", function(tableName, key, data) {
        if (key === Game.GetLocalPlayerID().toString()) {
            CheckPatronLevel();
        }
    });

    CheckPatronLevel();
})();
