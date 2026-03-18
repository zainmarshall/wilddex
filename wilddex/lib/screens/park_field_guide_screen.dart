import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/app_data.dart';
import '../models/species.dart';
import '../models/taxa.dart';
import '../theme/colors.dart';
import '../utils/user_data_provider.dart';
import '../data/park_guides.dart';
import 'animal_detail_screen.dart';
import '../widgets/web_image.dart';

class ParkFieldGuideScreen extends StatelessWidget {
  final List<Species> speciesList;
  final List<Taxa> taxaList;

  const ParkFieldGuideScreen({
    super.key,
    required this.speciesList,
    required this.taxaList,
  });

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context, listen: false);
    final allowedIds = speciesList.map((s) => s.id).toSet();
    final parks = buildParkGuides(appData, allowedIds: allowedIds);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Park Field Guide'),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.foreground,
      ),
      body: Consumer<UserDataProvider>(
        builder: (context, userData, child) {
          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: parks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final park = parks[index];
              final discoveredCount = park.species
                  .where((s) => userData.isSpeciesDiscovered(s.id))
                  .length;
              final totalCount = park.species.length;
              final progress = totalCount == 0 ? 0.0 : discoveredCount / totalCount;

              return Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ParkDetailScreen(
                          park: park,
                          taxaList: taxaList,
                          allSpecies: speciesList,
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          park.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          park.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: AppColors.shadow,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.accent,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$discoveredCount / $totalCount species found',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

}

class ParkDetailScreen extends StatefulWidget {
  final ParkGuide park;
  final List<Taxa> taxaList;
  final List<Species> allSpecies;

  const ParkDetailScreen({
    super.key,
    required this.park,
    required this.taxaList,
    required this.allSpecies,
  });

  @override
  State<ParkDetailScreen> createState() => _ParkDetailScreenState();
}

class _ParkDetailScreenState extends State<ParkDetailScreen> {
  String _searchQuery = '';
  bool _showDiscoveredOnly = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<UserDataProvider>(
      builder: (context, userData, child) {
        final discoveredIds = userData.discoveredSpeciesIds;
        final allSpecies = widget.park.species
            .map(
              (s) => s.copyWith(discovered: discoveredIds.contains(s.id)),
            )
            .toList();

        var filtered = allSpecies;
        if (_searchQuery.isNotEmpty) {
          filtered = filtered
              .where((s) =>
                  s.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                  s.scientificName
                      .toLowerCase()
                      .contains(_searchQuery.toLowerCase()))
              .toList();
        }
        if (_showDiscoveredOnly) {
          filtered = filtered.where((s) => s.isDiscovered).toList();
        }

        filtered.sort((a, b) {
          if (a.isDiscovered != b.isDiscovered) {
            return b.isDiscovered ? 1 : -1;
          }
          return a.name.compareTo(b.name);
        });

        final discoveredCount =
            allSpecies.where((s) => s.isDiscovered).length;
        final totalCount = allSpecies.length;

        return Scaffold(
          appBar: AppBar(
            title: Text(widget.park.name),
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.foreground,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.park.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: totalCount == 0
                          ? 0
                          : discoveredCount / totalCount,
                      backgroundColor: AppColors.shadow,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$discoveredCount / $totalCount species found',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search species...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.all(8),
                      ),
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FilterChip(
                        label: const Text('Discovered Only'),
                        selectedColor: AppColors.accent,
                        selected: _showDiscoveredOnly,
                        onSelected: (val) =>
                            setState(() => _showDiscoveredOnly = val),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final species = filtered[index];
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: species.isDiscovered
                              ? AppNetworkImage(
                                  url: species.apiImageUrl,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 56,
                                    height: 56,
                                    color: AppColors.background,
                                    child: const Icon(Icons.image_not_supported),
                                  ),
                                )
                              : Container(
                                  width: 56,
                                  height: 56,
                                  color: AppColors.undiscovered,
                                  child: const Icon(
                                    Icons.question_mark,
                                    color: AppColors.foreground,
                                  ),
                                ),
                        ),
                        title: Text(species.name),
                        subtitle: Text(species.scientificName),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AnimalDetailScreen(
                                species: species,
                                taxaList: widget.taxaList,
                                allSpecies: widget.allSpecies,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
