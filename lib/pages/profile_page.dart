import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme.dart';
import '../models/habit.dart';
import '../services/supabase_service.dart';
import 'landing_page.dart';
import 'auth/signup_page.dart';
import '../services/notification_service.dart';

class ProfilePage extends StatefulWidget {
  final List<Habit> habits;
  final bool isGuest;

  const ProfilePage({super.key, required this.habits, required this.isGuest});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = 'Guest';
  String _email = '';
  String? _avatarUrl;
  bool _uploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    if (!widget.isGuest) {
      setState(() {
        _name = SupabaseService.currentUserName ?? 'User';
        _email = SupabaseService.currentUserEmail ?? '';
        _avatarUrl = SupabaseService.currentUserAvatarUrl;
      });
    }
  }

  Future<void> _showNotificationSettings(BuildContext context) async {
    final settings = await NotificationService.getSavedSettings();
    bool enabled = settings['enabled'] as bool;
    TimeOfDay time = TimeOfDay(
      hour: settings['hour'] as int,
      minute: settings['minute'] as int,
    );
    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Daily Reminder',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kText)),
              const SizedBox(height: 6),
              const Text('Get a nudge each day to complete your habits.',
                  style: TextStyle(color: kSubtext, fontSize: 14)),
              const SizedBox(height: 24),

              // Toggle row
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kBackground,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.notifications_active_rounded, color: kPrimary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text('Enable reminder',
                          style: TextStyle(fontWeight: FontWeight.w600, color: kText)),
                    ),
                    Switch.adaptive(
                      value: enabled,
                      activeColor: kPrimary,
                      onChanged: (val) => setModal(() => enabled = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Time picker
              if (enabled)
                GestureDetector(
                  onTap: () async {
                    final picked = await showTimePicker(
                        context: ctx, initialTime: time);
                    if (picked != null) setModal(() => time = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kPrimaryLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: kPrimary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time_rounded, color: kPrimary),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Remind me at',
                              style: TextStyle(color: kPrimary, fontWeight: FontWeight.w600)),
                        ),
                        Text(
                          time.format(ctx),
                          style: const TextStyle(
                              color: kPrimary, fontWeight: FontWeight.w800, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    if (enabled) {
                      await NotificationService.scheduleDailyReminder(
                        hour: time.hour,
                        minute: time.minute,
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('Reminder set for ${time.format(context)} every day'),
                          backgroundColor: kGreen,
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    } else {
                      await NotificationService.cancelReminder();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Reminder turned off'),
                          behavior: SnackBarBehavior.floating,
                        ));
                      }
                    }
                  },
                  child: const Text('Save',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Avatar upload ────────────────────────────────────────────────────────────

  Future<void> _pickAndUploadAvatar() async {
    if (widget.isGuest) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploadingAvatar = true);
    try {
      final url = await SupabaseService.uploadAvatar(File(picked.path));
      setState(() => _avatarUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingAvatar = false);
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    if (!widget.isGuest) await SupabaseService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LandingPage()),
            (_) => false,
      );
    }
  }

  // ── Stats ─────────────────────────────────────────────────────────────────────

  int get _bestStreak => widget.habits.isEmpty
      ? 0
      : widget.habits.map((h) => h.longestStreak).reduce(max);

  int get _totalDone =>
      widget.habits.fold(0, (sum, h) => sum + h.totalCompletions);

  int get _activeDays {
    final allDays = <String>{};
    for (final h in widget.habits) {
      allDays.addAll(
          h.completionHistory.entries.where((e) => e.value).map((e) => e.key));
    }
    return allDays.length;
  }

  double get _avgRate {
    if (widget.habits.isEmpty) return 0;
    return widget.habits
        .map((h) => h.completionRate30d)
        .reduce((a, b) => a + b) /
        widget.habits.length;
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final displayName = widget.isGuest ? 'Guest' : _name;
    final initials = displayName.trim().isEmpty
        ? '?'
        : displayName
        .trim()
        .split(' ')
        .map((w) => w[0])
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: kBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Gradient hero header ─────────────────────────────────────────
          SliverToBoxAdapter(child: _buildHero(context, displayName, initials)),

          // ── Body content ─────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Guest banner
                if (widget.isGuest) ...[
                  _buildGuestBanner(context),
                  const SizedBox(height: 24),
                ],

                // Stats
                _sectionTitle('Your Stats'),
                const SizedBox(height: 14),
                _buildStatsGrid(),
                const SizedBox(height: 28),

                // Achievements
                _sectionTitle('Achievements'),
                const SizedBox(height: 14),
                _buildAchievements(),
                const SizedBox(height: 28),

                // Account
                _sectionTitle('Account'),
                const SizedBox(height: 14),
                if (!widget.isGuest)
                  _settingsRow(Icons.edit_rounded, 'Edit Profile',
                      subtitle: 'Update your name',
                      onTap: () => _showEditProfile(context)),
                _settingsRow(Icons.notifications_outlined, 'Notifications',
                    subtitle: 'Daily reminders',
                    onTap: () => _showNotificationSettings(context)),
                _settingsRow(Icons.privacy_tip_outlined, 'Privacy Policy',
                    subtitle: 'How we use your data', onTap: () {}),
                _settingsRow(Icons.help_outline_rounded, 'Help & Support',
                    subtitle: 'FAQs and contact', onTap: () {}),
                const SizedBox(height: 8),

                // Logout
                _buildLogoutButton(),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Ritual v2.0.0',
                    style:
                    TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero section ─────────────────────────────────────────────────────────────

  Widget _buildHero(BuildContext context, String displayName, String initials) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Gradient background
        Container(
          height: 230,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF312E81), kPrimary, Color(0xFF818CF8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Subtle dot pattern
        Positioned.fill(
          child: Opacity(
            opacity: 0.05,
            child: CustomPaint(painter: _DotPatternPainter()),
          ),
        ),
        // Content
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + edit button
                  Row(
                    children: [
                      Text(
                        'Profile',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      if (!widget.isGuest)
                        GestureDetector(
                          onTap: () => _showEditProfile(context),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3)),
                            ),
                            child: const Icon(Icons.edit_rounded,
                                color: Colors.white, size: 18),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Avatar + name row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Tappable avatar with camera overlay
                      GestureDetector(
                        onTap: _pickAndUploadAvatar,
                        child: Stack(
                          children: [
                            // Avatar circle
                            Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: Colors.white.withOpacity(0.6),
                                    width: 2.5),
                                color: Colors.white.withOpacity(0.2),
                              ),
                              child: ClipOval(
                                child: _buildAvatarContent(initials),
                              ),
                            ),
                            // Upload spinner or camera badge
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: kPrimary.withOpacity(0.3),
                                      width: 1.5),
                                ),
                                child: _uploadingAvatar
                                    ? const Padding(
                                  padding: EdgeInsets.all(5),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: kPrimary,
                                  ),
                                )
                                    : Icon(
                                  widget.isGuest
                                      ? Icons.lock_rounded
                                      : Icons.camera_alt_rounded,
                                  color: kPrimary,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Name + email / guest badge
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (!widget.isGuest && _email.isNotEmpty)
                              Row(
                                children: [
                                  Icon(Icons.email_rounded,
                                      size: 12,
                                      color: Colors.white.withOpacity(0.7)),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      _email,
                                      style: TextStyle(
                                          color:
                                          Colors.white.withOpacity(0.75),
                                          fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.3)),
                                ),
                                child: const Text(
                                  'Guest Mode',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            if (!widget.isGuest) ...[
                              const SizedBox(height: 8),
                              _HeroStatRow(
                                  habits: widget.habits.length,
                                  streak: _bestStreak,
                                  done: _totalDone),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        // Curved bottom
        Positioned(
          bottom: -1,
          left: 0,
          right: 0,
          child: Container(
            height: 28,
            decoration: const BoxDecoration(
              color: kBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarContent(String initials) {
    if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return Image.network(
        _avatarUrl!,
        width: 76,
        height: 76,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initialsWidget(initials),
        loadingBuilder: (_, child, progress) {
          if (progress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded /
                  progress.expectedTotalBytes!
                  : null,
              strokeWidth: 2,
              color: Colors.white,
            ),
          );
        },
      );
    }
    return _initialsWidget(initials);
  }

  Widget _initialsWidget(String initials) => Container(
    width: 76,
    height: 76,
    color: Colors.white.withOpacity(0.15),
    child: Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );

  // ── Guest banner ─────────────────────────────────────────────────────────────

  Widget _buildGuestBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kPrimary.withOpacity(0.08), kPrimary.withOpacity(0.03)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kPrimary.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: kPrimaryLight, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.cloud_off_rounded, color: kPrimary, size: 22),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("You're in guest mode",
                    style: TextStyle(
                        color: kText, fontWeight: FontWeight.w700, fontSize: 14)),
                SizedBox(height: 2),
                Text('Sign up to sync across devices.',
                    style: TextStyle(color: kSubtext, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignUpPage()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Sign Up',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Stats grid ────────────────────────────────────────────────────────────────

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _StatCard(
          label: 'Habits',
          value: '${widget.habits.length}',
          unit: 'total',
          icon: Icons.checklist_rounded,
          color: kPrimary,
          bgColor: kPrimaryLight,
        ),
        _StatCard(
          label: 'Best Streak',
          value: '$_bestStreak',
          unit: 'days',
          icon: Icons.local_fire_department_rounded,
          color: kOrange,
          bgColor: kOrangeLight,
        ),
        _StatCard(
          label: 'Completions',
          value: '$_totalDone',
          unit: 'all time',
          icon: Icons.check_circle_rounded,
          color: kGreen,
          bgColor: kGreenLight,
        ),
        _StatCard(
          label: '30-day Rate',
          value: '${(_avgRate * 100).round()}%',
          unit: 'avg',
          icon: Icons.trending_up_rounded,
          color: const Color(0xFF8B5CF6),
          bgColor: const Color(0xFFF5F3FF),
        ),
      ],
    );
  }

  // ── Achievements ──────────────────────────────────────────────────────────────

  Widget _buildAchievements() {
    final achievements = [
      _Achievement(
        icon: Icons.local_fire_department_rounded,
        label: 'On Fire',
        desc: '7-day streak',
        earned: _bestStreak >= 7,
        color: kOrange,
      ),
      _Achievement(
        icon: Icons.emoji_events_rounded,
        label: 'Century',
        desc: '100 completions',
        earned: _totalDone >= 100,
        color: const Color(0xFFEAB308),
      ),
      _Achievement(
        icon: Icons.spa_rounded,
        label: 'Mindful',
        desc: '30-day streak',
        earned: _bestStreak >= 30,
        color: kGreen,
      ),
      _Achievement(
        icon: Icons.rocket_launch_rounded,
        label: 'Launcher',
        desc: '5+ habits',
        earned: widget.habits.length >= 5,
        color: kPrimary,
      ),
      _Achievement(
        icon: Icons.calendar_month_rounded,
        label: 'Consistent',
        desc: '${_activeDays}+ active days',
        earned: _activeDays >= 14,
        color: const Color(0xFF8B5CF6),
      ),
    ];

    return SizedBox(
      height: 116,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: achievements.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => _AchievementCard(achievement: achievements[i]),
      ),
    );
  }

  // ── Settings rows ─────────────────────────────────────────────────────────────

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
        fontSize: 18, fontWeight: FontWeight.w800, color: kText),
  );

  Widget _settingsRow(IconData icon, String title,
      {String? subtitle, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: kPrimaryLight, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: kPrimary, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: kText, fontSize: 14)),
        subtitle: subtitle != null
            ? Text(subtitle,
            style: const TextStyle(color: kSubtext, fontSize: 12))
            : null,
        trailing: Icon(Icons.chevron_right_rounded,
            color: Colors.grey.shade400, size: 22),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: ListTile(
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12)),
          child:
          Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 20),
        ),
        title: Text(
          widget.isGuest ? 'Exit Guest Mode' : 'Log Out',
          style: TextStyle(
              color: Colors.red.shade500,
              fontWeight: FontWeight.w700,
              fontSize: 14),
        ),
        trailing: Icon(Icons.chevron_right_rounded,
            color: Colors.red.shade300, size: 22),
        onTap: () => _confirmLogout(context),
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────────

  void _showEditProfile(BuildContext ctx) {
    final nameCtrl = TextEditingController(text: _name);
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
        builder: (_) => SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Edit Profile',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: kText)),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_rounded,
                      size: 18, color: kSubtext),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: kPrimary, width: 2),
                  ),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty) return;
                    await SupabaseService.updateUserName(nameCtrl.text.trim());
                    setState(() => _name = nameCtrl.text.trim());
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Profile updated!'),
                            behavior: SnackBarBehavior.floating),
                      );
                    }
                  },
                  child: const Text('Save Changes',
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
        ),
    );
  }

  void _confirmLogout(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Text(
          widget.isGuest ? 'Exit Guest Mode?' : 'Log Out?',
          style: const TextStyle(fontWeight: FontWeight.w800, color: kText),
        ),
        content: Text(
          widget.isGuest
              ? 'Your habits are saved locally. Create an account to keep them forever.'
              : 'You will be returned to the welcome screen.',
          style: const TextStyle(color: kSubtext),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: kSubtext, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0),
            onPressed: () {
              Navigator.pop(ctx);
              _logout();
            },
            child: Text(widget.isGuest ? 'Exit' : 'Log Out'),
          ),
        ],
      ),
    );
  }
}

