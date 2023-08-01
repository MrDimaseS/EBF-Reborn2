GameUI.Information = GameUI.Information || {};
GameUI.ToggleSingleClassInParent = (parent, child, class_name) => {
	parent.Children().forEach((upgrade) => {
		upgrade.RemoveClass(class_name);
	});
	if (child) child.AddClass(class_name);
};

let state = 0;
let mouseCallback = null;

let ToggleInformationShow = () => {
	$.GetContextPanel().ToggleClass("Show_IN");
	if (!$.GetContextPanel().BHasClass("Show_IN")) $.DispatchEvent("DropInputFocus");

	if ($.GetContextPanel().BHasClass("Show_IN")) {
		state = 1;
		mouseCallback = function (eventName, button) {
			if (eventName === "pressed" && button === 0) {
				state = 0;
				$.GetContextPanel().RemoveClass("Show_IN");
				GameUI.SetMouseCallback(null);
			}
		};
		GameUI.SetMouseCallback(mouseCallback);
	}
};

GameUI.Information.Show = () => {
	$.GetContextPanel().AddClass("Show_IN");
};

(() => {
	GameUI.Custom_ToggleInformation = ToggleInformationShow;
	formatPatchNotes();
})();

function formatPatchNotes() {
  const patchNotesContent = CustomNetTables.GetTableValue("game_state", "patchnotes_content");
  // Get the patch notes panel
  const patchNotesPanel = $("#patchnotesPanel");

  if (patchNotesPanel) {
    // Clear existing contents
    patchNotesPanel.RemoveAndDeleteChildren();

    if (patchNotesContent && patchNotesContent.content) {
      // Extract the version number and patch date from the content
      const versionRegex = /EBF (\d+\.\d+)/;
      const dateRegex = /- (\d{2}\/\d{2}\/\d{4})/;
      const versionMatch = patchNotesContent.content.match(versionRegex);
      const dateMatch = patchNotesContent.content.match(dateRegex);

      let version = "";
      let date = "";

      if (versionMatch && versionMatch[1]) {
        version = versionMatch[1];
      }

      if (dateMatch && dateMatch[1]) {
        date = dateMatch[1];
      }

      // Replace the label texts with the extracted version and date
      $("#ver_label").text = version;
      $("#date_label").text = date;

      // Remove the line "> EBF 1.31 - 11/07/2023" from the content
      let cleanedContent = patchNotesContent.content.replace(/^> EBF \d+\.\d+ - \d{2}\/\d{2}\/\d{4}\n/, "");

      // Remove style and div tags and their contents
      cleanedContent = cleanedContent.replace(/<style>(.|[\r\n])*?<\/style>/g, "");
      cleanedContent = cleanedContent.replace(/<div[^>]*>/g, "");
      cleanedContent = cleanedContent.replace(/<\/div>/g, "");

      // Replace <h1>...</h1> with the same content but with the "h1" ID added
      cleanedContent = cleanedContent.replace(/<\/h1>/g, "");

      // Split the cleaned patch notes content into individual lines
      const lines = cleanedContent.split(/\r?\n/);

      // Process each line and create a label for it
      lines.forEach((line) => {
        // Process line if it is not empty
        if (line.trim() !== "") {
          let text = line.trim();
          let id = "";

          // Check for replacements and assign corresponding ID
          if (text.startsWith(">")) {
            text = text.substring(1).trim();
            id = "quote";
          } else if (text.startsWith("*")) {
            text = text.replace("*", "•").trim();
            id = "li";
          } else if (text.startsWith("-")) { // Four spaces before the asterisk
            text = text.replace("-", "◦").trim();
            id = "li2";
          } else if (text.startsWith("##")) {
            text = text.substring(2).trim();
            id = "h2";
          } else if (text.startsWith("#")) {
            text = text.substring(1).trim();
            id = "h1";
          } else if (text.startsWith("<h1>")) {
            text = text.substring(4).trim();
            id = "h1";
          }

          // Create label with text and assigned ID
          const label = $.CreatePanel("Label", patchNotesPanel, id);
          label.text = text;

          // Add a new line after each line that has "##"
          if (line.includes("##")) {
            const newLine = $.CreatePanel("Label", patchNotesPanel, "h1line");
            newLine.text = " ";
          }
        }
      });
    } else {
      // Create a label with default message if the content is missing or undefined
      const label = $.CreatePanel("Label", patchNotesPanel, "");
      label.text = "No patch notes available";
    }

  } else {
    formatPatchNotes(); // Retry after 0.1 second if panel element is not found
  }
}