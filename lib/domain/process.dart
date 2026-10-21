enum TransitionMode {
  waitForMe('wait_for_me'),
  keepGoing('keep_going');

  const TransitionMode(this.json);
  final String json;
  static TransitionMode parse(String s) =>
      values.firstWhere((v) => v.json == s);
}

enum StepKind {
  presoak('presoak'),
  developer('developer'),
  stop('stop'),
  fix('fix'),
  hypoClear('hypo_clear'),
  wash('wash'),
  wettingAgent('wetting_agent'),
  custom('custom');

  const StepKind(this.json);
  final String json;
  static StepKind parse(String s) => values.firstWhere((v) => v.json == s);
}

sealed class AgitationPattern {
  const AgitationPattern();

  factory AgitationPattern.fromJson(Map<String, dynamic> json) {
    switch (json['type'] as String) {
      case 'intermittent':
        return Intermittent(
          initialS: json['initial_s'] as int,
          everyS: json['every_s'] as int,
          burstS: json['burst_s'] as int,
        );
      case 'continuous':
        return const Continuous();
      case 'stand':
        return Stand(
          initialS: json['initial_s'] as int,
          midAgitationAtS: json['mid_agitation_at_s'] as int?,
          midBurstS: json['mid_burst_s'] as int?,
        );
      case 'none':
        return const NoAgitation();
    }
    throw FormatException('unknown agitation type ${json['type']}');
  }

  Map<String, dynamic> toJson();

  /// Problems with this pattern, empty when valid.
  List<String> validate() => const [];
}

class Intermittent extends AgitationPattern {
  const Intermittent({
    required this.initialS,
    required this.everyS,
    required this.burstS,
  });

  final int initialS, everyS, burstS;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'intermittent',
    'initial_s': initialS,
    'every_s': everyS,
    'burst_s': burstS,
  };

  @override
  List<String> validate() => [
    if (initialS < 0) 'initial agitation cannot be negative',
    if (everyS < 1) 'agitation interval must be at least 1 s',
    if (burstS < 1) 'agitation burst must be at least 1 s',
    if (burstS >= everyS) 'burst must be shorter than the interval',
  ];

  @override
  bool operator ==(Object other) =>
      other is Intermittent &&
      other.initialS == initialS &&
      other.everyS == everyS &&
      other.burstS == burstS;

  @override
  int get hashCode => Object.hash(initialS, everyS, burstS);
}

class Continuous extends AgitationPattern {
  const Continuous();

  @override
  Map<String, dynamic> toJson() => {'type': 'continuous'};

  @override
  bool operator ==(Object other) => other is Continuous;

  @override
  int get hashCode => 1;
}

class Stand extends AgitationPattern {
  const Stand({required this.initialS, this.midAgitationAtS, this.midBurstS});

  final int initialS;
  final int? midAgitationAtS, midBurstS;

  @override
  Map<String, dynamic> toJson() => {
    'type': 'stand',
    'initial_s': initialS,
    if (midAgitationAtS != null) 'mid_agitation_at_s': midAgitationAtS,
    if (midBurstS != null) 'mid_burst_s': midBurstS,
  };

  @override
  List<String> validate() => [
    if (initialS < 0) 'initial agitation cannot be negative',
    if (midAgitationAtS != null && midAgitationAtS! < 1)
      'mid-stand agitation time must be at least 1 s',
    if (midBurstS != null && midBurstS! < 1)
      'mid-stand burst must be at least 1 s',
  ];

  @override
  bool operator ==(Object other) =>
      other is Stand &&
      other.initialS == initialS &&
      other.midAgitationAtS == midAgitationAtS &&
      other.midBurstS == midBurstS;

  @override
  int get hashCode => Object.hash(initialS, midAgitationAtS, midBurstS);
}

class NoAgitation extends AgitationPattern {
  const NoAgitation();

  @override
  Map<String, dynamic> toJson() => {'type': 'none'};

