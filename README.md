# Kaufen oder farmen?

**Version 0.8.0-alpha.1 (Testversion) – Materialbeschaffung, Craft-Bewertung, Goldpuffer,
Goldplaner, Ratgeber und die neue Berufsansicht. Bis 0.7.0-alpha.6 in WoW Classic Era 1.15.9 im Spiel
getestet; der Reiter „Berufe“ (neu in 0.8.0) ist nur außerhalb des Spiels geprüft. Nicht in Forever
getestet.**

„Kaufen oder farmen?“ hilft dir zu entscheiden, wie du fehlende Herstellungsmaterialien beschaffst:
kaufen, selbst farmen oder beides. Die Empfehlungen beruhen auf deinen eigenen Daten – deinem
Bestand, den Preisen, die du siehst, und deinem gemessenen Farmtempo.

Diese Version enthält die **Materialbeschaffung**:

- **Materialziele:** Zutaten und Anzahl Herstellungen, von Hand oder aus einem Rezept im
  Berufsfenster (auch Verzauberkunst).
- **Bestand:** Taschen und Bank, auch deiner anderen Charaktere auf dem Realm.
- **Preise:** eigene Eingabe, Händler und Auktionshaus (mit AH-Scan), getrennt nach Realm und
  Fraktion, veraltete Preise markiert; optional die Preise von Auctionator.
- **Farmrunden:** Farmzeit, Anreise und Ertrag messen; daraus schätzt das Addon, wie lange du für
  die fehlenden Materialien brauchst.
- **Vergleich Kaufen/Farmen:** wie viel du kaufen und wie viel du farmen solltest, mit Kosten,
  Farmzeit und Budget – nach der Strategie „Zeit sparen“, „Gold sparen“ oder „Selbst farmen“.

Neu in 0.3.0: **Lohnt sich der Craft?** – der hergestellte Gegenstand eines Rezept-Ziels wird
mit deiner angelegten Ausrüstung verglichen (nach deinen Gewichten für Stärke, Beweglichkeit,
Ausdauer, Intelligenz und Willenskraft), dazu Beschaffungskosten und Farmzeit pro
Verbesserungspunkt, der Wert schon vorhandener Zutaten und eingeplante oder mögliche Alternativen
mit deren Kosten, Zeitaufwand und Voraussetzungen.

Ebenfalls neu: der **Goldpuffer** – Sparziele (Reiten, Training, Berufsausbau, ein weiterer Craft)
mit Priorität, einmaliges Verteilen deines Golds, Übersicht über Rücklagen, freies Gold und
ungedeckte Ziele, Hinweis, ob ein Einkauf deine Rücklagen angreift, dein Nettoerlös pro Stunde und
daraus der **Zeitgegenwert** eines Einkaufs („2g entsprechen etwa 30 Min. Spielzeit“).

Neu in 0.4.0: **weniger tippen, mehr Automatik.** Alles geht im Fenster – Felder anklicken, Wert
eintippen, Enter; Gegenstände ziehst du aus den Taschen in ein Feld oder fügst sie mit Umschalt+Klick
ein. Farmrunden zählen Leerlauf nicht mit, pausieren bei AFK und in Städten, werten Flugrouten als
Anreise und speichern sich selbst, wenn nichts unklar ist. Das Addon schlägt eine Farmrunde vor,
wenn du ein fehlendes Material erbeutest, zeigt im Tooltip, was dir noch fehlt, warnt beim Händler,
wenn ein Einkauf deine Rücklagen angreift, bietet passende Questbelohnungen als Alternative an und
fasst deine letzte Sitzung zusammen. Jede Automatik lässt sich im Tab „Einstellungen“ abschalten.

Neu in 0.5.0: **Zeitlimit** für die Beschaffung, gemeinsame Auswertung von Materialien aus derselben
Farmrunde („nebenbei“), der **andere Weg** (etwas anderes farmen, verkaufen und davon kaufen),
**Rüstung und Waffen-DPS** in der Craft-Bewertung, Vergleich mit einem geplanten Ersatz, Hinweis auf
die nötige Stufe und optional die Preise von **Auctionator**.

