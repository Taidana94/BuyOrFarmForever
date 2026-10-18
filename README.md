# Kaufen oder farmen?

**Entwicklungsversion 0.3.0-alpha.1 – Materialbeschaffung (getestet in WoW Classic Era) und neu:
Craft-Bewertung, Goldpuffer, Tab „Farmen“ (noch nicht im Spiel getestet). Nicht in Forever getestet.**

„Kaufen oder farmen?“ hilft dir zu entscheiden, wie du fehlende Herstellungsmaterialien beschaffst:
kaufen, selbst farmen oder beides. Die Empfehlungen beruhen auf deinen eigenen Daten – deinem
Bestand, den Preisen, die du siehst, und deinem gemessenen Farmtempo.

Diese Version enthält die **Materialbeschaffung**:

- **Materialziele:** Zutaten und Anzahl Herstellungen, von Hand oder aus einem Rezept im
  Berufsfenster (auch Verzauberkunst).
- **Bestand:** Taschen und Bank, auch deiner anderen Charaktere auf dem Realm.
- **Preise:** eigene Eingabe, Händler und Auktionshaus (mit AH-Scan), getrennt nach Realm und
  Fraktion, veraltete Preise markiert.
- **Farmrunden:** Farmzeit, Anreise und Ertrag messen; daraus schätzt das Addon, wie lange du für
  die fehlenden Materialien brauchst.
- **Vergleich Kaufen/Farmen:** wie viel du kaufen und wie viel du farmen solltest, mit Kosten,
  Farmzeit und Budget – nach der Strategie „Zeit sparen“, „Gold sparen“ oder „Selbst farmen“.

Neu in 0.3.0-alpha.1: **Lohnt sich der Craft?** – der hergestellte Gegenstand eines Rezept-Ziels wird
mit deiner angelegten Ausrüstung verglichen (nach deinen Gewichten für Stärke, Beweglichkeit,
Ausdauer, Intelligenz und Willenskraft), dazu Beschaffungskosten und Farmzeit pro
Verbesserungspunkt, der Wert schon vorhandener Zutaten und eingeplante oder mögliche Alternativen.

Ebenfalls neu: der **Goldpuffer** – Sparziele (Reiten, Training, Berufsausbau, ein weiterer Craft)
mit Priorität, einmaliges Verteilen deines Golds, Übersicht über Rücklagen, freies Gold und
ungedeckte Ziele, Hinweis, ob ein Einkauf deine Rücklagen angreift, dein Nettoerlös pro Stunde und
daraus der **Zeitgegenwert** eines Einkaufs („2g entsprechen etwa 30 Min. Spielzeit“).

## Unterstützte Spielversion

| Client | Version | Status |
|---|---|---|
| WoW Classic Era | 1.15.9 (Build 70003, Interface 11509) | im Spiel getestet (deutscher Client) |
| WoW Forever | – | geplant, **nicht in Forever getestet** |

## Installation

