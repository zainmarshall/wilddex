import '../constants.dart';

class Classification {
  final String? kingdom;
  final String? phylum;
  final String? class_;
  final String? order;
  final String? family;
  final String? genus;
  final String? species;

  Classification({
    this.kingdom,
    this.phylum,
    this.class_,
    this.order,
    this.family,
    this.genus,
    this.species,
  });

  String get kingdomName => kingdom ?? 'Unknown';
  String get phylumName => phylum ?? 'Unknown';
  String get className => class_ ?? 'Unknown';
  String get orderName => order ?? 'Unknown';
  String get familyName => family ?? 'Unknown';
  String get genusName => genus ?? 'Unknown';
  String get speciesName => species ?? 'Unknown';

  factory Classification.fromJson(Map<String, dynamic> json) {
    return Classification(
      kingdom: json['kingdom'] as String?,
      phylum: json['phylum'] as String?,
      class_: json['class'] as String?,
      order: json['order'] as String?,
      family: json['family'] as String?,
      genus: json['genus'] as String?,
      species: json['species'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kingdom': kingdom,
      'phylum': phylum,
      'class': class_,
      'order': order,
      'family': family,
      'genus': genus,
      'species': species,
    };
  }
}

class Species {
  final String id;
  final String name;
  final String scientificName;
  final String description;
  final Classification? classification;
  final String? image;
  final bool? discovered;
  final String? conservationStatus;
  final String? iucnStatus;
  final String? rangeMap;
  final String? animalImage;

  Species({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.description,
    this.classification,
    this.image,
    this.discovered,
    this.conservationStatus,
    this.iucnStatus,
    this.rangeMap,
    this.animalImage,
  });

  // Getters
  String get displayName => name;
  String get displayScientificName => scientificName.isNotEmpty
      ? scientificName[0].toUpperCase() + scientificName.substring(1)
      : scientificName;
  String get displayDescription => description;
  bool get isDiscovered => discovered ?? false;
  String get imagePath => image ?? 'assets/species/images/$id.jpg';
  Classification get displayClassification => classification ?? Classification();
  String get apiImageUrl => '$googleCloudStorageBucket/images/${id}.jpg'; ///images/leopardus_geoffroyi.jpg
  /// Possible range map URLs ordered by likelihood.
  List<String> get apiRangeMapUrls {
    const exts = ['.png', '.jpg', '.jpeg', '.webp', '.svg'];
    return exts.map((ext) => '$googleCloudStorageBucket/range/${id}_range$ext').toList();
  }

  /// Default range map URL (png).
  String get apiRangeMapUrl => '$googleCloudStorageBucket/range/${id}_range.png';



  factory Species.fromJson(Map<String, dynamic> json) {
    // Capitalize first letter of scientific name
    String rawScientificName = json['scientific_name'] as String? ?? '';
    String capitalizedScientificName = rawScientificName.isNotEmpty
        ? rawScientificName[0].toUpperCase() + rawScientificName.substring(1)
        : rawScientificName;
    return Species(
      id: json['id'] as String? ?? '',
      name: json['common_name'] as String? ?? json['name'] as String? ?? '',
      scientificName: capitalizedScientificName,
      description: json['summary'] as String? ?? json['description'] as String? ?? '',
      classification: json['classification'] != null && json['classification'] is Map<String, dynamic>
          ? Classification.fromJson(json['classification'] as Map<String, dynamic>)
          : null,
      image: json['image'] as String? ?? json['animal_image'] as String?,
      discovered: json['discovered'] as bool? ?? false,
      conservationStatus: json['conservation_status'] as String?,
      iucnStatus: json['iucn_status'] as String?,
      rangeMap: json['range_map'] as String?,
      animalImage: json['animal_image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'scientificName': scientificName,
      'description': description,
      'classification': classification?.toJson(),
      'image': image,
      'discovered': discovered,
      'conservation_status': conservationStatus,
      'iucn_status': iucnStatus,
      'range_map': rangeMap,
      'animal_image': animalImage,
    };
  }

  Species copyWith({
    String? id,
    String? name,
    String? scientificName,
    String? description,
    Classification? classification,
    String? image,
    bool? discovered,
    String? conservationStatus,
    String? iucnStatus,
    String? rangeMap,
    String? animalImage,
  }) {
    return Species(
      id: id ?? this.id,
      name: name ?? this.name,
      scientificName: scientificName ?? this.scientificName,
      description: description ?? this.description,
      classification: classification ?? this.classification,
      image: image ?? this.image,
      discovered: discovered ?? this.discovered,
      conservationStatus: conservationStatus ?? this.conservationStatus,
      iucnStatus: iucnStatus ?? this.iucnStatus,
      rangeMap: rangeMap ?? this.rangeMap,
      animalImage: animalImage ?? this.animalImage,
    );
  }
}