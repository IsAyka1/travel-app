# Travel Atlas

A Flutter travel planner with four pages: Overview, Map, Places to visit, and Files.

## Features

- Add, edit, search, and mark places visited. Places are saved on the device.
- See saved places on an OpenStreetMap map. Long-press the map to add a place at that location. Map tiles require an internet connection.
- Import files from the device into the app's documents folder, then save copies back to a chosen device location. The file page works on Android, iOS, Windows, macOS, and Linux. The web build displays an unsupported message for local app file storage.
- Navigate from the sidebar on a wide screen or the drawer on a small screen.

## Run

```sh
flutter pub get
flutter run
```

Imported files are stored in the app documents directory under `travel_app/files`. File metadata is in `travel_app/files.json`; saved places use `shared_preferences`. Removing an imported file does not delete its original source file.
