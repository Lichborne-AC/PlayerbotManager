# Playerbot Manager

**A World of Warcraft WotLK 3.3.5a Addon for AzerothCore Private Servers that tracks gear score, iLvL, gear slots, specs, strategies, and raid composition for your entire playerbot roster.**

**Version 1.1**


## Installation

### Option 1 — Git Clone (recommended, stays updated)

Note: No other mods/addons are required to use Playerbot Manager

Navigate to your AddOns folder and run:

```
git clone https://github.com/Lichborne-AC/PlayerBotManager
```

To update later just run `git pull` inside the PlayerBotManager folder.

### Option 2 — Manual Install

1. Download the latest zip from the Releases page
2. Extract and drag the PlayerBotManager folder into:

   World of Warcraft/Interface/AddOns/

3. Launch WoW and type `/pmb` or click the minimap button

   **Requirements:** WoW 3.3.5a (WotLK) | AzerothCore | Playerbot module

---

## Features

### Class Tabs
![Class Tracker](Screenshots/ClassTab.png)
Each of the 10 playable classes has its own tab with unlimited roster slots. Each character row tracks:

* Spec — auto-detected from talent inspection or from manual scans
* iLvL — average equipped item level calculated via inspect
* Gear Score — actual WotLK-style GearScore calculated from inspected gear, colored by item quality
* 17 gear slots — Head, Neck, Shoulders, Back, Chest, Wrists, Hands, Waist, Legs, Feet, Ring 1, Ring 2, Trinket 1, Trinket 2, Main Hand, Off Hand, Ranged
* Hover any gear slot to see the full item tooltip

### Character Sheet
![Character Sheet](Screenshots/CharacterSheet.png)
Click any bot name to open its character sheet.

* **Spec tree** — three talent-tree icons at the top, one per spec. Active specs are lit up; inactive ones are grayed out. Click to switch.
* **Strategy list** — all active combat (CO) and non-combat (NC) strategies are displayed and color-coded by tier. Click any strategy icon to toggle it on or off.
* **Quick access** — Talents, Inventory, and Spellbook buttons for the bot without leaving the window.

### Strategy Colors

Strategy replies from bots are filtered out of regular chat and shown in the addon's own output frame, tagged with the bot's class color.

| Tier | Color | Examples |
|---|---|---|
| 1 | Class color | blood, frost, unholy, arms, fury, holy heal, shadow… |
| 2 | Yellow | heal, offheal, bmana, bdps, buff… |
| 3 | Orange | tank assist, dps assist, pull, cc… |
| 4 | Dark gold | loot, gather, food… |
| 5 | Per-strategy | boost, avoid aoe, stealth, potions, formation… |

### Bottom Controls

* **+ Add Target** — Adds target to tracker
* **+ Add Group** — Bulk-adds all group/raid members
* **+ Add Target/Group Gear** — Refreshes both iLvL and GS from inspect (does not affect spec)
* **+ Add Target/Group Spec** — Reads talent spec (does not affect GS); disabled during active scan
* **Full Group Scan** — Runs all three phases automatically: add members → scan gear → scan specialization
* **Stop** — Cancels a running scan at any point, including during the member-adding phase
* **Log in / Log Out All Bots** — `.playerbots bot add/remove \*`
* **Log Out Orphaned Bots** — Logs out any roster bots not currently in your active raid group
* **Disband Group / Raid** — Kicks all members then leaves. Requires confirmation

### Output Box

* Scrollable log at the bottom of the tracker window
* All status messages route here instead of chat
* Mouse-wheel scrollable, 500-line history
* Expand (∧) / collapse (∨) toggle for more visible lines
* **DBG button** — toggles detailed inspect debug logging (green = active)

### Summary Bars

* **Avg bar** — average tracked item level per class (values in gold)
* **GS bar** — average GearScore per class (values in gold)
* **Count bar** — total characters per class

### Help Buttons

Three help icons in the header bar (hover for tooltips):

