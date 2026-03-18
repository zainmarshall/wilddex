import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/species.dart';
import '../models/taxa.dart';
import '../theme/colors.dart';
import '../utils/user_data_provider.dart';
import 'animal_detail_screen.dart';
import '../widgets/web_image.dart';

class TaxaDetailScreen extends StatelessWidget {
	final Taxa taxa;
	final List<Taxa> taxaList;
	final List<Species> speciesList;

	const TaxaDetailScreen({
		super.key,
		required this.taxa,
		required this.taxaList,
		required this.speciesList,
	});

	@override
	Widget build(BuildContext context) {
		final displayName = taxa.commonName.isNotEmpty ? taxa.commonName : taxa.name;
		final childRank = _childRankFor(taxa.rank);
		final speciesInTaxa = _filterSpeciesForTaxa(taxa, speciesList);

		return Scaffold(
			appBar: AppBar(
				title: Text(displayName),
				backgroundColor: AppColors.accent,
				foregroundColor: AppColors.foreground,
			),
			body: Consumer<UserDataProvider>(
				builder: (context, userData, _) {
					final discoveredCount = speciesInTaxa
							.where((s) => userData.isSpeciesDiscovered(s.id))
							.length;
					final totalCount = speciesInTaxa.length;
					final progress = totalCount == 0 ? 0.0 : discoveredCount / totalCount;

					return CustomScrollView(
						slivers: [
							SliverToBoxAdapter(
								child: Container(
									padding: const EdgeInsets.all(16.0),
									color: AppColors.accent,
									child: Column(
										crossAxisAlignment: CrossAxisAlignment.start,
										children: [
											Text(
												displayName,
												style: Theme.of(context).textTheme.titleLarge?.copyWith(
															color: AppColors.foreground,
															fontWeight: FontWeight.bold,
														),
											),
											const SizedBox(height: 4),
											Text(
												taxa.name,
												style: Theme.of(context).textTheme.titleMedium?.copyWith(
															color: AppColors.foreground,
															fontStyle: FontStyle.italic,
														),
											),
											const SizedBox(height: 6),
											Text(
												'Rank: ${taxa.rank}',
												style: Theme.of(context).textTheme.bodyMedium?.copyWith(
															color: AppColors.foreground.withOpacity(0.8),
														),
											),
											if (taxa.description.isNotEmpty) ...[
												const SizedBox(height: 8),
												Text(
													taxa.description,
													style: Theme.of(context).textTheme.bodyMedium?.copyWith(
																color: Colors.white70,
																height: 1.4,
															),
												),
											],
											const SizedBox(height: 12),
											LinearProgressIndicator(
												value: progress,
												backgroundColor: Colors.white24,
												valueColor: const AlwaysStoppedAnimation<Color>(
													Colors.white,
												),
											),
											const SizedBox(height: 6),
											Text(
												'$discoveredCount / $totalCount species found',
												style: Theme.of(context).textTheme.bodySmall?.copyWith(
															color: Colors.white70,
														),
											),
										],
									),
								),
							),
							if (childRank == 'species')
								_buildSpeciesGrid(context, speciesInTaxa, userData)
							else
								_buildChildTaxaList(context, childRank, speciesInTaxa, userData),
						],
					);
				},
			),
		);
	}

	String? _childRankFor(String rank) {
		switch (rank.toLowerCase()) {
			case 'kingdom':
				return 'phylum';
			case 'phylum':
				return 'class';
			case 'class':
				return 'order';
			case 'order':
				return 'family';
			case 'family':
				return 'genus';
			case 'genus':
				return 'species';
			default:
				return null;
		}
	}

	List<Species> _filterSpeciesForTaxa(Taxa taxa, List<Species> allSpecies) {
		final rank = taxa.rank.toLowerCase();
		final target = taxa.name.toLowerCase();
		return allSpecies.where((species) {
			final classification = species.classification;
			if (classification == null) return false;
			switch (rank) {
				case 'kingdom':
					return classification.kingdom?.toLowerCase() == target;
				case 'phylum':
					return classification.phylum?.toLowerCase() == target;
				case 'class':
					return classification.class_?.toLowerCase() == target;
				case 'order':
					return classification.order?.toLowerCase() == target;
				case 'family':
					return classification.family?.toLowerCase() == target;
				case 'genus':
					return classification.genus?.toLowerCase() == target;
				case 'species':
					return classification.species?.toLowerCase() == target;
				default:
					return false;
			}
		}).toList();
	}

