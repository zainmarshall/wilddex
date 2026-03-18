import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';

import '../data/app_data.dart';
import '../models/species.dart';
import '../models/taxa.dart';
import '../theme/colors.dart';
import 'taxa_detail_screen.dart';
import '../widgets/web_image.dart';

class AnimalDetailScreen extends StatelessWidget {
  final Species species;
  final List<Taxa>? taxaList;
  final List<Species>? allSpecies;

  const AnimalDetailScreen({
    super.key,
    required this.species,
    this.taxaList,
    this.allSpecies,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(species.displayName),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.foreground,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            SpeciesImage(species: species),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SpeciesDetails(
                species: species,
                textTheme: textTheme,
                context: context,
                taxaList: taxaList,
                allSpecies: allSpecies,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpeciesImage extends StatelessWidget {
  final Species species;
  const SpeciesImage({required this.species});

  @override
  Widget build(BuildContext context) {
    // Skip BackdropFilter on web — it's slow and can cause rendering issues.
    if (kIsWeb) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: AppNetworkImage(
          url: species.apiImageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              color: AppColors.background,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppColors.background,
            child: const Center(
              child: Icon(Icons.image_not_supported, size: 48, color: AppColors.text),
            ),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Blurred background
          Image.network(
            species.apiImageUrl,
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.3),
            colorBlendMode: BlendMode.darken,
            errorBuilder: (context, error, stackTrace) => Container(
              color: AppColors.background,
            ),
          ),
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
          // Foreground image
          Center(
            child: AppNetworkImage(
              url: species.apiImageUrl,
              fit: BoxFit.fitHeight,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  height: 180,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.accent,
                    ),
                  ),
                );
              },
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
          ),
        ],
      ),
    );
  }
}

class SpeciesDetails extends StatefulWidget {
  final Species species;
  final TextTheme textTheme;
  final BuildContext context;
  final List<Taxa>? taxaList;
  final List<Species>? allSpecies;
  const SpeciesDetails({
    required this.species,
    required this.textTheme,
    required this.context,
    this.taxaList,
    this.allSpecies,
  });

  @override
  State<SpeciesDetails> createState() => _SpeciesDetailsState();
}

class _SpeciesDetailsState extends State<SpeciesDetails> {
  int? expandedIndex;

  @override
  Widget build(BuildContext context) {
    final species = widget.species;
    final textTheme = widget.textTheme;

    final taxaList = widget.taxaList;
    final allSpecies = widget.allSpecies;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Scientific Name
        Text(
          species.displayScientificName,
          style: textTheme.titleMedium?.copyWith(
            fontStyle: FontStyle.italic,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 16),
        // IUCN Status
        if (species.iucnStatus != null && species.iucnStatus!.isNotEmpty) ...[
          _buildSection(
            context,
            'IUCN Status',
            Text(
              species.iucnStatus!,
              style: textTheme.bodyLarge?.copyWith(color: AppColors.text),
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Range Map
       // if (species.apiRangeMapUrl != 'null') ...[
          _buildSection(
            context,
            'Range Map',
            AppNetworkImage(
              url: species.apiRangeMapUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                color: AppColors.background,
                child: const Center(
                  child: Icon(Icons.map, size: 48, color: AppColors.text),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
    //    ],

        // Classification
        if (species.classification != null) ...[
          _buildSection(
            context,
            'Classification',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildClassificationRow(
                  'Kingdom',
                  species.classification!.kingdomName,
                  taxaList: taxaList,
                  allSpecies: allSpecies,
                ),
                _buildClassificationRow(
                  'Phylum',
                  species.classification!.phylumName,
                  taxaList: taxaList,
                  allSpecies: allSpecies,
                ),
                _buildClassificationRow(
                  'Class',
                  species.classification!.className,
                  taxaList: taxaList,
                  allSpecies: allSpecies,
                ),
                _buildClassificationRow(
                  'Order',
                  species.classification!.orderName,
                  taxaList: taxaList,
                  allSpecies: allSpecies,
                ),
                _buildClassificationRow(
                  'Family',
                  species.classification!.familyName,
                  taxaList: taxaList,
                  allSpecies: allSpecies,
                ),
                _buildClassificationRow(
                  'Genus',
                  species.classification!.genusName,
                  taxaList: taxaList,
                  allSpecies: allSpecies,
                ),
                _buildClassificationRow(
                  'Species',
                  species.classification!.speciesName,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        // Description
        _buildSection(
          context,
          'Description',
          Html(
            data: species.displayDescription,
            style: {
              'body': Style(
                margin: Margins.zero,
                padding: HtmlPaddings.zero,
                fontSize: FontSize(16),
                lineHeight: LineHeight(1.5),
                color: AppColors.text,
              ),
              'p': Style(margin: Margins.only(bottom: 8)),
              'em': Style(fontStyle: FontStyle.italic),
              'strong': Style(fontWeight: FontWeight.bold),
            },
          ),
        ),
        const SizedBox(height: 16),
        // Biomes
      ],
    );
  }

  Widget _buildSection(BuildContext context, String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        content,
      ],
    );
  }

  Widget _buildClassificationRow(
    String label,
    String value, {
    List<Taxa>? taxaList,
    List<Species>? allSpecies,
  }) {
    final rank = label.toLowerCase();
    if (taxaList == null || allSpecies == null || value.isEmpty) {
      return _buildClassificationRowContent(label, value, null);
    }

    final appData = Provider.of<AppData>(context, listen: false);
    final key = '$rank|${value.toLowerCase()}';
    final Taxa? taxa = appData.taxaByRankName[key];

    final row = _buildClassificationRowContent(label, value, taxa);

    if (taxa == null) {
      return row;
    }

    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TaxaDetailScreen(
              taxa: taxa,
              taxaList: taxaList,
              speciesList: allSpecies,
            ),
          ),
        );
      },
      child: row,
    );
  }

  Widget _buildClassificationRowContent(String label, String value, Taxa? taxa) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: AppColors.text)),
          ),
          if (taxa != null)
            const Padding(
              padding: EdgeInsets.only(left: 6.0, top: 2.0),
              child: Icon(Icons.chevron_right, size: 18, color: AppColors.text),
            ),
        ],
      ),
    );
  }

}