Neu in 0.6.0: der **Goldplaner** – wie du in 1, 2, 4 Stunden oder einer beliebigen Zeit am meisten
Gold machst: Taschen ausräumen (Händler, Auktionshaus oder Entzaubern), mit Gewinn herstellen,
Abklingzeiten nutzen und die beste Farmroute aus deinen Farmrunden, mit der Anreise verrechnet.
Gold aus dem Auktionshaus steht getrennt („bis zu“), weil Verkäufe dort nicht sicher sind.

Neu in 0.7.0: der **Ratgeber** – ein kleines Fenster mit fünf Zeilen „Mach das“: Verkaufen,
Entzaubern (wenn du es kannst), Herstellen, Sparziel und deine beste Stunde. Am Händler, im Auktionshaus, in der Bank und
am Briefkasten erscheinen passende Karten direkt neben dem Fenster. Beim Händler verkauft „Verkaufen“
die vorgeschlagenen Gegenstände und „Kaufen“ besorgt fehlende Zutaten – jeweils erst nach deiner
Bestätigung.

Neu in 0.8.0: der Reiter **„Berufe“** – pro Beruf eine eigene Ansicht mit deinen gelernten Rezepten,
sortiert nach dem, wofür sie gut sind: Essen und Elixiere nach Stärke, Beweglichkeit, Intelligenz,
Angeln usw., Ausrüstung nach ihrem stärksten Wert, Verzauberungen nach ihrem Effekt. Dazu deine
Fertigkeit, eine Suche und der Filter **Zutaten**: alle Rezepte, nur die, von deren Zutaten du schon
etwas hast, oder nur die, die du jetzt herstellen kannst. Rechts siehst du Zutaten, Kosten, Wert und
Gewinn und legst mit einem Klick ein Materialziel an.

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

1. Klick auf den Knopf an der Minimap (oder `/bof show`) öffnet das Fenster.
2. Ziel anlegen: Berufsfenster öffnen, Rezept anklicken, im Tab „Material“ die Anzahl eintragen und
   „Rezept übernehmen“ – oder „Neues Ziel“ und Gegenstände in das Feld unten links ziehen.
3. Tab „Material“: Bedarf, Bestand, Fehlmenge und Preise. Am Händler und im Auktionshaus sammelt
   das Addon Preise automatisch; einen eigenen Preis trägst du per Klick in die Preisspalte ein.
4. Farmen: Tab „Farmen“, das Zielmaterial ist schon ausgewählt, „Start: Gegner“ oder
   „Start: Sammeln“. Pausen, Anreise und Speichern erledigt das Addon weitgehend selbst.
5. Tab „Beschaffung“: was du kaufen und was du farmen solltest.

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
| `/bof perf` | Speicher, Anteil an der Frame-Zeit und Rechenzeit des Addons |
| `/bof reset` | setzt die Einstellungen zurück (bestätigen mit `/bof reset confirm` innerhalb von 30 Sekunden); Ziele, Preise und Messungen bleiben |
| `/bof set [Einstellung Wert]` | Einstellungen anzeigen oder ändern, z. B. `/bof set farmIdleMinutes 10`, `/bof set tooltipEnabled off` |

**Ziele und Bestand**

