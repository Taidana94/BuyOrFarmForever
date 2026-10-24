# Kaufen oder farmen?

**Version 0.12.0 – Ziele mit dem günstigsten Weg, „Was lohnt sich?“ für deine Spielzeit, „Jetzt tun“ als
Checkliste, Verkaufschance im AH, Einkaufsliste, Post für Twinks, Wochenrückblick, automatische
Farmrouten, Berufsansicht mit Herstellen, Sparziele und Ratgeber. Getestet in WoW Classic
Era 1.15.9. Nicht in Forever getestet.**

„Kaufen oder farmen?“ sagt dir, wie du ein Item **am günstigsten** bekommst. Du nimmst ein Item in
deine Ziele auf, und das Addon prüft von selbst:

- **Hast du es schon?** In deinen Taschen, deiner Bank oder bei deinen anderen Charakteren auf dem
  Realm. Den Bestand erfasst das Addon automatisch, du musst nichts eintragen.
- **Kannst du es kaufen?** Preise vom Händler, aus dem Auktionshaus (mit AH-Scan), deine eigenen
  oder die von Auctionator.
- **Kannst du es farmen?** Aus deinen aufgezeichneten Farmrunden weiß das Addon, wo und wie schnell
  du es bekommst.
- **Kannst du es herstellen?** Mit einem gelernten Rezept, auch eines deiner Twinks. Dann prüft es
  für jede Zutat genauso: haben, kaufen, farmen oder wieder herstellen.

Dann schlägt es den günstigsten Weg vor: „kaufen“, „farmen“ oder „herstellen“. Farmzeit rechnet es
dabei in Gold um, mit dem, was dir deine beste Farmroute pro Stunde bringt. Bei Gleichstand gewinnt
Kaufen, weil es am schnellsten geht. Herstellen und Farmen startest du direkt aus dem Plan.

Weitere Teile:

- **Farmfenster:** ein kleines Fenster mit Start, Pause, Anreise und Beenden. Der Reiter „Farmen“
  zeigt deine Farmrouten mit Gold pro Stunde.
- **Berufe:** deine gelernten Rezepte nach Zweck sortiert (Essen nach Werten, Ausrüstung nach ihrem
  stärksten Wert …), mit Kosten, Wert, Gewinn, Vergleich mit deiner Ausrüstung und Herstellen per
  Klick.
- **Reiter „Gold“ – Sparziele und Goldplaner:** Sparziele mit Rücklagen und wie du in 1, 2 oder 4 Stunden am meisten
  Gold machst.
- **Ratgeber:** ein kleines Fenster mit „Mach das“: verkaufen, entzaubern, herstellen, sparen.

## Unterstützte Spielversion

| Client | Version | Status |
|---|---|---|
| WoW Classic Era | 1.15.9 (Build 70003, Interface 11509) | im Spiel getestet bis 0.12.0 (deutscher Client) |
| WoW Forever | – | geplant, **nicht in Forever getestet** |

## Installation