  @override
  bool operator ==(Object other) => other is NoAgitation;

  @override
  int get hashCode => 2;
}

sealed class WashMethod {
  const WashMethod();

  factory WashMethod.fromJson(Map<String, dynamic> json) {
    switch (json['method'] as String) {
      case 'running':
        return RunningWash(json['duration_s'] as int);
      case 'ilford':
        return IlfordWash(List<int>.from(json['fills'] as List));
    }
    throw FormatException('unknown wash method ${json['method']}');
  }

  Map<String, dynamic> toJson();

  List<String> validate() => const [];
}

class RunningWash extends WashMethod {
  const RunningWash([this.durationS = 600]);

  final int durationS;

  @override
  Map<String, dynamic> toJson() => {
    'method': 'running',
    'duration_s': durationS,
  };

  @override
  List<String> validate() => [
    if (durationS < 1) 'wash time must be at least 1 s',
  ];

  @override
  bool operator ==(Object other) =>
      other is RunningWash && other.durationS == durationS;

  @override
  int get hashCode => durationS.hashCode;
}

class IlfordWash extends WashMethod {
  const IlfordWash([this.fills = const [5, 10, 20]]);

  /// Counted inversions for each fill.
  final List<int> fills;

  @override
  Map<String, dynamic> toJson() => {'method': 'ilford', 'fills': fills};

  @override
  List<String> validate() => [
    if (fills.isEmpty) 'at least one fill is needed',
    if (fills.any((f) => f < 1 || f > 50)) 'each fill must be 1–50 inversions',
  ];

  @override
  bool operator ==(Object other) =>
      other is IlfordWash &&
      other.fills.length == fills.length &&
      Iterable<int>.generate(fills.length)
          .every((i) => fills[i] == other.fills[i]);

  @override
  int get hashCode => Object.hashAll(fills);
}

class Step {
  const Step({
    required this.id,
    required this.kind,
    required this.name,
    required this.enabled,
    required this.agitation,
    this.durationS = 60,
    this.howTo,
    this.wash,
    this.chemicalDilution,
  });

  factory Step.fromJson(Map<String, dynamic> json) => Step(
    id: json['id'] as String,
    kind: StepKind.parse(json['kind'] as String),
    name: json['name'] as String,
    enabled: json['enabled'] as bool,
    durationS: json['duration_s'] as int? ?? 60,
    agitation: AgitationPattern.fromJson(
      json['agitation'] as Map<String, dynamic>,
    ),
    howTo: json['how_to'] as String?,
    wash: json['wash'] == null
        ? null
        : WashMethod.fromJson(json['wash'] as Map<String, dynamic>),
    chemicalDilution: json['chemical_dilution'] as String?,
  );

  final String id;
  final StepKind kind;
  final String name;
  final bool enabled;

  /// Ignored for `developer` (it comes from the recipe) and for an Ilford wash.
  final int durationS;
  final AgitationPattern agitation;
  final String? howTo;
  final WashMethod? wash;
  final String? chemicalDilution;

  Step copyWith({
    String? id,
    String? name,
    bool? enabled,
    int? durationS,
    AgitationPattern? agitation,
    String? howTo,
    WashMethod? wash,
    String? chemicalDilution,
  }) => Step(
    id: id ?? this.id,
    kind: kind,
    name: name ?? this.name,
    enabled: enabled ?? this.enabled,
    durationS: durationS ?? this.durationS,
    agitation: agitation ?? this.agitation,
    howTo: howTo ?? this.howTo,
    wash: wash ?? this.wash,
    chemicalDilution: chemicalDilution ?? this.chemicalDilution,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.json,
    'name': name,
    'enabled': enabled,
    'duration_s': durationS,
    'agitation': agitation.toJson(),
    if (howTo != null) 'how_to': howTo,
    if (wash != null) 'wash': wash!.toJson(),
    if (chemicalDilution != null) 'chemical_dilution': chemicalDilution,
  };

