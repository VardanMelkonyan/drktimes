# drktimes

A film development timer for the darkroom. Look up a developing time, run the
whole process by sound and screen (agitation metronome, dump & pour, washes),
keep your own recipes and notes, and share them without an account or server.
Everything stays on the phone. Develop mode is built; Print mode is a
placeholder.

## Build

```sh
export PATH=$PATH:$HOME/development/flutter/bin   # Flutter 3.47.4
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter test
flutter run
```

- Android emulator: `export ANDROID_AVD_HOME=$HOME/.config/.android/avd`, JDK 21.
- iOS builds run on GitHub Actions (`.github/workflows/ios-testflight.yml`).
- Rebuild the bundled dataset after editing `resources/devdata`:
  `dart run tool/build_dataset.dart`.

## Licence

Code: MIT (`LICENSE`). Dataset in `resources/devdata`: CC0. User content
(recipes, notes) is never part of the dataset.

## More

- `specs/001-film-develop-timer/`: spec, plan, tasks
- `design/`: the visual design
- `resources/devdata/README.md`: the dataset and its sources
- `site/README.md`: the static share-link site
