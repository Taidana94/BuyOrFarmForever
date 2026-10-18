# Kaufen oder farmen?

**Status: frühe Entwicklungsversion 0.1.0, noch ohne Spielfunktionen.**

„Kaufen oder farmen?“ soll dir helfen zu entscheiden, wie du fehlende Herstellungsmaterialien
beschaffst, ob sich ein geplanter Craft lohnt und wie sich Ausgaben auf deine Sparziele auswirken.
Die Empfehlungen sollen auf deinen eigenen Messungen beruhen: deinem Farmtempo, deinen Einnahmen
und deinen Vorhaben.

Diese Version enthält erst das Grundgerüst: gespeicherte Einstellungen, Debug-Protokoll und
Chat-Befehle. Materialbeschaffung, Craft-Bewertung und Goldpuffer folgen in den nächsten Versionen.

## Unterstützte Spielversion

| Client | Version | Status |
|---|---|---|
| WoW Classic Era | 1.15.9 (Build 70003, Interface 11509) | in Entwicklung, Grundgerüst im Spiel getestet (deutscher Client) |
| WoW Forever | – | geplant, **nicht in Forever getestet** |

## Installation

1. ZIP entpacken.
2. Den Ordner `BuyOrFarmForever` nach
   `World of Warcraft\_classic_era_\Interface\AddOns\` kopieren.
3. Spiel starten bzw. `/reload` eingeben und das Addon in der Addon-Liste aktivieren.

## Befehle

Statt `/bof` funktioniert auch `/kof`.

| Befehl | Wirkung |
|---|---|
| `/bof` oder `/bof help` | zeigt die Befehlsliste |
| `/bof version` | zeigt Addon-Version, Interface-Version und Build des Spiels |
| `/bof debug` | schaltet den Debug-Modus ein oder aus |
| `/bof reset` | setzt die Einstellungen zurück; bestätigen mit `/bof reset confirm` innerhalb von 30 Sekunden. Ziele, Preise und Messungen bleiben erhalten. |

## Bedienung

Noch kein Fenster. Bedienung derzeit nur über die Befehle oben.

Im Debug-Modus erscheinen technische Meldungen (englisch) im Chat. Zusätzlich speichert das Addon
ein kurzes Protokoll (höchstens 200 Einträge) in seinen gespeicherten Daten. Fehler werden immer
protokolliert und an BugSack bzw. die Fehleranzeige des Spiels weitergegeben.

## Abhängigkeiten

Keine. Für Tests wird BugSack mit BugGrabber empfohlen.

## Gespeicherte Daten

`WTF\Account\<Account>\SavedVariables\BuyOrFarmForever.lua` (eine Datei für alle Charaktere).
Die Daten enthalten eine Schema-Version. Stammen sie aus einer neueren Addon-Version, verändert
das Addon sie nicht.

## Bekannte Einschränkungen

- Noch keine Spielfunktionen (Materialbeschaffung, Farmmessung, Craft-Bewertung, Goldpuffer).
- Nur deutsche Texte. Clients in anderen Sprachen zeigen ebenfalls Deutsch.
- Nur Classic Era. Auf anderen Clients wird das Addon nicht geladen bzw. meldet, dass es nicht passt.

## Durchgeführte Tests

**Außerhalb des Spiels** (Version 0.1.0):

- Struktur der Addon-Dateien und der TOC-Datei
- Lua-Syntax (Lua 5.1) und luacheck
- Prüfung der Übersetzungsschlüssel
- 43 automatische Tests in einer nachgebauten Spielumgebung: erster Start, `/reload`,
  beschädigte und neuere gespeicherte Daten, Debug-Protokoll, Fehlerweitergabe, alle Befehle

**Im Spiel** (Version 0.1.0, Classic Era 1.15.9, deutscher Client, 18.10.2026):

- erster Start, `/reload`, alle Befehle, Debug-Modus, Zurücksetzen, Kampf: ohne Fehler
- nicht getestet: andere Spielsprachen, Zusammenspiel mit anderen Addons

**Nicht in Forever getestet.**

## Version

0.1.0 – siehe [CHANGELOG.md](CHANGELOG.md).

## Lizenz

MIT, siehe [LICENSE](LICENSE).
