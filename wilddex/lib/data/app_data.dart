import '../models/species.dart';
import '../models/park.dart';
import '../models/taxa.dart';

class AppData {
  final List<Species> speciesList;
  final List<Taxa> taxaList;
  final List<Park> parksList;
  final Map<String, Park> parksById;
  final Map<String, Species> speciesById;
  final Map<String, Species> speciesByGenusSpecies;
  final Map<String, List<Species>> speciesByFamily;
  final Map<String, Taxa> taxaByRankName;
  final Map<String, List<Species>> speciesByRankValue;

  late final List<Species> coreSpeciesList =
      _buildCoreSpeciesList(speciesList);

  AppData({
    required this.speciesList,
    required this.taxaList,
    List<Park> parksList = const [],
    Map<String, Park>? parksById,
    required this.speciesById,
    required this.speciesByGenusSpecies,
    required this.speciesByFamily,
    required this.taxaByRankName,
    required this.speciesByRankValue,
  })  : parksList = parksList,
        parksById =
            parksById ?? {for (final park in parksList) park.id: park};

  static AppData fromJsonLists(
    List<dynamic> speciesJson,
    List<dynamic> taxaJson,
    List<Park> parksList,
  ) {
    final speciesList = speciesJson
        .map((e) => Species.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    final taxaList = taxaJson
        .map((e) => Taxa.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);

    final speciesById = <String, Species>{};
    final speciesByGenusSpecies = <String, Species>{};
    final speciesByFamily = <String, List<Species>>{};
    final speciesByRankValue = <String, List<Species>>{};

    for (final species in speciesList) {
      speciesById[species.id] = species;

      final genus = species.classification?.genus?.toLowerCase();
      final sp = species.classification?.species?.toLowerCase();
      if (genus != null && genus.isNotEmpty && sp != null && sp.isNotEmpty) {
        final key = '$genus|$sp';
        speciesByGenusSpecies.putIfAbsent(key, () => species);
      }

      final family =
          (species.classification?.familyName ?? 'Unknown Family').toLowerCase();
      speciesByFamily.putIfAbsent(family, () => []).add(species);

      void addRank(String rank, String? value) {
        final normalized = value?.toLowerCase();
        if (normalized == null || normalized.isEmpty) return;
        final key = '$rank|$normalized';
        speciesByRankValue.putIfAbsent(key, () => []).add(species);
      }

      addRank('kingdom', species.classification?.kingdom);
      addRank('phylum', species.classification?.phylum);
      addRank('class', species.classification?.class_);
      addRank('order', species.classification?.order);
      addRank('family', species.classification?.family);
      addRank('genus', species.classification?.genus);
      addRank('species', species.classification?.species);
    }

    final taxaByRankName = <String, Taxa>{};
    for (final taxa in taxaList) {
      final key = _rankKey(taxa.rank, taxa.name);
      taxaByRankName[key] = taxa;
      if (taxa.commonName.isNotEmpty) {
        taxaByRankName[_rankKey(taxa.rank, taxa.commonName)] = taxa;
      }
    }

    return AppData(
      speciesList: speciesList,
      taxaList: taxaList,
      parksList: parksList,
      speciesById: speciesById,
      speciesByGenusSpecies: speciesByGenusSpecies,
      speciesByFamily: speciesByFamily,
      taxaByRankName: taxaByRankName,
      speciesByRankValue: speciesByRankValue,
    );
  }

  static AppData fromNormalizedJsonLists(
    List<dynamic> speciesJson,
    List<dynamic> taxaJson,
    List<Park> parksList,
  ) {
    final taxaById = <String, Taxa>{};
    for (final raw in taxaJson) {
      final map = raw as Map<String, dynamic>;
      final id = map['id'] as String? ?? '';
      taxaById[id] = Taxa(
        name: map['name'] as String? ?? '',
        commonName: map['common_name'] as String? ?? '',
        rank: map['rank'] as String? ?? '',
        description: map['description'] as String? ?? '',
      );
    }

    final speciesList = speciesJson.map((raw) {
      final map = raw as Map<String, dynamic>;
      final rawScientificName = map['scientific_name'] as String? ?? '';
      final scientificName = rawScientificName.isNotEmpty
          ? rawScientificName[0].toUpperCase() +
              rawScientificName.substring(1)
          : rawScientificName;
      final classification = Classification(
        kingdom: _taxonName(taxaById, map['kingdom_id']),
        phylum: _taxonName(taxaById, map['phylum_id']),
        class_: _taxonName(taxaById, map['class_id']),
        order: _taxonName(taxaById, map['order_id']),
        family: _taxonName(taxaById, map['family_id']),
        genus: _taxonName(taxaById, map['genus_id']),
        species: _taxonName(taxaById, map['species_id']),
      );
      return Species(
        id: map['id'] as String? ?? '',
        name: map['common_name'] as String? ?? '',
        scientificName: scientificName,
        description: map['summary'] as String? ?? '',
        classification: classification,
        iucnStatus: map['iucn_status'] as String?,
      );
    }).toList(growable: false);

    final taxaList = taxaById.values.toList(growable: false);
    return buildIndices(speciesList, taxaList, parksList: parksList);
  }

  static String? _taxonName(
    Map<String, Taxa> taxaById,
    Object? id,
  ) {
    if (id == null) return null;
    final key = id as String;
    return taxaById[key]?.name;
  }

  static AppData buildIndices(
    List<Species> speciesList,
    List<Taxa> taxaList, {
    List<Park> parksList = const [],
  }) {
    final speciesById = <String, Species>{};
    final speciesByGenusSpecies = <String, Species>{};
    final speciesByFamily = <String, List<Species>>{};
    final speciesByRankValue = <String, List<Species>>{};

    for (final species in speciesList) {
      speciesById[species.id] = species;

      final genus = species.classification?.genus?.toLowerCase();
      final sp = species.classification?.species?.toLowerCase();
      if (genus != null && genus.isNotEmpty && sp != null && sp.isNotEmpty) {
        final key = '$genus|$sp';
        speciesByGenusSpecies.putIfAbsent(key, () => species);
      }

      final family =
          (species.classification?.familyName ?? 'Unknown Family').toLowerCase();
      speciesByFamily.putIfAbsent(family, () => []).add(species);

      void addRank(String rank, String? value) {
        final normalized = value?.toLowerCase();
        if (normalized == null || normalized.isEmpty) return;
        final key = '$rank|$normalized';
        speciesByRankValue.putIfAbsent(key, () => []).add(species);
      }

      addRank('kingdom', species.classification?.kingdom);
      addRank('phylum', species.classification?.phylum);
      addRank('class', species.classification?.class_);
      addRank('order', species.classification?.order);
      addRank('family', species.classification?.family);
      addRank('genus', species.classification?.genus);
      addRank('species', species.classification?.species);
    }

    final taxaByRankName = <String, Taxa>{};
    for (final taxa in taxaList) {
      final key = _rankKey(taxa.rank, taxa.name);
      taxaByRankName[key] = taxa;
      if (taxa.commonName.isNotEmpty) {
        taxaByRankName[_rankKey(taxa.rank, taxa.commonName)] = taxa;
      }
    }

    return AppData(
      speciesList: speciesList,
      taxaList: taxaList,
      parksList: parksList,
      speciesById: speciesById,
      speciesByGenusSpecies: speciesByGenusSpecies,
      speciesByFamily: speciesByFamily,
      taxaByRankName: taxaByRankName,
      speciesByRankValue: speciesByRankValue,
    );
  }

  List<Species> speciesForPark(Park park) {
    return park.speciesIds
        .map((id) => speciesById[id])
        .whereType<Species>()
        .toList(growable: false);
  }

  static String _rankKey(String rank, String name) {
    return '${rank.toLowerCase()}|${name.toLowerCase()}';
  }

  static List<Species> _buildCoreSpeciesList(List<Species> speciesList) {
    return speciesList.where((species) {
      final nameOk = species.name.trim().isNotEmpty;
      final sciOk = species.scientificName.trim().isNotEmpty;
      final descOk = species.description.trim().isNotEmpty;
      final classification = species.classification;
      final taxonomyOk = classification != null &&
          (classification.family?.trim().isNotEmpty ?? false) &&
          (classification.genus?.trim().isNotEmpty ?? false);
      return nameOk && sciOk && descOk && taxonomyOk;
    }).toList(growable: false);
  }
}
