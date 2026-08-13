# myQualityOfLife

myQualityOfLife is a configurable quality-of-life mod pack for Pokemon Gen 1 and the experimental Pokemon Gold support in Gen1Recomp. Every feature can be toggled on or off, so you are free to customize the experience however you prefer.

Current release: **1.3.0-beta.23** (requires Gen1Recomp 0.1.80 or newer)

> **Pokemon Gold / Gen 2 beta notice:** the Gen 2 features are implemented and
> working in current tests. However, Pokemon Gold support in Gen1Recomp is still
> beta, so unexpected problems or compatibility changes may occur. Keep backup
> saves while using the Gold implementation. The Gen 1 implementation has been
> tested and approved.

## Generation isolation

This package contains two separate implementations selected automatically at startup:

- `gen1.lua` is the tested implementation used by Red, Blue, and Yellow.
- `gen2.lua` is a new implementation written specifically for the Pokemon Gold beta.

Gold does not load the Gen 1 implementation, and Gen 1 does not load the Gold implementation. This prevents experimental Gold changes from altering the stable Gen 1 behavior while the beta is tested.

Gold already provides its own four-pocket Pack, TM move names, physical/special split, and corrected type behavior. Therefore **Type Fixes** and **Pikachu Evo** are intentionally Gen 1-only. Gold Quick HM includes Cut, Fly, Surf, Strength, Flash, Whirlpool, and Waterfall. Gold support is experimental and should be tested with backup saves.

## Requirement

