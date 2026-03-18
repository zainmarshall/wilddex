import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/user_data_provider.dart';
import '../models/species.dart';
import '../models/taxa.dart';
import 'animal_detail_screen.dart';
import 'settings_screen.dart';
import 'badges_screen.dart';
import '../utils/badge_engine.dart';
import '../data/app_data.dart';
import '../theme/colors.dart';
import '../widgets/web_image.dart';

class ProfileScreen extends StatefulWidget {
  final List<Species> speciesList;
  final List<Taxa> taxaList;
  const ProfileScreen({
    super.key,
    required this.speciesList,
    required this.taxaList,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Species> _allSpecies = [];

  @override
  void initState() {
    super.initState();
    _allSpecies = widget.speciesList;
  }

  // Removed: species loading logic

  @override
  Widget build(BuildContext context) {
    // No loading state needed
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<UserDataProvider>(
        builder: (context, userData, child) {
          BadgeEngine.syncAwards(context);
          final discoveredSpecies = userData.getDiscoveredSpecies(_allSpecies);
          final totalSightings = userData.sightings.length;
          final totalSpecies = _allSpecies.length;
          final streakDays = userData.streakDays;
          final lastDiscovery = userData.lastDiscoveryDate;
          final appData = Provider.of<AppData>(context, listen: false);
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                FutureBuilder(
                  future: BadgeEngine.loadDefinitions(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final defs = snapshot.data ?? [];
                    final summary = BadgeEngine.evaluate(defs, appData, userData);
                    final tierColor = _tierColorForPoints(summary.totalPoints);
                    final levelInitial = summary.levelName.isNotEmpty
                        ? summary.levelName[0].toUpperCase()
                        : '?';
                    return Center(
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: tierColor.withOpacity(0.2),
                            child: CircleAvatar(
                              radius: 44,
                              backgroundColor: tierColor,
                              child: Text(
                                levelInitial,
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            summary.levelName,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${summary.totalPoints} points',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.text.withOpacity(0.7)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Stats Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Species Discovered',
                        '${discoveredSpecies.length} / $totalSpecies',
                        Icons.pets,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Streak',
                        streakDays == null ? '—' : '${streakDays}d',
                        Icons.camera_alt,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Total Sightings',
                        totalSightings.toString(),
                        Icons.camera_alt,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Last Discovery',
                        lastDiscovery == null
                            ? '—'
                            : '${lastDiscovery.month}/${lastDiscovery.day}',
                        Icons.star,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Badges
                Text(
                  'Badges',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                FutureBuilder(
                  future: BadgeEngine.loadDefinitions(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final defs = snapshot.data ?? [];
                    final summary = BadgeEngine.evaluate(defs, appData, userData);
                    final earned = summary.badges.where((b) => b.isEarned).length;
                    return _buildBadgesSummaryCard(
                      context,
                      earned,
                      summary.badges.length,
                      summary.totalPoints,
                      summary.levelName,
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Recent Discoveries
                Text(
                  'Recent Discoveries',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                if (discoveredSpecies.isEmpty)
                  const Center(
                    child: Text('No species discovered yet!'),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: discoveredSpecies.length,
                    itemBuilder: (context, index) {
                      final species = discoveredSpecies[index];
                      return _buildSpeciesCard(context, species);
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeciesCard(BuildContext context, Species species) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: AppNetworkImage(
            url: species.apiImageUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: const Icon(Icons.image_not_supported),
              );
            },
          ),
        ),
        title: Text(species.name),
        subtitle: Text(species.scientificName),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AnimalDetailScreen(
                species: species,
                taxaList: widget.taxaList,
                allSpecies: widget.speciesList,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBadgesSummaryCard(
    BuildContext context,
    int earned,
    int total,
    int points,
    String level,
  ) {
    return Card(
      elevation: 2,
      child: ListTile(
        title: Text('$earned / $total earned'),
        subtitle: Text('$points points • $level'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const BadgesScreen(),
            ),
          );
        },
      ),
    );
  }

  Color _tierColorForPoints(int points) {
    if (points >= 150) return AppColors.tierMythic;
    if (points >= 100) return AppColors.tierLegendary;
    if (points >= 60) return AppColors.tierEpic;
    if (points >= 30) return AppColors.tierRare;
    if (points >= 10) return AppColors.tierUncommon;
    return AppColors.tierCommon;
  }
}
