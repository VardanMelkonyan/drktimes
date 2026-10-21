import 'package:drift/native.dart';
import 'package:drktimes/data/db/database.dart';
import 'package:drktimes/data/db/seed.dart';
import 'package:drktimes/data/repositories/process_repository.dart';
import 'package:drktimes/domain/clock.dart';
import 'package:drktimes/domain/process.dart';
import 'package:drktimes/domain/timeline/session_run.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProcessRepository repo;
  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await seedDatabase(db);
    repo = ProcessRepository(db);
  });
  tearDown(() => db.close());

  test('gets and saves the default process', () async {
    final p = await repo.get(Process.defaultId);
    expect(p.toJson(), Process.defaults().toJson());
    final changed = p.copyWith(
      steps: [
        for (final s in p.steps)
          s.kind == StepKind.fix ? s.copyWith(durationS: 420) : s,
      ],
    );
    await repo.save(changed);
    final again = await repo.get(Process.defaultId);
    expect(
      again.steps.firstWhere((s) => s.kind == StepKind.fix).durationS,
      420,
    );
  });

  test('refuses to save an invalid process', () async {
    final p = Process.defaults();
    expect(
      () => repo.save(
        p.copyWith(
          steps: [for (final s in p.steps) s.copyWith(enabled: false)],
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => repo.save(
        p.copyWith(
          steps: p.steps.where((s) => s.kind != StepKind.developer).toList(),
        ),
      ),
      throwsArgumentError,
    );
  });

  test('an unknown id falls back to the default', () async {
    expect((await repo.get('nope')).id, Process.defaultId);
  });

  test('the default cannot be deleted; custom ones can', () async {
    await repo.save(Process.defaults().copyWith(id: 'mine'));
    await repo.delete('mine');
    await repo.delete(Process.defaultId);
    expect([for (final p in await repo.all()) p.id], [Process.defaultId]);
  });

  test('a session keeps its snapshot after the default is edited', () async {
    final clock = FakeClock();
    final run = SessionRun(
      id: 's',
      tankSlot: 1,
      process: await repo.get(Process.defaultId),
      devTimeS: 780,
      inversionPaceS: 2,
    )..start(clock.now());
    final before = run.process.toJson();
    final p = await repo.get(Process.defaultId);
    await repo.save(
      p.copyWith(
        steps: [
          for (final s in p.steps)
            s.kind == StepKind.stop ? s.copyWith(durationS: 5) : s,
        ],
      ),
    );
    expect(run.process.toJson(), before);
    expect(SessionRun.fromJson(run.toJson()).process.toJson(), before);
  });
}
