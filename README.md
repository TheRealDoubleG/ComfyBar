# ComfyBar

**Version 0.6 – Beta**  
**Tested target: WoW Forever 1.60.1 / Build 70009 / Interface 16001**  
Author: **TheRealDoubleG**  
Discord: **the.real.double.g**

ComfyBar is a customizable utility-bar addon for World of Warcraft Forever. It is designed to keep buffs, consumables, travel tools, professions, scrolls and racial abilities organized without turning into another full combat action-bar replacement.

## Core rule

**One player input = at most one game action.**

ComfyBar does not automate rotations, repeated item use or multi-step gameplay. Secure WoW action buttons are used for player-triggered spells and items.

## 0.1 Beta foundation

The first beta establishes the common framework:

- Separate bars for **Consumables**, **Buffs**, **Utility**, **Professions & Scrolls** and **Racials**.
- Each bar can be enabled independently.
- Horizontal or vertical layout.
- Per-bar scale and adjustable icon spacing (0–30 px).
- **Apply layout to all bars** copies orientation, scale and icon spacing from the selected bar to every bar with one click.
- Freely movable bars while edit mode is enabled.
- Bars are locked during normal use.
- A **+ slot** appears only in edit mode.
- Drag a spell or item onto the + slot to add it.
- Right-click a custom button in edit mode to remove it.
- Optional per-bar **hide in combat** behavior.
- Standard WoW spell/item icons, tooltips, item counts and cooldown sweeps.
- Utility bar starts with the **Hearthstone**.
- Built-in presets: **Minimal**, **Preferred**, **Complete**.
- OnPoint-style settings window and minimap behavior.
- Saved settings-window position with its own default location, so ComfyBar and OnPoint no longer open directly on top of each other.
- Each bar keeps its own full UI anchor/position and uses a separate bottom-right default position.
- Minimap button: left click toggles ComfyBar, right click opens settings, drag moves it when unlocked.
- Left-click toggle now prints a chat message confirming whether ComfyBar is enabled or disabled, matching OnPoint's behavior.
- German UI on a German client, English otherwise.
- Info tab with addon version, build date, client build/interface, author, Discord and compatibility state.

## Planned smart modules

The next development steps will add the features that make ComfyBar truly smart:

- Mage conjured food and water detection across leveling ranks.
- Configurable stock thresholds for showing/hiding conjure buttons.
- Combined eat + drink helper with one player action per click.
- Automatic class-buff discovery.
- Automatic racial ability discovery, including combat-usable racials.
- Mana stones, bandages and other useful combat consumables.
- Scroll inventory flyout and one-scroll-per-click deciphering support where the client API allows it.
- Profession discovery and profession buttons.
- Teleport and portal flyouts.
- Better inventory-aware item selection.
- Custom named profiles.
- Clean integration points for a future standalone **ComfyCC** cooldown addon.

## Installation

Copy the ComfyBar folder into:

World of Warcraft\Interface\AddOns\

The final path should be:

World of Warcraft\Interface\AddOns\ComfyBar\ComfyBar.toc

## Slash commands

- /comfybar or /cb – open settings
- /cb unlock – enable edit mode
- /cb lock – lock the bars
- /cb on – enable ComfyBar
- /cb off – disable ComfyBar

## Development status

ComfyBar is currently **Beta**. The 0.6 release is the current test foundation for in-game testing before the automatic class-, racial-, profession- and inventory-aware systems are added.

---

# ComfyBar – Deutsch

ComfyBar ist ein anpassbares Komfortleisten-Addon für WoW Forever. Es bündelt Verbrauchsgegenstände, Buffs, Utility, Berufe, Scrolls und Rassenfähigkeiten, ohne eine komplette Kampf-Actionbar ersetzen zu wollen.

Die wichtigste Regel lautet:

**Eine Eingabe des Spielers = höchstens eine Spielaktion.**

Die Beta 0.6 liefert das aktuelle Test-Grundgerüst mit mehreren Leisten, Bearbeitungsmodus, + Slot, WoW-Icons, Minimap-Button, Profil-Voreinstellungen und dem OnPoint-artigen Einstellungsmenü. Die intelligenten Klassen- und Inventarfunktionen folgen Schritt für Schritt.
