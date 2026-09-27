# ComfyBar Changelog

## 0.13 Beta – 27.09.2026
- Fixed the repeating `Bars.lua:84` Lua error caused by comparing WoW protected/secret cooldown duration values.
- Secret cooldown values are now passed directly to the native Cooldown widget instead of being inspected in addon Lua.
- Added guarded handling for protected item-count values to prevent the same class of taint error there.
- This stops the rapid error loop that could trigger WoW's "large number of errors" warning.


## 0.12 Beta – 27.09.2026
- Added the shared **Settings** tab immediately before Info.
- Added automatic per-character saved profiles plus account and named custom profiles, with copy/load from another known character profile.
- Added window lock, window/background opacity, optional Blizzard border and minimalist borderless background.
- Moved minimap presentation controls into Settings.
- Tightened the default centered bar stack slightly below the character.
- Improved migration of bars still sitting on the old bottom-right defaults while leaving manually moved bars untouched.
- Added one-time cleanup of saved spell actions that are not known by the current character.
- Renamed the old feature-profile page to **Presets / Voreinstellungen** to distinguish it from saved character profiles.
- Changed active tabs to a selected/pushed state and cleaned Info footer spacing.


## 0.11 Beta – 27.09.2026
- Added reliable ComfyHub minimap bundling support.
- The standalone minimap button now hides while ComfyHub bundling is active.
- Disabling bundling restores the button according to this addon's own minimap visibility setting.
- Re-enabling bundling hides the standalone button again immediately.


## 0.10 Beta – 27.09.2026
- Updated current documentation to the renamed **ComfyOnPoint** addon.
- Kept ComfyBar naming and family references aligned with the Comfy Suite.


## 0.9 Beta – 27.09.2026
- Adopted the shared Comfy Suite UI standard.
- Added the Comfy Suite badge to the Info tab.
- Added Comfy Suite metadata to the TOC for family identification.
- Standardized the Info-tab structure and family styling with OnPoint, ComfyCC and ComfyHub.


## 0.8 Beta – 27.09.2026
- Changed ComfyBar's default bar anchor from the bottom-right of the screen to the screen center.
- Default bars are now stacked in the lower-middle area for a more natural starting position.
- Added a safe migration for bars that were still sitting exactly on the old default bottom-right positions; manually moved bars are left untouched.
- "Reset position" now resets the selected bar to the new centered default position.


## 0.7 Beta – 27.09.2026
- Matched the Info-tab footer wording to OnPoint's family style.
- Footer now thanks users for using ComfyBar and invites feedback and bug reports via Discord.


## 0.6 Beta – 27.09.2026
- Added chat feedback when ComfyBar is enabled or disabled.
- Minimap left-click now reports "ComfyBar: aktiviert." / "ComfyBar: deaktiviert." on German clients, matching OnPoint's toggle feedback.
- Settings are refreshed after toggling so the UI immediately reflects the new state.


## 0.5 Beta – 27.09.2026
- Fixed overlapping copyright/thanks text at the bottom of the Info tab.
- Added "Apply layout to all bars" in the Bars tab.
- The new one-click layout action copies orientation, scale and icon spacing from the currently selected bar to every ComfyBar bar while keeping visibility, combat behavior and positions independent.


## 0.4 Beta – 27.09.2026
- Added independent full anchor/position saving for every ComfyBar bar.
- Added separate bottom-right default positions for Utility, Buffs, Consumables, Professions & Scrolls and Racials.
- Added a saved ComfyBar settings-window position with a left-offset default so it no longer opens directly on top of OnPoint.
- Moved normal ComfyBar bars to MEDIUM frame strata / level 5.
- Moved the settings window to HIGH strata / level 20, enabled top-level behavior and raise-on-click.


## 0.3 Beta – 27.09.2026
- Removed the permanent Quickslot background squares from normal action buttons for a cleaner icon-only look.
- Increased the visible icon area inside each action button.
- Renamed the spacing control to Icon spacing / Icon-Abstand and expanded its range to 0–30 px per bar.


## 0.2 Beta – 27.09.2026
- Fixed the minimap tracking-border anchor so the gold ring is correctly centered around the icon instead of appearing detached.

## 0.1 Beta – 27.09.2026

- Renamed the project from ComfyMage to ComfyBar and made the architecture class-independent.
- Added five independent bar groups: Consumables, Buffs, Utility, Professions & Scrolls, and Racials.
- Added horizontal/vertical orientation, scale, spacing and movable bar positions.
- Added locked normal mode and an explicit edit mode.
- Added a persistent + slot in edit mode for dropping spells and items.
- Added right-click removal of custom buttons while edit mode is active.
- Added optional hide-in-combat behavior per bar.
- Added standard WoW icons, tooltips, item counts and cooldown sweeps.
- Added Hearthstone to the default Utility bar.
- Added Minimal, Preferred and Complete presets.
- Added an OnPoint-style settings window with an Info tab.
- Added an OnPoint-style minimap button: left click toggles ComfyBar, right click opens settings, drag moves it when unlocked.
- Added German and English UI strings.
- Added client version/build/interface compatibility display.
- Documented the rule that ComfyBar never performs more than one game action per player input.
