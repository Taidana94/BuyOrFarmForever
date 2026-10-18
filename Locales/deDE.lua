-- German strings (base language). Keys are stable English identifiers.
-- Placeholders: %1$s, %2$d ... by position (see Util.Format), so translations can reorder them.
local _, ns = ...

local L = ns.Locale.NewLocale("deDE")

-- General
L.ADDON_TITLE = "Kaufen oder farmen?"
L.CLIENT_CLASSIC_ERA = "Classic Era"
L.CLIENT_MISMATCH = "Diese Addon-Version ist nicht für diesen Spielclient gedacht und wurde nicht gestartet."
L.UNKNOWN_VALUE = "unbekannt"
L.NOT_READY = "Das Addon ist noch nicht fertig geladen. Bitte versuche es gleich noch einmal."

-- Slash commands
L.HELP_HEADER = "Befehle (statt /bof geht auch /kof):"
L.HELP_LINE_HELP = "/bof help – zeigt diese Hilfe"
L.HELP_LINE_VERSION = "/bof version – zeigt Addon-Version, Interface-Version und Build"
L.HELP_LINE_DEBUG = "/bof debug – schaltet den Debug-Modus ein oder aus"
L.HELP_LINE_RESET = "/bof reset – setzt die Einstellungen zurück (mit Bestätigung)"
L.UNKNOWN_COMMAND = "Unbekannter Befehl: „%1$s“. Eine Übersicht gibt es mit /bof help."
L.VERSION_LINE = "Version %1$s · Interface %2$s · Build %3$s (%4$s) · %5$s"
L.DEBUG_ON = "Debug-Modus ist an. Technische Meldungen erscheinen im Chat und werden gespeichert."
L.DEBUG_OFF = "Debug-Modus ist aus."
L.DEBUG_PREFIX = "[Debug]"
L.RESET_CONFIRM_PROMPT = "Alle Einstellungen werden auf die Standardwerte gesetzt. Ziele, Preise und Messungen bleiben erhalten. Zum Bestätigen innerhalb von %1$d Sekunden „/bof reset confirm“ eingeben."
L.RESET_DONE = "Die Einstellungen wurden zurückgesetzt."
L.RESET_NOT_PENDING = "Es wartet kein Zurücksetzen auf Bestätigung. Gib zuerst „/bof reset“ ein."
L.READ_ONLY_REFUSED = "Nicht möglich: Die gespeicherten Daten stammen aus einer neueren Addon-Version und werden nicht verändert."

-- Material goals (provisional chat commands)
L.HELP_LINE_GOAL = "/bof goal – Materialziele anlegen und bearbeiten (vorläufig, bis das Fenster fertig ist)"
L.HELP_LINE_STOCK = "/bof stock [all] – Bedarf, Bestand und Fehlmenge des ausgewählten Ziels bzw. aller Ziele"
L.GOAL_USAGE = "Ziele: /bof goal new <Name> | list | select <Nr.> | add <Gegenstand> [Menge] | set <Gegenstand> <Menge> | remove <Gegenstand> | crafts <Anzahl> | delete <Nr.>"
L.GOAL_UNNAMED = "ohne Namen"
L.GOAL_CREATED = "Ziel %1$d „%2$s“ angelegt und ausgewählt."
L.GOAL_SELECTED = "Ziel %1$d „%2$s“ ausgewählt."
L.GOAL_NOT_FOUND = "Es gibt kein Ziel mit der Nummer „%1$s“."
L.GOAL_NONE_ACTIVE = "Kein Ziel ausgewählt. Lege eines an mit /bof goal new <Name> oder wähle eines mit /bof goal select <Nr.>."
L.GOAL_LIST_EMPTY = "Noch keine Ziele. Lege eines an mit /bof goal new <Name>."
L.GOAL_LIST_HEADER = "Deine Ziele (* = ausgewählt):"
L.GOAL_LIST_LINE = "%1$s%2$d: „%3$s“ – %4$d Zutaten, %5$d× herstellen"
L.GOAL_HEADER = "Ziel %1$d „%2$s“ (%3$d× herstellen):"
L.GOAL_ITEM_ADDED = "%1$s: jetzt %2$d pro Herstellung."
L.GOAL_ITEM_REMOVED = "%1$s wurde aus dem Ziel entfernt."
L.GOAL_ITEM_NOT_IN_GOAL = "%1$s ist nicht in diesem Ziel."
L.GOAL_CRAFTS_SET = "Anzahl Herstellungen: %1$d."
L.GOAL_DELETE_CONFIRM = "Ziel %1$d „%2$s“ wirklich löschen? Dann „/bof goal delete %1$d confirm“ eingeben."
L.GOAL_DELETED = "Ziel %1$d wurde gelöscht."
L.ERR_INVALID_ITEM = "Bitte einen Gegenstand angeben: Gegenstandslink (Umschalt+Klick) oder Item-ID."
L.ERR_INVALID_COUNT = "Die Menge muss eine ganze Zahl von 1 bis %1$d sein."
L.ERR_TOO_MANY = "Mehr als %1$d Stück pro Zutat sind nicht möglich."
L.ERR_INVALID_CRAFTS = "Die Anzahl Herstellungen muss eine ganze Zahl von 1 bis %1$d sein."
L.ITEM_UNKNOWN = "Gegenstand %1$d"
L.UNKNOWN_SHORT = "?"

-- Stock
L.STOCK_ALL_HEADER = "Alle Ziele zusammen:"
L.STOCK_EMPTY = "Das Ziel enthält noch keine Zutaten. Füge welche hinzu mit /bof goal add <Gegenstand> <Menge>."
L.STOCK_LINE = "%1$s: benötigt %2$d, Taschen %3$d, Bank %4$s – fehlt %5$d"
L.STOCK_LINE_DONE = "%1$s: benötigt %2$d, Taschen %3$d, Bank %4$s – vollständig"
L.STOCK_BANK_SNAPSHOT = "    Bank beim letzten Besuch (%2$s): %1$s"
L.STOCK_BANK_NEVER = "    Bank seit Anlegen des Ziels noch nicht besucht."

-- Time
L.AGE_NOW = "gerade eben"
L.AGE_MINUTES = "vor %1$d Min."
L.AGE_HOURS = "vor %1$d Std."
L.AGE_DAY = "vor 1 Tag"
L.AGE_DAYS = "vor %1$d Tagen"

-- Saved data
L.DB_NEWER_SCHEMA = "Die gespeicherten Daten stammen aus einer neueren Addon-Version. Das Addon verändert sie nicht, bis du es aktualisierst."
L.DB_MIGRATION_FAILED = "Die gespeicherten Daten konnten nicht auf das neue Format umgestellt werden. Sie bleiben unverändert, das Addon arbeitet nur lesend."
L.DB_REPAIRED = "%1$d gespeicherte Werte waren ungültig und wurden auf Standardwerte gesetzt."
