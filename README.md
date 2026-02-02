# LazyPI

A simple World of Warcraft addon for managing a Power Infusion macro. Mouseover a player and update to set them as your PI target.

## Installation

1. Download and extract the `LazyPI` folder
2. Place it in your WoW addons directory:
   - **Retail**: `World of Warcraft/_retail_/Interface/AddOns/`
3. Restart WoW or reload your UI (`/reload`)

## Usage

1. Drag the **LazyPI** macro to your action bar (this casts Power Infusion)
2. Drag the **LazyPI Update** macro to your action bar (this sets the target)
3. Mouseover a friendly player
4. Click **LazyPI Update** to set them as your PI target
5. Click **LazyPI** to cast Power Infusion on them

### Slash Commands

| Command | Description |
|---------|-------------|
| `/lpi update` | Set target to current mouseover |
| `/lpi status` | Show current target |
| `/lpi clear` | Clear target (use fallback) |

## How It Works

- **LazyPI macro**: Casts Power Infusion on your set target
- **LazyPI Update macro**: Sets your mouseover as the new target
- If no target is set, falls back to mouseover → target → self

## Requirements

- World of Warcraft (Interface 120000 / Patch 12.x - Midnight)
- Priest class with Power Infusion
