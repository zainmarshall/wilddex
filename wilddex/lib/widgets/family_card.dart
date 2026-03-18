import 'package:flutter/material.dart';

import '../models/family.dart';
import '../models/species.dart';
import '../models/taxa.dart';
import '../theme/colors.dart';
import 'mini_species_card.dart';
import 'web_image.dart';

class FamilyCard extends StatelessWidget {
  final Family family;
  final List<Taxa> taxaList;
  final VoidCallback onTap;
  final String highlightQuery;

  const FamilyCard({
    super.key,
    required this.family,
    required this.taxaList,
    required this.onTap,
    this.highlightQuery = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Check if any species in the family is discovered
    final bool anyDiscovered = family.species.any((s) => s.isDiscovered);
    // Find family common name from taxaList
    String? familyCommonName;
    try {
      familyCommonName = taxaList
          .firstWhere(
            (taxa) =>
                taxa.rank == 'family' &&
                (taxa.name == family.scientificName ||
                    taxa.commonName == family.name),
          )
          .commonName;
    } catch (e) {
      familyCommonName = null;
    }
    // Sort species: discovered first, then by name
    final sortedSpecies = [...family.species]
      ..sort((a, b) {
        if (a.isDiscovered != b.isDiscovered) {
          return b.isDiscovered ? 1 : -1;
        }
        return a.name.compareTo(b.name);
      });

    final List<Species> displaySpecies = highlightQuery.isEmpty
        ? sortedSpecies
        : _moveMatchesToTop(sortedSpecies, highlightQuery);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FamilyHeader(
              family: family,
              theme: theme,
              useAccent: anyDiscovered,
              familyCommonName: familyCommonName,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(8.0),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: 4,
                    mainAxisSpacing: 4,
                  ),
                  itemCount: displaySpecies.length.clamp(0, 4),
                  itemBuilder: (context, index) {
                    final species = displaySpecies[index];
                    return MiniSpeciesCard(
                      species: species,
                      useHero: true,
                      heroIndex: index,
                      highlight: highlightQuery.isNotEmpty &&
                          _matchesQuery(species, highlightQuery),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<Species> _moveMatchesToTop(List<Species> species, String query) {
  final lower = query.toLowerCase();
  final matches = <Species>[];
  final rest = <Species>[];
  for (final s in species) {
    if (_matchesQuery(s, lower)) {
      matches.add(s);
    } else {
      rest.add(s);
    }
  }
  return [...matches, ...rest];
}

bool _matchesQuery(Species species, String lowerQuery) {
  return species.name.toLowerCase().contains(lowerQuery) ||
      species.scientificName.toLowerCase().contains(lowerQuery);
}

class _FamilyHeader extends StatelessWidget {
  final Family family;
  final ThemeData theme;
  final bool useAccent;
  final String? familyCommonName;

  const _FamilyHeader({
    required this.family,
    required this.theme,
    this.useAccent = false,
    this.familyCommonName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      color: useAccent ? AppColors.accent : AppColors.undiscovered,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    familyCommonName ?? family.name,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.foreground,
                    ),
                  ),
                ),
                Text(
                  family.scientificName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.foreground.withOpacity(0.7),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SpeciesImage extends StatelessWidget {
  final Species species;
  const SpeciesImage({required this.species});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: AppNetworkImage(
        url: species.apiImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppColors.background,
          child: const Center(
            child: Icon(
              Icons.image_not_supported,
              size: 48,
              color: AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class QuestionMarkImage extends StatelessWidget {
  const QuestionMarkImage();

  @override
  Widget build(BuildContext context) {
    return const AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.undiscovered,
          borderRadius: BorderRadius.all(Radius.circular(6.0)),
        ),
        child: Center(
          child: Icon(
            Icons.question_mark,
            size: 48,
            color: AppColors.foreground,
          ),
        ),
      ),
    );
  }
}