* **Setup** — How to set up your tracker
* **Raid Tab** — How to use the Raid tab: picking a tier/raid, adding characters, inviting via INVITE RAID or INVITE GROUP
* **Overview Tab** — How to use the Overview tab: adding/removing from raid, inviting to group, filtering, and sorting
* **Class Tab** — How to use class tabs: filtering, spec icon assignment, gear slot inspection, count bar

## Raid Tab
![Raid Planner](Screenshots/RaidTab.png)
Up to 40 slots across two columns. Each slot shows class icon, spec icon, name, iLvL, GS, needs, role, and notes.

### Invite Raid / Invite Group

* **INVITE RAID** — Automatically logs out old bots, leaves party, converts to raid, and invites all roster members via `.playerbots bot add`. Always invites from the currently selected raid's table.
* **INVITE GROUP** — Invites the 5-Man team from the T0 5-Man Dungeons tab. Operates independently of whichever tab is active. **Invite Group** always reads from the T0 / N/A (5-Man) roster regardless of which tier is currently displayed.

Both buttons remove active bots first, leave the current party, then re-add each roster member in order. Missed bots are automatically re-invited. A **Stop** button cancels at any point.

## Overview Tab

Master view of all tracked characters across all classes — 3 columns of 20 rows (60 per page, 180 total).

* Groups A, B, C for organizing characters
* Sort by Spec, Name, iLvL, GS, or raid membership (+ header)
* Add to Raid (left-click +) and Remove from Raid (right-click +) per row
* Invite to Group (left-click >) and Kick from Group (right-click >) per row
* Delete characters directly
* Count bar shows totals across all pages

---

## Individual Progression Tab

Requires the **mod-individual-progression** server module ([github.com/ZhengPeiRu21/mod-individual-progression](https://github.com/ZhengPeiRu21/mod-individual-progression)).

Displays a full tier reference table showing each progression tier, its raids, level cap, final boss, and what it unlocks. Hover any tier row for a detailed tooltip.

### + Add IP Tiers button

A new **+ Add IP Tiers** button in the bottom bar reads the current IP tier of every tracked character and writes it into the tracker automatically. This lets you see at a glance where each bot sits in the progression system without having to check each character individually.

---

## LevelSync Tab

Built-in UI for the mod-levelsync server module. Communicates via `.levelsync` server commands. No separate addon needed.

## How To Use

### Tracking Gear

* **+ Add Target/Group Gear** — updates both iLvL and GS without touching spec
* Hover any gear slot to see the full item tooltip
* Gear slot colors reflect WoW item quality

### Building a Raid Roster

1. Switch to the Raid tab and select a tier and raid from the header dropdowns
2. Use + on any character row (Class or Overview tab) to add them to the active raid
3. Right-click + to remove a character from the raid roster
4. Click **Invite Raid** to log in all roster members

### Managing a 5-Man Group

1. Switch to the **T0 / N/A (5-Man)** tab on the Raid tab
2. Add up to 5 characters via the Class or Overview tabs
3. Click **Invite Group** to log them in

### Copying a Roster

1. Navigate to the source roster and click **Copy**
2. Switch to destination and click **Paste** then confirm

### Importing / Exporting Characters

Use the Import/Export button to generate a text string of your current roster. Copy it and import it on another account to transfer your tracked characters and gear data.

---

## Credits

Built for AzerothCore private servers.

Special thanks to: **Dohtt**, **Scarecr0w12** — TheCGN.net, **Dreathean**, **Revision**, **Crow**, **LatChee**, **InvaderCanuck**, and **ScoobyPwnsOnU** for feature suggestions, testing, and support.

Additional thanks to Wishmaster117 for Multibot, whose work laid the groundwork for several PBM systems, and to the Playerbots Discord community for their support.

**Questions & Support:** lichborne.wow@proton.me | Discord: jared2219

---

## Suggested Downloads

* **[mod-levelsync](https://github.com/Lichborne-AC/mod-levelsync)** — AzerothCore server module that powers the LevelSync tab. Not required, but the LevelSync tab will have no effect without it.

---

## Compatibility

WoW 3.3.5a (build 12340) | AzerothCore | Playerbot Module
