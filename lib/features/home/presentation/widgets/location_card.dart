import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:prince_academy/core/constants/app_colors.dart';
import 'package:prince_academy/features/admin/data/models/branch_model.dart';
import 'package:prince_academy/features/maps/data/models/maps_model.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationCard extends StatelessWidget {
  final Branch? branch;

  const LocationCard({
    super.key,
    this.branch,
  });

  GymLocation? _matchedGym() {
    if (branch == null) return gymLocations.isNotEmpty ? gymLocations.first : null;
    final name = branch!.name.toLowerCase();
    for (final gym in gymLocations) {
      if (gym.name.toLowerCase().contains(name) ||
          name.contains(gym.name.toLowerCase())) {
        return gym;
      }
    }
    return gymLocations.isNotEmpty ? gymLocations.first : null;
  }

  Future<void> _openDirections(BuildContext context) async {
    final gym = _matchedGym();
    final query = gym != null
        ? '${gym.latitude},${gym.longitude}'
        : Uri.encodeComponent(branch?.address ?? branch?.name ?? 'Prince Academy');
    final url = gym != null
        ? 'https://www.google.com/maps/search/?api=1&query=$query'
        : 'https://www.google.com/maps/search/?api=1&query=$query';

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open directions')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gym = _matchedGym();
    final title = branch?.name ?? gym?.name ?? 'Prince Academy';
    final address = branch?.address ?? gym?.address ?? '';

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            blurRadius: 12,
            offset: const Offset(0, 4),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Container(
            height: 72,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Iconsax.map,
              size: 36,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              address,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _openDirections(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child: const Text('Get Directions'),
            ),
          ),
        ],
      ),
    );
  }
}
