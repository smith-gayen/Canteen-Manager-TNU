import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'app_colors.dart';
import 'meal_state.dart';
import 'auth_service.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackSlot {
  final String dateKey; // YYYY-MM-DD
  final String displayDate;
  final String slot; // Breakfast, Lunch...
  final List<String> items;
  bool isScanned;
  bool hasFeedback;
  int foodRating;
  int serviceRating;
  int cleanlinessRating;
  String comment;

  _FeedbackSlot({
    required this.dateKey,
    required this.displayDate,
    required this.slot,
    required this.items,
    this.isScanned = false,
    this.hasFeedback = false,
    this.foodRating = 0,
    this.serviceRating = 0,
    this.cleanlinessRating = 0,
    this.comment = '',
  });
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  bool _isLoading = true;
  List<_FeedbackSlot> _slots = [];

  @override
  void initState() {
    super.initState();
    _loadData();
    MealStateProvider.instance.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) _loadData();
  }

  @override
  void dispose() {
    MealStateProvider.instance.removeListener(_onStateChanged);
    super.dispose();
  }

  String _formatDisplayDate(String ymd) {
    try {
      final parts = ymd.split('-');
      final date = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${weekdays[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
    } catch (_) {
      return ymd;
    }
  }

  Future<void> _loadData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final List<_FeedbackSlot> loaded = [];

      final uid = AuthService.currentUser?['uid'] ?? 'default';

      for (final key in keys) {
        if (key.startsWith('booked_${uid}_')) {
          final parts = key.split('_');
          if (parts.length >= 4) {
            final dateKey = parts[2];
            final slot = parts[3];
            final status = prefs.getString(key);

            if (status == 'true') {
              // It's a booked meal
              final itemsJson = prefs.getString(
                'items_${uid}_${dateKey}_$slot',
              );
              final items = itemsJson != null
                  ? List<String>.from(jsonDecode(itemsJson))
                  : <String>[];

              final isScanned =
                  prefs.getString('scanned_${uid}_${dateKey}_$slot') == 'true';
              final hasFeedback =
                  prefs.getBool('feedback_${uid}_${dateKey}_$slot') ?? false;

              int foodRating = 0, serviceRating = 0, cleanlinessRating = 0;
              String comment = '';
              if (hasFeedback) {
                foodRating =
                    prefs.getInt('feedback_food_${uid}_${dateKey}_$slot') ?? 0;
                serviceRating =
                    prefs.getInt('feedback_service_${uid}_${dateKey}_$slot') ??
                    0;
                cleanlinessRating =
                    prefs.getInt(
                      'feedback_cleanliness_${uid}_${dateKey}_$slot',
                    ) ??
                    0;
                comment =
                    prefs.getString(
                      'feedback_comment_${uid}_${dateKey}_$slot',
                    ) ??
                    '';
              }

              loaded.add(
                _FeedbackSlot(
                  dateKey: dateKey,
                  displayDate: _formatDisplayDate(dateKey),
                  slot: '${slot[0].toUpperCase()}${slot.substring(1)}',
                  items: items,
                  isScanned: isScanned,
                  hasFeedback: hasFeedback,
                  foodRating: foodRating,
                  serviceRating: serviceRating,
                  cleanlinessRating: cleanlinessRating,
                  comment: comment,
                ),
              );
            }
          }
        }
      }

      // Sort newest first
      loaded.sort((a, b) => b.dateKey.compareTo(a.dateKey));

      if (mounted) {
        setState(() {
          _slots = loaded;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _simulateScan(_FeedbackSlot slot) async {
    final uid = AuthService.currentUser?['uid'] ?? 'default';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'scanned_${uid}_${slot.dateKey}_${slot.slot.toLowerCase()}',
      'true',
    );
    _loadData();
  }

  Future<void> _submitFeedback(
    _FeedbackSlot slot,
    int food,
    int service,
    int clean,
    String comment,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final lowerSlot = slot.slot.toLowerCase();
    await prefs.setBool('feedback_submitted_${slot.dateKey}_$lowerSlot', true);
    await prefs.setInt('feedback_food_${slot.dateKey}_$lowerSlot', food);
    await prefs.setInt('feedback_service_${slot.dateKey}_$lowerSlot', service);
    await prefs.setInt(
      'feedback_cleanliness_${slot.dateKey}_$lowerSlot',
      clean,
    );
    await prefs.setString(
      'feedback_comment_${slot.dateKey}_$lowerSlot',
      comment,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thank you for your feedback! 🙏'),
        backgroundColor: AppColors.primary,
      ),
    );
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _slots.isEmpty
                ? const Center(
                    child: Text(
                      'No booked meals found.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _slots.length,
                    itemBuilder: (ctx, idx) => _buildSlotCard(_slots[idx]),
                  ),
          ),
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
            'Meal Feedback',
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

  Widget _buildSlotCard(_FeedbackSlot slot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.slot,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slot.displayDate,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (slot.hasFeedback)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'SUBMITTED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                )
              else if (!slot.isScanned)
                GestureDetector(
                  onDoubleTap: () =>
                      _simulateScan(slot), // Secret double tap to simulate scan
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.lock_outline,
                          size: 12,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'LOCKED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'PENDING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.red,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Items: ${slot.items.join(', ')}',
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEDEAE6)),
          const SizedBox(height: 16),
          if (slot.hasFeedback)
            _buildReadonlyFeedback(slot)
          else if (!slot.isScanned)
            _buildLockedFeedback()
          else
            _FeedbackForm(
              slot: slot,
              onSubmit: (f, s, c, text) => _submitFeedback(slot, f, s, c, text),
            ),
        ],
      ),
    );
  }

  Widget _buildLockedFeedback() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: const [
          Icon(Icons.info_outline, color: AppColors.textMuted, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Feedback unlocks after meal collection is verified via QR scan.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadonlyFeedback(_FeedbackSlot slot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildReadonlyRating('Food Quality', slot.foodRating),
        const SizedBox(height: 8),
        _buildReadonlyRating('Service', slot.serviceRating),
        const SizedBox(height: 8),
        _buildReadonlyRating('Cleanliness', slot.cleanlinessRating),
        if (slot.comment.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '"${slot.comment}"',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textDark,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReadonlyRating(String label, int rating) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        Row(
          children: List.generate(
            5,
            (i) => Icon(
              i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
              color: i < rating ? AppColors.primary : const Color(0xFFD6D3CE),
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _FeedbackForm extends StatefulWidget {
  final _FeedbackSlot slot;
  final Function(int, int, int, String) onSubmit;

  const _FeedbackForm({required this.slot, required this.onSubmit});

  @override
  State<_FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<_FeedbackForm> {
  int _foodRating = 0;
  int _serviceRating = 0;
  int _cleanlinessRating = 0;
  final _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildRatingRow(
          'Food Quality',
          _foodRating,
          (v) => setState(() => _foodRating = v),
        ),
        const SizedBox(height: 12),
        _buildRatingRow(
          'Service',
          _serviceRating,
          (v) => setState(() => _serviceRating = v),
        ),
        const SizedBox(height: 12),
        _buildRatingRow(
          'Cleanliness',
          _cleanlinessRating,
          (v) => setState(() => _cleanlinessRating = v),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _commentController,
          maxLines: 2,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Add a comment (optional)',
            hintStyle: const TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
            filled: true,
            fillColor: AppColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 0,
            ),
            onPressed:
                (_foodRating > 0 ||
                    _serviceRating > 0 ||
                    _cleanlinessRating > 0)
                ? () => widget.onSubmit(
                    _foodRating,
                    _serviceRating,
                    _cleanlinessRating,
                    _commentController.text,
                  )
                : null,
            child: const Text(
              'Submit Review',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRatingRow(
    String label,
    int rating,
    ValueChanged<int> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        Row(
          children: List.generate(
            5,
            (i) => GestureDetector(
              onTap: () => onChanged(i + 1),
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: i < rating
                      ? AppColors.primary
                      : const Color(0xFFD6D3CE),
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