1. ZIP entpacken.
2. Den Ordner `BuyOrFarmForever` nach `World of Warcraft\_classic_era_\Interface\AddOns\` kopieren.
3. Spiel starten bzw. `/reload` eingeben und das Addon in der Addon-Liste aktivieren.

## Schnellstart

1. Klick auf den Knopf an der Minimap (oder `/bof show`) öffnet das Fenster, Reiter „Ziele“.
2. Ein Item, das du haben willst, in das Feld oben links ziehen (oder mit Umschalt+Klick einfügen),
   Anzahl eintragen, „Hinzufügen“.
3. Rechts steht, wie du es am günstigsten bekommst, für Zutaten genauso. Unten stehen die Summen.
4. Öffne einmal deine Berufsfenster, damit das Addon deine Rezepte kennt. Besuche einmal mit jedem
   Charakter die Bank, damit es auch dort den Bestand kennt.
5. Damit das Addon farmen vorschlagen kann, zeichne Farmrunden auf: Farmfenster (`/bof farm` oder
   Rechtsklick auf den Minimap-Knopf), „Start“ im Farmgebiet, „Beenden“ zum Speichern.

## So sammelt das Addon seine Daten

Fast alles läuft automatisch. Damit die Vorschläge gut werden, hilft Folgendes
(im Spiel: Reiter „Hilfe“ → „Anleitung“ oder `/bof howto`):

| Daten | Was du tun solltest |
|---|---|
| Twinks | Jeden Charakter einmal einloggen (gezählt: gleicher Realm, gleiche Fraktion). |
| Taschen | Nichts – automatisch bei jeder Änderung und nach dem Einloggen. |
| Bank | Einmal pro Charakter die Bank besuchen; danach bei jedem Besuch aktualisiert. |
| Post | Briefkasten öffnen – Gegenstände und Gold in der Post werden gemerkt. |
| Gold | Nichts – beim Einloggen und bei jeder Änderung. |
| Rezepte und Berufe | Jedes Berufsfenster einmal öffnen (auch Verzauberkunst); nach neuen Rezepten erneut öffnen. |
| Händlerpreise | Händler ansprechen – Kaufpreise für Ziele und Rezepte werden gespeichert. Verkaufspreise kennt das Spiel. |
| Auktionshaus | Im AH suchen, oder Knopf „AH-Scan“ bzw. `/bof price scan` für fehlende Preise. |
| Auctionator | Optional, empfohlen: dessen Preise werden live gelesen (Einstellung „Preise von Auctionator verwenden“). |
| Preisverlauf | Jede AH-Suche zählt; ab 3 Tagen erkennt der Goldplaner günstige Angebote zum Weiterverkaufen. |
| Eigene Preise | `/bof price <Gegenstand> <Preis>` für Dinge, die nie im AH oder beim Händler auftauchen. |
| Farmrouten | Einfach farmen: Die Runde startet beim ersten Loot außerhalb von Städten und endet nach der Leerlaufzeit. Eine Route braucht mindestens 10 Min. |
| Angeln | Wird automatisch erkannt und als eigene Route gespeichert. |
| Ziele | Gegenstand ins Feld im Reiter „Ziele“ ziehen; ab dann werden seine Preise und Zutaten mit erfasst. |

## Befehle

Alles hier geht auch im Fenster; die Befehle bleiben für alle, die lieber tippen. Statt `/bof`
funktioniert auch `/kof`. `<Gegenstand>` ist ein Gegenstandslink (Umschalt+Klick auf
den Gegenstand, während die Chatzeile offen ist) oder die Item-ID. Gib Befehle einzeln ein; mehrere
eingefügte Zeilen setzt das Spiel zu einer Zeile zusammen.

**Allgemein**

| Befehl | Wirkung |
|---|---|
| `/bof` oder `/bof help` | Befehlsliste |
| `/bof show` | öffnet oder schließt das Fenster |
| `/bof version` | Addon-Version, Interface-Version und Build des Spiels |
| `/bof debug` | Debug-Modus ein/aus |
| `/bof perf` | Speicher, Anteil an der Frame-Zeit und Rechenzeit des Plans |
| `/bof reset` | setzt die Einstellungen zurück (bestätigen mit `/bof reset confirm` innerhalb von 30 Sekunden); Ziele, Preise und Messungen bleiben |
| `/bof set [Einstellung Wert]` | Einstellungen anzeigen oder ändern, z. B. `/bof set hourValueGold 5`, `/bof set tooltipEnabled off` |

**Ziele**

| Befehl | Wirkung |
|---|---|
| `/bof want` | deine Ziele mit dem günstigsten Weg und den Summen |
| `/bof want add <Gegenstand> [Anzahl]` | Ziel aufnehmen (Anzahl wird addiert, ohne Angabe 1) |
| `/bof want set <Gegenstand> <Anzahl>` | Anzahl setzen (0 entfernt das Ziel) |
| `/bof want remove <Gegenstand>` | Ziel entfernen |
| `/bof recipe [Anzahl]` | nimmt das Produkt des im Berufsfenster ausgewählten Rezepts als Ziel auf (bei Verzauberungen die Zutaten) |
| `/bof make <Rezept> [Anzahl\|all]` | stellt ein gelerntes Rezept her (wie die Knöpfe „Herstellen“) |

**Preise**

| Befehl | Wirkung |
|---|---|
| `/bof price` | Preise der Items deiner Ziele und ihrer möglichen Zutaten |
| `/bof price <Gegenstand> <Preis>` | eigener Preis pro Stück, z. B. `1g 20s 5k`, `35s`, `80k` |
| `/bof price <Gegenstand> clear` | eigenen Preis löschen |
| `/bof price scan` | im offenen Auktionshaus das nächste Item ohne aktuellen Preis suchen |

**Farmrunden**

| Befehl | Wirkung |
|---|---|
| `/bof farm` | öffnet oder schließt das Farmfenster |
| `/bof farm start [Gegenstand]` | Runde in der aktuellen Zone starten (optional mit Zielmaterial) |
| `/bof farm travel` | zwischen Anreise und Farmen umschalten (der Chat sagt, was gerade zählt) |
| `/bof farm pause` / `resume` | pausieren / fortsetzen (Pausen zählen nicht) |
| `/bof farm stop` | Runde beenden und speichern (nur Beute zählt) |
| `/bof farm discard` | laufende Runde verwerfen |
| `/bof farm status` / `list` | Stand der Runde / deine letzten 5 Runden |
| `/bof farm scope` | Farmzeiten nur aus diesem Charakter oder aus allen |

**Ausrüstung**

| Befehl | Wirkung |
|---|---|
| `/bof craft <Gegenstand>` | einen Gegenstand mit deiner Ausrüstung vergleichen |
| `/bof weights` | deine Gewichte anzeigen |
| `/bof weights str\|agi\|sta\|int\|spi\|armor\|dps <Zahl>` | Gewicht setzen (0 bis 10, z. B. `/bof weights int 2`; Rüstung pro Punkt, z. B. `/bof weights armor 0,05`) |
| `/bof weights template caster\|healer\|agility\|strength\|tank` | Gewichte aus einer Vorlage (Zauber, Heiler, Beweglichkeit, Stärke, Tank) |
| `/bof weights suggest` | Vorlage passend zu Klasse und Talenten |

**Gold**

| Befehl | Wirkung |
|---|---|
| `/bof gold` | Übersicht: Gold, Rücklagen, frei, ungedeckt, Sparziele, Nettoerlös |
| `/bof gold add <Betrag> <Name>` | Sparziel anlegen, z. B. `/bof gold add 90g Reiten` |
| `/bof gold set <Nr.> <Betrag>` | Betrag ändern |
| `/bof gold name <Nr.> <Name>` | Sparziel umbenennen |
| `/bof gold up <Nr.>` | Priorität erhöhen (eine Stelle nach oben) |
| `/bof gold done <Nr.>` / `delete <Nr.>` | Sparziel erreicht (Rücklage wird frei) / löschen |
| `/bof gold distribute` | dein aktuelles Gold einmalig nach Priorität auf die Sparziele verteilen |
| `/bof gold undo` | die letzte Verteilung rückgängig machen |
| `/bof gold check <Betrag>` | greift ein Einkauf dieser Höhe deine Rücklagen an? Zeitgegenwert |
| `/bof goldplan [Dauer]` | was du in der Zeit am besten tust, um Gold zu machen (ohne Dauer: 1, 2 und 4 Std.) |
| `/bof plan [start [Dauer] \| stop \| <Nr.>]` | „Jetzt tun“: Goldplan als Checkliste starten, Schritt ab-/aufhaken, beenden; ohne Angabe: Fenster |
| `/bof shop` | AH-Einkaufsliste des laufenden Plans und deiner Ziele; mit Auctionator als dessen Einkaufsliste „BuyOrFarm“ |
| `/bof mail` | Post vorbereiten: was du an welchen Twink schickst (seine Ziele, Zutaten für Herstell-Schritte im Plan) |
| `/bof week` | Wochenrückblick: Gold gegen die Vorwoche, Quellen, Pläne gegen ihr Ergebnis, Farmrunden |
| `/bof skillup` | Berufe leveln: je Beruf die günstigsten Rezepte für den nächsten Fertigkeitspunkt |
| `/bof goldsources` | deine Farmrouten mit Gold pro Stunde (sicher und im AH) und Anreise |
| `/bof goldkeep [Gegenstand]` | Gegenstand auf die Behalten-Liste setzen oder davon nehmen; ohne Gegenstand: die Liste |
| `/bof advisor` | Ratgeber öffnen oder schließen (auch Umschalt+Klick auf den Minimap-Knopf) |

## Bedienung

**Eingeben im Fenster:** Feld anklicken, Wert eintippen, mit Enter bestätigen (Escape bricht ab).
Gegenstände ziehst du aus den Taschen in ein Feld mit Gegenstandssymbol oder fügst sie mit
Umschalt+Klick ein, während das Fenster offen ist. Löschen fragt immer nach.

**Reiter „Ziele“:** Oben ziehst du ein Item in das Feld, trägst die Anzahl ein und klickst
„Hinzufügen“. Links stehen deine Ziele mit ihrer Anzahl (direkt änderbar, „x“ entfernt); ein Klick
wählt eines aus, das Mausrad blättert die Liste. Rechts steht der Plan des ausgewählten Ziels als Baum:

- **hast du** (grün): genug im Bestand, auch bei deinen Twinks.
- **kaufen: 4 für 40s (AH)**: so viele fehlen, der Kauf kostet so viel; die Quelle steht dabei.
- **farmen: 12 in etwa 18 Min. (Brachland)**: aus deinen Farmrunden; „Farmen“ startet eine Runde mit
  diesem Item als Ziel.
- **herstellen: 2×**: darunter die Zutaten mit ihrem eigenen Weg; „Herstellen“ stellt her (wie im
  Reiter „Berufe“). Kann nur ein Twink das Rezept, steht sein Name dabei.
- **offen** (rot): kein Preis, keine Farmrunde, kein Rezept. Der Knopf „AH-Scan“ (nur am
  Auktionshaus) sucht Items ohne Preis.

Der Tooltip einer Zeile zeigt den Preis pro Stück, die Anreise und, wo dein Bestand liegt (deine
Taschen und Bank, jeder Twink mit Stand). Unten stehen die Summen: Gold zum Ausgeben, Farmzeit mit
Anreise, Anzahl Herstellungen. Reicht dein freies Gold (ohne Rücklagen) nicht, steht das dort; ebenso,
wie viel eine Stunde Farmen gerade wert ist.

**So entscheidet das Addon:** Zuerst zählt der Bestand. Für den Rest vergleicht es: Kaufen kostet den
Preis. Farmen kostet Zeit, gerechnet mit dem Gold pro Stunde deiner besten Farmroute (oder mit deiner
Einstellung „1 Std. Farmen ist wert“); ohne gemessene Route kostet Farmen kein Gold. Herstellen kostet,
was die Zutaten auf ihrem günstigsten Weg kosten; Zutaten aus deinem Bestand zählen mit dem, was sie
beim Verkauf bringen würden. Der niedrigste Wert gewinnt, bei Gleichstand Kaufen. Rezepte werden
höchstens drei Ebenen tief aufgelöst.

**Farmfenster:** `/bof farm`, Rechtsklick auf den Minimap-Knopf oder „Farmfenster öffnen“ im Reiter
„Farmen“. Knöpfe: **Start** (Runde in der aktuellen Zone), **Pause**/**Fortsetzen**,
**Anreise**/**Angekommen** und **Beenden** (speichert die Runde). Darüber laufen Zustand, Zone,
Farmzeit und Anreise mit.

**Farmrunden:** Während einer Runde vergleicht das Addon nach jeder Taschenänderung den Inhalt
deiner Taschen. Was bei offenem Beutefenster dazukommt, zählt als Beute. Was du bei offenem
Händler, Bank, Auktionshaus, Briefkasten oder Handel bekommst, zählt nicht; andere Zugänge auch
nicht. Zeit ohne Aktivität (Beute, Taschenänderung, Kampf) zählt höchstens 5 Minuten am Stück. Bei
AFK und in Städten oder Gasthäusern pausiert die Runde und läuft danach weiter; auf Flugrouten zählt
die Zeit als Anreise. Nach `/reload` läuft eine Runde weiter; nach Ausloggen ist sie pausiert.

**Reiter „Farmen“:** deine Farmrouten, eine Zeile pro Zone: Anzahl Runden, gemessene Farmzeit, Gold
pro Stunde (sicher: Händlerwert der Beute und gelootetes Gold) und was das Auktionshaus darüber hinaus
bringt. Der Tooltip zeigt die Anreise und die Beute pro Stunde. Gold pro Stunde zählt auf die
Farmzeit, die Anreise einmal pro Ausflug.

**Reiter „Berufe“:** links die Symbole deiner Berufe (ein Klick wechselt den Beruf), daneben
deine Fertigkeit, eine Suche und die Zutaten-Filter „Alle“, „Teilweise“ (mindestens eine Zutat in der
nötigen Menge in den Taschen) und „Komplett“ (jetzt herstellbar). Die Rezepte stehen in Gruppen wie
„Stärke“, „Ausdauer & Willenskraft“, „Heilung“ oder „Handwerkswaren“; ein Klick auf die Gruppe klappt
sie zu oder auf. Die Farbe des Namens zeigt wie im Berufsfenster, ob ein Fertigkeitspunkt kommt;
rechts steht, wie oft deine Taschen reichen („3×“) oder wie viele Zutaten du hast („1/2“). Rechts im
Detail: Zutaten (Taschen/Bedarf, dazu die Bank), herstellbar, was die Zutaten wert sind, Wert beim
Händler und im AH (nach Gebühr), Gewinn pro Herstellung und bei Ausrüstung die Wertung gegenüber
deiner angelegten Ausrüstung. „Als Ziel anlegen“ nimmt das Produkt in deine Ziele auf. Unten stellst
du direkt her: Anzahl ins Feld und „Herstellen“, oder „Alle: n“ bzw. „Stapel: n“. Ist das Berufsfenster
zu, öffnet der erste Klick es, der zweite stellt her. Im Kampf geht das nicht; Verzauberungen wendest
du wie gewohnt im Verzauberkunstfenster an.

**Ausrüstung bewerten:** Die Wertung ist die Summe der Werte (Stärke, Beweglichkeit, Ausdauer,
Intelligenz, Willenskraft, Rüstung, Waffen-DPS) mal deinem Gewicht, verglichen mit dem, was du an
diesem Platz trägst (bei Ringen und Schmuck mit dem schwächeren, bei Zweihandwaffen mit Haupt- und
Nebenhand zusammen). Die Gewichte stehen im Reiter „Einstellungen“ unten, mit dem Knopf „Vorschlag“
passend zu Klasse und Talenten.

**Reiter „Gold“, Ansicht „Sparziele“:** Übersicht (Gold, Rücklagen, frei, ungedeckt), deine Sparziele als
Zeilen (Name und Betrag direkt ändern, „hoch“, „erreicht“, „x“), eine Zeile „Neu“ zum Anlegen,
„Einkauf prüfen“, dein Nettoerlös mit Quellen und Knöpfe für „Gold verteilen“ und „Rückgängig“.
Die Ansicht **„Goldplaner“** (Knopf oben rechts): Zeit wählen (1, 2, 4 Std. oder eigene Dauer),
darunter der Plan Schritt für Schritt mit sicherem Gold und Gold „bis zu“ im AH, andere Möglichkeiten
und deine Farmrouten. Ein Gegenstand, den du ins Feld unten links ziehst, kommt auf die Behalten-Liste.

**Rezepte und Abklingzeiten:** Öffnest du ein Berufsfenster, merkt sich das Addon alle sichtbaren
Rezepte dieses Charakters (nur gelernte). Haben Produkt und Zutaten Preise, schlägt der Goldplaner
gewinnbringende Crafts vor. Rezepte mit Abklingzeit erkennt es, sobald das Fenster eine Restzeit
zeigt; ist sie vorbei, nennt der Login sie.

**Ratgeber:** Umschalt+Klick auf den Minimap-Knopf, `/bof advisor` oder eine Taste (Tastaturbelegung).
Die Zeilen: **Verkaufen**, **Entzaubern** (nur wenn du entzaubern kannst), **Herstellen** (Herstellungen
deiner Ziele, deren Zutaten in den Taschen sind, bereite Abklingzeiten, dann Rezepte mit Gewinn),
**Sparziel** und **Deine beste Stunde**. Ein Klick auf eine Zeile führt sie aus. Am Händler, im
Auktionshaus, in der Bank und am Briefkasten erscheinen passende Karten neben dem Fenster (zum Beispiel
„kaufen“ für Items deiner Ziele, die der Händler hat, oder „aus der Bank nehmen“).

**Reiter „Einstellungen“:** alle Einstellungen zum An- und Abschalten (Farm-Automatik, Bestand und
Preise, Gold, Anzeige), die Gewichte für die Ausrüstung, Debug-Modus, Leistung anzeigen und
Zurücksetzen.

**Hinweise ohne Eingabe:** Der Tooltip eines Gegenstands zeigt, wie viel dir für deine Ziele noch
fehlt, und bei gewünschter Ausrüstung die Verbesserung gegenüber deiner. Am Händler steht unter dem
Fenster dein freies Gold und deine Rücklagen; greift ein Einkauf die Rücklagen an, warnt das Addon
einmal. Im Auktionshaus nennt es, wie viele Items für deine Ziele noch keinen Preis haben. Erbeutest
du ein Item, das dein Plan noch braucht, ohne laufende Runde, schlägt es eine Farmrunde vor. Nach dem
Login fasst es deine letzte Sitzung zusammen.

**Minimap und Tasten:** Linksklick auf den Minimap-Knopf öffnet das Fenster, Rechtsklick öffnet das
Farmfenster bzw. pausiert oder setzt die Farmrunde fort. Unter Esc → Tastaturbelegung → AddOns kannst
du Tasten für Fenster und Farmrunde vergeben.

**Nettoerlös:** Jede Änderung deines Golds, während du online bist, zählt – Beute, Quests,
Verkäufe ebenso wie Einkäufe, Reparaturen, Post und Handel. Dazu zählt die Spielzeit (Pausen ohne
Aktivität höchstens 30 Minuten am Stück). Aus den letzten 14 Tagen ergibt sich der Nettoerlös pro
Stunde; ab einer Stunde Spielzeit gibt es den Zeitgegenwert.

Das Fenster lässt sich verschieben, merkt sich Position und Reiter und schließt mit Escape.

## Abhängigkeiten

Keine. Optional: **Auctionator** – ist es installiert, nutzt das Addon dessen Auktionspreise als
zusätzliche Preisquelle „Auctionator“ (abschaltbar im Reiter „Einstellungen“). Für Tests wird BugSack
mit BugGrabber empfohlen.

## Gespeicherte Daten

`WTF\Account\<Account>\SavedVariables\BuyOrFarmForever.lua` (eine Datei für alle Charaktere).
WoW schreibt sie beim Ausloggen, Beenden und bei `/reload`. Die Daten enthalten eine
Schema-Version; stammen sie aus einer neueren Addon-Version, verändert das Addon sie nicht und
weist darauf hin. Beim ersten Start von 0.10.0 werden deine alten Materialziele zu Zielen: ein Ziel
aus einem Rezept wird zu dessen Produkt, ein selbst angelegtes Ziel zu seinen Zutaten.

## Bekannte Einschränkungen

- Bestand: Taschen werden bei jeder Änderung und kurz nach dem Login erfasst, die Bank nur, während
  sie offen ist. Die Bank eines Twinks kennt das Addon also erst nach dessen erstem Bankbesuch mit
  dieser Version. Gezählt werden Twinks auf demselben Realm und derselben Fraktion.
- Farmen kennt das Addon nur aus **deinen** Farmrunden (keine Drop-Datenbank). Gefarmte Nebenbeute
  verringert die Kosten des Farmens nicht. Ohne gemessene Farmroute (mindestens 10 Minuten) kostet
  Farmen im Vergleich kein Gold.
- Herstellen kennt das Addon nur für gelernte Rezepte, die du im Berufsfenster gesehen hast, höchstens
  drei Ebenen tief. Ein Ziel wird ganz gekauft, ganz gefarmt oder ganz hergestellt, nicht gemischt.
  Rezepte mit mehreren möglichen Ergebnissen rechnen mit dem Durchschnitt.
- Für Twinks plant der Ratgeber am Briefkasten nur mit ihren Ziel-Items, nicht mit deren Zutaten.
- Preise: automatisch erfasst werden nur Preise der Items deiner Ziele und ihrer möglichen Zutaten.
  AH- und eigene Preise gelten nach 7 Tagen als veraltet, Händlerpreise nicht. Pro AH-Suche wird nur
  die erste Seite gelesen. Alte Preise löscht das Addon nach 60 Tagen (einstellbar, 0 = nie); deine
  eigenen Preise bleiben.
- Farmrunden zählen nur die Taschen, nicht die Bank. Zugänge ohne Beutefenster (Post, Handel …)
  zählen nicht. Stürzt das Spiel ab, fehlt alles seit dem letzten Speichern.
- Gold, das du per Post zwischen deinen Charakteren schickst, zählt beim einen als Einnahme, beim
  anderen als Ausgabe. Sparziele und Nettoerlös gelten pro Charakter.
- Ausrüstungswertung: Effekte und Setboni werden nicht bewertet; Einhandwaffen werden nur mit der
  Haupthand verglichen. Die Gewichte-Vorlagen sind ein Startpunkt des Addons, keine offiziellen Werte.
- Goldplaner: Verkäufe im Auktionshaus sind nicht garantiert (Preis vom letzten Scan, Einstellgebühr
  nicht abgezogen); die Anreise ist der Durchschnitt deiner Runden.
- Ratgeber: Verkaufen und Kaufen gehen nur beim Händler und nur nach Bestätigung; verkauft werden
  nie Items deiner Ziele, ihre möglichen Zutaten und die Behalten-Liste.
- Berufe: nur gelernte Rezepte, erst nachdem du das Berufsfenster einmal geöffnet hast. Die Gruppen
  für Essen, Tränke und Verzauberungen stammen aus einer Datentabelle (Wowhead Classic, Stand
  23.10.2026), nicht aus dem Spiel. Herstellen aus dem Reiter: beim ersten Klick nur Öffnen des
  Berufsfensters, wenn es zu ist.
- Nur deutsche Texte; Clients in anderen Sprachen zeigen ebenfalls Deutsch.
- Nur Classic Era. Auf anderen Clients startet das Addon nicht und meldet das.

## Durchgeführte Tests

**Außerhalb des Spiels** (Version 0.10.0-alpha.1): Struktur und TOC, Lua-Syntax (Lua 5.1), luacheck
ohne Warnungen, Übersetzungsschlüssel, Zeichen der Spielschrift, Sauberkeit und Leistung
(Funktionslänge, keine Skripte pro Bild, kein Speicherzuwachs bei Taschenänderungen) und
automatische Tests in einer nachgebauten Spielumgebung (Start, `/reload`, beschädigte und neuere
Daten, Übernahme alter Ziele, alle Befehle, Fenster-Eingaben, Bestand mit Bank und Twinks, Planer
mit Kaufen, Farmen, Herstellen über mehrere Ebenen, Farmfenster und Routen, Preise mit Auctionator,
Ausrüstungswertung, Sparziele, Goldplaner, Ratgeber, Berufsansicht, Herstellen, Hinweise).

**Im Spiel** (Classic Era 1.15.9, deutscher Client, Charaktere auf zwei Realms und beiden
Fraktionen), jeweils ohne Lua-Fehler:

- 0.1.0 bis 0.2.0 (18.10.2026): Grundgerüst und Befehle, Kampf, Ziele, Bestand mit Bank und Twinks,
  Rezeptimport, Fenster, Preise (eigene, Händler, Auktionshaus, AH-Scan), Farmrunden, `/bof perf`
  (259 KB Speicher, Spitze 0,13 % der Frame-Zeit).
- 0.3.0 bis 0.7.0 (18. und 19.10.2026): Craft-Bewertung, Farmen, Goldpuffer, Hilfe, Automatik und
  Eingaben im Fenster, Zeitlimit und Auctionator, Goldplaner (Farmrouten mit Beispieldaten), Ratgeber.
- 0.8.0 (23.10.2026): Reiter „Berufe“ (Kochkunst, Erste Hilfe, Schneiderei, Verzauberkunst; die
  übrigen Berufe nicht im Spiel geprüft), Bewertung der Zutaten aus der Tasche. `/bof perf`: 1640 KB
  Speicher, Spitze 7,54 % der Frame-Zeit.
- 0.9.0 (Herstellen aus dem Reiter „Berufe“) und 0.10.0 (Ziele mit günstigstem Weg, Farmfenster,
  vollständiger Bestand): **noch nicht im Spiel getestet.**

Nicht im Spiel geprüft: andere Spielsprachen, Zusammenspiel mit anderen Addons.

**Nicht in Forever getestet.**

## Über

Entwickelt von **Taidana** aka **Zuerich3**. Fragen, Wünsche, Fehler oder Verbesserungsvorschläge: bitte als Kommentar auf der CurseForge-Seite; bei Fehlern die Meldung von BugSack/BugGrabber mitschicken. Im Spiel: Reiter „Hilfe“ → „Über“ oder `/bof about`.

## Version

0.12.0 – siehe [CHANGELOG.md](CHANGELOG.md).

## Lizenz

MIT, siehe [LICENSE](LICENSE).
