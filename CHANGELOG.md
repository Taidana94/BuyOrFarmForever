# Änderungen

Format nach [Keep a Changelog](https://keepachangelog.com/de/1.1.0/), Versionen nach
[Semantic Versioning](https://semver.org/lang/de/).

## [0.5.0-alpha.2] – 2026-10-19 (Testversion)

Auctionator-Preise und Waffen-DPS in Classic Era im Spiel bestätigt, der Rest nur außerhalb des
Spiels geprüft; nicht in Forever getestet.

### Behoben

- Im Tab „Beschaffung“ fehlten die Pfeile `<` `>` zum Wechseln des Ziels.

## [0.5.0-alpha.1] – 2026-10-19 (Testversion)

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
