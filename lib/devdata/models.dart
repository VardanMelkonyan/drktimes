void checkKeys(Map<String, dynamic> json, Set<String> allowed, String where) {
  final unknown = json.keys.where((k) => !allowed.contains(k)).toList();
  if (unknown.isNotEmpty) {
    throw FormatException('$where: unknown key(s) ${unknown.join(', ')}');
  }
}

List<String> _strings(Object? value) =>
    value == null ? const [] : List<String>.from(value as List);

class Film {
  const Film({
    required this.id,
    required this.brand,
    required this.name,
    required this.iso,
    required this.process,
    required this.spectral,
    required this.formats,
    required this.status,
    this.aliases = const [],
    this.rebrandOf,
    this.rebrandBasis,
    this.datasheetLead,
    this.verifiedBy,
    this.notes,
  });

  factory Film.fromJson(Map<String, dynamic> json) {
    checkKeys(json, _keys, 'film ${json['id']}');
    return Film(
      id: json['id'] as String,
      brand: json['brand'] as String,
      name: json['name'] as String,
      iso: json['iso'] as num,
      process: json['process'] as String,
      spectral: json['spectral'] as String,
      formats: List<String>.from(json['formats'] as List),
      status: json['status'] as String,
      aliases: _strings(json['aliases']),
      rebrandOf: json['rebrand_of'] as String?,
      rebrandBasis: json['rebrand_basis'] as String?,
      datasheetLead: json['datasheet_lead'] as String?,
      verifiedBy: json['verified_by'] as String?,
      notes: json['notes'] as String?,
    );
  }

  static const _keys = {
    'id', 'brand', 'name', 'iso', 'process', 'spectral', 'formats', 'status',
    'aliases', 'rebrand_of', 'rebrand_basis', 'datasheet_lead', 'verified_by',
    'notes',
  };

  final String id, brand, name, process, spectral, status;
  final num iso;
  final List<String> formats, aliases;
  final String? rebrandOf, rebrandBasis, datasheetLead, verifiedBy, notes;
}

class Developer {
  const Developer({
    required this.id,
    required this.brand,
    required this.name,
    this.aliases = const [],
    this.notes,
  });

  factory Developer.fromJson(Map<String, dynamic> json) {
    checkKeys(json, _keys, 'developer ${json['id']}');
    return Developer(
      id: json['id'] as String,
      brand: json['brand'] as String,
      name: json['name'] as String,
      aliases: _strings(json['aliases']),
      notes: json['notes'] as String?,
    );
  }

  static const _keys = {'id', 'brand', 'name', 'aliases', 'notes'};

  final String id, brand, name;
  final List<String> aliases;
  final String? notes;
}

class Source {
  const Source({
    required this.id,
    required this.kind,
    required this.publisher,
    required this.title,
    this.docCode,
    this.edition,
    this.url,
    this.retrieved,
    this.sha256,
    this.permissionRef,
    this.contributor,
    this.notes,
  });

  factory Source.fromJson(Map<String, dynamic> json) {
    checkKeys(json, _keys, 'source ${json['id']}');
    return Source(
      id: json['id'] as String,
      kind: json['kind'] as String,
      publisher: json['publisher'] as String,
      title: json['title'] as String,
      docCode: json['doc_code'] as String?,
      edition: json['edition'] as String?,
      url: json['url'] as String?,
      retrieved: json['retrieved'] as String?,
      sha256: json['sha256'] as String?,
      permissionRef: json['permission_ref'] as String?,
      contributor: json['contributor'] as String?,
      notes: json['notes'] as String?,
    );
  }

  static const _keys = {
    'id', 'kind', 'publisher', 'title', 'doc_code', 'edition', 'url',
    'retrieved', 'sha256', 'permission_ref', 'contributor', 'notes',
  };

  final String id, kind, publisher, title;
  final String? docCode, edition, url, retrieved, sha256, permissionRef,
      contributor, notes;
}

class DevTime {
  const DevTime({
    required this.filmId,
    required this.developerId,
    required this.dilution,
    required this.ei,
    required this.tempC,
    required this.timeS,
    required this.method,
    required this.sourceId,
    this.timeMaxS,
    this.page,
    this.agitation,
    this.notes,
  });

  factory DevTime.fromJson(Map<String, dynamic> json, String sourceId) {
    checkKeys(json, _keys, 'time ${json['film_id']}/${json['developer_id']}');
    return DevTime(
      filmId: json['film_id'] as String,
      developerId: json['developer_id'] as String,
      dilution: json['dilution'] as String,
      ei: json['ei'] as num,
      tempC: json['temp_c'] as num,
      timeS: json['time_s'] as int,
      timeMaxS: json['time_max_s'] as int?,
      method: json['method'] as String,
      page: json['page'] as int?,
      agitation: json['agitation'] as String?,
      notes: json['notes'] as String?,
      sourceId: sourceId,
    );
  }

  static const _keys = {
    'film_id', 'developer_id', 'dilution', 'ei', 'temp_c', 'time_s',
    'time_max_s', 'method', 'page', 'agitation', 'notes',
  };

  final String filmId, developerId, dilution, method, sourceId;
  final num ei, tempC;
  final int timeS;
  final int? timeMaxS, page;
  final String? agitation, notes;
}

class Dataset {
  const Dataset({
    required this.films,
    required this.developers,
    required this.sources,
    required this.times,
  });

  final List<Film> films;
  final List<Developer> developers;
  final List<Source> sources;
  final List<DevTime> times;
}
