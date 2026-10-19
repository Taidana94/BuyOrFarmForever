# Data sources

The addon ships no game data (no item, quest, NPC, spell or map IDs).

## Addon design data (not game data)

| Data | File | Source | Date | Client |
|---|---|---|---|---|
| Stat weight templates (caster, healer, agility, strength, tank) and the template per talent tree of each class | `Core/WeightTemplates.lua` | own choice as a starting point for players; not taken from any guide or game file; the player can change every weight | 2026-10-19 | class file names and three talent trees per class: Classic Era (Blizzard UI 70003) |
| Texture paths of the minimap button (`Interface\Icons\INV_Misc_Coin_01`, `Interface\Minimap\MiniMap-TrackingBorder`) | `UI/MinimapButton.lua` | common client paths; **unverified in game** for 1.15.9 | 2026-10-19 | Classic Era |

## API references used for development

| Source | Client | Version / date | Use |
|---|---|---|---|
| Gethe/wow-ui-source, branch `classic_era`, commit `8165d4cd6e48` | Classic Era | 1.15.9 (70003), 2026-09-29 | Blizzard UI code and `Blizzard_APIDocumentationGenerated`: API existence, signatures, events |
| Gethe/wow-ui-source, branch `forever`, commit `172a387e3ab8` | Forever (beta) | 1.60.1 (70450), 2026-10-16 | planning only; beta data is not final |
| warcraft.wiki.gg API pages and Forever API notes | both | fetched 2026-10-18 | flavor tables, TOC rules, Blizzard quotes |
| Auctionator `Source/API/v1` (copy in Industrial/nixos-dotfiles, TOC Interface incl. 11509, version 335) | Classic Era | commit 2026-09-12, read 2026-10-19 | external price API; see `work/notes/price-addons.md` |
| In game: `/dump GetBuildInfo()` | Classic Era | 1.15.9 (70003), 2026-10-18 | client version and interface |

Details and checksums: `work/research/README.md` and `work/notes/forever-facts.md` in the development folder.
