import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'app_colors.dart';
import 'auth_service.dart';
import 'services/api_service.dart';

class MealToken {
  final String date;
  final String meal;
  final String orderId;
  final List<String> items;
  final DateTime startTime;
  final DateTime endTime;
  final bool isSkipped;
  final String uid;
  final String hostel;
  final String room;

  MealToken({
    required this.date,
    required this.meal,
    required this.orderId,
    required this.items,
    required this.startTime,
    required this.endTime,
    required this.isSkipped,
    required this.uid,
    required this.hostel,
    required this.room,
  });
}

class MealPassScreen extends StatefulWidget {
  final int? bookingId;
  final String? studentName;
  final String? roomNumber;
  final String? orderID;
  final String? bookedDate;
  final String? location;
  final List<String>? bookedSlots;
  final Map<String, List<String>>? slotItems;

  const MealPassScreen({
    super.key,
    this.bookingId,
    this.studentName,
    this.roomNumber,
    this.orderID,
    this.bookedDate,
    this.location,
    this.bookedSlots,
    this.slotItems,
  });

  @override
  State<MealPassScreen> createState() => _MealPassScreenState();
}

class _MealPassScreenState extends State<MealPassScreen> {
  String _studentName = '';
  String _uid = '';
  bool _isLoading = true;
  List<MealToken> _allTokens = [];
  Timer? _timer;

  String? _qrPayload;
  bool _isLoadingQr = true;
  String? _qrError;

