# StudiCockpit

Persönliches Studien-Cockpit für den B. Sc. Sportwissenschaft an der Ruhr-Universität Bochum (PO 2025): Studienfortschritt, Module nach Modulhandbuch, Studienverlauf, Stundenplan, Prüfungen und Termine.

Die App ist eine Progressive Web App ohne Server: Sie läuft im Browser, lässt sich auf Tablet und Handy installieren und funktioniert offline. Persönliche Daten liegen nur auf dem Gerät (Sicherung über „Daten & Sicherung“) und nicht in diesem Repository.

## Aufbau

- `src/app.html` – die App (Oberfläche, Logik und die Studiengangsdaten als JSON-Block `#studiengang`)
- `src/sw.template.js` – Service Worker für den Offline-Betrieb
- `build.js` – baut daraus `index.html` und `sw.js` (`node build.js`)
- `manifest.webmanifest`, `icons/` – App-Name und -Symbol

## Quellen der Studiengangsdaten

Modulhandbuch B. Sc. Sportwissenschaft (Stand 24.08.2026) und Prüfungsordnung 2025 (Amtliche Bekanntmachung Nr. 1707). Lücken im Modulhandbuch sind in der App als Hinweis markiert.
