import re

with open('lib/meal_booking_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

idx = content.find("  Widget _buildBookingHeader() {")
if idx != -1:
    end_idx = content.find("  Widget _buildMealTabs() {", idx)
    content = content[:end_idx]

new_code = """
  Widget _buildSlotCard(int index) {
    final isBooked = _bookedMeals[index] == true;
    final isSkipped = _skippedMeals[index] == true;
    final isCancelled = _cancelledMeals[index] == true;
    final isRebooking = _isRebooking[index] == true;
    
    final selectedItems = _selectedItems[index] ?? {};
    final hasSelection = selectedItems.isNotEmpty;

    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final selectedDay = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final isTomorrow = selectedDay.isAtSameMomentAs(tomorrow);

    final items = _allMenuItems[index];
    final dateKey = _formatDateKey(_selectedDate);
    final tabName = _mealTabs[index];
    final cutoffPassed = _isCutoffPassed(dateKey, tabName);
    
    final info = _deadlineInfo[index];
    final remaining = info['remaining'] as int;

    // If it's skipped
    if (isSkipped) {
       return Padding(
         padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text(
                       _mealTabs[index],
                       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                     ),
                     const SizedBox(height: 4),
                     Text(
                       _mealTimes[index],
                       style: const TextStyle(color: AppColors.primary),
                     ),
                   ],
                 ),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(
                     color: const Color(0xFFF3F4F6),
                     borderRadius: BorderRadius.circular(999),
                   ),
                   child: const Text(
                     'SKIPPED',
                     style: TextStyle(
                       fontSize: 12,
                       fontWeight: FontWeight.bold,
                       color: AppColors.textMuted,
                     ),
                   ),
                 ),
               ],
             ),
             const SizedBox(height: 16),
             Container(
               width: double.infinity,
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: const Color(0xFFF9FAFB),
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: const Color(0xFFEDEAE6)),
               ),
               child: const Center(
                 child: Text(
                   'You chose to skip this meal.',
                   style: TextStyle(fontSize: 14, color: AppColors.textMuted, fontStyle: FontStyle.italic),
                 ),
               ),
             ),
             const SizedBox(height: 16),
             if (!cutoffPassed)
               Align(
                 alignment: Alignment.centerRight,
                 child: TextButton.icon(
                   onPressed: () => _showUndoSkipDialog(index),
                   icon: const Icon(Icons.restore, size: 16),
                   label: const Text('Undo Skip'),
                 ),
               )
             else
               const Align(
                 alignment: Alignment.centerRight,
                 child: Text(
                   'Skip cannot be undone after the booking window closes.',
                   style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                 ),
               ),
           ],
         ),
       );
    }

    if ((isBooked || isCancelled) && !isRebooking) {
      final names = _bookedItemsList[index] ?? [];
      Set<int> bookedIndices = {};
      for (int i = 0; i < items.length; i++) {
        if (names.contains(items[i]['name'])) {
          bookedIndices.add(i);
        }
      }

      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _mealTabs[index],
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _mealTimes[index],
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCancelled ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isCancelled ? 'CANCELLED' : 'BOOKED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isCancelled ? Colors.red : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...items.asMap().entries.map((e) => _buildFoodItem(
              index,
              e.key, e.value, 
              disabled: true, 
              forceSelected: bookedIndices.contains(e.key),
              isCancelled: isCancelled,
            )),
            if (isCancelled) ...[
              const SizedBox(height: 16),
              const Text(
                'This booking was cancelled. Rebooking is not available after cancellation.',
                style: TextStyle(color: Colors.red, fontSize: 13),
              ),
            ] else if (!cutoffPassed) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() => _isRebooking[index] = true),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Change Selection'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showCancelDialog(index),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text('Cancel Booking'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ).copyWith(
                        backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
                          if (states.contains(WidgetState.pressed) || states.contains(WidgetState.hovered)) {
                            return Colors.red.withValues(alpha: 0.1);
                          }
                          return null;
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Cancellation closed',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.bold),
                ),
              ),
            ]
          ],
        ),
      );
    }

    if (!isTomorrow) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFCA5A5)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _mealTabs[index],
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Bookings are only accepted for tomorrow's meals. Please select tomorrow's date to continue.",
                      style: TextStyle(fontSize: 14, color: Colors.red, height: 1.4),
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _menuTitles[index],
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              if (isRebooking)
                TextButton(
                  onPressed: () => setState(() => _isRebooking[index] = false),
                  child: const Text('Cancel Edit', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
          if (!_isAdvanceOrder) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.timer_outlined,
                        color: AppColors.primary, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Booking closes at ${info['closeTime']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_isAdvanceOrder) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
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
                      style: TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          ...items.asMap().entries.map((e) => _buildFoodItem(index, e.key, e.value)),
          
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => _showSkipConfirmation(index),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFD6D3CE)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    ),
                    child: const Text('Skip Meal', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: hasSelection ? () => _confirmBooking(index) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      elevation: 0,
                    ),
                    child: Text(isRebooking ? 'Save Changes' : 'Confirm Booking', style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFEDEAE6)),
        ],
      ),
    );
  }

  bool _isCutoffPassed(String ymd, String mealType) {
    final now = DateTime.now();
    try {
      final parts = ymd.split('-');
      final mealDate = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      
      if (mealDate.isBefore(DateTime(now.year, now.month, now.day))) {
        return true;
      }
      if (mealDate.isAfter(DateTime(now.year, now.month, now.day))) {
        return false;
      }
      
      int cutoffHour;
      int cutoffMinute = 0;
      switch (mealType.toLowerCase()) {
        case 'breakfast': cutoffHour = 7; cutoffMinute = 30; break;
        case 'lunch': cutoffHour = 12; cutoffMinute = 0; break;
        case 'snacks': cutoffHour = 16; cutoffMinute = 30; break;
        case 'dinner': cutoffHour = 20; cutoffMinute = 0; break;
        default: cutoffHour = 0;
      }
      final cutoffTime = DateTime(now.year, now.month, now.day, cutoffHour, cutoffMinute);
      return now.isAfter(cutoffTime);
    } catch (_) {
      return true;
    }
  }

  void _showCancelDialog(int index) {
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
            Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFD6D3CE), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
            const SizedBox(height: 16),
            Text('Cancel $mealName booking for ${_formatDate(_selectedDate)}?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD6D3CE)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: const Text('Go Back', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('booked_${dateKey}_${mealName.toLowerCase()}', 'cancelled');
                        setState(() { _isRebooking[index] = false; });
                        MealStateProvider.instance.notifyStateChanged();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        elevation: 0,
                      ),
                      child: const Text('Confirm Cancel', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
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
            Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFD6D3CE), borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            const Icon(Icons.restore, color: AppColors.primary, size: 40),
            const SizedBox(height: 16),
            Text('Undo skip for $mealName on ${_formatDate(_selectedDate)}?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            const Text("You can then place a booking for this slot.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFD6D3CE)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      ),
                      child: const Text('Go Back', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('skipped_${dateKey}_${mealName.toLowerCase()}');
                          await prefs.remove('skipReason_${dateKey}_${mealName.toLowerCase()}');
                          MealStateProvider.instance.notifyStateChanged();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                        ),
                        child: const Text('Confirm', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
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

  Widget _buildFoodItem(int mealIndex, int itemIndex, Map<String, dynamic> item, {bool disabled = false, bool forceSelected = false, bool isCancelled = false}) {
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
          boxShadow: disabled ? [] : [
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
                color: disabled ? const Color(0xFFF3F4F6) : AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item['icon'] as IconData,
                  color: disabled ? AppColors.textDisabled : AppColors.primary, size: 28),
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
                            color: disabled ? AppColors.textMuted : AppColors.textDark,
                            decoration: isCancelled && isSelected ? TextDecoration.lineThrough : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Veg/Non-veg badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                      color: disabled ? AppColors.textDisabled : AppColors.textMuted,
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
        color: disabled && isSelected ? const Color(0xFFD6D3CE) : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: disabled ? const Color(0xFFD6D3CE) : (isSelected ? AppColors.primary : const Color(0xFFD6D3CE)),
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
          color: disabled ? const Color(0xFFD6D3CE) : (isSelected ? AppColors.primary : const Color(0xFFD6D3CE)),
          width: 2,
        ),
      ),
      child: isSelected
          ? Icon(Icons.check, color: disabled ? Colors.white70 : Colors.white, size: 14)
          : null,
    );
  }
}
"""

content += new_code

with open('lib/meal_booking_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Phase 2 replacements done.")
