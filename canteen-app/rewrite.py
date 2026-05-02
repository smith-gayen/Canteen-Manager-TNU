import re

with open('lib/meal_booking_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Variables
content = re.sub(
    r'  int _selectedMeal = 1; // 0=Breakfast, 1=Lunch, 2=Snacks, 3=Dinner\n',
    r'  final Map<int, bool> _isRebooking = {0: false, 1: false, 2: false, 3: false};\n',
    content
)

# 2. _loadStateForDate fallback removal
content = re.sub(
    r'        bool found = false;\n        for \(int i = 0; i < 4; i\+\+\) \{\n          if \(_skippedMeals\[i\] != true && _bookedMeals\[i\] != true && _cancelledMeals\[i\] != true\) \{\n            _selectedMeal = i;\n            found = true;\n            break;\n          \}\n        \}\n        if \(!found\) \{\n          _selectedMeal = 0;\n        \}\n',
    r'',
    content
)

# 3. _confirmBooking to _confirmBooking(int index)
content = re.sub(
    r'  Future<void> _confirmBooking\(\) async \{',
    r'  Future<void> _confirmBooking(int index) async {',
    content
)
content = re.sub(
    r'    final dateKey = _formatDateKey\(_selectedDate\);\n    final tabName = _mealTabs\[_selectedMeal\];\n    final selected = _selectedItems\[_selectedMeal\] \?\? \{\};\n    final items = _currentItems;',
    r'    final dateKey = _formatDateKey(_selectedDate);\n    final tabName = _mealTabs[index];\n    final selected = _selectedItems[index] ?? {};\n    final items = _allMenuItems[index];\n    setState(() { _isRebooking[index] = false; });',
    content
)

# 4. _getSelectedMenuSummary
content = re.sub(
    r'  String _getSelectedMenuSummary\(\) \{\n    final items = _currentItems;\n    final selected = _currentSelected;',
    r'  String _getSelectedMenuSummary(int index) {\n    final items = _allMenuItems[index];\n    final selected = _selectedItems[index] ?? {};',
    content
)

# 5. _showSkipConfirmation
content = re.sub(
    r'  void _showSkipConfirmation\(\) \{\n    final mealName = _mealTabs\[_selectedMeal\];\n    final mealTime = _mealTimes\[_selectedMeal\];\n    final mealMenu = _getSelectedMenuSummary\(\);',
    r'  void _showSkipConfirmation(int index) {\n    final mealName = _mealTabs[index];\n    final mealTime = _mealTimes[index];\n    final mealMenu = _getSelectedMenuSummary(index);',
    content
)

# 6. _toggleItem
content = re.sub(
    r'  void _toggleItem\(int index\) \{',
    r'  void _toggleItem(int mealIndex, int itemIndex) {',
    content
)
content = re.sub(
    r'      final items = _currentItems;\n      final selected = _currentSelected;\n      final item = items\[index\];',
    r'      final items = _allMenuItems[mealIndex];\n      final selected = _selectedItems[mealIndex] ?? {};\n      final item = items[itemIndex];',
    content
)
content = re.sub(
    r'        if \(selected\.contains\(index\)\) \{\n          selected\.remove\(index\);\n        \} else \{\n          for \(int i = 0; i < items\.length; i\+\+\) \{\n            if \(i != index && items\[i\]\[\'exclusive\'\] == exclusiveGroup\) \{\n              selected\.remove\(i\);\n            \}\n          \}\n          selected\.add\(index\);\n        \}',
    r'        if (selected.contains(itemIndex)) {\n          selected.remove(itemIndex);\n        } else {\n          for (int i = 0; i < items.length; i++) {\n            if (i != itemIndex && items[i][\'exclusive\'] == exclusiveGroup) {\n              selected.remove(i);\n            }\n          }\n          selected.add(itemIndex);\n        }',
    content
)
content = re.sub(
    r'        if \(selected\.contains\(index\)\) \{\n          selected\.remove\(index\);\n        \} else \{\n          selected\.add\(index\);\n        \}',
    r'        if (selected.contains(itemIndex)) {\n          selected.remove(itemIndex);\n        } else {\n          selected.add(itemIndex);\n        }',
    content
)

with open('lib/meal_booking_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Phase 1 replacements done.")
