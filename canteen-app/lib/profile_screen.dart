import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _mealsBooked = 0;
  int _mealsSkipped = 0;
  int _daysActiveThisMonth = 0;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadStats();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = await AuthService.getCurrentUser();
    if (mounted) {
      setState(() => _currentUser = user);
    }
  }

  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      int booked = 0;
      int skipped = 0;

      final now = DateTime.now();
      final currentMonthStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      Set<String> activeDaysThisMonth = {};

      for (final key in keys) {
        if (key.startsWith('booked_')) {
          if (prefs.getString(key) == 'true') {
            booked++;
            final parts = key.split('_');
            if (parts.length >= 2) {
              final datePart = parts[1];
              if (datePart.startsWith(currentMonthStr)) {
                activeDaysThisMonth.add(datePart);
              }
            }
          }
        } else if (key.startsWith('skipped_')) {
          if (prefs.getString(key) == 'true') {
            skipped++;
            final parts = key.split('_');
            if (parts.length >= 2) {
              final datePart = parts[1];
              if (datePart.startsWith(currentMonthStr)) {
                activeDaysThisMonth.add(datePart);
              }
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _mealsBooked = booked;
          _mealsSkipped = skipped;
          _daysActiveThisMonth = activeDaysThisMonth.length;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 20),
                  _buildInfoSections(),
                  const SizedBox(height: 4),
                  _buildQuickStats(),
                  const SizedBox(height: 20),
                  _buildSettingsList(),
                  const SizedBox(height: 32),
                  _buildLogoutButton(),
                ],
              ),
            ),
          ),
          _buildBottomNav(context),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 24,
        right: 24,
        bottom: 12,
      ),
      child: const Row(
        children: [
          Text(
            'My Profile',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    final fn = _currentUser?['firstName']?.toString() ?? '';
    final mn = _currentUser?['middleName']?.toString() ?? '';
    final ln = _currentUser?['lastName']?.toString() ?? '';
    String fullName = '';
    if (fn.isNotEmpty) fullName += fn;
    if (mn.isNotEmpty) fullName += ' $mn';
    if (ln.isNotEmpty) fullName += ' $ln';
    final name = fullName.isNotEmpty ? fullName : 'Student';

    final initial =
        _currentUser != null &&
            _currentUser!['firstName'].isNotEmpty &&
            _currentUser!['lastName'].isNotEmpty
        ? '${_currentUser!['firstName'][0]}${_currentUser!['lastName'][0]}'
              .toUpperCase()
        : 'ST';
    final hostel = _currentUser != null ? _currentUser!['hostel'] : 'Hostel';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hostel $hostel',
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'ACTIVE MEMBER',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSections() {
    final fn = _currentUser?['firstName']?.toString() ?? '';
    final mn = _currentUser?['middleName']?.toString() ?? '';
    final ln = _currentUser?['lastName']?.toString() ?? '';

    final firstName = fn.isEmpty ? 'Not Provided' : fn;
    final middleName = mn.isEmpty ? 'Not Provided' : mn;
    final lastName = ln.isEmpty ? 'Not Provided' : ln;

    String fullName = '';
    if (fn.isNotEmpty) fullName += fn;
    if (mn.isNotEmpty) fullName += ' $mn';
    if (ln.isNotEmpty) fullName += ' $ln';
    if (fullName.isEmpty) fullName = 'Not Provided';

    final email = _currentUser?['email']?.toString() ?? '';
    final emailDisplay = email.isEmpty ? 'Not Provided' : email;

    final phone = _currentUser?['phone']?.toString() ?? '';
    final phoneDisplay = phone.isEmpty ? 'Not Provided' : phone;

    final uid = _currentUser?['uid']?.toString() ?? '';
    final uidDisplay = uid.isEmpty ? 'Not Provided' : uid;

    final hostel = _currentUser?['hostel']?.toString() ?? '';
    final hostelDisplay = hostel.isEmpty ? 'Not Provided' : hostel;

    final room = _currentUser?['room']?.toString() ?? '';
    final roomDisplay = room.isEmpty ? 'Not Provided' : room;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _buildInfoSection('Personal Details', [
            {'label': 'Full Name', 'value': fullName},
            {'label': 'First Name', 'value': firstName},
            {'label': 'Middle Name', 'value': middleName},
            {'label': 'Last Name', 'value': lastName},
          ]),
          _buildInfoSection('Student Details', [
            {'label': 'UID', 'value': uidDisplay},
            {'label': 'University Email', 'value': emailDisplay},
          ]),
          _buildInfoSection('Hostel Details', [
            {'label': 'Hostel Number', 'value': hostelDisplay},
            {'label': 'Room Number', 'value': roomDisplay},
          ]),
          _buildInfoSection('Contact Information', [
            {'label': 'Phone Number', 'value': phoneDisplay},
          ]),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Map<String, String>> details) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEAE6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ...details.map((d) {
            // Hide the value if it's 'Not Provided' for optional fields
            if (d['label'] == 'Middle Name' && d['value'] == 'Not Provided') {
              return const SizedBox.shrink();
            }
            return _buildDetailRow(d['label']!, d['value']!);
          }),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _buildStatChip(
              '🍽️',
              'Meals Booked',
              _mealsBooked.toString(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatChip(
              '⏭️',
              'Meals Skipped',
              _mealsSkipped.toString(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatChip(
              '✅',
              'This Month',
              '$_daysActiveThisMonth days',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String emoji, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDEAE6), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFEDEAE6), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildSettingsRow(
              Icons.notifications_outlined,
              'Notifications',
              true,
            ),
            _buildSettingsRow(Icons.lock_outline, 'Privacy & Security', true),
            _buildSettingsRow(Icons.help_outline, 'Help & Support', true),
            _buildSettingsRow(Icons.info_outline, 'About', false),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsRow(IconData icon, String label, bool showDivider) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$label settings coming soon!')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.textDark, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFF0EEEA),
            indent: 72,
          ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () async {
            await AuthService.logout();
            if (mounted) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (_) => false,
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFFEBEE),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.red,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.logout, color: Colors.red, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 70 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Color(0xFFEDEAE6))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.home_outlined,
            label: 'HOME',
            isActive: false,
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (_) => false,
            ),
          ),
          _NavItem(
            icon: Icons.restaurant_menu_outlined,
            label: 'MENU',
            isActive: false,
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/meal-booking',
              (_) => false,
            ),
          ),
          _NavItem(
            icon: Icons.confirmation_number_outlined,
            label: 'TOKEN',
            isActive: false,
            onTap: () => Navigator.pushNamed(context, '/meal-pass'),
          ),
          _NavItem(
            icon: Icons.history_outlined,
            label: 'HISTORY',
            isActive: false,
            onTap: () => Navigator.pushNamed(context, '/history'),
          ),
          _NavItem(
            icon: Icons.person,
            label: 'PROFILE',
            isActive: true,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isActive ? AppColors.primary : AppColors.textDisabled,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isActive ? AppColors.primary : AppColors.textDisabled,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
