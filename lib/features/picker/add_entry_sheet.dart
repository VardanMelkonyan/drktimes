import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../domain/combination_key.dart';
import '../common/widgets.dart';

/// "Add a film / Add a developer" form (FR-015). Returns the new ref.
Future<T?> showAddEntrySheet<T extends Object>(
  BuildContext context, {
  required bool film,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.pal.s1,
    shape: const RoundedRectangleBorder(),
    builder: (_) => _AddEntrySheet<T>(film: film),
  );
}

class _AddEntrySheet<T extends Object> extends ConsumerStatefulWidget {
  const _AddEntrySheet({required this.film});

  final bool film;

  @override
  ConsumerState<_AddEntrySheet<T>> createState() => _AddEntrySheetState<T>();
}

class _AddEntrySheetState<T extends Object>
    extends ConsumerState<_AddEntrySheet<T>> {
  final _brand = TextEditingController();
  final _name = TextEditingController();
  final _iso = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _brand.dispose();
    _name.dispose();
    _iso.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(userCatalogRepositoryProvider);
    try {
      final Object ref_;
      if (widget.film) {
        final iso = int.tryParse(_iso.text.trim());
        if (iso == null) throw ArgumentError('Box ISO is a number, 1–25600.');
        final f = await repo.addFilm(
          brand: _brand.text,
          name: _name.text,
          boxIso: iso,
        );
        ref_ = FilmRef.user(f.id);
      } else {
        final d = await repo.addDeveloper(brand: _brand.text, name: _name.text);
        ref_ = DeveloperRef.user(d.id);
      }
      ref.read(dataVersionProvider.notifier).state++;
      if (mounted) Navigator.of(context).pop(ref_ as T);
    } on ArgumentError catch (e) {
      setState(() => _error = e.message?.toString() ?? 'Check the fields.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        24,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.film ? 'Add a film' : 'Add a developer',
            style: DrkType.dp.copyWith(color: context.pal.fg),
          ),
          const SizedBox(height: DrkSpace.s16),
          DrkField(
            key: const Key('add-brand'),
            controller: _brand,
            hint: 'Brand',
            autofocus: true,
          ),
          const SizedBox(height: DrkSpace.s12),
          DrkField(key: const Key('add-name'), controller: _name, hint: 'Name'),
          if (widget.film) ...[
            const SizedBox(height: DrkSpace.s12),
            DrkField(
              key: const Key('add-iso'),
              controller: _iso,
              hint: 'Box ISO, e.g. 400',
              keyboardType: TextInputType.number,
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: DrkSpace.s12),
            Text(_error!, style: DrkType.sm.copyWith(color: context.pal.fg)),
          ],
          const SizedBox(height: DrkSpace.s16),
          DrkButton(
            key: const Key('add-save'),
            label: 'Add',
            kind: DrkButtonKind.primary,
            size: DrkButtonSize.large,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
