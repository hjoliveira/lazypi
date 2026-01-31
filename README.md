# LazyPI

A World of Warcraft addon that automatically manages a Power Infusion macro, targeting the most valuable player in your group based on specialization priorities.

## Features

- **Automatic Target Selection** - Analyzes group/raid members and identifies the highest-priority target based on their specialization
- **Dynamic Macro Management** - Creates and updates a "LazyPI" macro that targets the optimal player
- **Customizable Priorities** - Adjust priority values (0-100) for all 38 specializations
- **Live Updates** - Automatically re-evaluates targets when:
  - Group roster changes
  - Player specializations change
  - Entering new zones
- **Smart Fallback** - When no priority target exists, defaults to mouseover → target → self
- **Settings Panel** - Full GUI for adjusting all options and spec priorities

## Installation

1. Download and extract the `LazyPI` folder
2. Place it in your WoW addons directory:
   - **Retail**: `World of Warcraft/_retail_/Interface/AddOns/`
   - **Classic**: `World of Warcraft/_classic_/Interface/AddOns/`
3. Restart WoW or reload your UI (`/reload`)
4. The addon will automatically create a "LazyPI" macro

## Usage

### Slash Commands

Use `/lazypi` or `/lpi` followed by:

| Command | Description |
|---------|-------------|
| *(none)* | Open settings panel |
| `config` | Open settings panel |
| `toggle` | Enable/disable the addon |
| `update` | Force macro update |
| `status` | Show current status and best target |
| `list` | List all group members with their priorities |
| `reset` | Reset all priorities to defaults |
| `debug` | Toggle debug mode |
| `?` | Show help |

### Quick Start

1. After installation, drag the "LazyPI" macro from your macro window to your action bar
2. Join a group or raid
3. The macro will automatically update to target the best Power Infusion candidate
4. Use `/lpi status` to see who is currently being targeted

## Configuration

Open the settings panel with `/lpi` to configure:

- **Enable/Disable** - Toggle the addon on or off
- **Auto-Update Macro** - Automatically update when group composition changes
- **Include Self** - Include yourself as a potential target (useful for Shadow Priests)
- **Specialization Priorities** - Sliders for each spec (0-100)
  - `0` = Never target this spec
  - `1-99` = Variable priority
  - `100` = Highest priority

The settings panel can also be accessed via WoW's Interface Options menu.

## Default Priorities

The addon comes with sensible defaults based on typical Power Infusion value:

| Priority | Specializations |
|----------|-----------------|
| **Highest (70-100)** | Arcane Mage, Affliction Warlock, Fire Mage, Demonology Warlock, Augmentation Evoker |
| **High (65-70)** | Balance Druid, Shadow Priest, Destruction Warlock, Devastation Evoker, Elemental Shaman |
| **Medium (45-60)** | Most other DPS specs |
| **Low/None (0)** | Tanks and Healers |

All priorities can be customized to match your group's needs.

## How It Works

1. When you join a group, the addon inspects each member to determine their specialization
2. Members are sorted by their spec's priority value
3. The highest-priority living player becomes the macro target
4. The macro is updated with `/cast [@PlayerName] Power Infusion`
5. When the target leaves or dies, the addon automatically selects the next best target

## Requirements

- World of Warcraft (Interface 120000 / Patch 12.x - Midnight)
- Priest class with Power Infusion

## Feedback & Issues

Found a bug or have a suggestion? Feel free to open an issue or submit a pull request.
