import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/community/community_repository.dart';
import '../common/widgets.dart';

/// Where community times are read from and, for a Supabase project, sent to
/// (spec 002, US4). Removing a source removes its cached times.
class CommunitySourcesScreen extends ConsumerStatefulWidget {
  const CommunitySourcesScreen({super.key});

  @override
  ConsumerState<CommunitySourcesScreen> createState() => _State();
}

class _State extends ConsumerState<CommunitySourcesScreen> {
  final _name = TextEditingController();
  final _url = TextEditingController();
  final _key = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await ref
        .read(communitySyncProvider)
        .addSource(name: _name.text, url: _url.text, publicKey: _key.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
    if (err == null) {
      _name.clear();
      _url.clear();
      _key.clear();
      ref.read(dataVersionProvider.notifier).state++;
    }
  }

  Future<void> _remove(SourceConfig s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Remove ${s.name}?'),
        content: const Text(
          'Its community times are removed from this phone. Times you already shared stay shared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('confirm-remove'),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(communityRepositoryProvider).removeSource(s.id);
    ref.read(dataVersionProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final sources = ref.watch(communitySourcesProvider).value ?? const [];
    final repo = ref.read(communityRepositoryProvider);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: DrkSpace.s20),
          children: [
            SizedBox(
              height: 44,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.canPop()
                        ? context.pop()
                        : context.go('/settings'),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  Text(
                    'COMMUNITY SOURCES',
                    style: labelStyle(context, fg: true),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (sources.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'No sources. The app works fully without them and makes no network requests for community times.',
                  key: const Key('no-sources'),
                  style: DrkType.sm.copyWith(color: p.mut),
                ),
              ),
            for (final s in sources)
              Container(
                key: Key('source-${s.id}'),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: p.ln2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            s.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          key: Key('remove-${s.id}'),
                          tooltip: 'Remove ${s.name}',
                          onPressed: () => _remove(s),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                    Text(
                      '${s.kind == SourceKind.supabase ? 'Project' : 'Read-only feed'} · ${s.url}',
                      style: DrkType.sm.copyWith(color: p.mut),
                    ),
                    if (s.kind == SourceKind.supabase)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            const Expanded(child: Text('Share my times here')),
                            DrkSwitch(
                              key: Key('share-to-${s.id}'),
                              value: s.shareTo,
                              label: 'Share my times to ${s.name}',
                              onChanged: (v) => repo.setShareTo(s.id, v),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 22),
            SectionLabel('Add a source', bottom: 10),
            Text(
              'A feed address, or a project address with its public key.',
              style: DrkType.sm.copyWith(color: p.mut),
            ),
            DrkField(
              key: const Key('source-name'),
              controller: _name,
              hint: 'Name',
            ),
            DrkField(
              key: const Key('source-url'),
              controller: _url,
              hint: 'https://…',
              keyboardType: TextInputType.url,
            ),
            DrkField(
              key: const Key('source-key'),
              controller: _key,
              hint: 'Public key (projects only)',
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  key: const Key('source-error'),
                  style: DrkType.sm.copyWith(color: p.fg),
                ),
              ),
            const SizedBox(height: 12),
            DrkButton(
              key: const Key('add-source'),
              label: _busy ? 'Checking…' : 'Add',
              onPressed: _busy ? null : _add,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
