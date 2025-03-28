# WoW Essentials

A comprehensive all-in-one World of Warcraft addon that combines UI customization, boss alerts, custom ability cues, and combat statistics tracking.

## Features

### UI Customization
- Custom player, target, and party frames
- Movable and resizable UI elements
- Customizable colors, fonts, and textures
- Preservation of original UI elements when desired

### Boss Alerts
- Visual and audio alerts for boss mechanics
- Low health warnings for important targets
- Customizable alert thresholds
- Boss-only mode to reduce alert spam

### Ability Cues
- Visual tracking for important cooldowns and procs
- Class-specific ability tracking
- Support for custom spell tracking
- Adjustable display settings

### Combat Stats
- Real-time DPS and HPS tracking
- Combat duration timer
- Session history
- Adjustable calculation window

## Installation

1. Download the latest version of WoW Essentials
2. Extract the `WoWEssentials` folder to your WoW `Interface\AddOns` directory
3. Restart World of Warcraft or reload your UI

## Usage

### General Commands
- `/we` or `/wowessentials` - Open the main configuration panel
- `/we help` - Show all available commands
- `/we version` - Show addon version information
- `/we enable [module]` - Enable a specific module
- `/we disable [module]` - Disable a specific module

### UI Module Commands
- `/weui` - Show UI module commands
- `/weui reset` - Reset all frame positions
- `/weui lock` - Lock all frames
- `/weui unlock` - Unlock frames for movement
- `/weui scale [0.5-2.0]` - Set UI scale

### Alerts Module Commands
- `/wealerts` - Show alerts module commands
- `/wealerts test` - Show a test alert
- `/wealerts sound on|off` - Toggle sound alerts
- `/wealerts visual on|off` - Toggle visual alerts
- `/wealerts text on|off` - Toggle text alerts
- `/wealerts bossonly on|off` - Toggle boss-only mode
- `/wealerts threshold [0-100]` - Set health percentage threshold for alerts

### Cues Module Commands
- `/wecues` - Show cues module commands
- `/wecues test` - Show a test cue
- `/wecues cooldowns on|off` - Toggle cooldown tracking
- `/wecues procs on|off` - Toggle proc tracking
- `/wecues resources on|off` - Toggle resource tracking
- `/wecues add [spellId]` - Add custom spell to track
- `/wecues remove [spellId]` - Remove custom spell
- `/wecues list` - List all tracked spells

### Stats Module Commands
- `/westats` - Show stats module commands
- `/westats show` - Show stats window
- `/westats hide` - Hide stats window
- `/westats reset` - Reset all stats
- `/westats dps on|off` - Toggle DPS display
- `/westats hps on|off` - Toggle HPS display
- `/westats combatonly on|off` - Toggle combat-only mode
- `/westats window [seconds]` - Set time window (5-300)
- `/westats threshold [value]` - Set minimum threshold to display

## Configuration

Most settings can be configured through the in-game configuration panel, accessible via the `/we config` command or by right-clicking certain elements of the addon's UI.

## Requirements
- World of Warcraft Retail (Current version)
- No external libraries required

## Known Issues
- First-time users may need to reload the UI for all settings to apply properly
- Some frame positions may need adjustment based on screen resolution

## Credits
- Created by WoWaddonAssistant
- Special thanks to the WoW addon development community

## License
This addon is provided as-is under the terms of the MIT license. 