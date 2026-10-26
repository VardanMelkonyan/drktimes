import 'package:drktimes/domain/combination_key.dart';
import 'package:drktimes/domain/community/eligibility.dart';
import 'package:flutter_test/flutter_test.dart';

final catalogKey = CombinationKey(
  film: const FilmRef.catalog('tri-x'),
  developer: const DeveloperRef.catalog('d76'),
  dilution: 'stock',
  ei: 400,
  tempC: 20,
);

void main() {
  bool own(String id) => id == 'mine';

  var base = {
    'status': 'completed',
    'timeSource': <String, dynamic>{'kind': 'recipe', 'recipe_id': 'mine'},
    'devTimeS': 600,
  };

  eligible({
    String? status,
    Map<String, dynamic>? source,
    int? time,
    CombinationKey? key,
    bool noKey = false,
  }) => eligibleSubmission(
    status: status ?? base['status'] as String,
    timeSource: source ?? base['timeSource'] as Map<String, dynamic>,
    devTimeS: time ?? base['devTimeS'] as int,
    key: noKey ? null : (key ?? catalogKey),
    isOwnRecipe: own,
  );

  test(
    'a completed run of an own recipe is eligible, with the session time',
    () {
      expect(eligible()!.timeS, 600);
    },
  );

  test('aborted, active, manual and datasheet starts are not', () {
    expect(eligible(status: 'aborted'), isNull);
    expect(eligible(status: 'active'), isNull);
    expect(eligible(source: {'kind': 'manual'}), isNull);
    expect(eligible(source: {'kind': 'datasheet', 'source_id': 's'}), isNull);
    expect(eligible(source: {'kind': 'community', 'source_id': 's'}), isNull);
    expect(eligible(noKey: true), isNull);
  });

  test('received recipes and unknown recipes are not', () {
    expect(
      eligible(source: {'kind': 'recipe', 'recipe_id': 'received'}),
      isNull,
    );
    expect(eligible(source: {'kind': 'recipe'}), isNull);
  });

  test('user-added film or developer, and implausible times, are not', () {
    expect(
      eligible(
        key: CombinationKey(
          film: const FilmRef.user('u'),
          developer: const DeveloperRef.catalog('d76'),
          dilution: 'stock',
          ei: 400,
          tempC: 20,
        ),
      ),
      isNull,
    );
    expect(eligible(time: 5), isNull);
    expect(eligible(time: 20000), isNull);
  });
}
