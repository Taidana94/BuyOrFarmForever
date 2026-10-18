# Features

Source: feature description (German) in `sources/BuyOrFarmForever-description-de.md` of the development
folder. Priority: material sourcing → craft evaluation → gold buffer.

| Area | Status |
|---|---|
| Foundation: SavedVariables, debug log, slash commands (`help`, `version`, `debug`, `reset`) | 0.1.0, tested out of game only |
| Material sourcing (goals, recipe import, stock incl. bank and other characters, shortfall, prices, farm runs, sourcing comparison) | planned (stage 2) |
| Craft evaluation (all professions, stat weights, tooltip-based stats if `GetItemStats` is missing) | planned (stage 3) |
| Gold buffer (savings goals, priorities, reserve check) | planned (stage 4) |
| Main window with tabs Material, Farm, Craft, Goldpuffer, Hilfe | planned |
| Forever support (second adapter and TOC) | phase B, after Forever launch |
| English localization | phase 2 |

Decisions (2026-10-18): all professions; farm estimates per character by default with an account-wide
option; stock = bags + bank of the current and other characters on the same realm (same faction counted);
no mailbox; no fallback TOC; no "Forever" in the Classic Era title.