1. ZIP entpacken.
2. Den Ordner `BuyOrFarmForever` nach `World of Warcraft\_classic_era_\Interface\AddOns\` kopieren.
3. Spiel starten bzw. `/reload` eingeben und das Addon in der Addon-Liste aktivieren.

## Schnellstart

1. `/bof show` öffnet das Fenster.
2. Ziel anlegen: Berufsfenster öffnen, Rezept anklicken, im Fenster „Rezept übernehmen“ – oder
   `/bof recipe 5` für 5 Herstellungen.
3. Tab „Material“: Bedarf, Bestand, Fehlmenge und Preise. Am Händler und im Auktionshaus sammelt
   das Addon Preise automatisch; „AH-Scan“ sucht fehlende Materialien.
4. Farmen messen: `/bof farm start` (für Gegner: `/bof farm start mobs`), farmen, `/bof farm stop`,
   `/bof farm save`.
5. Tab „Beschaffung“: was du kaufen und was du farmen solltest.

## Befehle

Statt `/bof` funktioniert auch `/kof`. `<Gegenstand>` ist ein Gegenstandslink (Umschalt+Klick auf
den Gegenstand, während die Chatzeile offen ist) oder die Item-ID. Gib Befehle einzeln ein; mehrere
eingefügte Zeilen setzt das Spiel zu einer Zeile zusammen.

**Allgemein**

| Befehl | Wirkung |
|---|---|
| `/bof` oder `/bof help` | Befehlsliste |
| `/bof show` | öffnet oder schließt das Fenster |
| `/bof version` | Addon-Version, Interface-Version und Build des Spiels |
| `/bof debug` | Debug-Modus ein/aus |
| `/bof perf` | Speicher, Anteil an der Frame-Zeit und Rechenzeit des Addons |
| `/bof reset` | setzt die Einstellungen zurück (bestätigen mit `/bof reset confirm` innerhalb von 30 Sekunden); Ziele, Preise und Messungen bleiben |

**Ziele und Bestand**

| Befehl | Wirkung |
|---|---|
| `/bof goal` | listet deine Ziele |
| `/bof goal new <Name>` | legt ein Ziel an und wählt es aus |
| `/bof goal select <Nr.>` | wählt ein Ziel aus |
| `/bof goal add <Gegenstand> [Menge]` | Zutat pro Herstellung hinzufügen (Menge wird addiert, ohne Angabe 1) |
| `/bof goal set <Gegenstand> <Menge>` | Menge pro Herstellung setzen (0 entfernt die Zutat) |
| `/bof goal remove <Gegenstand>` | Zutat entfernen |
| `/bof goal crafts <Anzahl>` | wie oft du herstellen willst |
| `/bof goal delete <Nr.>` | Ziel löschen (bestätigen mit `/bof goal delete <Nr.> confirm`) |
| `/bof recipe [Anzahl]` | neues Ziel aus dem im Berufsfenster ausgewählten Rezept (ohne Anzahl: 1×) |
| `/bof stock` / `/bof stock all` | Bedarf, Bestand und Fehlmenge des ausgewählten bzw. aller Ziele |
| `/bof stock others` | Mitzählen deiner anderen Charaktere ein/aus (Standard: an) |

**Preise**

| Befehl | Wirkung |
|---|---|
| `/bof price` | Preise der Zutaten des ausgewählten Ziels |
| `/bof price <Gegenstand> <Preis>` | eigener Preis pro Stück, z. B. `1g 20s 5k`, `35s`, `80k` |
| `/bof price <Gegenstand> clear` | eigenen Preis löschen |
| `/bof price scan` | im offenen Auktionshaus das nächste fehlende Material suchen |

**Farmrunden**

| Befehl | Wirkung |
|---|---|
| `/bof farm` | Stand der Runde |
| `/bof farm start [gather\|mobs\|other] [Gegenstand]` | Runde starten (Sammeln, Gegner, Sonstiges; optional mit Zielmaterial) |
| `/bof farm travel` | zwischen Anreise und Farmen umschalten (der Chat sagt, was gerade zählt) |
| `/bof farm pause` / `resume` | pausieren / fortsetzen (Pausen zählen nicht) |
| `/bof farm stop` | Runde beenden, danach prüfen |
| `/bof farm keep <Gegenstand>` / `keep all` | unklare Zugänge eines bzw. aller Gegenstände doch mitzählen |
| `/bof farm save` / `discard` | beendete Runde speichern / verwerfen |
| `/bof farm list` | deine letzten 5 Runden |
| `/bof farm estimate` | geschätzte Farmzeit für die fehlenden Materialien |
| `/bof farm scope` | Schätzung nur aus diesem Charakter oder aus allen |

**Craft-Bewertung**

| Befehl | Wirkung |
|---|---|
| `/bof craft` | Bewertung des ausgewählten Ziels (Rezept mit Gegenstand) |
| `/bof craft <Gegenstand>` | einen beliebigen Gegenstand mit deiner Ausrüstung vergleichen |
| `/bof weights` | deine Gewichte anzeigen |
| `/bof weights str\|agi\|sta\|int\|spi <Zahl>` | Gewicht setzen (0 bis 10, z. B. `/bof weights int 2`) |
| `/bof alt` | deine Alternativen |
| `/bof alt add <Gegenstand> planned\|drop [Notiz]` | Alternative: eingeplant (z. B. Questbelohnung) oder möglicher Drop |
| `/bof alt remove <Nr.>` | Alternative entfernen |

**Goldpuffer**

| Befehl | Wirkung |
|---|---|
| `/bof gold` | Übersicht: Gold, Rücklagen, frei, ungedeckt, Sparziele, Nettoerlös |
| `/bof gold add <Betrag> <Name>` | Sparziel anlegen, z. B. `/bof gold add 90g Reiten` |
| `/bof gold set <Nr.> <Betrag>` | Betrag ändern |
| `/bof gold up <Nr.>` | Priorität erhöhen (eine Stelle nach oben) |
| `/bof gold done <Nr.>` / `delete <Nr.>` | Sparziel erreicht (Rücklage wird frei) / löschen |
| `/bof gold distribute` | dein aktuelles Gold einmalig nach Priorität auf die Sparziele verteilen |
| `/bof gold reserves` | ob die Beschaffung Rücklagen verwenden darf (Standard: ja) |
| `/bof gold check <Betrag>` | greift ein Einkauf dieser Höhe deine Rücklagen an? Zeitgegenwert |

**Beschaffung**

| Befehl | Wirkung |
|---|---|
| `/bof plan [all]` | was du kaufen und was du farmen solltest (ausgewähltes bzw. alle Ziele) |
| `/bof strategy time\|gold\|farm` | Strategie: Zeit sparen, Gold sparen, selbst farmen |
| `/bof budget [Betrag\|clear]` | eigenes Budget für Käufe; ohne Budget zählt dein aktuelles Gold |

## Bedienung

**Fenster, Tab „Material“:** das ausgewählte Ziel mit Bedarf, Bestand in Taschen und Bank, Bestand
deiner anderen Charaktere („Twinks“), Fehlmenge (rot/grün) und Preis pro Stück (grau = veraltet).
`<` und `>` wechseln das Ziel, „Alle Ziele zusammen“ zeigt alles. Der Tooltip einer Zeile zeigt, welcher
Twink wie viel hat und alle Preisquellen. „Rezept übernehmen“ legt ein Ziel aus dem zuletzt
angeklickten Rezept an; „AH-Scan“ (nur am Auktionshaus) sucht pro Klick ein fehlendes Material.

**Fenster, Tab „Beschaffung“:** pro fehlendem Material, wie viel du kaufen und wie viel du farmen
solltest, mit Kosten und Farmzeit (inklusive Anreise), darunter die Summe und das Restbudget.
Strategien:

- **Zeit sparen:** kaufen, was einen Preis hat. Reicht das Budget nicht, wird zuerst gekauft, was
  pro Gold am meisten Farmzeit spart (auch Teilkäufe); der Rest wird gefarmt.
- **Gold sparen:** farmen, was du schon einmal gefarmt hast; kaufen nur, was du nicht farmen kannst.
- **Selbst farmen:** nichts kaufen.

Was weder einen Preis im Budget noch eine Farmmessung hat, steht als „offen“ (rot). Der Tooltip
zeigt Farmzeit und Anreise getrennt.

**Farmrunden:** Während einer Runde vergleicht das Addon nach jeder Taschenänderung den Inhalt
deiner Taschen. Was bei offenem Beutefenster dazukommt, zählt als **geplündert**; alles andere
(Post, Handel, Bank, Kauf) als **unklar** – das prüfst du nach `/bof farm stop` und zählst es mit
`keep` mit oder lässt es weg. Nach `/reload` läuft eine Runde weiter; nach Ausloggen ist sie
pausiert, die Zeit offline zählt nicht.

**Fenster, Tab „Farmen“:** Knöpfe für die Farmrunde (Start mit Sammeln, Gegner oder Sonstiges,
Pause/Fortsetzen, Anreise/Angekommen, Beenden; nach dem Beenden „Unklare mitzählen“, Speichern,
Verwerfen), der Stand der Runde mit laufender Zeit und den Gegenständen und die geschätzte Farmzeit
für die fehlenden Materialien des ausgewählten Ziels. Die Knöpfe tun dasselbe wie die Chat-Befehle.

**Fenster, Tab „Craft“:** die Craft-Bewertung des ausgewählten Ziels: Wertung des hergestellten
Gegenstands gegen das, was du an diesem Platz trägst (bei Ringen und Schmuck gegen den schwächeren,
Zweihandwaffen gegen Haupt- und Nebenhand zusammen), Beschaffungskosten und Farmzeit, Kosten pro
Wertungspunkt, Wert vorhandener Zutaten (beim Händler und nach deinen Preisen) und deine
Alternativen. Die Wertung ist die Summe der fünf Grundwerte mal deinem Gewicht. Aktualisiert sich,
wenn du Ausrüstung wechselst.

**Fenster, Tab „Goldpuffer“:** Übersicht (Gold, Rücklagen, frei, ungedeckt), deine Sparziele mit
zurückgelegtem Betrag, dein Nettoerlös und Knöpfe für „Gold verteilen“ und „Rücklagen an/aus“.
Sparziele legst du per Chat an. Der Tab „Beschaffung“ zeigt unter dem Plan, ob die Käufe deine
Rücklagen angreifen, und den Zeitgegenwert der Kosten.

**Nettoerlös:** Jede Änderung deines Golds, während du online bist, zählt – Beute, Quests,
Verkäufe ebenso wie Einkäufe, Reparaturen, Post und Handel. Dazu zählt die Spielzeit (Pausen ohne
Aktivität höchstens 30 Minuten am Stück). Aus den letzten 14 Tagen ergibt sich der Nettoerlös pro
Stunde; ab einer Stunde Spielzeit gibt es den Zeitgegenwert.

Das Fenster lässt sich verschieben, merkt sich Position und Tab und schließt mit Escape.

## Abhängigkeiten

Keine. Für Tests wird BugSack mit BugGrabber empfohlen.

## Gespeicherte Daten

`WTF\Account\<Account>\SavedVariables\BuyOrFarmForever.lua` (eine Datei für alle Charaktere).
WoW schreibt sie beim Ausloggen, Beenden und bei `/reload`. Die Daten enthalten eine
Schema-Version; stammen sie aus einer neueren Addon-Version, verändert das Addon sie nicht und
weist darauf hin.

## Bekannte Einschränkungen

- Ziele werden im Fenster angezeigt, angelegt und bearbeitet aber über Chat-Befehle (außer
  „Rezept übernehmen“). Ein Zielmaterial für eine Farmrunde geht nur per Chat (`/bof farm start …`).
- Der Bestand anderer Charaktere ist der Stand von deren letzter Taschenänderung, ihrem letzten
  Bankbesuch oder `/bof stock`. Neue Zutaten kennen sie erst nach ihrem nächsten Login.
- Rezeptimport nur für das ausgewählte Rezept, nur feste Zutaten.
- Automatisch erfasst werden nur Preise von Materialien aus deinen Zielen. AH- und eigene Preise
  gelten nach 7 Tagen als veraltet, Händlerpreise nicht. Pro AH-Suche wird nur die erste Seite
  gelesen; bei sehr vielen Angeboten kann der günstigste Preis fehlen.
- Farmrunden zählen nur die Taschen, nicht die Bank.
- Stürzt das Spiel ab, fehlt alles seit dem letzten Speichern, auch eine in dieser Sitzung
  gestartete Farmrunde.
- Der Nettoerlös unterscheidet nicht, woher Gold kommt; Gold, das du per Post zwischen deinen
  Charakteren schickst, zählt beim einen als Einnahme, beim anderen als Ausgabe. Sparziele und
  Nettoerlös gelten pro Charakter.
- Die Craft-Bewertung rechnet nur mit Stärke, Beweglichkeit, Ausdauer, Intelligenz und
  Willenskraft. Rüstung, Waffenschaden, Effekte und Setboni werden nicht bewertet. Einhandwaffen
  werden nur mit der Haupthand verglichen. Gewichte und Alternativen gibt es nur per Chat-Befehl.
- Nur deutsche Texte; Clients in anderen Sprachen zeigen ebenfalls Deutsch.
- Nur Classic Era. Auf anderen Clients startet das Addon nicht und meldet das.

## Durchgeführte Tests

**Außerhalb des Spiels** (Version 0.3.0-alpha.1): Struktur und TOC, Lua-Syntax (Lua 5.1), luacheck ohne
Warnungen, Übersetzungsschlüssel, Sauberkeit und Leistung (Funktionslänge, keine Skripte pro Bild,
kein Speicherzuwachs bei Taschenänderungen) und 152 automatische Tests in einer nachgebauten
Spielumgebung (Start, `/reload`, beschädigte und neuere Daten, alle Befehle, Ziele, Bestand,
Rezeptimport, Fenster, Preise, Farmrunden, Beschaffungsplan, Craft-Bewertung, Farm-Tab, Goldpuffer).

**Im Spiel** (Classic Era 1.15.9, deutscher Client, 18.10.2026, Charaktere auf zwei Realms und
beiden Fraktionen): alle Teile während der Entwicklung (Zwischenversionen 0.1.0 bis 0.2.0-alpha.10)
getestet, ohne Lua-Fehler: Grundgerüst und Befehle, Kampf, Ziele, Bestand mit Bank und Twinks,
Rezeptimport (Schmiedekunst, Schneiderei, Verzauberkunst, zwei offene Fenster), Fenster, Preise
(eigene, Händler, Auktionshaus, AH-Scan), Farmrunden (Plündern, Anreise, Speichern, `/reload`),
Beschaffungsplan mit Strategien und Budget, `/bof perf` (259 KB Speicher, Spitze 0,13 % der
Frame-Zeit).

Nicht im Spiel geprüft: andere Spielsprachen, Zusammenspiel mit anderen Addons; als „getestet“
nur nach deiner Rückmeldung, ohne Spur in den gespeicherten Daten: unklare Zugänge mit `keep`,
Pause einer Farmrunde nach dem Ausloggen. Die Version 0.2.0 selbst unterscheidet sich von
0.2.0-alpha.10 nur in Versionsnummer und Dokumentation.

Version 0.3.0-alpha.1 (Craft-Bewertung, Tab „Farmen“, Goldpuffer) ist im Spiel noch nicht getestet. Bestätigt im Spiel ist
nur, dass `GetItemStats` in Classic Era die Werte eines Gegenstands liefert.

**Nicht in Forever getestet.**

## Version

0.3.0-alpha.1 – siehe [CHANGELOG.md](CHANGELOG.md).

## Lizenz

MIT, siehe [LICENSE](LICENSE).
