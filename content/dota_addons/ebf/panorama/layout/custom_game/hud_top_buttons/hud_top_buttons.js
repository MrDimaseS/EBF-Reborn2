(function() {
    // Function to check the Patron level and show/hide the voiceChatButton
    function CheckPatronLevel() {
        const playerId = Game.GetLocalPlayerID();
        const patronData = CustomNetTables.GetTableValue("patrons", playerId.toString());

        $.Msg("Checking Patron Level for player ID: " + playerId);

        if (patronData) {
            const patronLevel = patronData.level;
            $.Msg("Patron data found: ", patronData);
            $.Msg("Patron level: " + patronLevel);

            if (patronLevel >= 2 && patronLevel <= 5) {
                $.Msg("Patron level is between 2 and 5. Showing voiceChatButton.");
                $("#voiceChatButton").style.visibility = "visible";
            } else {
                $.Msg("Patron level is not between 2 and 5. Hiding voiceChatButton.");
                $("#voiceChatButton").style.visibility = "collapse";
            }
        } else {
            $.Msg("No patron data found for player ID: " + playerId + ". Hiding voiceChatButton.");
            $("#voiceChatButton").style.visibility = "collapse";
        }
    }

    CustomNetTables.SubscribeNetTableListener("patrons", function(tableName, key, data) {
        $.Msg("NetTable 'patrons' updated. Key: " + key + ", Data: ", data);
        if (key === Game.GetLocalPlayerID().toString()) {
            CheckPatronLevel();
        }
    });

    CheckPatronLevel();
})();

