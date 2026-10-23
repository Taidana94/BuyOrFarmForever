# Änderungen

Format nach [Keep a Changelog](https://keepachangelog.com/de/1.1.0/), Versionen nach
[Semantic Versioning](https://semver.org/lang/de/).

## [0.11.0-alpha.5] – 2026-10-23 (Testversion)

Nur außerhalb des Spiels geprüft; kein echter In-Game-Test durchgeführt. Nicht in Forever getestet.

### Geändert

- **Behalten-Liste im Goldplaner:** Jeder behaltene Gegenstand erscheint als Symbol neben dem Feld
  (Tooltip mit dem Gegenstand); Rechtsklick nimmt ihn von der Liste. Bisher ging das nur durch
  erneutes Hineinziehen oder `/bof goldkeep`.

## [0.11.0-alpha.4] – 2026-10-23 (Testversion)

Nur außerhalb des Spiels geprüft; kein echter In-Game-Test durchgeführt. Nicht in Forever getestet.

### Hinzugefügt

- **Farmrunde startet von selbst:** Lootest du außerhalb von Städten und Gasthäusern und läuft keine
  Runde, startet eine (fehlt dir das gelootete Material, ist es das Ziel). Der erste Loot zählt nicht
  mit; die Leerlaufzeit beendet die Runde wie sonst. Abschaltbar in den Einstellungen („Farmrunde beim
  Looten automatisch starten“), dann gilt wieder der Vorschlag.
- **Rezepte deiner Twinks im Goldplaner:** Kennt ein Twink (gleicher Realm, gleiche Fraktion) ein
  lohnendes Rezept, das du nicht kennst, plant der Goldplaner es mit ein („– auf Name (Zutaten per
  Post)“, 3 Min. für Post und Umloggen eingerechnet).
- **Preisverlauf und Weiterverkauf:** Jede AH-Suche speichert den niedrigsten Preis je Gegenstand und
  Tag (14 Tage). Liegt ein aktuelles Angebot deutlich unter dem üblichen Preis (mindestens 3 Tage
  Verlauf, mindestens 20 % Gewinn nach AH-Gebühr), schlägt der Goldplaner „Im AH kaufen und neu
  einstellen“ vor; im Vergleich als eigener Weg. Höchstens 20 Stück, da die Nachfrage unbekannt ist.

## [0.11.0-alpha.3] – 2026-10-23 (Testversion)

Nur außerhalb des Spiels geprüft; kein echter In-Game-Test durchgeführt. Nicht in Forever getestet.

### Hinzugefügt

- **Briefkasten im Bestand:** Beim Öffnen des Briefkastens merkt sich das Addon automatisch die
  Gegenstände und das Gold in empfangener Post. Sie zählen bei Zielen, Plan und Ratgeber mit; der
  Tooltip zeigt „Post …“, die Kontoübersicht das Gold in der Post.

### Geändert

- **Schneller:** Farmrouten und „Beute verarbeiten“-Routen werden nicht mehr bei jeder Taschen- oder
  Goldänderung neu berechnet, sondern nur nach neuen Läufen, Preisen, Rezepten oder Einstellungen
  (spätestens nach einer Minute wegen der Live-Preise von Auctionator).
- Farmfenster-Knöpfe breiter; die Ansichtsknöpfe des Goldplaners haben eine eigene Zeile (alpha.2).

## [0.11.0-alpha.1] – 2026-10-23 (Testversion)

Nur außerhalb des Spiels geprüft; kein echter In-Game-Test durchgeführt. Nicht in Forever getestet.

### Hinzugefügt

- **Was lohnt sich?** Goldplaner (Reiter „Goldpuffer“ → „Goldplaner“): Zeit wählen, dann „Vergleich“.
  Alle Wege zu Gold für diese Zeit nebeneinander, bester zuerst: alles kombiniert, Taschen verkaufen
  oder entzaubern, Herstellen und verkaufen (Zutaten aus den Taschen oder gekauft), Farmen, Angeln,
  Farmen und die Beute verarbeiten. Wege ohne Daten stehen unten mit dem, was fehlt. Im Chat:
  `/bof compare [Dauer]`.
- **Farmen → Herstellen → Verkaufen:** Macht ein gelerntes Rezept die Beute einer Route wertvoller,
  plant der Goldplaner „Westfall, verarbeitet zu …“ mit ein (Herstell- und Einstellzeit eingerechnet).
- **Angeln wird automatisch erkannt:** Eine Farmrunde, deren Beute meist vom Angeln stammt, wird als
  Angelroute der Zone gespeichert („Westfall (Angeln)“).
- **Konto:** Gold jedes Charakters wird gespeichert. Ansicht „Konto“ im Goldplaner und `/bof account`:
  Gold, Berufe mit Stufe und Rezepten, Gegenstände in Taschen und Bank – je Charakter auf dem Realm.

### Bekannt

- Reines AH-Handeln (billig kaufen, teurer einstellen) wird nicht vorgeschlagen: Ohne Preisverlauf und
  Verkaufsmengen wäre das geraten.
- Herstellen zum Verkauf bleibt auf 5 je Rezept begrenzt, weil die Nachfrage im AH unbekannt ist.

## [0.10.0-alpha.1] – 2026-10-23 (Testversion)

Nur außerhalb des Spiels geprüft; kein echter In-Game-Test durchgeführt. Nicht in Forever getestet.

### Hinzugefügt

- **Reiter „Ziele“:** Du nimmst ein Item auf, das du haben willst. Das Addon prüft, ob du es hast
  (Taschen, Bank, Twinks), kaufen, farmen oder herstellen kannst, und zeigt den günstigsten Weg, für
  Zutaten genauso. Farmzeit zählt mit dem Gold pro Stunde deiner besten Farmroute (einstellbar: „1 Std.
  Farmen ist wert“). „Herstellen“ und „Farmen“ starten direkt aus dem Plan. Unten: Summen, Hinweis, wenn
  dein freies Gold nicht reicht. Im Chat: `/bof want`.
- **Bestand automatisch:** alle Items in Taschen und Bank jedes Charakters werden erfasst (Bank beim
  Bankbesuch), auch kurz nach dem Login. Nichts muss mehr eingetragen werden.
- **Farmfenster:** kleines Fenster mit Start, Pause/Fortsetzen, Anreise/Angekommen, Beenden (`/bof farm`,
  Rechtsklick auf den Minimap-Knopf). Der Reiter „Farmen“ zeigt deine Farmrouten pro Zone mit Gold pro
  Stunde und Beute pro Stunde.
- Reiter „Berufe“: bei Ausrüstung die Wertung gegenüber deiner angelegten Ausrüstung.

### Geändert

- Die Reiter „Material“, „Beschaffung“ und „Craft“ sind im Reiter „Ziele“ aufgegangen. Alte
  Materialziele werden beim ersten Start übernommen (Rezeptziel → Produkt, Handziel → Zutaten).
- Farmrunden haben keine Art mehr (Sammeln/Gegner); „Beenden“ speichert sofort, nur Beute zählt.
  Farmrouten sind jetzt eine pro Zone.
- Die Gewichte für die Ausrüstungswertung stehen im Reiter „Einstellungen“ (mit „Vorschlag“).
- `/bof recipe` nimmt das Produkt des Rezepts als Ziel auf.

### Entfernt

- Strategien, Budget und Zeitlimit der Beschaffung, Alternativen und Questbelohnungen der
  Craft-Bewertung, `/bof goal`, `/bof stock`, `/bof plan`, `/bof alt`, `/bof gold reserves`, die
  Einstellungen „Unklare Zugänge automatisch einordnen“, „Beschaffung darf Rücklagen verwenden“ und
  „Questbelohnungen als Alternative vorschlagen“.

## [0.9.0-alpha.1] – 2026-10-23 (Testversion)

Nur außerhalb des Spiels geprüft; kein echter In-Game-Test durchgeführt. Nicht in Forever getestet.

### Hinzugefügt

- **Herstellen im Reiter „Berufe“:** unten im Detail ein Feld für die Anzahl, „Herstellen“, „Alle: n“ (so oft
  die Zutaten in deinen Taschen reichen) und „Stapel: n“ (ein voller Stapel des Produkts). Ist das
  Berufsfenster zu oder zeigt einen anderen Beruf, öffnet der erste Klick das richtige Fenster; der zweite
  Klick stellt her. Verzauberungen gehen weiterhin nur im Verzauberkunstfenster.
- `/bof make <Rezept> [Anzahl|all]` – dasselbe im Chat.

### Geändert

- „Als Ziel anlegen“ steht jetzt oben rechts neben „Zutaten“.

## [0.8.0] – 2026-10-23

Ratgeber und Berufsansicht. Getestet in WoW Classic Era 1.15.9; nicht in Forever getestet. Die Version
0.7.0 wurde nicht einzeln veröffentlicht, ihre Neuerungen sind hier enthalten.

### Hinzugefügt

- **Reiter „Berufe“:** pro Beruf eine Ansicht mit deinen gelernten Rezepten, gruppiert nach dem, wofür
  sie gut sind – Essen, Elixiere und Verzauberungen nach ihrem Effekt (Stärke, Beweglichkeit, Ausdauer &
  Willenskraft, Zaubermacht, Angeln, Heilung …), Ausrüstung nach ihrem stärksten Wert, alles andere nach
  Gegenstandsart. Gruppen lassen sich zuklappen. Dazu Fertigkeitsbalken, Suche und der Zutaten-Filter
  **Alle**, **Teilweise** (mindestens eine Zutat in den Taschen) und **Komplett** (jetzt herstellbar).
  Rechts: Zutaten mit Taschen/Bedarf und Bank, wie oft du es herstellen kannst, was die Zutaten wert sind
  (aus der Tasche zum Verkaufswert nach AH-Gebühr, fehlende zum Kaufpreis – wie beim Ratgeber), Wert beim
  Händler und im AH, Gewinn pro Herstellung und „Als Ziel anlegen“.
- **Ratgeber** (`/bof advisor`, Umschalt+Klick auf den Minimap-Knopf, Taste): ein kleines Fenster mit
  festen Zeilen **Verkaufen**, **Entzaubern** (nur wenn dein Charakter entzaubern kann), **Herstellen**,
  **Sparziel** und **Deine beste Stunde**; ein Klick auf eine Zeile führt sie aus. Gibt es nichts zu tun,
  sagt die Zeile, warum. Öffnet sich nach dem Login, wenn etwas Wichtiges ansteht.
- **Karten an den Spielfenstern:** Händler (fehlende Zutaten kaufen, Kram verkaufen, „Nicht verkaufen –
  entzaubern“), Auktionshaus (laut Plan kaufen, einstellen, Preise scannen), Bank (Material für deine
  Ziele mitnehmen), Briefkasten (Material an Twinks schicken).
- **Verkaufen und Kaufen auf Knopfdruck** beim Händler, jeweils nach Bestätigung.
- `/bof recipe key <Rezept> [Anzahl]`: Ziel aus einem gemerkten Rezept (nutzt der Knopf im Reiter „Berufe“).

### Geändert

- **Herstellen rechnet genauer** (Ratgeber und Goldplaner): Zutaten in deinen Taschen zählen mit ihrem
  Rohwert, Zutaten zum Kaufen mit dem Kaufpreis, das Produkt mit Händler- und AH-Wert. Hat eine Zutat
  keinen Preis, aber eine gemessene Farmrunde, wird sie als gefarmt gerechnet (Farmzeit statt Gold).
  Vorgeschlagen werden nur gelernte Rezepte; bereite Abklingzeiten stehen oben, wartende im Tooltip.
- Das Rezeptbuch merkt sich jetzt auch Beruf, Fertigkeit und Schwierigkeit sowie Verzauberungen.
- Goldplaner: Bleibt Zeit übrig, weil eine gemessene Farmroute fehlt, steht das im Plan.

## [0.6.0] – 2026-10-19

Goldplaner: wie du in deiner verfügbaren Zeit am meisten Gold machst. Getestet in WoW Classic Era
1.15.9; nicht in Forever getestet.

### Hinzugefügt

- **Goldplaner** (`/bof goldplan [Dauer]`, Ansicht „Goldplaner“ im Tab „Goldpuffer“): was du in 1, 2,
  4 Stunden oder einer eigenen Zeit am besten tust – Taschen beim Händler oder im Auktionshaus
  verkaufen, entzaubern, mit Gewinn herstellen, Abklingzeiten nutzen, die beste Farmroute farmen.
  Anreise wird verrechnet; Gold aus dem Auktionshaus steht getrennt und zählt für die Reihenfolge
  mit einem Abschlag (Einstellung, Standard 25 %).
- **Farmrouten** (`/bof goldsources`): Zone + Art + Zielmaterial, mit Gold pro Stunde (sicher und im
  AH) und Anreise. Farmrunden erfassen jetzt auch das gelootete Gold.
- **Behalten-Liste** (`/bof goldkeep`, Feld im Goldplaner): Gegenstände, die nie zum Verkauf
  vorgeschlagen werden.
- **Rezeptbuch:** Beim Öffnen eines Berufsfensters merkt sich das Addon alle Rezepte; bereite
  Abklingzeiten stehen in der Login-Zusammenfassung.

### Geändert

- „Anderer Weg“ im Tab „Beschaffung“ nutzt die neuen Farmrouten (mit Beutegold und AH-Abschlag).
- Im Tab „Goldpuffer“ steht „Einkauf prüfen“ jetzt rechts neben „Deine Sparziele“.

### Behoben

- Eingabefelder, die ein Knopf abschickt (neues Sparziel, Einkauf prüfen, Anzahl im Tab „Material“),
  verloren den eingegebenen Text, sobald man das Feld verließ.

## [0.5.0] – 2026-10-19

Ausbau für Classic Era: Zeitlimit, gemeinsame Auswertung, anderer Weg, Rüstung und Waffen-DPS,
Auctionator. Getestet in WoW Classic Era 1.15.9; nicht in Forever getestet.

### Hinzugefügt

- **Zeitlimit für die Beschaffung:** Feld „Zeitlimit“ im Tab „Beschaffung“ oder `/bof timelimit 2h`.
  Passt die Farmzeit nicht hinein, plant das Addon mehr Zukauf ein (zuerst, was pro Gold am meisten
  Zeit spart), soweit das Budget reicht; sonst sagt es, um wie viel das Limit überschritten wird.
- **Nebenbei gefarmt:** Materialien, die in denselben Farmrunden zusammen anfallen, werden gemeinsam
  ausgewertet. Was beim Farmen eines anderen Materials nebenbei mitkommt, steht als „nebenbei“ im
  Plan und kostet keine zusätzliche Farmzeit mehr.
- **Anderer Weg:** Aus deinen gespeicherten Farmrunden berechnet das Addon, wie viel Gold pro Stunde
  du mit einer anderen Farmroute verdienst (Auktionspreis abzüglich 5 % Gebühr oder Händlerpreis).
  Plan und Tab „Beschaffung“ zeigen, wie lange du mit der besten Route für den Kauf aller fehlenden
  Materialien brauchst.
- **Rüstung und Waffen-DPS in der Craft-Bewertung:** zwei neue Gewichte (Standard 0, die Vorlagen
  setzen passende Werte), z. B. `/bof weights armor 0,05`. Die Gewichte im Tab „Craft“ haben kurze
  Namen (Stä, Bew, Ausd, Int, Wil, Rüst, DPS).
- **Geplanter Ersatz:** Für jede eingeplante Alternative sagt die Bewertung, ob der Craft auch danach
  besser bleibt oder nur die Zeit bis dahin überbrückt.
- **Stufe:** Gegenstände, die du noch nicht tragen kannst, sind mit „tragbar ab Stufe …“ markiert.
- **Auctionator als Preisquelle (optional):** Ist Auctionator installiert, liest das Addon dessen
  zuletzt gesehene Auktionspreise. Sie erscheinen als „Auctionator“ bei `/bof price`, im Tab
  „Material“ und fließen in Beschaffung und Craft-Bewertung ein. Preise ohne Altersangabe (älter als
  21 Tage) gelten als veraltet. Gespeichert wird davon nichts. Abschaltbar im Tab „Einstellungen“
  („Preise von Auctionator verwenden“) oder mit `/bof set useAuctionator off`.
- Pfeile `<` `>` zum Wechseln des Ziels jetzt auch im Tab „Beschaffung“.
- In der Addon-Liste steht das Addon in der Kategorie „Berufe“ und zeigt eine Goldmünze statt eines
  Fragezeichens.

## [0.4.0] – 2026-10-19

Spielerentlastung: alles im Fenster bedienbar, viel Automatik. Getestet in WoW Classic Era 1.15.9; nicht
in Forever getestet.

### Hinzugefügt

- **Eingabe im Fenster statt im Chat:** Felder anklicken, Wert eintippen, Enter. Gegenstände in ein
  Feld ziehen oder mit Umschalt+Klick einfügen. Löschen fragt nach.
  - Tab „Material“: Ziel neu anlegen, umbenennen, löschen; Herstellungen; Menge pro Zutat; Zutat
    entfernen; eigener Preis per Klick in die Preisspalte; „Twinks mitzählen“; Rezept mit Anzahl.
  - Tab „Craft“: Gewichte als Felder, Vorlagen (Zauber, Heiler, Beweglichkeit, Stärke, Tank) mit
    Vorschlag nach Klasse und Talenten, Ansicht „Alternativen“ zum Anlegen und Bearbeiten.
  - Tab „Goldpuffer“: Sparziele als Zeilen (Name, Betrag, hoch, erreicht, löschen), neues Sparziel,
    Einkauf prüfen, Verteilung rückgängig machen.
  - Tab „Beschaffung“: Feld für das eigene Budget.
  - Tab „Farmen“: Zielmaterial vorausgewählt und änderbar, „mitzählen“ pro unklarem Gegenstand.
  - Neuer Tab „Einstellungen“ für alle Einstellungen, Debug-Modus, Leistung und Zurücksetzen.
- **Farm-Automatik:** Leerlauf zählt höchstens 5 Minuten am Stück; Zugänge bei Händler, Bank,
  Auktionshaus, Briefkasten und Handel zählen nicht; eine Runde ohne unklare Zugänge speichert sich
  beim Beenden selbst; Pause bei AFK und in Städten/Gasthäusern, danach geht es weiter; Flugrouten
  zählen als Anreise; Meldung, wenn das Zielmaterial für deine Ziele reicht; Vorschlag einer
  Farmrunde, wenn du ein fehlendes Material erbeutest; Ergebnis-Zeile nach jeder gespeicherten Runde.
- **Hinweise:** Zeilen im Gegenstands-Tooltip (was fehlt, Verbesserung eines Craft-Ziels); freies
  Gold und Rücklagen unter dem Händlerfenster mit Warnung, wenn ein Einkauf die Rücklagen angreift;
  Hinweis im Auktionshaus auf Materialien ohne Preis; Questbelohnungen als Alternative.
- **Goldpuffer:** neues Gold auf Wunsch automatisch verteilen (standardmäßig aus); Nettoerlös nach
  Quelle (Beute, Quests, Händler, Lehrer, Post, Auktionshaus, Handel, Sonstiges).
- Minimap-Knopf (Links: Fenster, Rechts: Farmrunde pausieren/fortsetzen), Tastenbelegungen für
  Fenster und Farmrunde, Rückblick auf die letzte Sitzung beim Login.
- Neue Chat-Befehle als Reserve: `/bof set`, `/bof goal name`, `/bof recipe new`,
  `/bof weights template|suggest`, `/bof alt kind`, `/bof gold name|undo`.

### Geändert

- Ein Rezept, das schon ein Ziel hat, erhöht beim Übernehmen dieses Ziel, statt ein doppeltes
  anzulegen (`/bof recipe new` legt trotzdem ein neues an).
- Alte Händler- und Auktionshauspreise werden nach 60 Tagen gelöscht (einstellbar); eigene Preise bleiben.
- Das Fenster hat eine Titelzeile über acht Tab-Knöpfen und ist etwas größer.

## [0.3.0] – 2026-10-19 (noch nicht veröffentlicht)

Craft-Bewertung, Goldpuffer und neue Fenster-Tabs. Getestet in WoW Classic Era 1.15.9; nicht in
Forever getestet.

### Hinzugefügt

- **Craft-Bewertung** (`/bof craft`, Tab „Craft“): hergestellter Gegenstand gegen deine angelegte
  Ausrüstung nach deinen Gewichten, mit dem verglichenen Platz (z. B. „Brust“, „Finger 1“),
  Beschaffungskosten und Farmzeit, Kosten pro Wertungspunkt und Wert vorhandener Zutaten. Der Tab
  hat eigene Knöpfe `<` und `>` und erklärt, warum ein Ziel nichts zu vergleichen hat.
- `/bof craft <Gegenstand>` vergleicht einen beliebigen Gegenstand mit deiner Ausrüstung.
- Gewichte für Stärke, Beweglichkeit, Ausdauer, Intelligenz, Willenskraft (`/bof weights`).
- **Alternativen** zum Craft (`/bof alt`): eingeplant oder möglicher Drop, mit Quelle/Notiz,
  Kosten, Zeitaufwand und Voraussetzung (`/bof alt cost|time|req <Nr.> …`, `clear` löscht einen
  Wert); die Craft-Bewertung zeigt sie neben Kosten und Farmzeit des Crafts.
- **Goldpuffer** (`/bof gold`, Tab „Goldpuffer“): Sparziele mit Priorität, Gold einmalig verteilen,
  Rücklagen, freies Gold und ungedeckte Ziele, Prüfung eines Einkaufs gegen die Rücklagen,
  Nettoerlös pro Stunde (inklusive Verlusten).
- Beschaffung: Zeitgegenwert der Kosten aus deinem Nettoerlös, Hinweis auf Rücklagen-Nutzung;
  wahlweise nur mit freiem Gold planen (`/bof gold reserves`).
- Tab „Farmen“: Farmrunde per Knopf starten, pausieren, Anreise umschalten, beenden, prüfen und
  speichern; laufende Zeit und geschätzte Farmzeit.
- `/bof farm keep all` zählt alle unklaren Zugänge mit.
- Tab „Hilfe“ mit allen Befehlen.

### Geändert

- Das Fenster ist breiter (sechs Tabs); der Titel steht rechts, damit die Tab-Knöpfe ihn nicht verdecken.

## [0.2.0] – 2026-10-18 (noch nicht veröffentlicht)

Materialbeschaffung. Getestet in WoW Classic Era 1.15.9; nicht in Forever getestet.

### Hinzugefügt

- **Materialziele** pro Charakter: Zutaten pro Herstellung, Anzahl Herstellungen, gleiche Zutaten
  werden zusammengefasst (`/bof goal …`).
- **Rezeptimport** aus dem Berufs- und Verzauberungsfenster (`/bof recipe [Anzahl]`, Knopf „Rezept
  übernehmen“). Sind beide Fenster offen, zählt das zuletzt angeklickte Rezept. Das Ziel trägt den
  Namen des Rezepts.
- **Bestand** in Taschen und Bank und Fehlmenge (`/bof stock [all]`); Bestand deiner anderen
  Charaktere auf demselben Realm und derselben Fraktion wird mitgezählt (`/bof stock others`).
- **Fenster** (`/bof show`) mit den Tabs „Material“ und „Beschaffung“; verschiebbar, Position und
  Tab werden gespeichert, schließt mit Escape.
- **Preise** pro Stück aus eigener Eingabe (`/bof price`), von Händlern und aus dem Auktionshaus
  (automatisch und per AH-Scan), getrennt nach Realm und Fraktion; veraltete Preise werden markiert.
- **Farmrunden** (`/bof farm …`): starten, pausieren, Anreise getrennt erfassen, beenden, unklare
  Zugänge prüfen, speichern; geschätzte Farmzeit mit Spanne und Datenbasis.
- **Vergleich Kaufen/Farmen** (`/bof plan`, Tab „Beschaffung“): Kauf-, Farm- und Teilkaufmengen,
  Kosten, Farmzeit und Restbudget nach den Strategien „Zeit sparen“, „Gold sparen“, „Selbst farmen“
  (`/bof strategy`), mit gemeinsamem Budget (`/bof budget`, sonst dein aktuelles Gold).
- `/bof perf` zeigt Speicher, Anteil an der Frame-Zeit und Rechenzeit.

### Geändert

- Groß-/Kleinschreibung wird nur beim Befehlswort ignoriert; Namen und Gegenstandslinks bleiben.

### Behoben

- Der gespeicherte Bestand wurde beim Ausloggen mit Nullen überschrieben (das Spiel meldet dann
  keine Gegenstände mehr); er wird jetzt nur bei Taschenänderungen, Bankbesuch und `/bof stock`
  gespeichert.
- Stammen die gespeicherten Daten aus einer neueren Addon-Version, lösten `/bof stock` und
  `/bof goal` einen Lua-Fehler aus; jetzt erscheint ein Hinweis.

## [0.1.0] – 2026-10-18 (noch nicht veröffentlicht)

### Hinzugefügt

- Grundgerüst für WoW Classic Era 1.15.9 (Interface 11509).
- Gespeicherte Einstellungen mit Standardwerten, Prüfung beschädigter Werte und Schema-Version.
- Debug-Modus mit Protokoll (höchstens 200 Einträge).
- Befehle `/bof` und `/kof`: `help`, `version`, `debug`, `reset`.
- Deutsche Texte.
