import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../data/app_data.dart';
import '../models/species.dart';
import '../utils/captured_image.dart';
import '../utils/user_data_provider.dart';
import '../theme/colors.dart';
import 'animal_detail_screen.dart';

/// Known subspecies → parent species mappings.
/// Key: "genus|subspecies_epithet", Value: replacement species epithet.
const Map<String, String> _subspeciesMappings = {
  'canis|familiaris': 'lupus familiaris',
  'felis|catus': 'silvestris catus',
  'bos|taurus': 'taurus',
};

class PredictionResultScreen extends StatelessWidget {
  final CapturedImage image;
  final Map<String, dynamic>? predictionResult;
  final bool isLoading;

  const PredictionResultScreen({
    Key? key,
    required this.image,
    this.predictionResult,
    this.isLoading = false,
  }) : super(key: key);

  /// Try to find a species match using progressively looser strategies.
  Species? _findSpecies(AppData appData, String genus, String species) {
    if (genus.isEmpty) return null;

    // 1. Exact match: genus|species
    final exactKey = '${genus.toLowerCase()}|${species.toLowerCase()}';
    final exact = appData.speciesByGenusSpecies[exactKey];
    if (exact != null) return exact;

    // 2. Try subspecies mapping
    final mappingKey = '${genus.toLowerCase()}|${species.toLowerCase()}';
    final mapped = _subspeciesMappings[mappingKey];
    if (mapped != null) {
      final mappedKey = '${genus.toLowerCase()}|${mapped.toLowerCase()}';
      final result = appData.speciesByGenusSpecies[mappedKey];
      if (result != null) return result;
    }

    // 3. Try genus-only match (first word of species if multi-word)
    if (species.contains(' ')) {
      final firstPart = species.split(' ').first;
      final partialKey = '${genus.toLowerCase()}|${firstPart.toLowerCase()}';
      final partial = appData.speciesByGenusSpecies[partialKey];
      if (partial != null) return partial;
    }

    // 4. Search all species by genus match (return first)
    for (final entry in appData.speciesByGenusSpecies.entries) {
      if (entry.key.startsWith('${genus.toLowerCase()}|')) {
        return entry.value;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String genus = predictionResult?['genus'] ?? '';
    final String species = predictionResult?['species'] ?? '';
    final boundingBox = (predictionResult?['bounding_box'] as List?)
        ?.cast<double>();

    final appData = Provider.of<AppData>(context, listen: false);
    final found = _findSpecies(appData, genus, species);
    final errorMessage = predictionResult?['error'] as String?;

    if (found != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final provider = Provider.of<UserDataProvider>(
          context,
          listen: false,
        );
        if (!provider.isSpeciesDiscovered(found.id)) {
          provider.discoverSpecies(found.id);
          HapticFeedback.lightImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('New species discovered!')),
          );
        }
        if (image.filePath != null) {
          provider.addSightingIfNew(found.id, image.filePath!);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.text,
        elevation: 0,
        title: const Text('Prediction Result'),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final imageDisplaySize = constraints.maxWidth - 48; // 24px padding each side
          final imageSize = imageDisplaySize.clamp(200.0, 400.0);

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                if (isLoading) ...[
                  const Padding(
                    padding: EdgeInsets.only(top: 48.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Identifying species...',
                    style: TextStyle(color: AppColors.text),
                  ),
                ] else if (predictionResult == null) ...[
                  _buildMessageState(
                    context,
                    'No prediction available. Try again.',
                    Icons.help_outline,
                  ),
                ] else if (errorMessage != null) ...[
                  _buildMessageState(
                    context,
                    'Something went wrong. Please try again.',
                    Icons.error_outline,
                  ),
                ] else if (found == null) ...[
                  _buildMessageState(
                    context,
                    'No match in the Dex for $genus $species.',
                    Icons.search_off,
                  ),
                ] else ...[
                  // Species name and new badge
                  Consumer<UserDataProvider>(
                    builder: (context, provider, _) {
                      final isDiscovered = provider.isSpeciesDiscovered(found.id);
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  found.name,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (!isDiscovered)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Text(
                                    'NEW',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (found.classification != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                '${found.classification?.genus ?? ''} ${found.classification?.species ?? ''}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // View Species button
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              AnimalDetailScreen(species: found),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: const Text('VIEW SPECIES'),
                  ),
                  const SizedBox(height: 32),

                  // Species database photo
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          found.apiImageUrl,
                          width: imageSize,
                          height: imageSize,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              width: imageSize,
                              height: imageSize,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.accent,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          (loadingProgress.expectedTotalBytes ?? 1)
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: imageSize,
                              height: imageSize,
                              color: AppColors.background,
                              child: const Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 48,
                                  color: AppColors.text,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Captured photo with bounding box
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Center(
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.memory(
                              image.bytes,
                              width: imageSize,
                              height: imageSize,
                              fit: BoxFit.cover,
                            ),
                          ),
                          if (boundingBox != null && boundingBox.length == 4)
                            Positioned(
                              left: boundingBox[0] * imageSize,
                              top: boundingBox[1] * imageSize,
                              width: boundingBox[2] * imageSize,
                              height: boundingBox[3] * imageSize,
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.red,
                                    width: 3,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageState(
    BuildContext context,
    String message,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.amber),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: AppColors.text),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: const Text('BACK TO CAMERA'),
          ),
        ],
      ),
    );
  }
}
