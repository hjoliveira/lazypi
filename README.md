# LazyPI

A World of Warcraft addon that creates a Power Infusion macro targeting the highest-priority DPS player in your group based on a customizable priority list.

## Features

- **Smart Target Selection** - Analyzes group/raid members and identifies the highest-priority DPS target
- **Macro Management** - Creates and updates a "LazyPI" macro that targets the optimal player
- **Customizable Priority List** - Reorder DPS specs using up/down arrows to set your preferred priority
- **Smart Fallback** - When no priority target exists, defaults to mouseover → target → self
- **DPS Only** - Only considers DPS specializations (tanks and healers are excluded)

## Installation

1. Download and extract the `LazyPI` folder
2. Place it in your WoW addons directory:
   - **Retail**: `World of Warcraft/_retail_/Interface/AddOns/`
3. Restart WoW or reload your UI (`/reload`)

## Usage

### Slash Commands

Use `/lazypi` or `/lpi` followed by:

| Command | Description |
|---------|-------------|
| *(none)* | Open settings |
| `update` | Update macro with best target |
| `status` | Show current status and best target |
| `list` | List all group members with their priorities |
| `reset` | Reset all priorities to defaults |
| `debug` | Toggle debug mode |

### Quick Start

1. After installation, drag the "LazyPI" macro from your macro window to your action bar
2. Join a group or raid
3. Run `/lpi update` to set the macro target
4. Use `/lpi status` to see who is currently being targeted

## Configuration

Open the settings panel via **Interface Options > AddOns > LazyPI** to configure:

- **Priority List** - Use the up/down arrows to reorder specs
  - Specs at the top of the list have highest priority
  - Move specs up or down to customize targeting order

## Default Priority Order

The addon comes with a default priority order based on typical Power Infusion value:

1. Arcane Mage
2. Affliction Warlock
3. Fire Mage
4. Demonology Warlock
5. Augmentation Evoker
6. Balance Druid
7. Shadow Priest
8. Destruction Warlock
9. Devastation Evoker
10. Elemental Shaman
11. *(and more...)*

All priorities can be customized by reordering the list in the settings panel.

## How It Works

1. Run `/lpi update` to scan your group
2. The addon inspects each member to determine their specialization
3. Only DPS specs are considered (tanks and healers are ignored)
4. Members are sorted by their spec's position in your priority list
5. The highest-ranked living DPS player becomes the macro target
6. The macro is updated with `/cast [@PlayerName] Power Infusion`

## Requirements

- World of Warcraft (Interface 120000 / Patch 12.x - Midnight)
- Priest class with Power Infusion

## Feedback & Issues

Found a bug or have a suggestion? Feel free to open an issue or submit a pull request.