  List<String> validate() => [
    if (name.isEmpty || name.length > 40) '$id: name must be 1–40 characters',
    if (howTo != null && howTo!.length > 1000)
      '$id: how-to is limited to 1000 characters',
    if (kind != StepKind.developer && wash == null && durationS < 1)
      '$id: duration must be at least 1 s',
    ...agitation.validate(),
    ...?wash?.validate(),
  ];
}

class Process {
  const Process({
    required this.id,
    required this.steps,
    this.transitionMode = TransitionMode.waitForMe,
  });

  factory Process.fromJson(Map<String, dynamic> json) => Process(
    id: json['id'] as String,
    steps: [
      for (final s in json['steps'] as List)
        Step.fromJson(s as Map<String, dynamic>),
    ],
    transitionMode: TransitionMode.parse(json['transition_mode'] as String),
  );

  /// The seeded default (FR-031); id is fixed to [defaultId].
  factory Process.defaults() => const Process(
    id: defaultId,
    steps: [
      Step(
        id: '00000000-0000-4000-8000-000000000001',
        kind: StepKind.presoak,
        name: 'Pre-soak',
        enabled: false,
        durationS: 60,
        agitation: Stand(initialS: 30),
        howTo: 'Fill with water at the same temperature as the developer.',
      ),
      Step(
        id: '00000000-0000-4000-8000-000000000002',
        kind: StepKind.developer,
        name: 'Developer',
        enabled: true,
        agitation: Intermittent(initialS: 60, everyS: 60, burstS: 10),
      ),
      Step(
        id: '00000000-0000-4000-8000-000000000003',
        kind: StepKind.stop,
        name: 'Stop',
        enabled: true,
        durationS: 60,
        agitation: Intermittent(initialS: 60, everyS: 60, burstS: 10),
      ),
      Step(
        id: '00000000-0000-4000-8000-000000000004',
        kind: StepKind.fix,
        name: 'Fixer',
        enabled: true,
        durationS: 300,
        agitation: Intermittent(initialS: 60, everyS: 60, burstS: 10),
      ),
      Step(
        id: '00000000-0000-4000-8000-000000000005',
        kind: StepKind.hypoClear,
        name: 'Hypo clear',
        enabled: false,
        durationS: 120,
        agitation: Intermittent(initialS: 30, everyS: 60, burstS: 10),
        howTo: 'Hypo clearing agent shortens the wash.',
      ),
      Step(
        id: '00000000-0000-4000-8000-000000000006',
        kind: StepKind.wash,
        name: 'Wash',
        enabled: true,
        agitation: NoAgitation(),
        wash: IlfordWash([5, 10, 20]),
      ),
      Step(
        id: '00000000-0000-4000-8000-000000000007',
        kind: StepKind.wettingAgent,
        name: 'Wetting agent',
        enabled: true,
        durationS: 30,
        agitation: NoAgitation(),
        howTo: 'Do not shake: the wetting agent will foam.',
      ),
    ],
  );

  static const defaultId = 'default';

  final String id;
  final List<Step> steps;
  final TransitionMode transitionMode;

  Iterable<Step> get enabledSteps => steps.where((s) => s.enabled);

  Process copyWith({
    String? id,
    List<Step>? steps,
    TransitionMode? transitionMode,
  }) => Process(
    id: id ?? this.id,
    steps: steps ?? this.steps,
    transitionMode: transitionMode ?? this.transitionMode,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'steps': [for (final s in steps) s.toJson()],
    'transition_mode': transitionMode.json,
  };

  /// Problems with this process, empty when valid.
  List<String> validate() => [
    if (steps.where((s) => s.kind == StepKind.developer).length != 1)
      'a process needs exactly one developer step',
    if (enabledSteps.isEmpty) 'at least one step must be enabled',
    for (final s in steps) ...s.validate(),
  ];
}
