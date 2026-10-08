import 'package:shared_preferences/shared_preferences.dart';

/// Simple model for budget settings.
class BudgetSettings {
  final double monthlyLimit;

  const BudgetSettings({required this.monthlyLimit});
}

/// Helper class to manage budget settings using SharedPreferences.
///
/// REASONING: Using SharedPreferences is simpler and more efficient for a single
/// configuration value (monthly limit) than creating a dedicated SQLite table
/// which would only ever hold one row.
class BudgetSettingsRepository {
  static const String _keyMonthlyLimit = 'monthly_budget_limit';
  final SharedPreferences _prefs;

  BudgetSettingsRepository(this._prefs);

  /// Gets the current budget settings. Defaults to 5,000,000 VND if not set.
  BudgetSettings getSettings() {
    final limit = _prefs.getDouble(_keyMonthlyLimit) ?? 5000000.0;
    return BudgetSettings(monthlyLimit: limit);
  }

  /// Saves the new monthly budget limit.
  Future<void> saveSettings(BudgetSettings settings) async {
    await _prefs.setDouble(_keyMonthlyLimit, settings.monthlyLimit);
  }
}
