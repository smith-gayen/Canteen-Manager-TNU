import sys

with open('lib/meal_booking_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

target1 = """    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
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
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _mealTimes[index],
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
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
            const SizedBox(height: 16),"""

replace1 = """    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          const SizedBox(height: 16),"""

target2 = """            _buildActionButtons(
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
      ),
    );
  }"""

replace2 = """            _buildActionButtons(
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
  }"""

if target1 in content and target2 in content:
    content = content.replace(target1, replace1)
    content = content.replace(target2, replace2)
    
    # Let's also move the deadline banner to be ABOVE 'BUILD YOUR THALI'
    deadline_code_target = """            ] else ...[
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
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF4B5563),
                        size: 20,
                      ),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
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
                        child: const Icon(
                          Icons.timer_outlined,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Booking closes at ${info['closeTime']}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],"""
              
    deadline_code_replace = """            ] else ...["""
    
    # We put the deadline code BEFORE 'BUILD YOUR THALI'
    deadline_inserted = """              if (isActive && _isAdvanceOrder) ...[
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
                      Icon(
                        Icons.info_outline,
                        color: Color(0xFF4B5563),
                        size: 20,
                      ),
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
                    border: Border.all(
                      color: const Color(0xFFE8D6C3),
                    ),
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
              """
              
    content = content.replace(deadline_code_target, deadline_code_replace)
    
    replace1_with_deadline = replace1.replace('          Row(\n            mainAxisAlignment: MainAxisAlignment.spaceBetween,\n            children: [', deadline_inserted + '          Row(\n            mainAxisAlignment: MainAxisAlignment.spaceBetween,\n            children: [')
    
    content = content.replace(replace1, replace1_with_deadline)

    with open('lib/meal_booking_screen.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print("SUCCESS")
else:
    print("FAILED TO FIND TARGETS")