| Befehl | Wirkung |
|---|---|
| `/bof goal` | listet deine Ziele |
| `/bof goal new <Name>` | legt ein Ziel an und wählt es aus |
| `/bof goal name <Name>` | benennt das ausgewählte Ziel um |
| `/bof goal select <Nr.>` | wählt ein Ziel aus |
| `/bof goal add <Gegenstand> [Menge]` | Zutat pro Herstellung hinzufügen (Menge wird addiert, ohne Angabe 1) |
| `/bof goal set <Gegenstand> <Menge>` | Menge pro Herstellung setzen (0 entfernt die Zutat) |
| `/bof goal remove <Gegenstand>` | Zutat entfernen |
| `/bof goal crafts <Anzahl>` | wie oft du herstellen willst |
| `/bof goal delete <Nr.>` | Ziel löschen (bestätigen mit `/bof goal delete <Nr.> confirm`) |
| `/bof recipe [Anzahl]` | Ziel aus dem im Berufsfenster ausgewählten Rezept (ohne Anzahl: 1×); hat ein Ziel das Rezept schon, wird es um die Anzahl erhöht |
| `/bof recipe new [Anzahl]` | legt immer ein neues Ziel aus dem Rezept an |
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
| `/bof weights str\|agi\|sta\|int\|spi\|armor\|dps <Zahl>` | Gewicht setzen (0 bis 10, z. B. `/bof weights int 2`; Rüstung pro Punkt, z. B. `/bof weights armor 0,05`) |
| `/bof weights template caster\|healer\|agility\|strength\|tank` | Gewichte aus einer Vorlage (Zauber, Heiler, Beweglichkeit, Stärke, Tank) |
| `/bof weights suggest` | Vorlage passend zu Klasse und Talenten |
| `/bof alt` | deine Alternativen |
| `/bof alt add <Gegenstand> planned\|drop [Quelle/Notiz]` | Alternative: eingeplant (z. B. Questbelohnung) oder möglicher Drop |
| `/bof alt remove <Nr.>` | Alternative entfernen |
| `/bof alt kind <Nr.> planned\|drop` | Art ändern: eingeplant oder möglicher Drop |
| `/bof alt cost <Nr.> <Betrag>` | Kosten der Alternative, z. B. `1g 50s` |
| `/bof alt time <Nr.> <Dauer>` | Zeitaufwand der Alternative, z. B. `45m` oder `1h 30m` |
| `/bof alt req <Nr.> <Text>` | Voraussetzung, z. B. `Stufe 20, Questreihe in Westfall` (`clear` löscht einen Wert) |

**Goldpuffer**

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
| `/bof gold reserves` | ob die Beschaffung Rücklagen verwenden darf (Standard: ja) |
| `/bof gold check <Betrag>` | greift ein Einkauf dieser Höhe deine Rücklagen an? Zeitgegenwert |

**Beschaffung**

| Befehl | Wirkung |
|---|---|
| `/bof plan [all]` | was du kaufen und was du farmen solltest (ausgewähltes bzw. alle Ziele) |
| `/bof strategy time\|gold\|farm` | Strategie: Zeit sparen, Gold sparen, selbst farmen |
| `/bof budget [Betrag\|clear]` | eigenes Budget für Käufe; ohne Budget zählt dein aktuelles Gold |
| `/bof advisor` | Ratgeber öffnen oder schließen (auch Umschalt+Klick auf den Minimap-Knopf) |
| `/bof goldplan [Dauer]` | was du in der Zeit am besten tust, um Gold zu machen (ohne Dauer: 1, 2 und 4 Std.) |
| `/bof goldsources` | deine Farmrouten mit Gold pro Stunde (sicher und im AH) und Anreise |
| `/bof goldkeep [Gegenstand]` | Gegenstand auf die Behalten-Liste setzen oder davon nehmen; ohne Gegenstand: die Liste |
| `/bof timelimit [Dauer\|clear]` | höchste Farmzeit im Plan, z. B. `2h` oder `1h 30m`; der Rest wird gekauft, soweit das Budget reicht |

## Bedienung

**Eingeben im Fenster:** Feld anklicken, Wert eintippen, mit Enter bestätigen (Escape bricht ab).
Gegenstände ziehst du aus den Taschen in ein Feld mit Gegenstandssymbol oder fügst sie mit
Umschalt+Klick ein, während das Fenster offen ist. Löschen fragt immer nach.

**Fenster, Tab „Material“:** das ausgewählte Ziel mit Menge pro Herstellung (Feld), Bedarf, Bestand in
Taschen und Bank, Bestand deiner anderen Charaktere („Twinks“), Fehlmenge (rot/grün) und Preis pro
Stück (grau = veraltet). Oben: `<` und `>` wechseln das Ziel, Name und Herstellungen direkt ändern,
„Neues Ziel“, „Löschen“; „Alle Ziele zusammen“ und „Twinks mitzählen“. In jeder Zeile: Menge ändern
(0 entfernt), „x“ entfernt, ein Klick auf den Preis öffnet ein Feld für deinen eigenen Preis (leer =
löschen). Unten: Gegenstand ins Feld ziehen, Menge, „Hinzufügen“ (ohne Ziel wird eines angelegt);
„Rezept übernehmen“ mit Anzahl; „AH-Scan“ (nur am Auktionshaus) sucht pro Klick ein fehlendes Material.

