# Kaufen oder farmen?

**Status: Entwicklungsversion 0.2.0-alpha.3. Materialziele, Rezeptimport und Bestand über Chat-Befehle, noch ohne Fenster.**

„Kaufen oder farmen?“ soll dir helfen zu entscheiden, wie du fehlende Herstellungsmaterialien
beschaffst, ob sich ein geplanter Craft lohnt und wie sich Ausgaben auf deine Sparziele auswirken.
Die Empfehlungen sollen auf deinen eigenen Messungen beruhen: deinem Farmtempo, deinen Einnahmen
und deinen Vorhaben.

Diese Version enthält das Grundgerüst (gespeicherte Einstellungen, Debug-Protokoll, Chat-Befehle)
und den ersten Teil der Materialbeschaffung: Materialziele mit Zutaten und Anzahl Herstellungen
(von Hand oder aus einem Rezept im Berufsfenster),
dazu Bedarf, Bestand in Taschen und Bank – auch deiner anderen Charaktere auf dem Realm – und Fehlmenge. Bedient wird das vorläufig über
Chat-Befehle, bis das Fenster fertig ist. Craft-Bewertung und Goldpuffer folgen später.

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
| `/bof goal` | listet deine Materialziele (vorläufig) |
| `/bof goal new <Name>` | legt ein Ziel an und wählt es aus |
| `/bof goal select <Nr.>` | wählt ein Ziel aus |
| `/bof goal add <Gegenstand> [Menge]` | fügt eine Zutat pro Herstellung hinzu (Menge wird addiert, ohne Angabe 1) |
| `/bof goal set <Gegenstand> <Menge>` | setzt die Menge pro Herstellung (0 entfernt die Zutat) |
| `/bof goal remove <Gegenstand>` | entfernt eine Zutat |
| `/bof goal crafts <Anzahl>` | wie oft du herstellen willst |
| `/bof goal delete <Nr.>` | löscht ein Ziel; bestätigen mit `/bof goal delete <Nr.> confirm` |
| `/bof recipe [Anzahl]` | legt aus dem Rezept, das im offenen Berufsfenster ausgewählt ist, ein neues Ziel an (ohne Anzahl: 1× herstellen) |
| `/bof stock` | Bedarf, Bestand (Taschen, Bank) und Fehlmenge des ausgewählten Ziels |
| `/bof stock all` | dasselbe für alle Ziele zusammen |
| `/bof stock others` | schaltet das Mitzählen deiner anderen Charaktere ein oder aus (Standard: an) |

`<Gegenstand>` ist ein Gegenstandslink (Umschalt+Klick auf den Gegenstand, während die Chatzeile
offen ist) oder die Item-ID.

## Bedienung

Noch kein Fenster. Bedienung derzeit über die Befehle oben.

Aus einem Rezept: Berufsfenster öffnen (z. B. Schneiderei oder Verzauberkunst), das Rezept
anklicken und `/bof recipe 5` eingeben. Das Ziel enthält dann die Zutaten für 5 Herstellungen
und heißt wie das Rezept.

Von Hand, Beispiel:

```
/bof goal new Leinenhemd
/bof goal add [Leinenstoff] 4
/bof goal crafts 3
/bof stock
```

Ziele gehören zum jeweiligen Charakter. Damit die anderen Charaktere mitgezählt werden, merkt sich
das Addon bei jedem Charakter, wie viel er von den Zielmaterialien in Taschen und Bank hat
(bei Taschenänderungen, Bankbesuch und bei `/bof stock`). Mitgezählt werden Charaktere auf demselben Realm
und derselben Fraktion; Charaktere der anderen Fraktion werden nur angezeigt. Neue Zutaten kennt ein
anderer Charakter erst, wenn du ihn wieder einloggst und dort `/bof stock` eingibst oder etwas in
den Taschen änderst.

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

- Noch kein Fenster; Materialziele nur über Chat-Befehle.
- Bestand anderer Charaktere ist ein gespeicherter Stand vom letzten Login dieses Charakters.
- Rezeptimport nur für das ausgewählte Rezept im offenen Berufsfenster, nur feste Zutaten.
- Noch nicht enthalten: Preise, Farmmessung,
  Kauf-/Farmvergleich, Craft-Bewertung, Goldpuffer.
- Nur deutsche Texte. Clients in anderen Sprachen zeigen ebenfalls Deutsch.
- Nur Classic Era. Auf anderen Clients wird das Addon nicht geladen bzw. meldet, dass es nicht passt.

## Durchgeführte Tests

**Außerhalb des Spiels** (Version 0.2.0-alpha.3):

- Struktur der Addon-Dateien und der TOC-Datei
- Lua-Syntax (Lua 5.1) und luacheck
- Prüfung der Übersetzungsschlüssel
- 83 automatische Tests in einer nachgebauten Spielumgebung: erster Start, `/reload`,
  beschädigte und neuere gespeicherte Daten, Debug-Protokoll, Fehlerweitergabe, alle Befehle,
  Materialziele, Bedarf und Fehlmenge, Bankstand, Gegenstandslinks, Bestand anderer Charaktere
  (Realm, Fraktion, später hinzugefügte Zutaten), Rezeptimport aus Berufs- und Verzauberungsfenster

**Im Spiel** (Version 0.1.0, Classic Era 1.15.9, deutscher Client, 18.10.2026):

- erster Start, `/reload`, alle Befehle, Debug-Modus, Zurücksetzen, Kampf: ohne Fehler
- nicht getestet: andere Spielsprachen, Zusammenspiel mit anderen Addons

Version 0.2.0-alpha.1 (18.10.2026): Ziel anlegen, Gegenstand per Link hinzufügen, Bestand in
Taschen und Bank (auch bei geschlossener Bank nach `/reload` und neuem Login): korrekt, ohne Fehler.
Löschen von Zielen: ohne Fehler.

Version 0.2.0-alpha.2 (18.10.2026): Bestand eines anderen Charakters auf demselben Realm und
derselben Fraktion wird mitgezählt und angezeigt, `/bof stock others` schaltet das Mitzählen
ein und aus: korrekt, ohne Fehler. Nicht getestet: Charaktere der anderen Fraktion und auf
anderen Realms (nur außerhalb des Spiels geprüft).

Version 0.2.0-alpha.3 (Rezeptimport) ist im Spiel noch nicht getestet.

**Nicht in Forever getestet.**

## Version

0.2.0-alpha.3 – siehe [CHANGELOG.md](CHANGELOG.md).

## Lizenz

MIT, siehe [LICENSE](LICENSE).
