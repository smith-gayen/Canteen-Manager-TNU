import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'skip_meal_screen.dart';
import 'meal_pass_screen.dart';
import 'meal_state.dart';
import 'auth_service.dart';
import 'services/api_service.dart';

class MealBookingScreen extends StatefulWidget {
  const MealBookingScreen({super.key});

  @override
  State<MealBookingScreen> createState() => _MealBookingScreenState();
}

class _MealBookingScreenState extends State<MealBookingScreen> {
  late DateTime _selectedDate;
  int _selectedMeal = 0;
  final Map<int, bool> _isRebooking = {0: false, 1: false, 2: false, 3: false};
  final Map<int, bool> _skippedMeals = {};
  final Map<int, bool> _bookedMeals = {};
  final Map<int, bool> _cancelledMeals = {};
  final Map<int, List<String>> _bookedItemsList = {};

  final List<String> _mealTimes = ['7:30 AM', '12:15 PM', '4:30 PM', '7:30 PM'];
  final List<String> _mealTabs = ['Breakfast', 'Lunch', 'Snacks', 'Dinner'];

  final Map<int, Set<int>> _selectedItems = {
    0: {0},
    1: {0},
    2: {0},
    3: {0},
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    _loadStateForDate();
    MealStateProvider.instance.addListener(_onStateChanged);
  }

  void _onStateChanged() {
    if (mounted) _loadStateForDate();
  }

  @override
  void dispose() {
    MealStateProvider.instance.removeListener(_onStateChanged);
    super.dispose();
  }

  String _formatDateKey(DateTime date) {
    final uid = AuthService.currentUser?['uid'] ?? 'default';
    return '${uid}_${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDate(DateTime date) {
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
  }

  bool get _isAdvanceOrder {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    return selectedDay.isAfter(tomorrow);
  }