[Gen1Recomp](https://github.com/bryanthaboi/gen1recomp) is required. myQualityOfLife is a Gen1Recomp mod and cannot be used as a standalone game or with a standard Pokemon ROM emulator.

Use a Gen1Recomp version compatible with the range declared in `manifest.json`.

## Installation

1. Install and configure Gen1Recomp.
2. Place the myQualityOfLife mod files in the Gen1Recomp mods directory.
3. Start Gen1Recomp and enable myQualityOfLife.
4. Open **OPTIONS**, then select **myQualityOfLife** to configure the features.

All features are disabled by default.

## Features

### Battle Options

- **EXP Share - Off**: uses the normal Gen 1 experience system.
- **EXP Share - Gen1**: divides 50% equally among the Pokemon that participated against the defeated opponent, then divides the other 50% among eligible non-participants.
- **EXP Share - Smart**: divides 50% equally among the participants and gives the shared half to the eligible non-participants that had the lowest level before distribution began. A Pokemon leveling up during that award does not change the recipient group; tied lowest-level recipients divide the shared experience equally.
- **Move Info**: adds Power and Accuracy to the Wide battle move selector while preserving the native Type and current/max PP display.

Fainted Pokemon and level 100 Pokemon do not receive shared experience. Level-ups, stat increases, and learned moves still use the normal Gen1Recomp flow.
Each participant completes its EXP, level-up, stat, and move-learning flow before the next participant. The shared summary then reports the per-Pokemon amount (for example, `2 POKEMON gained 25 EXP!`) before shared recipients begin their own level-up flows. Shared recipients receive equal awards; any division remainder is added to the primary participant's award.

### Cheats

- **Never Miss**: prevents the player's attacks from missing.
- **Always Crit**: makes the player's attacks always land as critical hits.
- **Infinite PP**: prevents the player's moves from consuming PP.
- **Always Catch**: makes Poke Balls successfully catch wild Pokemon.
- **EXP Multiplier - Off / 2X / 3X / 4X**: multiplies each Pokemon's final experience award once. It also works with both EXP Share modes.
- **Move Editor - Off**: disables the Move Editor.
- **Move Editor - Base**: allows moves from the Pokemon's Gen 1 level-up learnset and compatible TMs. HMs are excluded.
- **Move Editor - All**: allows any move loaded by the game.
- **Force Encounter**: enables a configurable keyboard/controller hotkey that immediately starts a wild encounter during free overworld control. The keyboard defaults to F6 and the controller defaults to Off.
- **Wild Select - Off**: uses the current area's normal Pokemon and level.
- **Wild Select - On**: replaces the species with the chosen Pokemon while preserving the level rolled from the current area.
- **Wild Select - First**: replaces the species with the chosen Pokemon and uses the level of the first Pokemon in the player's party.

The Pokemon list is specific to the running generation. Scripted and special Gold encounters are not replaced.

The Move Editor shows each selected move's type, PP, power, and accuracy. Left and Right change pages; holding either direction continues changing pages until released. Up and Down move through the list.

### Pokemon Options

- **Forget HM**: allows HM moves to be forgotten.
- **Reusable TMs**: prevents TMs from being consumed after use.
- **Quick HM - Off**: disables Quick HM.
- **Quick HM - On**: adds Quick HM to the START menu and allows field moves without teaching them to a Pokemon, while still requiring the correct HM and badge.
- **Quick HM - Ignore**: enables all five field HMs without requiring the HM item or badge.
- **HM Hotkey**: appears when Quick HM is enabled. In free overworld control it immediately uses Cut when facing a cuttable tree, Surf when facing water or a valid dismount, and Strength when facing a pushable boulder. If there is no contextual action, it opens the Quick HM menu normally. Keyboard and controller shortcuts are configured independently, so either or both can remain active. The keyboard defaults to Shift and the controller defaults to Off.
- **Pikachu Evo**: allows Pikachu to evolve with a Thunder Stone in Pokemon Yellow.

### Miscellaneous

- **Fast Run - Off**: uses normal movement speed.
- **Fast Run - On**: enables faster running while preserving normal movement during cutscenes.
- **Fast Run - On + Surf**: also applies faster movement while surfing.
- **Auto Run**: keeps Fast Run active without holding the run button. This option appears only when Fast Run is enabled.
- **Instant Text**: displays dialogue instantly while preserving normal pages, choices, and script behavior.
- **Itemfinder - Off**: disables the Itemfinder enhancement.
- **Itemfinder - On**: detects hidden items within the native Itemfinder range without requiring the item and marks their locations with an animated shrinking square.
- **Itemfinder - Have Item**: enables the same detection effect only when the player owns the Itemfinder.
- **Type Fixes**: makes Ghost attacks super effective against Psychic; changes Karate Chop from Normal to Fighting, Sand Attack from Normal to Ground, and Gust from Normal to Flying; changes Lick into a 40-power Special Ghost move; raises Low Kick from 50 to 60 power; and raises Submission from 80 to 90 accuracy.
- **Fast Center**: skips the standard Pokemon Center conversation, heals the party immediately, and plays the normal healing-machine jingle.
- **Fast Save**: saves immediately without confirmation text boxes and plays only the save confirmation sound.

### Bag Improvements

- Increases the Bag capacity to **999 different item slots**. The native per-item quantity limit remains unchanged.
- Separates the Bag into Gen 2-style **Items**, **Key**, **Ball**, and **TM/HM** tabs.
- Shows each TM/HM's move name beside its machine number. Long names use readable abbreviations such as `THNDRBOLT`, then shorten at the final fitting letter if still necessary, without dots or overlap with the quantity.
- Switches tabs with Left and Right.
- Opens the Auto Sort menu with START.
- **Sort - Off**: preserves acquisition order and allows manual reordering with SELECT.
- **Sort - Name**: sorts items alphabetically.
- **Sort - Quantity**: sorts items by quantity in descending order.
- **Sort - Type**: uses a fixed functional order, grouping healing items, status recovery, battle items, exploration items, key items, Balls, HMs, and TMs.
- Shows the active tab with a black background and white text.
- Marks the active Auto Sort mode with a hollow selection arrow.

### Reset Options

- Each category includes **Reset Defaults**.
- The main menu includes **Reset Default All**.
- Every reset action opens a confirmation box with **No** selected by default.

## Notes

myQualityOfLife affects gameplay mechanics and link compatibility. Feature availability can depend on the installed Gen1Recomp build and its internal APIs.
