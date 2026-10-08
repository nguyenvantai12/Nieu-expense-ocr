import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/models/budget_settings.dart';

/// Provider for SharedPreferences instance.
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((
  ref,
) async {
  return SharedPreferences.getInstance();
});

/// Provider for BudgetSettingsRepository.
final budgetSettingsRepoProvider = FutureProvider<BudgetSettingsRepository>((
  ref,
) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return BudgetSettingsRepository(prefs);
});

/// Provider for current budget settings.
final budgetSettingsProvider = FutureProvider<BudgetSettings>((ref) async {
  final repo = await ref.watch(budgetSettingsRepoProvider.future);
  return repo.getSettings();
});
