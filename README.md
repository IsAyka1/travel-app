# Travel Atlas

A Flutter travel planner with six pages: Overview, Map, Calendar, Files, Visa, and Share trips.

## Features

- Add, edit, search, and mark places visited. Every Add place dialog can search the map, select a result to fill its name and coordinates, and set an optional visit date before saving. Use the calendar to see planned places for each day, edit their details, change their visited status, or open them on the map. Places are saved on the device.
- Expand a calendar day to plan trip actions. Each action can have an optional time, linked saved place, reservation status (none, needed, or confirmed), and file attachment. Check actions off as done, edit them, postpone them to another day, or delete them. Attachments use files imported into the app.
- Search for cities, addresses, and landmarks on the OpenStreetMap map. Select a result to center the map, then save it as a place on the Calendar page. You can also long-press the map to add a place at that location. Map tiles and search require an internet connection. Search uses the Photon public demo service, which is intended for modest use and has no uptime guarantee.
- Import files from the device into the app's documents folder, then save copies back to a chosen device location. The file page works on Android, iOS, Windows, macOS, and Linux. The web build displays an unsupported message for local app file storage.
- Navigate from the sidebar on a wide screen or the drawer on a small screen.

## Run

```sh
flutter pub get
flutter run
```

Imported files are stored in the app documents directory under `travel_app/files`. File metadata is in `travel_app/files.json`; saved places use `shared_preferences`. Removing an imported file does not delete its original source file.
