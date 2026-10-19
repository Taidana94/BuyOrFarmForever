# Änderungen

Format nach [Keep a Changelog](https://keepachangelog.com/de/1.1.0/), Versionen nach
[Semantic Versioning](https://semver.org/lang/de/).

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
