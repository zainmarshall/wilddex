import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'data/app_data.dart';
import 'data/app_data_store.dart'
    if (dart.library.html) 'data/app_data_store_web.dart' as store;
import 'models/park.dart';

Future<AppData> loadAppData() async {
  if (kIsWeb) {
    return _loadFromAssetsOnly();
  }
  return store.AppDataStore.loadAppData();
}

/// Web fallback: load directly from JSON assets (no Isar).
Future<AppData> _loadFromAssetsOnly() async {
  const speciesAsset = 'assets/data/species_normalized.json';
  const taxaAsset = 'assets/data/taxa_normalized.json';
  const parksAsset = 'assets/data/parks.json';

  final results = await Future.wait([
    rootBundle.loadString(speciesAsset),
    rootBundle.loadString(taxaAsset),
  ]);

  final speciesData = jsonDecode(results[0]) as List;
  final taxaData = jsonDecode(results[1]) as List;

  List<Park> parksList = const [];
  try {
    final raw = await rootBundle.loadString(parksAsset);
    final decoded = jsonDecode(raw);
    final list = decoded is Map ? decoded['parks'] : decoded;
    if (list is List) {
      parksList = list
          .whereType<Map<String, dynamic>>()
          .map((e) => Park.fromJson(e))
          .toList(growable: false);
    }
  } catch (_) {}

  return AppData.fromNormalizedJsonLists(speciesData, taxaData, parksList);
}
