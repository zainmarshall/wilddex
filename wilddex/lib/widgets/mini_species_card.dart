import 'package:flutter/material.dart';
import '../models/species.dart';
import '../theme/colors.dart';
import 'web_image.dart';

class MiniSpeciesCard extends StatelessWidget {
  final Species species;
  final VoidCallback? onTap;
  final bool useHero;
  final int? heroIndex;
  final bool roundTopCorners;
  final BorderRadius borderRadius;
  final bool highlight;

  const MiniSpeciesCard({
    super.key,
    required this.species,
    this.onTap,
    this.useHero = true,
    this.heroIndex,
    this.roundTopCorners = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(10.0)),
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDiscovered = species.isDiscovered;
    final String heroTag = heroIndex != null
        ? (isDiscovered
            ? 'species-image-${species.id}-image-$heroIndex'
            : 'species-image-${species.id}-question-$heroIndex')
        : (isDiscovered
            ? 'species-image-${species.id}-image'
            : 'species-image-${species.id}-question');

    final Widget imageWidget = isDiscovered
        ? ClipRRect(
            borderRadius: borderRadius,
            child: AppNetworkImage(
              url: species.apiImageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: AppColors.background,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
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
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.undiscovered,
              borderRadius: borderRadius,
            ),
            child: const Center(
              child: Icon(
                Icons.question_mark,
                size: 48,
                color: AppColors.foreground,
              ),
            ),
          );

    final Widget highlighted = highlight
        ? Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(color: Colors.amber, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66FFC107),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: imageWidget,
          )
        : imageWidget;

    final Widget card = AspectRatio(
      aspectRatio: 16 / 9,
      child: useHero && heroIndex != null
          ? Hero(
              tag: heroTag,
              child: highlighted,
            )
          : highlighted,
    );

    return GestureDetector(
      onTap: onTap,
      child: card,
    );
  }
}