// ─── Hero stat row (shown inside the gradient header for logged-in users) ──────

class _HeroStatRow extends StatelessWidget {
  final int habits;
  final int streak;
  final int done;
  const _HeroStatRow(
      {required this.habits, required this.streak, required this.done});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _pill('$habits', 'habits'),
        const SizedBox(width: 6),
        _pill('${streak}d', 'streak'),
        const SizedBox(width: 6),
        _pill('$done', 'done'),
      ],
    );
  }

  Widget _pill(String value, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(8),
    ),
    child: RichText(
      text: TextSpan(
        children: [
          TextSpan(
              text: '$value ',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12)),
          TextSpan(
              text: label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontWeight: FontWeight.w500,
                  fontSize: 11)),
        ],
      ),
    ),
  );
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: kText,
                  letterSpacing: -0.4,
                  height: 1)),
          const SizedBox(height: 2),
          Text(unit,
              style: const TextStyle(
                  color: kSubtext, fontSize: 10, fontWeight: FontWeight.w500)),
          const SizedBox(height: 1),
          Text(label,
              style: const TextStyle(
                  color: kText, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── Achievement Card ─────────────────────────────────────────────────────────

class _Achievement {
  final IconData icon;
  final String label;
  final String desc;
  final bool earned;
  final Color color;
  const _Achievement(
      {required this.icon,
        required this.label,
        required this.desc,
        required this.earned,
        required this.color});
}

class _AchievementCard extends StatelessWidget {
  final _Achievement achievement;
  const _AchievementCard({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final a = achievement;
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: a.earned ? a.color.withOpacity(0.08) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: a.earned ? a.color.withOpacity(0.25) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: a.earned ? a.color.withOpacity(0.15) : Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(a.icon,
                color: a.earned ? a.color : Colors.grey.shade400, size: 22),
          ),
          const SizedBox(height: 8),
          Text(a.label,
              style: TextStyle(
                  color: a.earned ? kText : Colors.grey.shade400,
                  fontWeight: FontWeight.w700,
                  fontSize: 10),
              textAlign: TextAlign.center),
          const SizedBox(height: 2),
          Text(a.desc,
              style: TextStyle(
                  color: a.earned ? kSubtext : Colors.grey.shade400,
                  fontSize: 9),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ─── Dot pattern painter ──────────────────────────────────────────────────────

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.5); // Added opacity
    const spacing = 20.0;
    const radius = 1.2;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false; // Changed from throw
}