**Fenster, Tab „Beschaffung“:** oben wechseln `<` und `>` das Ziel; pro fehlendem Material, wie viel du kaufen und wie viel du farmen
solltest, mit Kosten und Farmzeit (inklusive Anreise), darunter die Summe und das Restbudget.
Strategien:

- **Zeit sparen:** kaufen, was einen Preis hat. Reicht das Budget nicht, wird zuerst gekauft, was
  pro Gold am meisten Farmzeit spart (auch Teilkäufe); der Rest wird gefarmt.
- **Gold sparen:** farmen, was du schon einmal gefarmt hast; kaufen nur, was du nicht farmen kannst.
- **Selbst farmen:** nichts kaufen.

Was weder einen Preis im Budget noch eine Farmmessung hat, steht als „offen“ (rot). Der Tooltip
zeigt Farmzeit und Anreise getrennt. Ein eigenes Budget trägst du oben ins Feld „Budget“ ein (leer =
dein aktuelles Gold), ein Zeitlimit oben rechts ins Feld „Zeitlimit“ (leer = keins). Fallen in deinen
Farmrunden mehrere fehlende Materialien zusammen an, zählt das Addon, was beim längsten Farmen
nebenbei mitkommt („nebenbei“ im Tooltip und im Chat). Unter dem Plan steht der **andere Weg**: die
Farmroute aus deinen Runden, die am meisten Gold pro Stunde bringt (Ziel einer Runde ist kein
fehlendes Material, mindestens 10 Minuten gemessen), und wie lange du damit für den Kauf von allem
Fehlenden brauchst.

**Farmrunden:** Während einer Runde vergleicht das Addon nach jeder Taschenänderung den Inhalt
deiner Taschen. Was bei offenem Beutefenster dazukommt, zählt als **geplündert**. Was du bei offenem
Händler, Bank, Auktionshaus, Briefkasten oder Handel bekommst, zählt nicht. Alles andere ist
**unklar** – das prüfst du nach dem Beenden und zählst es mit „mitzählen“ mit oder lässt es weg;
gibt es nichts Unklares, speichert sich die Runde selbst und zeigt ihr Ergebnis. Zeit ohne
Aktivität (Beute, Taschenänderung, Kampf) zählt höchstens 5 Minuten am Stück. Bei AFK und in Städten
oder Gasthäusern pausiert die Runde und läuft danach weiter; auf Flugrouten zählt die Zeit als
Anreise. Nach `/reload` läuft eine Runde weiter; nach Ausloggen ist sie pausiert.

**Fenster, Tab „Farmen“:** Knöpfe für die Farmrunde (Start mit Sammeln, Gegner oder Sonstiges,
Pause/Fortsetzen, Anreise/Angekommen, Beenden; nach dem Beenden „Unklare mitzählen“, Speichern,
Verwerfen), das Zielmaterial (vorausgewählt: das erste fehlende Material des Ziels, mit `<` `>`
änderbar), der Stand der Runde mit laufender Zeit und den Gegenständen (bei unklaren Zugängen je ein
Knopf „mitzählen“) und die geschätzte Farmzeit für die fehlenden Materialien des ausgewählten Ziels.

**Fenster, Tab „Craft“:** die Craft-Bewertung des ausgewählten Ziels: Wertung des hergestellten
Gegenstands gegen das, was du an diesem Platz trägst (bei Ringen und Schmuck gegen den schwächeren,
Zweihandwaffen gegen Haupt- und Nebenhand zusammen), Beschaffungskosten und Farmzeit, Kosten pro
Wertungspunkt, Wert vorhandener Zutaten (beim Händler und nach deinen Preisen) und deine
Alternativen. Die Wertung ist die Summe der Werte (fünf Grundwerte, Rüstung, Waffen-DPS) mal deinem
Gewicht. Bei eingeplanten Alternativen steht, ob der Craft auch danach besser bleibt oder nur die Zeit
bis dahin überbrückt; was du noch nicht tragen kannst, ist mit der nötigen Stufe markiert. Aktualisiert sich,
wenn du Ausrüstung wechselst. Unten trägst du die Gewichte direkt ein oder übernimmst eine Vorlage
(Zauber, Heiler, Beweglichkeit, Stärke, Tank; ein Vorschlag passend zu Klasse und Talenten steht
dabei). Der Knopf „Alternativen“ oben rechts öffnet die Liste deiner Alternativen: Art umschalten,
Kosten, Zeit (z. B. `1h 30m`) und Voraussetzung eintragen, entfernen, neue per Feld hinzufügen.

