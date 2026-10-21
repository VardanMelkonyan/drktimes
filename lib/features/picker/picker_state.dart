import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/combination_key.dart';

/// The four-step picker's selections so far.
class PickerState {
  const PickerState({
    this.film,
    this.developer,
    this.ei,
    this.dilution,
    this.tempC = 20,
  });

  final FilmRef? film;
  final DeveloperRef? developer;
  final int? ei;
  final String? dilution;
  final int tempC;

  PickerState copyWith({
    FilmRef? film,
    DeveloperRef? developer,
    int? ei,
    String? dilution,
    int? tempC,
    bool clearDeveloper = false,
    bool clearEi = false,
    bool clearDilution = false,
  }) => PickerState(
    film: film ?? this.film,
    developer: clearDeveloper ? null : (developer ?? this.developer),
    ei: clearEi ? null : (ei ?? this.ei),
    dilution: clearDilution ? null : (dilution ?? this.dilution),
    tempC: tempC ?? this.tempC,
  );

  CombinationKey? get key {
    if (film == null || developer == null || ei == null || dilution == null) {
      return null;
    }
    return CombinationKey(
      film: film!,
      developer: developer!,
      dilution: dilution!,
      ei: ei!,
      tempC: tempC,
    );
  }
}

class PickerNotifier extends Notifier<PickerState> {
  @override
  PickerState build() => const PickerState();

  void reset() => state = const PickerState();

  /// Picks the film. A developer chosen earlier (from search) is kept.
  void pickFilm(FilmRef film) =>
      state = PickerState(film: film, developer: state.developer);

  /// Starts the picker from a developer found by search; the film comes next.
  void startWithDeveloper(DeveloperRef dev) =>
      state = PickerState(developer: dev);

  void pickDeveloper(DeveloperRef dev) =>
      state = PickerState(film: state.film, developer: dev);

  void pickEi(int ei) =>
      state = PickerState(film: state.film, developer: state.developer, ei: ei);

  void pickDilution(String dilution, {int? tempC}) =>
      state = state.copyWith(dilution: dilution, tempC: tempC);

  void setTemp(int tempC) => state = state.copyWith(tempC: tempC);

  /// Starts the picker from a known film (search result).
  void startFrom(FilmRef film) => state = PickerState(film: film);
}

final pickerProvider = NotifierProvider<PickerNotifier, PickerState>(
  PickerNotifier.new,
);

/// `/combo/:key` carries the key as URL-safe base64 of its JSON.
String comboPath(CombinationKey key) =>
    '/combo/${base64Url.encode(utf8.encode(jsonEncode(key.toJson())))}';

CombinationKey comboKeyFromParam(String param) => CombinationKey.fromJson(
  jsonDecode(utf8.decode(base64Url.decode(param))) as Map<String, dynamic>,
);
