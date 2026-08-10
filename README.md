# Deco QoL

Deco QoL is a configurable quality-of-life mod pack designed to provide what I believe is the best way to experience Pok?mon Gen 1 using Gen1Recomp. Every feature can be toggled on or off, so you are free to customize the experience however you prefer.

Current stable version: **1.2.14**

## Requirement

[Gen1Recomp](https://github.com/Gen1Recomp/Gen1Recomp) is required. Deco QoL is a Gen1Recomp mod and cannot be used as a standalone game or with a standard Pok?mon ROM emulator.

Use a Gen1Recomp version compatible with the range declared in `manifest.json`.

## Installation

1. Install and configure Gen1Recomp.
2. Place the Deco QoL mod files in the Gen1Recomp mods directory.
3. Start Gen1Recomp and enable Deco QoL.
4. Open **MOD OPTIONS** from the in-game START menu to configure the features.

All features are disabled by default.

## Features

### Battle Options

- **Never Miss**: prevents the player's attacks from missing.
- **Always Crit**: makes the player's attacks always land as critical hits.
- **Infinite PP**: prevents the player's moves from consuming PP.
- **Always Catch**: makes Pok? Balls successfully catch wild Pok?mon.
- **EXP Share ? Off**: uses the normal Gen 1 experience system.
- **EXP Share ? Gen1**: gives 50% of the experience to the active Pok?mon and divides the other 50% among the eligible party members.
- **EXP Share ? Smart**: gives 50% to the active Pok?mon and prioritizes lower-level eligible party members when distributing the shared half. If all recipients are at the same level, the experience is divided equally.
- **Move Info**: displays the selected move's type, power, and accuracy during battle.

Fainted Pok?mon and level 100 Pok?mon do not receive shared experience. Level-ups, stat increases, and learned moves still use the normal Gen1Recomp flow.

### Pok?mon Options

- **Move Editor ? Off**: disables the Move Editor.
- **Move Editor ? Base**: allows moves from the Pok?mon's Gen 1 level-up learnset and compatible TMs. HMs are excluded.
- **Move Editor ? All**: allows any move loaded by the game.
- **Forget HM**: allows HM moves to be forgotten.
- **Reusable TMs**: prevents TMs from being consumed after use.
- **Quick HM ? Off**: disables Quick HM.
- **Quick HM ? On**: adds Quick HM to the START menu and allows field moves without teaching them to a Pok?mon, while still requiring the correct HM and badge.
- **Quick HM ? Ignore**: enables all five field HMs without requiring the HM item or badge.
- **Pikachu Evo**: allows Pikachu to evolve with a Thunder Stone in Pok?mon Yellow.

The Move Editor shows each selected move's type, PP, power, and accuracy. Left and Right change pages; Up and Down move through the list.

### Miscellaneous

- **Fast Run ? Off**: uses normal movement speed.
- **Fast Run ? On**: enables faster running while preserving normal movement during cutscenes.
- **Fast Run ? On + Surf**: also applies faster movement while surfing.
- **Auto Run**: keeps Fast Run active without holding the run button. This option appears only when Fast Run is enabled.
- **Instant Text**: displays dialogue instantly while preserving normal pages, choices, and script behavior.
- **Itemfinder ? Off**: disables the Itemfinder enhancement.
- **Itemfinder ? On**: detects hidden items within the native Itemfinder range without requiring the item and marks their locations with an animated shrinking square.
- **Itemfinder ? Have Item**: enables the same detection effect only when the player owns the Itemfinder.
- **Fast Center**: skips the standard Pok?mon Center conversation, heals the party immediately, and plays the normal healing-machine jingle.
- **Fast Save**: saves immediately without confirmation text boxes and plays only the save confirmation sound.

### Bag Improvements

- Increases the Bag capacity to **999 different item slots**. The native per-item quantity limit remains unchanged.
- Separates the Bag into Gen 2-style **Items**, **Key**, **Ball**, and **TM/HM** tabs.
- Switches tabs with Left and Right.
- Opens the Auto Sort menu with START.
- **Sort ? Off**: preserves acquisition order and allows manual reordering with SELECT.
- **Sort ? Name**: sorts items alphabetically.
- **Sort ? Quantity**: sorts items by quantity in descending order.
- **Sort ? Type**: uses a fixed functional order, grouping healing items, status recovery, battle items, exploration items, key items, Balls, HMs, and TMs.
- Shows the active tab with a black background and white text.
- Marks the active Auto Sort mode with a hollow selection arrow.

### Reset Options

- Each category includes **Reset Defaults**.
- The main menu includes **Reset Default All**.
- Every reset action opens a confirmation box with **No** selected by default.

## Notes

Deco QoL affects gameplay mechanics and link compatibility. Feature availability can depend on the installed Gen1Recomp build and its internal APIs.