**Fenster, Tab „Berufe“:** links die Symbole deiner Berufe (ein Klick wechselt den Beruf), daneben
deine Fertigkeit, eine Suche und die Zutaten-Filter „Alle“, „Teilweise“ (mindestens eine Zutat in der
nötigen Menge in den Taschen) und „Komplett“ (jetzt herstellbar). Die Rezepte stehen in Gruppen wie
„Stärke“, „Ausdauer & Willenskraft“, „Heilung“ oder „Handwerkswaren“; ein Klick auf die Gruppe klappt
sie zu oder auf. Die Farbe des Namens zeigt wie im Berufsfenster, ob ein Fertigkeitspunkt kommt;
rechts steht, wie oft deine Taschen reichen („3×“) oder wie viele Zutaten du hast („1/2“). Rechts im
Detail: Zutaten (Taschen/Bedarf, dazu die Bank), herstellbar, Zutatenkosten nach deinen Preisen, Wert
beim Händler und im AH (nach Gebühr) und Gewinn pro Herstellung. „Als Ziel anlegen“ macht daraus ein
Materialziel (oder erhöht ein vorhandenes). Das Addon kennt die Rezepte, sobald du das Berufsfenster
einmal geöffnet hast. Mausrad blättert.

**Fenster, Tab „Hilfe“:** alle Befehle (dieselben wie bei `/bof help`), mit dem Mausrad blätterbar.

**Fenster, Tab „Goldpuffer“:** Übersicht (Gold, Rücklagen, frei, ungedeckt), deine Sparziele als
Zeilen (Name und Betrag direkt ändern, „hoch“, „erreicht“, „x“), eine Zeile „Neu“ zum Anlegen,
„Einkauf prüfen“, dein Nettoerlös mit Quellen und Knöpfe für „Gold verteilen“, „Rückgängig“ und
„Rücklagen an/aus“. Der Tab „Beschaffung“ zeigt unter dem Plan, ob die Käufe deine Rücklagen
angreifen, und den Zeitgegenwert der Kosten.

**Fenster, Tab „Goldpuffer“, Ansicht „Goldplaner“** (Knopf oben rechts): Zeit wählen (1, 2, 4 Std.
oder eigene Dauer), darunter der Plan Schritt für Schritt mit sicherem Gold und Gold „bis zu“ im AH,
andere Möglichkeiten und deine Farmrouten. Ein Gegenstand, den du ins Feld unten links ziehst, kommt
auf die Behalten-Liste (nochmal ziehen nimmt ihn herunter).

So entsteht eine **Farmroute**: Jede gespeicherte Farmrunde gehört zu einer Route aus Zone (wo du
startest), Art (Sammeln, Gegner, Sonstiges) und Zielmaterial. Ihr Wert ist die Beute zu aktuellen
Preisen plus das gelootete Gold (seit 0.6.0 erfasst). Gold pro Stunde zählt auf die Farmzeit, die
Anreise einmal pro Ausflug. Eine Route braucht mindestens 10 Minuten Messung.

**Rezepte und Abklingzeiten:** Öffnest du ein Berufsfenster, merkt sich das Addon alle sichtbaren
Rezepte dieses Charakters (nur gelernte). Haben Produkt und Zutaten Preise, schlägt der Goldplaner
gewinnbringende Crafts vor: Verkaufswert beim Händler und im AH minus Zutaten. Zutaten in deinen
Taschen zählen mit dem, was sie roh beim Verkauf bringen würden; Zutaten zum Kaufen mit dem
Kaufpreis. Hat eine Zutat keinen Preis, aber du hast sie schon einmal gefarmt (gemessene Farmrunde),
rechnet das Addon sie als „farmen“: kein Gold, dafür die geschätzte Farmzeit. Mit Zutaten in der Tasche so viele Crafts, wie sie reichen, sonst höchstens 5. Rezepte mit Abklingzeit erkennt es, sobald das Fenster eine
Restzeit zeigt; ist sie vorbei, nennt der Login sie.

