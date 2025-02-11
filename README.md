# FF7 Rebirth Packager
Windows CLI tool for rapid packaging and testing mods for FF7 Rebirth
Based on a script by Yoraiz0r

### This tool:
- Packages your `.uasset` and `.ubulk` files using UnrealReZen
- Creates a timestamped export folder (e.g. `MOD_BASE_DIR/TifaGreenHair_timestamp`) in the mod directory and places UnrealReZen's output into the folder
- Hex edits the headers of UnrealReZen's `.utoc` output to be compatible with FF7 Rebirth
- Creates a .zip file for easy uploading to Nexus Mods in the timestamped export folder
- If the user confirms:
  - The mod files are copied to `GAME_DIR/End/Content/Paks/YourModName_timestamp`
  - If there are any previous version of the current mod name in the game's Paks direcctory, will clean them up from the game's Pak directory first. (The timestamped export folders in `MOD_BASE_DIR/your-mod-name` are NOT deleted)
  - Lanunches the game
 
# Requirements
- Windows OS with Powershell
- UnrealReZen: https://github.com/rm-NoobInCoding/UnrealReZen

### IMPORTANT:
This tool has opinionated expectations about your mod projects' directory structure.

```
MOD_BASE_DIR <- You will set this directory during the first run of the script
├── my-first-mod <- The script will detect all folders in MOD_BASE_DIR for you to select from
│   └── mod-content <- You must have a folder called mod-content inside your individual mod folders
│       └── ...
├── tifa-green-hair <- The repacked mod will automatically convert dash-cased folder names into a PascalCased mod name
│   └── mod-content <- mod-content must includes the entire default path to the assets your mod is changing
│       └── End
│           └── Content
│               └── Character
│                   └── Player
│                       └── PC0002_00_Tifa_Standard
│                           └── Texture
│                               └── PC0002_00_Hair_C.uasset
│                               └── PC0002_00_Hair_C.ubulk
├── cloud-purple-eyes
│   └── mod-content
└       └── ...
```

# Usage
- Run the script by opening start.bat

- First run will ask for relevant filepaths:
  - UNREALREZEN_DIR: Path to the folder containing UnrealReZen.exe
  - MOD_BASE_DIR: The base folder where your mods live.
  - GAME_DIR: The instalation location of FFVII Rebirth
  - STEAM_EXE: The path to your Steam.exe
  - Once set, these can be updated by modifying config.ini

- The script will list all folders in the MOD_BASE_DIR you specified. Pick the folder containing the `mod-content` folder you wish to package and test.
- If you've set up your fodler structure correctly, then that's it!
- The script will remember the last mod you packaged to make it easier to run subsequent tests quickly

- When you're happy with your mod, manually delete any remaining test folders in `GAME_DIR/End/Content/Paks/`
- Upload the `.zip` file in the timestamped export folder that contains the version of your mod that you like to Nexus!
- Optionally delete any local timestamped exports in `MOD_BASE_DIR/YourModName/` that you don't want anymore


# FAQ
### The game crashed or the mod doesn't work.
Ensure your directory structure matches the original path to the assets that your mod is changing.
