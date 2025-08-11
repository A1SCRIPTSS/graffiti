# QBCore Graffiti System

An advanced graffiti & gang territory system for FiveM servers using **QBCore**, **ox_lib**, **ox_target**, and **ox_inventory**. Players can buy spray cans, place graffiti, claim territories for gangs, and remove enemy tags. Admins have full control over graffiti management.

## ✨ Features

- 🖌️ **Place custom graffiti** anywhere (with placement restrictions)
- 🏴 **Gang territory control** – claim or defend turf with graffiti
- 🚫 **Blacklist zones** – prevent graffiti in police, hospital, or other restricted areas
- 🛠️ **Removal system** – clean graffiti, remove gang tags, or overwrite enemy sprays
- 💰 **Graffiti shop** with configurable prices & gang-specific sprays
- 👑 **Admin tools** – clear all graffiti, spawn spray cans directly
- 📍 **Optional blips** for certain sprays
- 📦 Fully integrated with **ox_inventory** & **ox_target**

## 📦 Dependencies

This script requires the following resources:

- [qbx_core](https://github.com/Qbox-project/qbx_core)
- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [ox_target](https://github.com/overextended/ox_target)
- [oxmysql](https://github.com/overextended/oxmysql)

## ⚙️ Installation

### 1. Download & Install
1. Download this resource and place it in your `resources/[qb]` folder
2. Rename the folder to `graffiti` (if not already named)

### 2. Server Configuration
Add the following to your `server.cfg`:

```cfg
ensure qbx_core
ensure ox_lib
ensure ox_target
ensure ox_inventory
ensure oxmysql
ensure graffiti
```

### 3. Database Setup
Import the following SQL table to your database:

```sql
CREATE TABLE `graffitis` (
    `key` INT NOT NULL AUTO_INCREMENT,
    `owner` VARCHAR(50) NOT NULL,
    `model` VARCHAR(50) NOT NULL,
    `coords` LONGTEXT NOT NULL,
    `rotation` LONGTEXT NOT NULL,
    PRIMARY KEY (`key`)
);
```

### 4. Item Configuration
Add the following items to your `ox_inventory/data/items.lua` or your item configuration:

```lua
    ["spraycan"] = {
        label = "Spray Can",
        weight = 1000,
        stack = false,
        close = true,
        usable = true,
        description = "A spray can for creating graffiti",
        server = {
            export = "graffiti.useSpraycan",
        },
    },

    ["sprayremover"] = {
        label = "Spray Remover",
        weight = 100,
        stack = true,
        close = true,
        usable = true,
        description = "Used to remove graffiti from walls",
        server = {
            export = "graffiti.useSprayremover",
        },
    },
```

## 🎮 Usage

### Shop
- Visit the graffiti shop NPC (default location: near Legion Square)
- Purchase spray cans and graffiti removal tools
- Different spray designs available for different gangs

### Placing Graffiti
1. Use a spray can from your inventory
2. Position the graffiti preview using movement controls
3. Press **ENTER** to place the graffiti
4. Press **BACKSPACE** to cancel placement

### Removing Graffiti
- Use the graffiti remover item to clean existing graffiti
- Target graffiti with **ox_target** interaction
- Removal time varies based on:
  - Your own gang's graffiti (fastest)
  - Enemy gang graffiti (medium)
  - Neutral graffiti (slowest)

### Gang Territory System
- Place gang-specific graffiti to claim territory
- Defend your turf by removing enemy tags
- Territory control affects gang reputation and influence

## 👑 Admin Commands

| Command | Description | Permission |
|---------|-------------|------------|
| `/cleargraffiti` | Clears all graffiti from the map | Admin only |
| `/spawnspraycan [type]` | Spawn a custom spray can | Admin only |

## 🛠️ Configuration

All configuration options are located in `config.lua`. You can customize:

### Spray Designs
- Add or remove spray can types
- Set gang restrictions for specific designs
- Configure spray models and textures

### Pricing
- Adjust spray can prices
- Set graffiti remover costs
- Configure shop locations

### Gang Settings
- Define which gangs can use specific sprays
- Set minimum gang members required to protect territory
- Configure territory claim mechanics

### Restrictions
- Set blacklisted zones (police stations, hospitals, etc.)
- Configure placement restrictions
- Adjust removal permissions

## 🎨 Adding Custom Sprays

To add new spray designs:

1. Place your texture files in the appropriate directory
2. Add the spray configuration to `config.lua`:

```lua
['new_spray'] = {
    label = 'Custom Gang Spray',
    model = 'prop_cs_spray_01',
    price = 150,
    gang = 'customgang', -- or nil for all gangs
    texture = 'custom_texture_name'
}
```

## 📝 Support

For issues, suggestions, or contributions:
- Open an issue on GitHub

## 🙏 Credits

**Original Repository:** [qb-graffiti](https://github.com/Kalajiqta/qb-graffiti)

---

⭐ **Star this repository** if you find it useful!