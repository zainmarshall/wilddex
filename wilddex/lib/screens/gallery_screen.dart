import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/app_data.dart';
import '../models/sighting.dart';
import '../models/species.dart';
import '../theme/colors.dart';
import '../utils/user_data_provider.dart';

class GalleryScreen extends StatelessWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appData = Provider.of<AppData>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<UserDataProvider>(
        builder: (context, userData, _) {
          final recentSightings = _buildRecentSightings(userData, appData);
          if (recentSightings.isEmpty) {
            return const Center(child: Text('No sightings yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recentSightings.length,
            itemBuilder: (context, index) {
              return _buildSightingGalleryCard(
                context,
                recentSightings[index],
              );
            },
          );
        },
      ),
    );
  }

  List<_RecentSightingGroup> _buildRecentSightings(
    UserDataProvider userData,
    AppData appData,
  ) {
    final entries = <_RecentSightingGroup>[];
    userData.allSightings.forEach((speciesId, sightings) {
      if (sightings.isEmpty) return;
      final species = appData.speciesById[speciesId];
      final sorted = List<Sighting>.from(sightings)
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      entries.add(
        _RecentSightingGroup(
          speciesId: speciesId,
          species: species,
          sightings: sorted,
          latest: sorted.first.timestamp,
        ),
      );
    });
    entries.sort((a, b) => b.latest.compareTo(a.latest));
    return entries;
  }

  Widget _buildSightingGalleryCard(
    BuildContext context,
    _RecentSightingGroup group,
  ) {
    final speciesName = group.species?.name.isNotEmpty == true
        ? group.species!.name
        : 'Unknown species';
    final subtitle = group.species?.scientificName ?? group.speciesId;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              speciesName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.text.withOpacity(0.6)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: group.sightings.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final sighting = group.sightings[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Container(
                            width: 96,
                            height: 96,
                            color: AppColors.background,
                            child: const Icon(Icons.photo, color: AppColors.text),
                          )
                        : Image.file(
                            File(sighting.imagePath),
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 96,
                                height: 96,
                                color: AppColors.background,
                                child: const Icon(Icons.image_not_supported),
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentSightingGroup {
  final String speciesId;
  final Species? species;
  final List<Sighting> sightings;
  final DateTime latest;

  _RecentSightingGroup({
    required this.speciesId,
    required this.species,
    required this.sightings,
    required this.latest,
  });
}
