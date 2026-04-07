---
paths:
  - "lib/**/*.dart"
  - "test/**/*.dart"
---

# Dart & Flutter Conventions for Aura

## File Structure
- Every file starts with a bilingual comment header block (English + Chinese 中文)
- Use `// =============================================================================` delimiters
- One primary class/enum per file
- Preserve existing bilingual comment style when editing files

## Naming
- **Files**: snake_case (e.g., `habit_provider.dart`)
- **Classes**: PascalCase (e.g., `HabitProvider`)
- **Variables/functions**: camelCase
- **Constants**: camelCase (Dart convention, NOT SCREAMING_SNAKE)
- **Private members**: prefix with underscore (`_habits`)
- **Enums**: PascalCase values, always add extension with `displayName` getter

## Model Classes
- Use `const` constructors with named parameters
- Implement `copyWith()` for immutable updates
- Implement `toJson()` and `factory fromJson()` for serialization
- Use safe JSON parsing: `(json['field'] as num?)?.toInt()` — never cast directly to int/double
- Override `toString()` for debugging when useful
- Import only from models/, config/, utils/, and dart:* packages

## Provider Pattern
- Extend `ChangeNotifier` (use `with ChangeNotifier` mixin)
- Expose state via getters, keep fields private (`List<Habit> _habits = []`)
- Call `notifyListeners()` after state changes
- Implement `clearUserData()` for logout cleanup
- Override `dispose()` to cancel StreamSubscriptions
- Use optimistic UI updates with rollback on Firestore error
- Track in-progress operations to prevent race conditions (e.g., `_togglingHabits` Set)
- Cache computed values and invalidate when source data changes

## Widget Conventions
- Always add `const` to constructors and widget trees where possible
- Use `context.select<T, R>()` to minimize rebuilds when only subset of data needed
- Use `context.read<T>()` for one-time reads (e.g., in callbacks)
- Use `context.watch<T>()` for reactive rebuilds
- Theme colors from `AppColors` — never hardcode `Color(0xFF...)` values
- Sizes from `UIConstants` — never hardcode magic numbers
- Organize widgets into subdirectories by screen: `widgets/home/`, `widgets/progress/`, `widgets/settings/`

## Import Conventions
- Use relative imports within the lib/ package (not `package:habit_tracker/...`)
- Import date_utils as: `import '../utils/date_utils.dart' as date_utils;`
- Group imports: dart:*, package:*, relative imports — separated by blank lines