	SliverPadding _buildSpeciesGrid(
		BuildContext context,
		List<Species> species,
		UserDataProvider userData,
	) {
		final discoveredIds = userData.discoveredSpeciesIds;
		final updatedSpecies = species
				.map((s) => s.copyWith(discovered: discoveredIds.contains(s.id)))
				.toList()
			..sort((a, b) {
				if (a.isDiscovered != b.isDiscovered) {
					return b.isDiscovered ? 1 : -1;
				}
				return a.name.compareTo(b.name);
			});

		return SliverPadding(
			padding: const EdgeInsets.all(16.0),
			sliver: SliverGrid(
				gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
					crossAxisCount: 2,
					childAspectRatio: 0.75,
					crossAxisSpacing: 16,
					mainAxisSpacing: 16,
				),
				delegate: SliverChildBuilderDelegate(
					(context, index) {
						final species = updatedSpecies[index];
						final isDiscovered = species.isDiscovered;
						final BorderRadius cardRadius =
								const BorderRadius.all(Radius.circular(20.0));
						return Card(
							color: Colors.white,
							elevation: 10,
							shadowColor: Colors.black26,
							shape: RoundedRectangleBorder(borderRadius: cardRadius),
							child: InkWell(
								borderRadius: cardRadius,
								onTap: () {
									Navigator.push(
										context,
										MaterialPageRoute(
											builder: (_) => AnimalDetailScreen(
												species: species,
												taxaList: taxaList,
												allSpecies: speciesList,
											),
										),
									);
								},
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.stretch,
									children: [
										Expanded(
											child: ClipRRect(
												borderRadius: const BorderRadius.vertical(
													top: Radius.circular(20.0),
												),
												child: isDiscovered
														? AppNetworkImage(
																url: species.apiImageUrl,
																fit: BoxFit.cover,
																errorBuilder: (context, error, stackTrace) =>
																		Container(color: AppColors.background),
															)
														: Container(
																color: AppColors.undiscovered,
																child: const Icon(
																	Icons.question_mark,
																	color: AppColors.foreground,
																	size: 36,
																),
															),
											),
										),
										if (isDiscovered) ...[
											Padding(
												padding: const EdgeInsets.only(
													top: 4.0,
													left: 4.0,
													right: 4.0,
												),
												child: Text(
													species.name,
													textAlign: TextAlign.center,
													style: TextStyle(
														fontWeight: FontWeight.bold,
														fontSize: 16,
														color: Theme.of(context).colorScheme.onSurface,
													),
												),
											),
											Padding(
												padding: const EdgeInsets.only(
													bottom: 4.0,
													left: 4.0,
													right: 4.0,
												),
												child: Text(
													species.scientificName,
													textAlign: TextAlign.center,
													style: TextStyle(
														fontStyle: FontStyle.italic,
														fontSize: 14,
														color: Theme.of(context)
																.colorScheme
																.onSurface
																.withOpacity(0.7),
													),
												),
											),
										],
										if (!isDiscovered)
											Padding(
												padding: const EdgeInsets.symmetric(vertical: 12.0),
												child: Text(
													species.name,
													textAlign: TextAlign.center,
													style: Theme.of(context)
															.textTheme
															.bodyMedium
															?.copyWith(color: AppColors.text),
												),
											),
									],
								),
							),
						);
					},
					childCount: updatedSpecies.length,
				),
			),
		);
	}

	SliverPadding _buildChildTaxaList(
		BuildContext context,
		String? childRank,
		List<Species> speciesInTaxa,
		UserDataProvider userData,
	) {
		if (childRank == null) {
			return const SliverPadding(
				padding: EdgeInsets.zero,
				sliver: SliverToBoxAdapter(),
			);
		}

		final Map<String, List<Species>> groups = {};
		for (final species in speciesInTaxa) {
			final classification = species.classification;
			if (classification == null) continue;
			final String? key = _childNameFromClassification(classification, childRank);
			if (key == null || key.isEmpty) continue;
			groups.putIfAbsent(key, () => []).add(species);
		}

		final sortedKeys = groups.keys.toList()..sort();

		return SliverPadding(
			padding: const EdgeInsets.all(16.0),
			sliver: SliverList(
				delegate: SliverChildBuilderDelegate(
					(context, index) {
						final name = sortedKeys[index];
						final speciesGroup = groups[name]!;
						final discoveredCount = speciesGroup
								.where((s) => userData.isSpeciesDiscovered(s.id))
								.length;
						final totalCount = speciesGroup.length;
						final progress = totalCount == 0 ? 0.0 : discoveredCount / totalCount;
						final taxa = _findTaxa(context, childRank, name) ?? Taxa(
							name: name,
							commonName: '',
							rank: childRank,
							description: '',
						);
						final displayName = taxa.commonName.isNotEmpty ? taxa.commonName : taxa.name;

						return Card(
							elevation: 4,
							shape: RoundedRectangleBorder(
								borderRadius: BorderRadius.circular(16),
							),
							child: InkWell(
								borderRadius: BorderRadius.circular(16),
								onTap: () {
									Navigator.of(context).push(
										MaterialPageRoute(
											builder: (_) => TaxaDetailScreen(
												taxa: taxa,
												taxaList: taxaList,
												speciesList: speciesList,
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
												displayName,
												style: Theme.of(context).textTheme.titleLarge,
											),
											const SizedBox(height: 4),
											Text(
												name,
												style: Theme.of(context).textTheme.bodyMedium?.copyWith(
															fontStyle: FontStyle.italic,
															color: AppColors.text.withOpacity(0.7),
														),
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
					childCount: sortedKeys.length,
				),
			),
		);
	}

	String? _childNameFromClassification(
		Classification classification,
		String childRank,
	) {
		switch (childRank.toLowerCase()) {
			case 'phylum':
				return classification.phylum;
			case 'class':
				return classification.class_;
			case 'order':
				return classification.order;
			case 'family':
				return classification.family;
			case 'genus':
				return classification.genus;
			case 'species':
				return classification.species;
			default:
				return null;
		}
	}

	Taxa? _findTaxa(BuildContext context, String rank, String name) {
		try {
			return taxaList.firstWhere(
				(t) => t.rank.toLowerCase() == rank.toLowerCase() && t.name == name,
			);
		} catch (_) {
			return null;
		}
	}
}
