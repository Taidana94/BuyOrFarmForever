# Data sources

The addon ships no game data yet (no item, quest, NPC, spell or map IDs).

## API references used for development

| Source | Client | Version / date | Use |
|---|---|---|---|
| Gethe/wow-ui-source, branch `classic_era`, commit `8165d4cd6e48` | Classic Era | 1.15.9 (70003), 2026-09-29 | Blizzard UI code and `Blizzard_APIDocumentationGenerated`: API existence, signatures, events |
| Gethe/wow-ui-source, branch `forever`, commit `172a387e3ab8` | Forever (beta) | 1.60.1 (70450), 2026-10-16 | planning only; beta data is not final |
| warcraft.wiki.gg API pages and Forever API notes | both | fetched 2026-10-18 | flavor tables, TOC rules, Blizzard quotes |
| In game: `/dump GetBuildInfo()` | Classic Era | 1.15.9 (70003), 2026-10-18 | client version and interface |

Details and checksums: `work/research/README.md` and `work/notes/forever-facts.md` in the development folder.
