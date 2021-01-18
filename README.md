# Custom-Report german-taxinvoice
Gnucash Custom Report, Deutsche Kundenrechung direkt aus Gnucash erstellen. [Gnucash](https://www.gnucash.org/) ist eine quelloffene Buchhaltungssoftware für Privatanwender und kleinere Unternehmen. Es ist unter Windows, Linux und MacOS lauffähig.

Der vorliegenende Report ist auf der Grundlage des Reports von Zelima, und chris [De/Kundenrechnung](https://wiki.gnucash.org/wiki/De/Kundenrechnung) und der von Gnucash enthaltenen taxinvoice.scm angepasst.

## Voraussetzungen
- [Gnucash](https://www.gnucash.org/) ab Version 4.2

## Installation
1. Für die Installation laden sie bitte die drei Dateien:

- [german-taxinvoice.scm](german-taxinvoice.scm)
- [german-taxinvoice.eguile.scm](german-taxinvoice.eguile.scm)

herunter und speichern sie diese Dateien in das Verzeichnis in [GNC_DATA_HOME](https://wiki.gnucash.org/wiki/Configuration_Locations#GNC_DATA_HOME) ab. In diesem Verzeichnis sucht schließlich Gnucash eigens gestaltete Guile/Scheme Dateien.

2. Bearbeiten sie nun im Verzeichnis [GNC_CONFIG_HOME](https://wiki.gnucash.org/wiki/Configuration_Locations#GNC_CONFIG_HOME) die Datei ```config-user.scm``` oder falls sie nicht exisitiert, legen sie diese an und fügen sie den folgenden Inhalt dieser Datei hinzu:
```
(load (gnc-build-userdata-path "german-taxinvoice.scm"))
```
GNC_DATA_HOME und GNC_CONFIG_HOME sind in unterschiedlichen Unterverzeichnissen des HOME-Verzeichnis/Profiles zu finden. Die Dateien in den Installationspfad von Gnucash oder Guile zu installieren ist nicht empfehlenswert, da bei Aktualisierungen diese wieder entfernt werden.

## Benutzung
Der Report ist dann unter unter Berichte -> Geschäft -> German Tax Invoice zu finden. Nach dem Aufruf muss dann eine Rechnung unter Optionen (aus der Werkzeugleiste ) -> Allgemein -> Rechnungsnummer -> Auswählen...

Weiterhin müssen die zusätzlichen Angaben noch eingegeben werden wie die Bankdaten usw. damit diese in die Rechnung mit eingefügt werden können.

**WICHTIG:** Da beim Schließen des Reports die Einstellungen (Bankdaten usw.) wieder verloren gehen, sollten sie diese Einstellungen mit dem 'Konf. speichern' sichern. Es befindet sich unter Berichte -> Gespeicherte Berichtsoptionen -> German Tax Invoice dann fest gespeicherte Konfigurationen die jederzeit wieder geladen werden können.

## Problemlösung
Für Fehler seitens der Guile/Scheme Reports kann ich nur eingeschränkt Support geben.

## License
This project is provided under the GNU General Public License v2. See [LICENSE](LICENSE).
