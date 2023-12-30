;#ifndef _WRC_TEST_MESSAGES_H
;#define _WRC_TEST_MESSAGES_H
;

LanguageNames = (
	English = 0x0409:Messages_ENU
	German  = 0x0407:Messages_GER
)

;/* Eventlog categories (must be defined first) */

MessageId       = 1
SymbolicName    = CATEGORY_ONE
Severity        = Success
Language        = English
First category
.
Language        = German
Erster Kategorie
.

MessageId       = +1
SymbolicName    = CATEGORY_TWO
Severity        = Success
Language        = English
Second category
.
Language        = German
Zweiter Kategorie
.

;/* Events */

MessageId       = +1
SymbolicName    = EVENT_STARTED_BY
Language        = English
First event
.
Language        = German
Erster Ereignis
.

MessageId       = +1
SymbolicName    = EVENT_BACKUP
Language        = English
Second event with parameters %1 and %2
.
Language        = German
Zweiter Ereignis mit Parametern %1 und %2
.

;/* Additional messages */

MessageId       = 1000
SymbolicName    = IDS_ADDTIONAL_MESSAGE
Language        = English
Additional message
.
Language        = German
Zusätzliche Nachricht
.

;
;#endif  /* _WRC_TEST_MESSAGES_H */
;
