import sys

with open('lib/meal_booking_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target = """    if (isActive) {
      final selectedItems = _selectedItems[index] ?? {};
      final hasSelection = selectedItems.isNotEmpty;

      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () => _showSkipConfirmation(index),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  side: const BorderSide(color: Color(0xFFD6D3CE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Skip this meal',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 16),
                  ],
                ),
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
                        fontWeight: FontWeight.w700,
                        color: hasSelection ? Colors.white : Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: hasSelection ? Colors.white : Colors.white70,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }"""

replace = """    if (isActive) {
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
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
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
    }"""

if target in content:
    content = content.replace(target, replace)
    with open('lib/meal_booking_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("SUCCESS")
else:
    print("FAILED TO FIND TARGET")