**Ratgeber:** Umschalt+Klick auf den Minimap-Knopf, `/bof advisor` oder eine Taste (Tastaturbelegung).
Die Zeilen stehen immer in dieser Reihenfolge:

- **Verkaufen:** Kram für den Händler und Waren fürs Auktionshaus; warnt bei vollen Taschen.
- **Entzaubern** (nur wenn du entzaubern kannst): was als Verzauberungsmaterial mehr bringt als
  verkauft; der Tooltip nennt den Unterschied pro Gegenstand (braucht Auctionator).
- **Herstellen:** nur gelernte Rezepte – bereite Ziele und Abklingzeiten, dann Rezepte mit Gewinn,
  zuerst die, deren Zutaten du schon hast. Der Tooltip zeigt pro Rezept Händler- und AH-Wert, den
  Wert der Zutaten und wann wartende Abklingzeiten bereit sind.
- **Sparziel** und **Deine beste Stunde**.

Ein Klick auf eine Zeile führt sie aus („Verkaufen“ beim Händler, „Sparziel“ öffnet den Goldpuffer,
„Deine beste Stunde“ den Goldplaner). Jede Zeile hat einen farbigen Streifen (gelb: Gold, blau:
Hinweis, orange: Warnung, grau: gerade nichts zu tun), eine Überschrift, den Goldwert und eine
Erklärung; der Tooltip zeigt die Gegenstände oder Rezepte. Unten im Ratgeber schaltest du die Karten an den Spielfenstern und das Öffnen nach dem
Login ab. Nach dem Login öffnet er sich von selbst, wenn etwas Wichtiges ansteht (volle Taschen,
Abklingzeit, herstellbares Ziel).

**Fenster, Tab „Einstellungen“:** alle Einstellungen zum An- und Abschalten (Farm-Automatik,
Preise, Goldpuffer, Anzeige), Debug-Modus, Leistung anzeigen und Zurücksetzen.

**Hinweise ohne Eingabe:** Der Tooltip eines Gegenstands zeigt, wie viel dir für deine Ziele noch
fehlt, und bei einem Craft-Ziel die Verbesserung gegenüber deiner Ausrüstung. Am Händler steht unter
dem Fenster dein freies Gold und deine Rücklagen; greift ein Einkauf die Rücklagen an, warnt das
Addon einmal. Im Auktionshaus nennt es, wie viele fehlende Materialien noch keinen Preis haben.
Erbeutest du ein fehlendes Material ohne laufende Runde, schlägt es eine Farmrunde vor; zeigt das
Questfenster eine Belohnung für den Platz eines Craft-Ziels, bietet es sie als Alternative an. Nach
dem Login fasst es deine letzte Sitzung zusammen. Wer möchte, lässt neues Gold automatisch auf die
Sparziele verteilen (Einstellung, standardmäßig aus).

**Minimap und Tasten:** Linksklick auf den Minimap-Knopf öffnet das Fenster, Rechtsklick pausiert
oder setzt die Farmrunde fort. Die Position stellst du in den Einstellungen ein (Grad). Unter
Esc → Tastaturbelegung → AddOns kannst du Tasten für Fenster und Farmrunde vergeben.

**Nettoerlös:** Jede Änderung deines Golds, während du online bist, zählt – Beute, Quests,
Verkäufe ebenso wie Einkäufe, Reparaturen, Post und Handel. Dazu zählt die Spielzeit (Pausen ohne
Aktivität höchstens 30 Minuten am Stück). Aus den letzten 14 Tagen ergibt sich der Nettoerlös pro
Stunde; ab einer Stunde Spielzeit gibt es den Zeitgegenwert. Seit 0.4.0 merkt sich das Addon, woher
das Gold kommt (Beute, Quests, Händler, Lehrer, Post, Auktionshaus, Handel, Sonstiges).

Das Fenster lässt sich verschieben, merkt sich Position und Tab und schließt mit Escape.

## Abhängigkeiten

Keine. Optional: **Auctionator** – ist es installiert, nutzt das Addon dessen Auktionspreise als
zusätzliche Preisquelle „Auctionator“ (abschaltbar im Tab „Einstellungen“). Für Tests wird BugSack mit
BugGrabber empfohlen.

## Gespeicherte Daten

