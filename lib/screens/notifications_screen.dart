import 'dart:async';

import 'package:flutter/material.dart';

import '../data/channel_data.dart';
import '../services/notification_service.dart';
import '../services/user_profile_service.dart';
import '../theme/app_theme.dart';

/// Notification preferences screen — reached via the bell icon in the
/// home screen header.
///
/// Shows:
///   • A single toggle: new-video alerts on/off (persisted via
///     NotificationService.setNotificationsEnabled).
///   • Which channels the background check will watch (the person's
///     selected-category channels + the 12 general channels).
///   • A permission-request button if the OS hasn't granted permission yet.
///
/// No push server required — all notifications are local, fired by the
/// WorkManager background task (see background_service.dart).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _enabled      = true;
  bool _loading      = true;
  bool _requesting   = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await NotificationService.instance.areNotificationsEnabled();
    if (mounted) setState(() { _enabled = enabled; _loading = false; });
  }

  Future<void> _toggle(bool value) async {
    setState(() => _enabled = value);
    await NotificationService.instance.setNotificationsEnabled(value);
    if (value && mounted) {
      // Request OS permission the first time the user enables notifications
      await _requestPermission();
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _requesting = true);
    await NotificationService.instance.requestPermission();
    if (mounted) setState(() => _requesting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.bgColor(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              size: 20, color: AppTheme.textColor(context)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Notifications',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.gold))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                _buildToggleCard(context),
                const SizedBox(height: 24),
                if (_enabled) ...[
                  _buildChannelsSection(context),
                  const SizedBox(height: 24),
                ],
                _buildPermissionCard(context),
              ],
            ),
    );
  }

  // ── Toggle card ──────────────────────────────────────────────────────────────

  Widget _buildToggleCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _enabled
                ? AppTheme.gold.withValues(alpha: 0.4)
                : AppTheme.dividerColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _enabled
                  ? AppTheme.gold.withValues(alpha: 0.12)
                  : AppTheme.dividerColor(context).withValues(alpha: 0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _enabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color: _enabled ? AppTheme.gold : AppTheme.textMuted(context),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New video alerts',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Get notified when channels you follow upload new videos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary(context)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value:    _enabled,
            onChanged: _toggle,
            activeColor: AppTheme.gold,
          ),
        ],
      ),
    );
  }

  // ── Channels being watched ────────────────────────────────────────────────────

  Widget _buildChannelsSection(BuildContext context) {
    final selected  = UserProfileService.instance.selectedCategoryIds;
    final channels  = ChannelData.eagerFor(selected);
    final count     = channels.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Channels you\'ll hear from ($count)',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.gold,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 10),
        ...channels.take(12).map((ch) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration:
                        BoxDecoration(color: ch.accentColor, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      ch.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            )),
        if (count > 12)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+ ${count - 12} more channels',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textMuted(context)),
            ),
          ),
      ],
    );
  }

  // ── OS permission card ────────────────────────────────────────────────────────

  Widget _buildPermissionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Device permission',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'FinReels needs notification permission to alert you about new videos. '
            'Tap below to grant it — you only need to do this once.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppTheme.textSecondary(context)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _requesting ? null : _requestPermission,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.gold,
                side: BorderSide(color: AppTheme.gold.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: _requesting
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          color: AppTheme.gold, strokeWidth: 2))
                  : const Icon(Icons.notifications_none_rounded, size: 18),
              label: Text(
                _requesting ? 'Requesting…' : 'Grant Permission',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
