import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'app_data.dart';
import 'isar_models.dart';
import '../models/park.dart';
import '../models/species.dart';
import '../models/taxa.dart';

class AppDataStore {
  static const _dataVersion = 1;
  static const _speciesAsset = 'assets/data/species_normalized.json';
  static const _taxaAsset = 'assets/data/taxa_normalized.json';
  static const _parksAsset = 'assets/data/parks.json';

  static Isar? _isar;

  static Future<AppData> loadAppData() async {
    final isar = await _openIsar();
    final needsSeed = await _needsSeed(isar);
    if (needsSeed) {
      final appData = await _loadFromAssets();
      await _seedIsar(isar, appData);
      return appData;
    }

    final taxaEntities = await isar.taxaEntitys.where().findAll();
    final speciesEntities = await isar.speciesEntitys.where().findAll();
    final parksList = await _loadParksFromAssets();
    return _fromEntities(speciesEntities, taxaEntities, parksList);
  }

  static Future<Isar> _openIsar() async {
    if (_isar != null) return _isar!;
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [SpeciesEntitySchema, TaxaEntitySchema, MetaEntitySchema],
      directory: dir.path,
      name: 'wilddex',
    );
    return _isar!;
  }

  static Future<bool> _needsSeed(Isar isar) async {
    final meta = await isar.metaEntitys
        .filter()
        .keyEqualTo('dataVersion')
        .findFirst();
    if (meta == null) return true;
    return meta.value != _dataVersion.toString();
  }

  static Future<AppData> _loadFromAssets() async {
    final speciesJsonString = await rootBundle.loadString(_speciesAsset);
    final taxaJsonString = await rootBundle.loadString(_taxaAsset);
    final parksList = await _loadParksFromAssets();

    final results = await Future.wait([
      compute(_decodeJsonList, speciesJsonString),
      compute(_decodeJsonList, taxaJsonString),
    ]);

    final speciesData = results[0];
    final taxaData = results[1];
    if (speciesData is! List || taxaData is! List) {
      throw Exception('Normalized JSON assets are invalid.');
    }
    return AppData.fromNormalizedJsonLists(speciesData, taxaData, parksList);
  }

  static Future<List<Park>> _loadParksFromAssets() async {
    try {
      final raw = await rootBundle.loadString(_parksAsset);
      final decoded = jsonDecode(raw);
      final list = decoded is Map ? decoded['parks'] : decoded;
      if (list is List) {
        return list
            .whereType<Map<String, dynamic>>()
            .map((e) => Park.fromJson(e))
            .toList(growable: false);
      }
    } catch (_) {}
    return const [];
  }

  static Future<void> _seedIsar(Isar isar, AppData appData) async {
    await isar.writeTxn(() async {
      await isar.clear();

      final taxaEntities = appData.taxaList.map((t) {
        final entity = TaxaEntity()
          ..taxonId = _taxonId(t.rank, t.name)
          ..rank = t.rank
          ..name = t.name
          ..commonName = t.commonName
          ..description = t.description;
        return entity;
      }).toList();
      await isar.taxaEntitys.putAll(taxaEntities);

      final taxaByKey = {
        for (final t in taxaEntities) _rankKey(t.rank, t.name): t.taxonId,
      };

      final speciesEntities = appData.speciesList.map((s) {
        final entity = SpeciesEntity()
          ..speciesId = s.id
          ..commonName = s.name
          ..scientificName = s.scientificName
          ..summary = s.description
          ..iucnStatus = s.iucnStatus
          ..kingdomId = taxaByKey[_rankKey('kingdom', s.classification?.kingdom)]
          ..phylumId = taxaByKey[_rankKey('phylum', s.classification?.phylum)]
          ..classId = taxaByKey[_rankKey('class', s.classification?.class_)]
          ..orderId = taxaByKey[_rankKey('order', s.classification?.order)]
          ..familyId = taxaByKey[_rankKey('family', s.classification?.family)]
          ..genusId = taxaByKey[_rankKey('genus', s.classification?.genus)]
          ..speciesTaxonId =
              taxaByKey[_rankKey('species', s.classification?.species)];
        return entity;
      }).toList();
      await isar.speciesEntitys.putAll(speciesEntities);

      final meta = MetaEntity()
        ..key = 'dataVersion'
        ..value = _dataVersion.toString();
      await isar.metaEntitys.put(meta);
    });
  }

  static String _taxonId(String rank, String name) {
    final slug = name.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return 'taxon:$rank:$slug';
  }

  static String _rankKey(String rank, String? name) {
    if (name == null) return '';
    return '${rank.toLowerCase()}|${name.toLowerCase()}';
  }
}

AppData _fromEntities(
  List<SpeciesEntity> speciesEntities,
  List<TaxaEntity> taxaEntities,
  List<Park> parksList,
) {
  final taxaList = taxaEntities
      .map((t) => Taxa(
            name: t.name,
            commonName: t.commonName ?? '',
            rank: t.rank,
            description: t.description ?? '',
          ))
      .toList(growable: false);
  final taxaById = {for (final t in taxaEntities) t.taxonId: t};

  String? taxonName(String? id) {
    if (id == null) return null;
    return taxaById[id]?.name;
  }

  final speciesList = speciesEntities
      .map((s) => Species(
            id: s.speciesId,
            name: s.commonName,
            scientificName: s.scientificName,
            description: s.summary,
            classification: Classification(
              kingdom: taxonName(s.kingdomId),
              phylum: taxonName(s.phylumId),
              class_: taxonName(s.classId),
              order: taxonName(s.orderId),
              family: taxonName(s.familyId),
              genus: taxonName(s.genusId),
              species: taxonName(s.speciesTaxonId),
            ),
            iucnStatus: s.iucnStatus,
          ))
      .toList(growable: false);

  return AppData.buildIndices(speciesList, taxaList, parksList: parksList);
}

List<dynamic> _decodeJsonList(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is List) {
    return decoded;
  }
  throw Exception('Expected a JSON list.');
}
