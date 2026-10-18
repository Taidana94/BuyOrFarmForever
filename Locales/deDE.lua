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

-- Saved data
L.DB_NEWER_SCHEMA = "Die gespeicherten Daten stammen aus einer neueren Addon-Version. Das Addon verändert sie nicht, bis du es aktualisierst."
L.DB_MIGRATION_FAILED = "Die gespeicherten Daten konnten nicht auf das neue Format umgestellt werden. Sie bleiben unverändert, das Addon arbeitet nur lesend."
L.DB_REPAIRED = "%1$d gespeicherte Werte waren ungültig und wurden auf Standardwerte gesetzt."
