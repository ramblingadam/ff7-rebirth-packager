# FF7 Rebirth Modding CLI Tools - Packager & Hair Mod Builder

Windows CLI tools for rapid packaging and testing mods for FF7 Rebirth

This repo currently sports two tools:

- Packager: A quick mod packaging/testing script
- EZ Hair Mod Maker: A quick hair mod creation script

# Packager

Packaging/testing tool based on a script by Yoraiz0r

https://github.com/user-attachments/assets/a54ed9a4-121c-4443-a95a-48807018df89

### This tool:

- Packages your `.uasset` and `.ubulk` files using UnrealReZen
- Creates a timestamped export folder (e.g.
  `MOD_BASE_DIR/TifaGreenHair_timestamp`) in the mod directory and places
  UnrealReZen's output into the folder
- Hex edits the headers of UnrealReZen's `.ucas` output to be compatible with
  FF7 Rebirth
- Creates a .zip file for easy uploading to Nexus Mods in the timestamped export
  folder
- Asks the user if they want to test the mod immediately
  - If the user confirms:
    - The mod files are copied to
      `GAME_DIR/End/Content/Paks/YourModName_timestamp`
    - If there are any previous version of the current mod name in the game's
      Paks direcctory, will clean them up from the game's Pak directory first.
      (The timestamped export folders in `MOD_BASE_DIR/your-mod-name` are NOT
      deleted)
    - Launches the game

# Requirements

- Windows OS with Powershell
- UnrealReZen: https://github.com/rm-NoobInCoding/UnrealReZen

### IMPORTANT:

This tool has opinionated expectations about your mod projects' directory
structure.

```
MOD_BASE_DIR <- You will set this directory during the first run of the script
├── my-first-mod <- The script will detect all folders in MOD_BASE_DIR for you to select from
│   └── mod-content <- You must have a folder called mod-content inside your individual mod folders
│       └── ...
├── tifa-green-hair
│   └── mod-content <- mod-content must include the entire default path to the assets your mod is changing
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

  - `UNREALREZEN_DIR`: Path to the folder containing UnrealReZen.exe
  - `MOD_BASE_DIR`: The base folder where your mods live.
  - `GAME_DIR`: The instalation location of FFVII Rebirth
  - `STEAM_EXE`: The path to your Steam.exe
  - Once set, these can be updated by modifying `config.ini`

- The script will list all folders in the MOD_BASE_DIR you specified. Pick the
  folder containing the `mod-content` folder you wish to package and test.
- If you've set up your fodler structure correctly, then that's it!
- The script will remember the last mod you packaged to make it easier to run
  subsequent tests quickly
- If your individual mod folder names are dash-cased, the packaged mod files
  will be PascalCased. (eg `MOD_BASE_DIR/tifa-green-hair/` =>
  `TifaGreenHair.ucas`, `TifaGreenHair.zip`, etc.)

  - Otherwise, the mod name will remain the same (eg
    `MOD_BASE_DIR/Cloud purple EYES/` => `Cloud purple EYES.zip`)

- When you're happy with your mod, manually delete any remaining test folders in
  `GAME_DIR/End/Content/Paks/`
- Upload the `.zip` file in the timestamped export folder that contains the
  version of your mod that you like to Nexus!
- Optionally delete any local timestamped exports in `MOD_BASE_DIR/YourModName/`
  that you don't want anymore

# FAQ

### The game crashed or the mod doesn't work.

- Ensure your directory structure matches the original path to the assets that
  your mod is changing
- Ensure your `GAME_DIR` points to the BASE FF7 Rebirth install directory (by
  default, this is
  `C:\Program Files (x86)\Steam\steamapps\common\FINAL FANTASY VII REBIRTH`)