  @override
  void initState() {
    super.initState();
    _loadData();
    _fetchQrData();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _fetchQrData() async {
    final prefs = await SharedPreferences.getInstance();
    final bookingId = widget.bookingId ?? prefs.getInt('lastBooking_booking_id');
    if (bookingId == null) {
      if (mounted) {
        setState(() {
          _qrError = 'No booking ID available for QR generation.';
          _isLoadingQr = false;
        });
      }
      return;
    }

    try {
      final data = await ApiService.getQrData(bookingId);
      if (mounted) {
        setState(() {
          _qrPayload = data['qr_payload'] ?? 'INVALID_PAYLOAD';
          _isLoadingQr = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _qrError = e.toString().replaceAll('Exception: ', '');
          _isLoadingQr = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load QR: $_qrError')),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = AuthService.currentUser;
      _uid = user?['uid'] ?? 'default';
      final fn = user?['firstName']?.toString() ?? '';
      final mn = user?['middleName']?.toString() ?? '';
      final ln = user?['lastName']?.toString() ?? '';

      String fullName = '';
      if (fn.isNotEmpty) fullName += fn;
      if (mn.isNotEmpty) fullName += ' $mn';
      if (ln.isNotEmpty) fullName += ' $ln';
      _studentName = fullName.isNotEmpty ? fullName : 'Student';

      final hostel = user?['hostel'] ?? '---';
      final roomNumber = user?['room'] ?? '---';

      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      final List<MealToken> tokens = [];

      for (final key in keys) {
        if (key.startsWith('booked_${_uid}_')) {
          final parts = key.split('_');
          if (parts.length >= 4) {
            final dateStr = parts[2];
            final mealType = parts[3];

            final status = prefs.getString(key);
            if (status != 'true') continue;

            final itemsJson = prefs.getString(
              'items_${_uid}_${dateStr}_$mealType',
            );
            final items = itemsJson != null
                ? List<String>.from(jsonDecode(itemsJson))
                : <String>[];

            final dateParts = dateStr.split('-');
            final year = int.tryParse(dateParts[0]) ?? 2026;
            final month = int.tryParse(dateParts[1]) ?? 1;
            final day = int.tryParse(dateParts[2]) ?? 1;

            DateTime startTime;
            DateTime endTime;

            if (mealType == 'breakfast') {
              startTime = DateTime(year, month, day, 0, 0);
              endTime = DateTime(year, month, day, 10, 0);
            } else if (mealType == 'lunch') {
              startTime = DateTime(year, month, day, 10, 0);
              endTime = DateTime(year, month, day, 14, 30);
            } else if (mealType == 'snacks') {
              startTime = DateTime(year, month, day, 14, 30);
              endTime = DateTime(year, month, day, 18, 0);
            } else {
              startTime = DateTime(year, month, day, 18, 0);
              endTime = DateTime(year, month, day, 22, 30);
            }

            final isSkipped =
                prefs.getString('skipped_${_uid}_${dateStr}_$mealType') ==
                'true';

            final orderIdStr = (_uid + dateStr + mealType).hashCode
                .toString()
                .replaceAll('-', '');
            final orderId =
                '#ORD-${orderIdStr.length > 4 ? orderIdStr.substring(0, 4) : orderIdStr}';

            tokens.add(
              MealToken(
                date: dateStr,
                meal: mealType[0].toUpperCase() + mealType.substring(1),
                orderId: orderId,
                items: items,
                startTime: startTime,
                endTime: endTime,
                isSkipped: isSkipped,
                uid: _uid,
                hostel: hostel.toString(),
                room: roomNumber.toString(),
              ),
            );
          }
        }
      }

      tokens.sort((a, b) => a.startTime.compareTo(b.startTime));
      _allTokens = tokens;
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final now = DateTime.now();
    MealToken? activeToken;
    List<MealToken> upcomingTokens = [];

    for (final t in _allTokens) {
      if (t.isSkipped) continue;
      if (now.isAfter(t.endTime)) {
        // Expired, ignore for now
      } else if (now.isAfter(t.startTime) && now.isBefore(t.endTime)) {
        activeToken = t;
      } else {
        upcomingTokens.add(t);
      }
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (activeToken != null) ...[
                    _buildPassCard(context, activeToken),
                    const SizedBox(height: 16),
                    _buildMealDetails(activeToken),
                  ] else ...[
                    _buildEmptyState(),
                  ],
                  const SizedBox(height: 16),
                  if (upcomingTokens.isNotEmpty) ...[
                    _buildUpcomingTokens(upcomingTokens),
                    const SizedBox(height: 16),
                  ],
                  _buildActionsRow(context),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          _buildBottomNav(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.no_meals, size: 64, color: AppColors.textDisabled),
          const SizedBox(height: 16),
          const Text(
            'No Active Meal Token',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'You do not have any meal booked for this current time slot. Check your upcoming meals below or book a new one.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingTokens(List<MealToken> tokens) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'UPCOMING TOKENS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const Divider(height: 20, color: Color(0xFFF0EEEA)),
          ...tokens.map((t) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${t.meal} • ${t.date}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.orderId,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const Icon(
                    Icons.lock_clock,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      color: AppColors.background,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 24,
        right: 24,
        bottom: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'My Meal Pass',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEDEAE6)),
            ),
            child: const Icon(
              Icons.share_outlined,
              color: AppColors.textMuted,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassCard(BuildContext context, MealToken token) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'HOSTEL MESS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${token.meal} Pass',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.restaurant,
                      color: Colors.white70,
                      size: 32,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SizedBox(
                    width: 180,
                    height: 180,
                    child: _isLoadingQr
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : _qrError != null
                          ? Center(child: Text('QR Error', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)))
                          : QrImageView(
                              data: _qrPayload ?? '${token.uid}|${token.date}|${token.meal}|${token.orderId}',
                              version: QrVersions.auto,
                              backgroundColor: Colors.white,
                            ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _InfoChip(label: 'NAME', value: _studentName),
                      _InfoChip(label: 'ROOM', value: 'Room ${token.room}'),
                      _InfoChip(label: 'ORDER', value: token.orderId),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Show at counter
                const Text(
                  'Show this QR at the mess counter',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealDetails(MealToken token) {
    final startTimeStr =
        '${token.startTime.hour.toString().padLeft(2, '0')}:${token.startTime.minute.toString().padLeft(2, '0')}';
    final endTimeStr =
        '${token.endTime.hour.toString().padLeft(2, '0')}:${token.endTime.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'MEAL DETAILS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const Divider(height: 20, color: Color(0xFFF0EEEA)),
          _buildDetailRow('Meal Type', token.meal),
          _buildDetailRow('Date', token.date),
          _buildDetailRow('Valid Range', '$startTimeStr to $endTimeStr'),
          _buildDetailRow('Location', 'Hostel ${token.hostel}'),
          const Divider(height: 20, color: Color(0xFFF0EEEA)),
          const Text(
            'ITEMS SELECTED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            'Items',
            token.items.isEmpty ? 'Standard Menu' : token.items.join(', '),
          ),
          const Divider(height: 20, color: Color(0xFFF0EEEA)),
          const Text(
            'STATUS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Active — Ready to scan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
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

  Widget _buildActionsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            icon: Icons.skip_next_outlined,
            label: 'Skip Meal',
            onTap: () => Navigator.pushNamed(context, '/skip-meal'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.star_border,
            label: 'Feedback',
            onTap: () => Navigator.pushNamed(context, '/feedback'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionButton(
            icon: Icons.history,
            label: 'History',
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 70 + MediaQuery.of(context).padding.bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: const Border(top: BorderSide(color: Color(0xFFEDEAE6))),
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
            onTap: () => Navigator.pushNamed(context, '/meal-booking'),
          ),
          _NavItem(
            icon: Icons.confirmation_number,
            label: 'TOKEN',
            isActive: true,
            onTap: () {},
          ),
          _NavItem(
            icon: Icons.history_outlined,
            label: 'HISTORY',
            isActive: false,
            onTap: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/history',
              (_) => false,
            ),
          ),
          _NavItem(
            icon: Icons.person_outline,
            label: 'PROFILE',
            isActive: false,
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white60,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
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
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
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
            size: 22,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: isActive ? AppColors.primary : AppColors.textDisabled,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