`WTF\Account\<Account>\SavedVariables\BuyOrFarmForever.lua` (eine Datei für alle Charaktere).
WoW schreibt sie beim Ausloggen, Beenden und bei `/reload`. Die Daten enthalten eine
Schema-Version; stammen sie aus einer neueren Addon-Version, verändert das Addon sie nicht und
weist darauf hin.

## Bekannte Einschränkungen

- Der Bestand anderer Charaktere ist der Stand von deren letzter Taschenänderung, ihrem letzten
  Bankbesuch oder `/bof stock`. Neue Zutaten kennen sie erst nach ihrem nächsten Login.
- Rezeptimport nur für das ausgewählte Rezept, nur feste Zutaten.
- Automatisch erfasst werden nur Preise von Materialien aus deinen Zielen. AH- und eigene Preise
  gelten nach 7 Tagen als veraltet, Händlerpreise nicht. Pro AH-Suche wird nur die erste Seite
  gelesen; bei sehr vielen Angeboten kann der günstigste Preis fehlen.
- Farmrunden zählen nur die Taschen, nicht die Bank.
- Stürzt das Spiel ab, fehlt alles seit dem letzten Speichern, auch eine in dieser Sitzung
  gestartete Farmrunde.
- Gold, das du per Post zwischen deinen Charakteren schickst, zählt beim einen als Einnahme, beim
  anderen als Ausgabe (Quelle „Post“). Questbelohnungen erkennt das Addon am offenen Questfenster;
  kommt das Gold erst nach dem Schließen, zählt es als „Sonstiges“. Sparziele und Nettoerlös gelten
  pro Charakter.
- Die Craft-Bewertung rechnet mit Stärke, Beweglichkeit, Ausdauer, Intelligenz, Willenskraft,
  Rüstung und Waffen-DPS. Effekte und Setboni werden nicht bewertet. Einhandwaffen
  werden nur mit der Haupthand verglichen. Die Gewichte-Vorlagen sind ein Startpunkt des Addons,
  keine offiziellen Werte.
- Der Tab „Craft“ zeigt höchstens 12 Zeilen; bei vielen Alternativen steht der Rest nur im Chat
  (`/bof craft`).
- Alte Preise vom Händler und aus dem Auktionshaus löscht das Addon nach 60 Tagen (einstellbar,
  0 = nie); deine eigenen Preise bleiben.
- Das Zeitlimit wird schrittweise eingehalten (erst das, was pro Gold am meisten Zeit spart), nicht
  mit der rechnerisch besten Kombination. Der andere Weg rechnet mit der AH-Gebühr von 5 %, nicht mit
  der Einstellgebühr, und nur mit aktuellen Preisen.
- Goldplaner: Verkäufe im Auktionshaus sind nicht garantiert (Preis vom letzten Scan, Nachfrage
  unbekannt, Einstellgebühr nicht abgezogen); die Anreise ist der Durchschnitt deiner Runden, nicht
  der Weg von deinem Standort; der Weg in die Stadt zum Verkaufen ist nicht eingerechnet. Die
  Zeiten pro Verkauf, Entzaubern und Craft sind Schätzungen des Addons. Rezepte kennt das Addon erst
  nach dem Öffnen des Berufsfensters; Abklingzeiten erst, wenn das Fenster einmal eine Restzeit zeigte.
- Ratgeber: Verkaufen und Kaufen gehen nur beim Händler und nur nach Bestätigung; im Auktionshaus
  und am Briefkasten zeigt er nur, was zu tun ist. Verkauft werden genau die Gegenstände der Liste
  (ohne Behalten-Liste und Material deiner Ziele); beim Händler kannst du sie zurückkaufen.
- Berufe: nur gelernte Rezepte, und erst nachdem du das Berufsfenster einmal geöffnet hast (Rezepte
  aus älteren Versionen ohne Beruf erscheinen unter „Sonstige“, bis du das Fenster wieder öffnest).
  Angeln hat keine Rezepte. Die Gruppen für Essen, Tränke und Verzauberungen stammen aus einer
  Datentabelle (Wowhead Classic, Stand 23.10.2026), nicht aus dem Spiel; einzelne Zuordnungen können
  abweichen. Ausrüstung kommt in die Gruppe ihres größten Grundwerts. Die Suche unterscheidet bei
  Umlauten Groß- und Kleinschreibung. Gewinn nur, wenn alle Zutaten und das Produkt einen Preis haben.
