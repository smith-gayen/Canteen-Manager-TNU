import 'package:flutter/foundation.dart';

class MealStateProvider extends ChangeNotifier {
  static final MealStateProvider instance = MealStateProvider._internal();
  MealStateProvider._internal();

  void notifyStateChanged() {
    notifyListeners();
  }
}
