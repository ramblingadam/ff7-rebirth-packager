# FF7 Rebirth Modding CLI Tools

Windows CLI tools for rapid packaging and testing mods for FF7 Rebirth

This project currently features two tools:

- EZ Hair Mod Maker: A quick character hair mod creation script
- EZ Mod Packager: A quick mod packaging/testing script

# EZ Hair Mod Maker

A specialized tool for quickly creating and updating hair mods for FF7 Rebirth
characters. Covers all hair variants across all outfits for each character.

### This tool:

- Creates new hair mods or updates existing ones with a simple menu-driven
  interface
- Automatically handles the correct directory structure for hair mods
- Injects your texture files into the game's hair assets
- Integrates with the packager for immediate testing
- Remembers your last used mod and texture files for rapid iteration

### Requirements:

- Windows OS with PowerShell
- UE4-DDS-Tools: Included in the `ez-hair-mod-maker/UE4-DDS-Tools-v0.6.1-Batch`
  directory
- Original hair asset files (`.uasset` and `.ubulk`) extracted from the game
- UModel or FModel for extracting the original hair assets

### Getting Started:

1. First, extract the original hair assets from the game using UModel or FModel.
   Reference the placeholder text files' filenames in each character
   subdirectory in `ez-hair-mod-maker/original-hair/` for the files you need to
   extract.
2. Place the extracted files in the matching character subdirectory in the
   `ez-hair-mod-maker/original-hair`:
   ```
   ez-hair-mod-maker/
   ├── original-hair/
   │   ├── Tifa/
   │   │   ├── PC0002_00_Hair_C.uasset
   │   │   └── PC0002_00_Hair_C.ubulk
   │   ├── Cloud/
   │   │   ├── PC0001_00_Hair_C.uasset
   │   │   └── PC0001_00_Hair_C.ubulk
   │   └── ...
   ```

### Mod Directory Structure:

Your mods will be created in the MOD_BASE_DIR with this structure:

```
MOD_BASE_DIR/
├── my-hair-mod/
│   └── mod-content/
│       └── End/
│           └── Content/
│               └── Character/
│                   └── Player/
│                       └── [Character Directory]/
│                           └── [Hair Assets]
└── ...
```

# Usage

- Run the script by opening `ez-hair-mod-maker/start.bat`
- Choose whether to create a new hair mod or update an existing one
- Select the character you want to mod (Cloud, Tifa, etc.)
- The script will verify that you have the required source files in the
  `original-hair` directory
  - If files are missing, it will tell you exactly which files you need to
    extract from the game
- Provide the path to your texture file (PNG, JPG, or BMP)
- The script will:
  1. Create the correct directory structure
  2. Copy the required files
  3. Inject your texture
  4. Optionally launch the packager to test your mod immediately

### Tips:

- Extract all character hair files at once and organize them in the
  `original-hair` directory to avoid having to extract them later
- Use descriptive names for your mods (e.g., "tifa-green-hair",
  "cloud-white-hair")
- The script remembers your last used texture file, making it easy to test
  different characters with the same texture
- If updating an existing mod, the script will verify the files exist before
  proceeding

# EZ Mod Packager

A specialized tool for quickly packaging and testing FF7 Rebirth mods. Handles
all the complexity of packaging mod files and getting them into your game.

https://github.com/user-attachments/assets/a54ed9a4-121c-4443-a95a-48807018df89

### This tool:

- Packages your `.uasset` and `.ubulk` files using UnrealReZen (included)
- Creates timestamped export folders for each version of your mod
- Hex edits the headers of UnrealReZen's `.ucas` output to be compatible with
  FF7 Rebirth
- Creates a .zip file for easy uploading to Nexus Mods
- Optionally tests the mod immediately by:
  - Copying files to your game's Paks directory
  - Cleaning up old versions of the same mod
  - Launching the game

### Requirements:

- Windows OS with PowerShell
- UnrealReZen: Included in the `ez-mod-packager/UnrealReZen` directory
- Steam installation of FF7 Rebirth

### Directory Structure:

Your mods must follow this structure:

```
MOD_BASE_DIR/ <- You will set this directory during the first run of the script
├── my-first-mod/ <- The script will detect all folders in MOD_BASE_DIR for you to select from
│   └── mod-content/ <- You must have a folder called mod-content inside your individual mod folders
│       └── ...
├── tifa-green-hair
│   └── mod-content/ <- mod-content must include the entire default path to the assets your mod is changing
│       └── End/
│           └── Content/
│               └── Character/
│                   └── Player/
│                       └── PC0002_00_Tifa_Standard/
│                           └── Texture/
│                               └── PC0002_00_Hair_C.uasset
│                               └── PC0002_00_Hair_C.ubulk
├── cloud-purple-eyes/
│   └── mod-content/
└       └── ...
```

# Usage

- Run the script by opening `ez-mod-packager/start.bat`
- First run will ask for:
  - `MOD_BASE_DIR`: The base folder where your mods live
  - `GAME_DIR`: The installation location of FF7 Rebirth
  - `STEAM_EXE`: The path to your Steam.exe
  - These can later be updated in `config.ini`
- Select the mod folder you want to package from the list
- The script will:
  1. Package your mod using UnrealReZen
  2. Create a timestamped export folder
  3. Generate a .zip file for Nexus Mods
  4. Optionally copy the files to your game and launch it

### Tips:

- The script remembers your last packaged mod for quick testing
- Mod folder names in dash-case will be converted to PascalCase in the output
  (e.g., `tifa-green-hair` → `TifaGreenHair.ucas`)
- Keep your old export folders until you're happy with your mod
- Clean up old versions from your game's Paks directory when you're done testing

# FAQ

### The game crashed or the mod doesn't work.

- Ensure your directory structure matches the original path to the assets that
  your mod is changing
- Sometimes UnrealReZen hiccups. Try running the packager on the same mod again.
- Ensure your `GAME_DIR` points to the BASE FF7 Rebirth install directory (by
  default, this is
  `C:\Program Files (x86)\Steam\steamapps\common\FINAL FANTASY VII REBIRTH`)

# Credits

### EZ Mod Packager

Inspired by a script from Yoraiz0r

### UE4-DDS-Tools

The EZ Hair Mod Maker uses
[UE4-DDS-Tools](https://github.com/matyalatte/UE4-DDS-Tools) by matyalatte,
distributed under the MIT License. A copy of this tool is included in the
`ez-hair-mod-maker/UE4-DDS-Tools-v0.6.1-Batch` directory.

### UnrealReZen

The EZ Mod Packager uses
[UnrealReZen](https://github.com/rm-NoobInCoding/UnrealReZen) by
rm-NoobInCoding. A copy of this tool is included in the `packager/UnrealReZen`
directory.