- Nur deutsche Texte; Clients in anderen Sprachen zeigen ebenfalls Deutsch.
- Nur Classic Era. Auf anderen Clients startet das Addon nicht und meldet das.

## Durchgeführte Tests

**Außerhalb des Spiels** (Version 0.6.0): Struktur und TOC, Lua-Syntax (Lua 5.1), luacheck
ohne Warnungen, Übersetzungsschlüssel, Zeichen der Spielschrift, Sauberkeit und Leistung
(Funktionslänge, keine Skripte pro Bild, kein Speicherzuwachs bei Taschenänderungen) und 255
automatische Tests in einer nachgebauten Spielumgebung (Start, `/reload`, beschädigte und neuere
Daten, alle Befehle, alle Fenster-Eingaben, Ziele, Bestand, Rezeptimport, Preise mit Auctionator,
Farmrunden mit Automatik, Beschaffungsplan mit Zeitlimit, Nebenbei-Materialien und anderem Weg,
Craft-Bewertung mit Rüstung, Waffen-DPS und geplantem Ersatz, Goldpuffer, Goldplaner mit Routen,
Taschen, Rezeptbuch und Abklingzeiten, Einstellungen, Hinweise).
Die Neuerungen von 0.5.0 wurden am 19.10.2026 in 0.5.0-alpha.1 und 0.5.0-alpha.2 in Classic Era im
Spiel getestet (mit Auctionator); die fehlenden Ziel-Pfeile im Tab „Beschaffung“ wurden in
0.5.0-alpha.2 ergänzt und bestätigt. Die Version 0.5.0 unterscheidet sich von 0.5.0-alpha.2 nur in
Versionsnummer und Dokumentation.
Der Goldplaner (0.6.0) wurde am 19.10.2026 in 0.6.0-alpha.1 und 0.6.0-alpha.2 in Classic Era im
Spiel getestet (Entzaubern, Auctionator-Entzauberungswerte, Taschen, Rezepte, Behalten-Liste;
Farmrouten mit Beispieldaten eines Entwickler-Addons statt echter Farmrunden). Ein Fehler in den
Eingabefeldern für neue Sparziele wurde in 0.6.0-alpha.2 behoben und bestätigt. Die Version 0.6.0
unterscheidet sich von 0.6.0-alpha.2 nur in Versionsnummer und Dokumentation.

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

Die Neuerungen von 0.3.0 (Craft-Bewertung mit Alternativen, Tab „Farmen“, Goldpuffer, Tab „Hilfe“)
wurden am 18. und 19.10.2026 in den Zwischenversionen 0.3.0-alpha.1 bis 0.3.0-alpha.3 im Spiel
getestet, ohne Lua-Fehler; zwei Darstellungsfehler im Tab „Craft“ wurden dabei gefunden und
behoben. Einnahmen und Ausgaben beim Nettoerlös: getestet nach deiner Rückmeldung, ohne Spur in
den gespeicherten Daten. Die Version 0.3.0 unterscheidet sich von 0.3.0-alpha.3 nur in
Versionsnummer und Dokumentation.

Die Neuerungen von 0.4.0 wurden am 19.10.2026 in 0.4.0-alpha.1 im Spiel getestet, ohne Lua-Fehler;
überlappende Knopftexte im Tab „Craft“ wurden in 0.4.0-alpha.2 behoben und im Spiel bestätigt. Die
Version 0.4.0 unterscheidet sich von 0.4.0-alpha.2 nur in Versionsnummer und Dokumentation.

Der Ratgeber (0.7.0) wurde am 19.10.2026 in 0.7.0-alpha.1 bis 0.7.0-alpha.6 in Classic Era im Spiel
getestet, ohne Lua-Fehler.

Der Reiter „Berufe“ (0.8.0-alpha.1) ist **nur außerhalb des Spiels geprüft; kein echter In-Game-Test
durchgeführt** (315 automatische Prüfungen, davon 14 neue Tests für Berufe, Gruppen, Filter, Suche,
Kosten und den Reiter).

**Nicht in Forever getestet.**

## Version

0.8.0-alpha.1 – siehe [CHANGELOG.md](CHANGELOG.md).

## Lizenz

MIT, siehe [LICENSE](LICENSE).
