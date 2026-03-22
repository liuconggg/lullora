import 'dart:math';
import '../models/condition.dart';

class RandomizationService {
  static final Random _random = Random.secure();

  /// Generates a random permutation of the three study conditions
  /// Returns a list with all three conditions in random order
  static List<Condition> generateConditionOrder() {
    final List<Condition> conditions = [
      Condition.control,
      Condition.fixed,
      Condition.personalized,
    ];
    
    // Fisher-Yates shuffle algorithm
    for (int i = conditions.length - 1; i > 0; i--) {
      int j = _random.nextInt(i + 1);
      final temp = conditions[i];
      conditions[i] = conditions[j];
      conditions[j] = temp;
    }
    
    return conditions;
  }

  /// Checks if a condition order is valid (contains all three conditions exactly once)
  static bool isValidConditionOrder(List<Condition> order) {
    if (order.length != 3) return false;
    return order.contains(Condition.control) &&
           order.contains(Condition.fixed) &&
           order.contains(Condition.personalized);
  }
}
