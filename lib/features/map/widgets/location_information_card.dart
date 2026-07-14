import 'dart:async';

import 'package:flutter/material.dart';

import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import '../constants/map_constants.dart';
import '../models/current_location_model.dart';
import '../services/permission_service.dart';
import '../utils/gps_helper.dart';

/// The bottom telemetry card. Displays the current address, every
/// [CurrentLocationModel] field, and GPS / permission badges.
///
/// Responsive: lays out 1 column under 360 px, 2 columns between 360 and
/// 600 px, and 3 columns at 600 px and above. The "Last updated" label
/// updates on its own via a periodic [Timer] so the relative-time string
/// advances without a new GPS fix.
class LocationInformationCard extends StatefulWidget {
  const LocationInformationCard({
    super.key,
    required this.location,
    required this.address,
    required this.gpsEnabled,
    required this.permissionStatus,
    required this.lastUpdatedAt,
  });

  final CurrentLocationModel location;
  final String address;
  final bool gpsEnabled;
  final LocationPermissionState permissionStatus;
  final DateTime lastUpdatedAt;

  @override
  State<LocationInformationCard> createState() =>
      _LocationInformationCardState();
}

class _LocationInformationCardState extends State<LocationInformationCard> {
  late Timer _refreshTimer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _refreshTimer = Timer.periodic(
      MapConstants.relativeTimeRefreshInterval,
      (_) {
        if (!mounted) return;
        setState(() => _now = DateTime.now());
      },
    );
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      elevation: 12,
      shadowColor: scheme.shadow.withValues(alpha: 0.15),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(AppSizes.radiusXXL),
        topRight: Radius.circular(AppSizes.radiusXXL),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.paddingLG,
            AppSizes.paddingLG,
            AppSizes.paddingLG,
            AppSizes.paddingLG,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Slide indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(AppSizes.radiusXS),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingMD),

              // Header: address
              _AddressHeader(address: widget.address),
              const SizedBox(height: AppSizes.paddingLG),
              Divider(color: scheme.outlineVariant, height: 1),
              const SizedBox(height: AppSizes.paddingLG),

              // Responsive telemetry grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 600
                      ? 3
                      : constraints.maxWidth >= 360
                          ? 2
                          : 1;
                  return _TelemetryGrid(
                    columns: columns,
                    location: widget.location,
                    lastUpdatedAt: widget.lastUpdatedAt,
                    now: _now,
                  );
                },
              ),
              const SizedBox(height: AppSizes.paddingLG),
              Divider(color: scheme.outlineVariant, height: 1),
              const SizedBox(height: AppSizes.paddingLG),

              // Status badges
              Row(
                children: [
                  Expanded(
                    child: _StatusBadge(
                      label: 'GPS Hardware',
                      statusText: widget.gpsEnabled ? 'Enabled' : 'Disabled',
                      isOk: widget.gpsEnabled,
                      icon: widget.gpsEnabled
                          ? Icons.check_circle_outline_rounded
                          : Icons.highlight_off_rounded,
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingSM),
                  Expanded(
                    child: _StatusBadge(
                      label: 'Permission',
                      statusText: _permissionStatusText(widget.permissionStatus),
                      isOk: widget.permissionStatus ==
                          LocationPermissionState.granted,
                      icon: widget.permissionStatus ==
                              LocationPermissionState.granted
                          ? Icons.verified_user_outlined
                          : Icons.gpp_bad_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _permissionStatusText(LocationPermissionState state) {
    switch (state) {
      case LocationPermissionState.granted:
        return 'Granted';
      case LocationPermissionState.denied:
        return 'Denied';
      case LocationPermissionState.permanentlyDenied:
        return 'Restricted';
      case LocationPermissionState.serviceDisabled:
        return 'Offline';
    }
  }
}

class _AddressHeader extends StatelessWidget {
  const _AddressHeader({required this.address});
  final String address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.paddingSM),
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(AppSizes.radiusMD),
          ),
          child: Icon(
            Icons.location_on_rounded,
            color: scheme.primary,
            size: AppSizes.iconMD,
          ),
        ),
        const SizedBox(width: AppSizes.paddingMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CURRENT ADDRESS',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: AppSizes.paddingXXS),
              Text(
                address.isNotEmpty ? address : 'Fetching address...',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Renders the telemetry items in a 1, 2, or 3 column grid based on
/// available width. Uses [LayoutBuilder] to compute column width.
class _TelemetryGrid extends StatelessWidget {
  const _TelemetryGrid({
    required this.columns,
    required this.location,
    required this.lastUpdatedAt,
    required this.now,
  });

  final int columns;
  final CurrentLocationModel location;
  final DateTime lastUpdatedAt;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final items = <_TelemetryItem>[
      _TelemetryItem(
        icon: Icons.my_location_rounded,
        label: 'Coordinates',
        value: GpsHelper.formatCoordinates(
          location.latitude,
          location.longitude,
        ),
      ),
      _TelemetryItem(
        icon: Icons.radar_rounded,
        label: 'Accuracy',
        value: GpsHelper.formatAccuracy(location.accuracy),
      ),
      _TelemetryItem(
        icon: Icons.landscape_rounded,
        label: 'Altitude',
        value: GpsHelper.formatAltitude(location.altitude),
      ),
      _TelemetryItem(
        icon: Icons.speed_rounded,
        label: 'Speed',
        value: GpsHelper.formatSpeed(location.speed),
      ),
      _TelemetryItem(
        icon: Icons.navigation_rounded,
        label: 'Heading',
        value: GpsHelper.formatHeading(location.heading),
      ),
      _TelemetryItem(
        icon: Icons.access_time_rounded,
        label: 'Last Updated',
        value: GpsHelper.formatRelativeTime(lastUpdatedAt, now: now),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = AppSizes.paddingMD;
        final columnWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;

        // Build rows of `columns` items each.
        final rows = <Widget>[];
        for (var i = 0; i < items.length; i += columns) {
          final rowItems = items.skip(i).take(columns).toList();
          rows.add(
            Row(
              children: [
                for (var j = 0; j < rowItems.length; j++) ...[
                  SizedBox(
                    width: columnWidth,
                    child: _TelemetryTile(item: rowItems[j]),
                  ),
                  if (j < rowItems.length - 1)
                    const SizedBox(width: AppSizes.paddingXS),
                ],
                // Pad short rows so the row still occupies full width and
                // aligns with longer rows above.
                for (var k = 0; k < columns - rowItems.length; k++)
                  const Spacer(),
              ],
            ),
          );
          if (i + columns < items.length) {
            rows.add(const SizedBox(height: AppSizes.paddingMD));
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}

class _TelemetryItem {
  const _TelemetryItem({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
}

class _TelemetryTile extends StatelessWidget {
  const _TelemetryTile({required this.item});
  final _TelemetryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(item.icon, color: scheme.onSurfaceVariant, size: 18),
        const SizedBox(width: AppSizes.paddingXS),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                item.value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.statusText,
    required this.isOk,
    required this.icon,
  });

  final String label;
  final String statusText;
  final bool isOk;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final themeColor = isOk ? AppColors.successGreen : AppColors.errorRed;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSM,
        vertical: AppSizes.paddingSM,
      ),
      decoration: BoxDecoration(
        color: themeColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSizes.radiusMD),
        border: Border.all(
          color: themeColor.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: themeColor, size: AppSizes.iconSM),
          const SizedBox(width: AppSizes.paddingXS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  statusText,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: themeColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}