  Future<void> _loadStateForDate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateKey = _formatDateKey(_selectedDate);
      setState(() {
        for (int i = 0; i < _mealTabs.length; i++) {
          final tabName = _mealTabs[i].toLowerCase();
          _skippedMeals[i] =
              prefs.getString('skipped_${dateKey}_$tabName') == 'true';

          final bookedVal = prefs.getString('booked_${dateKey}_$tabName');
          _bookedMeals[i] = bookedVal == 'true';
          _cancelledMeals[i] = bookedVal == 'cancelled';

          if (_bookedMeals[i]! || _cancelledMeals[i]!) {
            final itemsJson = prefs.getString('items_${dateKey}_$tabName');
            if (itemsJson != null) {
              _bookedItemsList[i] = List<String>.from(jsonDecode(itemsJson));
            } else {
              _bookedItemsList[i] = [];
            }
          } else {
            _bookedItemsList[i] = [];
          }
        }

        if (_isAdvanceOrder) {
          _setToStandardMenu();
        } else {
          for (int i = 0; i < 4; i++) {
            _selectedItems[i] = {0};
          }
        }
      });
    } catch (_) {}
  }

  void _setToStandardMenu() {
    for (int i = 0; i < _allMenuItems.length; i++) {
      final items = _allMenuItems[i];
      final selected = <int>{};
      final Set<String> groupsHandled = {};

      for (int j = 0; j < items.length; j++) {
        final exclusive = items[j]['exclusive'] as String?;
        if (exclusive != null) {
          if (!groupsHandled.contains(exclusive)) {
            selected.add(j);
            groupsHandled.add(exclusive);
          }
        } else {
          selected.add(j);
        }
      }
      _selectedItems[i] = selected;
    }
  }

  // ── Per-tab deadline info ──
  final List<Map<String, dynamic>> _deadlineInfo = [
    {'closeTime': '7:00 AM today', 'remaining': 45},
    {'closeTime': '2:00 PM today', 'remaining': 102},
    {'closeTime': '4:00 PM today', 'remaining': 180},
    {'closeTime': '6:00 PM today', 'remaining': 240},
  ];

  // ── Per-tab menu titles ──
  final List<String> _menuTitles = [
    'Morning Breakfast Menu',
    'Organic Lunch Menu',
    'Evening Snacks Menu',
    'Wholesome Dinner Menu',
  ];

  // ── Menu items per tab ──
  // Items with 'exclusive' key share a radio group — only one can be selected.
  final List<List<Map<String, dynamic>>> _allMenuItems = [
    // ── Breakfast ──
    [
      {
        'name': 'Poha',
        'desc': 'Light flattened rice with mustard seeds and curry leaves.',
        'icon': Icons.rice_bowl,
        'veg': true,
      },
      {
        'name': 'Boiled Eggs',
        'desc': 'Two farm-fresh boiled eggs.',
        'icon': Icons.egg_outlined,
        'veg': false,
      },
      {
        'name': 'Bread & Butter',
        'desc': 'Toasted white bread with salted butter.',
        'icon': Icons.bakery_dining,
        'veg': true,
      },
      {
        'name': 'Banana',
        'desc': 'Fresh seasonal fruit.',
        'icon': Icons.eco,
        'veg': true,
      },
    ],
    // ── Lunch ──
    [
      {
        'name': 'Rice & Dal',
        'desc': 'Hand-milled brown rice, aromatic dal tadka.',
        'icon': Icons.rice_bowl,
        'veg': true,
      },
      {
        'name': 'Fish Curry Potato',
        'desc': 'Multi-grain, served warm with butter.',
        'icon': Icons.set_meal,
        'veg': false,
        'exclusive': 'lunch_main',
      },
      {
        'name': 'Paneer',
        'desc': 'Multi-grain, served warm with butter.',
        'icon': Icons.lunch_dining,
        'veg': true,
        'exclusive': 'lunch_main',
      },
      {
        'name': 'Seasonal Salad',
        'desc': 'Garden greens with citrus dressing.',
        'icon': Icons.eco,
        'veg': true,
      },
    ],
    // ── Snacks ──
    [
      {
        'name': 'Samosa',
        'desc': 'Crispy fried pastry with spiced potato filling.',
        'icon': Icons.lunch_dining,
        'veg': true,
      },
      {
        'name': 'Veg Cutlet',
        'desc': 'Pan-fried mixed vegetable patty.',
        'icon': Icons.set_meal,
        'veg': true,
      },
      {
        'name': 'Chai',
        'desc': 'Hot ginger tea with milk.',
        'icon': Icons.coffee,
        'veg': true,
      },
      {
        'name': 'Biscuits',
        'desc': 'Assorted cream biscuits.',
        'icon': Icons.cookie_outlined,
        'veg': true,
      },
    ],
    // ── Dinner ──
    [
      {
        'name': 'Roti',
        'desc': 'Fresh soft wheat flatbread.',
        'icon': Icons.bakery_dining,
        'veg': true,
      },
      {
        'name': 'Dal Makhani',
        'desc': 'Slow-cooked black lentils in creamy gravy.',
        'icon': Icons.rice_bowl,
        'veg': true,
      },
      {
        'name': 'Chicken Curry',
        'desc': 'Tender chicken in spiced tomato gravy.',
        'icon': Icons.set_meal,
        'veg': false,
        'exclusive': 'dinner_main',
      },
      {
        'name': 'Paneer Butter Masala',
        'desc': 'Cottage cheese in rich buttery tomato sauce.',
        'icon': Icons.lunch_dining,
        'veg': true,
        'exclusive': 'dinner_main',
      },
      {
        'name': 'Kheer',
        'desc': 'Sweet rice pudding with cardamom.',
        'icon': Icons.icecream,
        'veg': true,
      },
    ],
  ];

  // ── Helpers ──

  Future<void> _confirmBooking(int index) async {
    final dateKey = _formatDateKey(_selectedDate);
    final tabName = _mealTabs[index];
    final selectedNames = <String>[];
    final items = _allMenuItems[index];
    final selected = _selectedItems[index] ?? {};

    for (int j = 0; j < items.length; j++) {
      if (selected.contains(j)) {
        selectedNames.add(items[j]['name'] as String);
      }
    }

    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one item'))
      );
      return;
    }

    final slotId = index + 1;
    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final selectedBackendIds = <int>[];
    Map<String, dynamic> bookingResp;
    try {
      final menuResp = await ApiService.getMenu(date: dateStr, slotId: slotId);
      final menuItems = (menuResp['items'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .toList();
      final selectedNamesLower = selectedNames.map((e) => e.toLowerCase()).toSet();
      for (final item in menuItems) {
        final name = item['name']?.toString().toLowerCase();
        final id = item['id'];
        if (name != null && selectedNamesLower.contains(name) && id is int) {
          selectedBackendIds.add(id);
        }
      }
      if (selectedBackendIds.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected items are unavailable in current backend menu')),
          );
        }
        return;
      }
      bookingResp = await ApiService.createBooking(slotId, dateStr, selectedBackendIds);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking successful!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      return;
    }

    final backendOrderId = bookingResp['order_id']?.toString();
    final backendBookingId = bookingResp['id'] as int?;
    final orderID = backendOrderId ?? '#ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'booked_${dateKey}_${tabName.toLowerCase()}',
        'true',
      );
      await prefs.setString(
        'items_${dateKey}_${tabName.toLowerCase()}',
        jsonEncode(selectedNames),
      );

      await prefs.setString('lastBooking_slots', jsonEncode([tabName]));
      await prefs.setString(
        'lastBooking_items',
        jsonEncode({tabName: selectedNames}),
      );
      await prefs.setString('lastBooking_date', _formatDate(_selectedDate));
      await prefs.setString('lastBooking_orderID', orderID);
      if (backendBookingId != null) {
        await prefs.setInt('lastBooking_booking_id', backendBookingId);
      }
      MealStateProvider.instance.notifyStateChanged();
    } catch (_) {}

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MealPassScreen(
          studentName: 'Aryan Shah',
          roomNumber: '402-B',
          bookingId: backendBookingId,
          orderID: orderID,
          bookedDate: _formatDate(_selectedDate),
          location: 'Hostel L5',
          bookedSlots: [tabName],
          slotItems: {tabName: selectedNames},
        ),
      ),
    );

    if (!mounted) return;
    _loadStateForDate();
  }

  String _getSelectedMenuSummary(int index) {
    final items = _allMenuItems[index];
    final selected = _selectedItems[index] ?? {};
    final names = <String>[];
    for (int i = 0; i < items.length; i++) {
      if (selected.contains(i)) names.add(items[i]['name'] as String);
    }
    return names.isEmpty ? 'No items selected' : names.join(', ');
  }

  void _showSkipConfirmation(int index) {
    final mealName = _mealTabs[index];
    final mealTime = _mealTimes[index];
    final mealMenu = _getSelectedMenuSummary(index);
    final mealDate = _formatDate(_selectedDate);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD6D3CE),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.primary,
              size: 40,
            ),
            const SizedBox(height: 16),
            const Text(
              'Skip this meal?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You're about to skip $mealName for $mealDate. This will be deducted from your monthly allowance.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD6D3CE)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Go Back',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final reason = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SkipMealScreen(
                                mealType: mealName,
                                mealTime: mealTime,
                                mealMenu: mealMenu,
                                mealDate: mealDate,
                              ),
                            ),
                          );
                          if (reason != null && reason is String) {
                            final prefs = await SharedPreferences.getInstance();
                            final dateKey = _formatDateKey(_selectedDate);
                            await prefs.setString(
                              'skipped_${dateKey}_${mealName.toLowerCase()}',
                              'true',
                            );
                            await prefs.setString(
                              'skipReason_${dateKey}_${mealName.toLowerCase()}',
                              reason,
                            );
                            MealStateProvider.instance.notifyStateChanged();

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Meal skipped successfully'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text(
                          'Yes, Skip',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleItem(int mealIndex, int itemIndex) {
    if (_isAdvanceOrder) return; // Disallow customization
    final now = DateTime.now();
    final tomorrow = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    if (!selectedDay.isAtSameMomentAs(tomorrow)) {
      return; // Only tomorrow is bookable
    }

    setState(() {
      final items = _allMenuItems[mealIndex];
      final selected = _selectedItems[mealIndex] ?? {};
      final item = items[itemIndex];
      final exclusiveGroup = item['exclusive'] as String?;

      if (exclusiveGroup != null) {
        if (selected.contains(itemIndex)) {
          selected.remove(itemIndex);
        } else {
          for (int i = 0; i < items.length; i++) {
            if (i != itemIndex && items[i]['exclusive'] == exclusiveGroup) {
              selected.remove(i);
            }
          }
          selected.add(itemIndex);
        }
      } else {
        if (selected.contains(itemIndex)) {
          selected.remove(itemIndex);
        } else {
          selected.add(itemIndex);
        }
      }
    });
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildTopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBookingHeader(),
                  _buildMealTabs(),
                  _buildSlotCard(_selectedMeal),
                ],
              ),
            ),
          ),
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
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFEAE8E3),
                child: const Icon(
                  Icons.person,
                  color: AppColors.textMuted,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Good Afternoon, Aryan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          const Icon(
            Icons.notifications_outlined,
            color: AppColors.primary,
            size: 22,
          ),
        ],
      ),
    );
  }

  void _showCalendarBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final tomorrow = today.add(const Duration(days: 1));
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Booking Date',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),
                Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                      onSurface: AppColors.textDark, // Normal dates color
                    ),
                  ),
                  child: CalendarDatePicker(
                    initialDate: tomorrow,
                    firstDate: today.subtract(const Duration(days: 365)),
                    lastDate: today.add(const Duration(days: 365)),
                    onDateChanged: (date) {
                      Navigator.pop(context);
                      setState(() {
                        _selectedDate = date;
                      });
                      _loadStateForDate();
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMealTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: _mealTabs.asMap().entries.map((e) {
          final isSelected = _selectedMeal == e.key;
          final isSkipped = _skippedMeals[e.key] == true;
          final isBooked = _bookedMeals[e.key] == true;
          final isCancelled = _cancelledMeals[e.key] == true;

          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _selectedMeal = e.key;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                          ),
                        ]
                      : [],
                ),
                child: Opacity(
                  opacity: 1.0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        e.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? AppColors.textDark
                              : AppColors.textDisabled,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (isSkipped)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFB91C1C,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'SKIPPED',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB91C1C),
                              letterSpacing: 0.3,
                            ),
                          ),
                        )
                      else if (isCancelled)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFFB91C1C,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'CANCELLED',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB91C1C),
                              letterSpacing: 0.3,
                            ),
                          ),
                        )
                      else if (isBooked)
                        const Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Color(0xFF1A6B4A),
                        )
                      else
                        const SizedBox(height: 14),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBookingHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isAdvanceOrder ? 'ADVANCE BOOKING' : 'BOOKING FOR:',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showCalendarBottomSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(_selectedDate),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard(int index) {
    final isBooked = _bookedMeals[index] == true;
    final isSkipped = _skippedMeals[index] == true;
    final isCancelled = _cancelledMeals[index] == true;
    final isRebooking = _isRebooking[index] == true;

    final isPending = !isBooked && !isSkipped && !isCancelled;
    final isActive = isPending || isRebooking;

    final now = DateTime.now();
    final tomorrow = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final selectedDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final isTomorrow = selectedDay.isAtSameMomentAs(tomorrow);

    final items = _allMenuItems[index];
    final tabName = _mealTabs[index];
    final cutoffPassed = _isCutoffPassed(_selectedDate, tabName);
    final info = _deadlineInfo[index];

    if (!isTomorrow && isActive) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFCA5A5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _mealTabs[index],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Bookings are only accepted for tomorrow's meals. Please select tomorrow's date to continue.",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red,
                        height: 1.4,
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isActive && _isAdvanceOrder) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Icon(Icons.info_outline, color: Color(0xFF4B5563), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Advance orders use the standard menu. Custom thali available for tomorrow only.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4B5563),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (isActive && !_isAdvanceOrder) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDF6EC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8D6C3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0E0CF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.timer_outlined,
                      color: Color(0xFF8A5A2B),
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking closes at ${info['closeTime']}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'TIME REMAINING: 01H 42M', // Placeholder or use _formatMinutes if restored
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFA67C52),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6EADC),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'BUILD YOUR THALI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFA67C52),
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Row(
                children: [
                  if (isRebooking)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _isRebooking[index] = false),
                        child: const Text(
                          'Cancel Edit',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  _buildStatusBadge(
                    isBooked,
                    isSkipped,
                    isCancelled,
                    isRebooking,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _menuTitles[index],
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),

          if (isSkipped && !isRebooking) ...[
            const Text(
              'You chose to skip this meal.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ] else ...[
            ...items.asMap().entries.map((e) {
              bool disabled = !isActive;
              bool forceSelected = false;
              if (!isActive) {
                final names = _bookedItemsList[index] ?? [];
                forceSelected = names.contains(e.value['name']);
              }

              if (disabled && !forceSelected) return const SizedBox.shrink();

              return _buildFoodItem(
                index,
                e.key,
                e.value,
                disabled: disabled,
                forceSelected: forceSelected,
                isCancelled: isCancelled && !isRebooking,
              );
            }),

            if (isCancelled && !isRebooking) ...[
              const SizedBox(height: 8),
              const Text(
                'This booking was cancelled. Rebooking is not available after cancellation.',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ],
          ],

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFEDEAE6), height: 1),
          const SizedBox(height: 16),

          _buildActionButtons(
            index,
            isBooked,
            isSkipped,
            isCancelled,
            isRebooking,
            cutoffPassed,
            isActive,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
    bool isBooked,
    bool isSkipped,
    bool isCancelled,
    bool isRebooking,
  ) {
    if (isRebooking || (!isBooked && !isSkipped && !isCancelled)) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'PENDING',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'CANCELLED',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
      );
    }

    if (isSkipped) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'SKIPPED',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.textMuted,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'BOOKED',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppColors.success,
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    int index,
    bool isBooked,
    bool isSkipped,
    bool isCancelled,
    bool isRebooking,
    bool cutoffPassed,
    bool isActive,
  ) {
    if (isCancelled && !isRebooking) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(999),
        ),
        child: const Text(
          'Cancellation closed',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (isSkipped && !isRebooking) {
      if (!cutoffPassed) {
        return SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () => _showUndoSkipDialog(index),
            icon: const Icon(Icons.restore, size: 18),
            label: const Text(
              'Undo Skip',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6B7280),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        );
      } else {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Skip cannot be undone',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
    }

    if (isBooked && !isRebooking) {
      if (!cutoffPassed) {
        return Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _isRebooking[index] = true),
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text(
                    'Change Selection',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF8B5E3C),
                    side: const BorderSide(color: Color(0xFF8B5E3C)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _showCancelDialog(index),
                  icon: const Icon(Icons.cancel_outlined, size: 16),
                  label: const Text(
                    'Cancel Booking',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      } else {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Text(
            'Cancellation closed',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMuted,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }
    }

    if (isActive) {
      final selectedItems = _selectedItems[index] ?? {};
      final hasSelection = selectedItems.isNotEmpty;

      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: hasSelection ? () => _confirmBooking(index) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: const Color(0xFFD6D3CE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isRebooking ? 'Save Changes' : 'Confirm Booking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: hasSelection ? Colors.white : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: hasSelection ? Colors.white : Colors.white,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Please complete or skip all remaining meals',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _showSkipConfirmation(index),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text(
                  'Skip this meal',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 16, color: AppColors.textDark),
              ],
            ),
          ),
        ],
      );
    }

    return const SizedBox();
  }

  bool _isCutoffPassed(DateTime mealDate, String mealType) {
    final now = DateTime.now();
    try {
      final today = DateTime(now.year, now.month, now.day);
      final compareDate = DateTime(mealDate.year, mealDate.month, mealDate.day);

      if (compareDate.isBefore(today)) {
        return true;
      }
      if (compareDate.isAfter(today)) {
        return false;
      }

      int cutoffHour;
      int cutoffMinute = 0;
      switch (mealType.toLowerCase()) {
        case 'breakfast':
          cutoffHour = 7;
          cutoffMinute = 30;
          break;
        case 'lunch':
          cutoffHour = 12;
          cutoffMinute = 0;
          break;
        case 'snacks':
          cutoffHour = 16;
          cutoffMinute = 30;
          break;
        case 'dinner':
          cutoffHour = 20;
          cutoffMinute = 0;
          break;
        default:
          cutoffHour = 0;
      }
      final cutoffTime = DateTime(
        now.year,
        now.month,
        now.day,
        cutoffHour,
        cutoffMinute,
      );
      return now.isAfter(cutoffTime);
    } catch (_) {
      return true;
    }
  }

  void _showCancelDialog(int index) {
    final dateKey = _formatDateKey(_selectedDate);
    final mealName = _mealTabs[index];
    final mealTime = _mealTimes[index];
    final bookedItems = _bookedItemsList[index] ?? [];
    final allItems = _allMenuItems[index];

    final selectedDetails = allItems
        .where((item) => bookedItems.contains(item['name']))
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6D3CE),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Cancel Booking?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'BOOKED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        mealName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mealTime,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE5E7EB), height: 1),
                  const SizedBox(height: 16),
                  const Text(
                    'Selected Items:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...selectedDetails.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Icon(
                              Icons.circle,
                              size: 6,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item['name'] as String,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (item['veg'] as bool)
                                  ? const Color(
                                      0xFF1A6B4A,
                                    ).withValues(alpha: 0.1)
                                  : const Color(
                                      0xFFB91C1C,
                                    ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 7,
                                  color: (item['veg'] as bool)
                                      ? const Color(0xFF1A6B4A)
                                      : const Color(0xFFB91C1C),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  (item['veg'] as bool) ? 'VEG' : 'NON-VEG',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    color: (item['veg'] as bool)
                                        ? const Color(0xFF1A6B4A)
                                        : const Color(0xFFB91C1C),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Are you sure you want to cancel this booking? You can book again if the cutoff time has not passed.',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD6D3CE)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Go Back',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove(
                          'booked_${dateKey}_${mealName.toLowerCase()}',
                        );
                        await prefs.remove(
                          'items_${dateKey}_${mealName.toLowerCase()}',
                        );
                        setState(() {
                          _isRebooking[index] = false;
                          _bookedMeals[index] = false;
                          _cancelledMeals[index] = false;
                          _bookedItemsList[index] = [];
                          _selectedItems[index] = {0};
                        });
                        MealStateProvider.instance.notifyStateChanged();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirm Cancellation',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUndoSkipDialog(int index) {
    final dateKey = _formatDateKey(_selectedDate);
    final mealName = _mealTabs[index];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFD6D3CE),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Icon(Icons.restore, color: AppColors.primary, size: 40),
            const SizedBox(height: 16),
            Text(
              'Undo skip for $mealName on ${_formatDate(_selectedDate)}?',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "You can then place a booking for this slot.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD6D3CE)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: const Text(
                        'Go Back',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove(
                            'skipped_${dateKey}_${mealName.toLowerCase()}',
                          );
                          await prefs.remove(
                            'skipReason_${dateKey}_${mealName.toLowerCase()}',
                          );
                          MealStateProvider.instance.notifyStateChanged();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text(
                          'Confirm',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodItem(
    int mealIndex,
    int itemIndex,
    Map<String, dynamic> item, {
    bool disabled = false,
    bool forceSelected = false,
    bool isCancelled = false,
  }) {
    final selected = _selectedItems[mealIndex] ?? {};
    final isSelected = disabled ? forceSelected : selected.contains(itemIndex);
    final isRadio = item.containsKey('exclusive');

    return GestureDetector(
      onTap: disabled ? null : () => _toggleItem(mealIndex, itemIndex),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: disabled ? const Color(0xFFF9FAFB) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected && !disabled
                ? AppColors.primary.withValues(alpha: 0.4)
                : const Color(0xFFEDEAE6),
            width: isSelected && !disabled ? 1.5 : 1,
          ),
          boxShadow: disabled
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                  ),
                ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: disabled
                    ? const Color(0xFFF3F4F6)
                    : AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item['icon'] as IconData,
                color: disabled ? AppColors.textDisabled : AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          item['name'] as String,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: disabled
                                ? AppColors.textMuted
                                : AppColors.textDark,
                            decoration: isCancelled && isSelected
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Veg/Non-veg badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: disabled
                              ? const Color(0xFFE5E7EB)
                              : (item['veg'] as bool)
                              ? const Color(0xFF1A6B4A).withValues(alpha: 0.1)
                              : const Color(0xFFB91C1C).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 7,
                              color: disabled
                                  ? AppColors.textDisabled
                                  : (item['veg'] as bool)
                                  ? const Color(0xFF1A6B4A)
                                  : const Color(0xFFB91C1C),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              (item['veg'] as bool) ? 'VEG' : 'NON-VEG',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: disabled
                                    ? AppColors.textDisabled
                                    : (item['veg'] as bool)
                                    ? const Color(0xFF1A6B4A)
                                    : const Color(0xFFB91C1C),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['desc'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      color: disabled
                          ? AppColors.textDisabled
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            isRadio
                ? _buildRadioIndicator(isSelected, disabled)
                : _buildCheckboxIndicator(isSelected, disabled),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioIndicator(bool isSelected, bool disabled) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: disabled && isSelected
            ? const Color(0xFFD6D3CE)
            : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: disabled
              ? const Color(0xFFD6D3CE)
              : (isSelected ? AppColors.primary : const Color(0xFFD6D3CE)),
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: disabled ? Colors.white : AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCheckboxIndicator(bool isSelected, bool disabled) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: disabled
            ? (isSelected ? const Color(0xFFD6D3CE) : Colors.transparent)
            : (isSelected ? AppColors.primary : Colors.transparent),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: disabled
              ? const Color(0xFFD6D3CE)
              : (isSelected ? AppColors.primary : const Color(0xFFD6D3CE)),
          width: 2,
        ),
      ),
      child: isSelected
          ? Icon(
              Icons.check,
              color: disabled ? Colors.white70 : Colors.white,
              size: 14,
            )
          : null,
    );
  }
}
