# Änderungen

Format nach [Keep a Changelog](https://keepachangelog.com/de/1.1.0/), Versionen nach
[Semantic Versioning](https://semver.org/lang/de/).

## [0.2.0-alpha.9] – noch nicht veröffentlicht

### Geändert

- Nach `/bof farm travel` steht klar im Chat, ob jetzt Anreise oder Farmzeit zählt; der Zustand
  heißt in der Statuszeile „farmt“ statt „läuft“.

## [0.2.0-alpha.8] – noch nicht veröffentlicht

### Hinzugefügt

- Farmrunden (`/bof farm`): starten, pausieren, fortsetzen, Anreise getrennt erfassen, beenden,
  unklare Zugänge prüfen, speichern. Ertrag aus geplünderten Gegenständen, Farmzeit ohne Pausen.
- Geschätzte Farmzeit für fehlende Materialien mit Spanne und Datenbasis (`/bof farm estimate`),
  wahlweise nur aus diesem Charakter oder aus allen.

## [0.2.0-alpha.7] – noch nicht veröffentlicht

### Geändert

- Sind Berufs- und Verzauberungsfenster gleichzeitig offen, übernimmt `/bof recipe` (und der Knopf
  „Rezept übernehmen“) das zuletzt angeklickte Rezept statt des zuletzt geöffneten Fensters.

## [0.2.0-alpha.6] – noch nicht veröffentlicht

### Hinzugefügt

- Preise pro Stück aus drei Quellen: eigene Eingabe (`/bof price`), Händler (automatisch beim
  Händlerfenster) und Auktionshaus (automatisch bei deinen Suchen und per AH-Scan).
- Getrennt nach Realm und Fraktion; veraltete Preise (älter als 7 Tage) werden markiert.
- Fenster: Spalte „Preis/Stück“, Preise im Tooltip, Knopf „AH-Scan“.

## [0.2.0-alpha.5] – noch nicht veröffentlicht

### Hinzugefügt

- `/bof perf` zeigt Speicher, Anteil an der Frame-Zeit und die Rechenzeit für den Bestand.

### Geändert

- Weniger Speicherverbrauch bei Taschenänderungen (keine neuen Tabellen pro Ereignis).

### Behoben

- Stammen die gespeicherten Daten aus einer neueren Addon-Version, lösten `/bof stock` und
  `/bof goal` einen Lua-Fehler aus. Jetzt erscheint ein Hinweis.

## [0.2.0-alpha.4] – noch nicht veröffentlicht

### Hinzugefügt

- Fenster mit dem Tab „Material“ (`/bof show`): Bedarf, Bestand in Taschen, Bank und bei
  Twinks und Fehlmenge des ausgewählten Ziels oder aller Ziele; Ziel wechseln, Tooltip,
  Knopf „Rezept übernehmen“. Verschiebbar, Position wird gespeichert, schließt mit Escape.

## [0.2.0-alpha.3] – noch nicht veröffentlicht

### Hinzugefügt

- `/bof recipe [Anzahl]` übernimmt das ausgewählte Rezept aus dem offenen Berufsfenster
  (auch Verzauberkunst) als neues Ziel; das Ziel trägt den Namen des Rezepts.

## [0.2.0-alpha.2] – noch nicht veröffentlicht

### Hinzugefügt

- Bestand deiner anderen Charaktere auf demselben Realm wird mitgezählt (gleiche Fraktion) und
  mit Stand angezeigt; Charaktere der anderen Fraktion werden nur angezeigt.
- `/bof stock others` schaltet das Mitzählen ein oder aus.

### Geändert

- Der gespeicherte Bestand wird bei Taschenänderungen, Bankbesuch und `/bof stock` aktualisiert,
  nicht nur bei offener Bank.

## [0.2.0-alpha.1] – noch nicht veröffentlicht

### Hinzugefügt

- Materialziele pro Charakter: Zutaten pro Herstellung, Anzahl Herstellungen, gleiche Zutaten
  werden zusammengefasst.
- Bedarf, Bestand in Taschen und Bank und Fehlmenge für ein Ziel oder alle Ziele.
- Bankstand wird beim Bankbesuch gespeichert.
- Vorläufige Befehle `/bof goal …` und `/bof stock [all]`, Gegenstände per Link oder Item-ID.

### Geändert

- Groß-/Kleinschreibung wird nur noch beim Befehlswort ignoriert; Namen und Gegenstandslinks
  bleiben unverändert.

## [0.1.0] – noch nicht veröffentlicht

### Hinzugefügt

- Grundgerüst für WoW Classic Era 1.15.9 (Interface 11509).
- Gespeicherte Einstellungen mit Standardwerten, Prüfung beschädigter Werte und Schema-Version.
- Debug-Modus mit Protokoll (höchstens 200 Einträge).
- Befehle `/bof` und `/kof`: `help`, `version`, `debug`, `reset`.
- Deutsche Texte.
