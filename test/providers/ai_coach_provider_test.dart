import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:habit_tracker/providers/ai_coach_provider.dart';
import 'package:habit_tracker/models/ai_coach_models.dart';
import 'package:habit_tracker/models/habit_category.dart';

// Mocks
class MockFirebaseFunctions extends Mock implements FirebaseFunctions {}

class MockHttpsCallable extends Mock implements HttpsCallable {}

class MockHttpsCallableResult extends Mock
    implements HttpsCallableResult<dynamic> {}

void main() {
  late MockFirebaseFunctions mockFunctions;
  late MockHttpsCallable mockCallable;
  late AICoachProvider provider;

  setUp(() {
    mockFunctions = MockFirebaseFunctions();
    mockCallable = MockHttpsCallable();

    // Default stub: any httpsCallable returns mockCallable
    when(() => mockFunctions.httpsCallable(any())).thenReturn(mockCallable);
  });

  group('AICoachProvider Suggestions Tests', () {
    final mockApiData = [
      {
        'habitName': 'Morning Jog',
        'explanation': 'Boosts energy',
        'reason': 'Cardio is good',
        'category': 'health',
      },
    ];

    test('fetches from API when cache is empty', () async {
      SharedPreferences.setMockInitialValues({}); // Empty cache

      final mockResult = MockHttpsCallableResult();
      when(() => mockResult.data).thenReturn(mockApiData);
      when(() => mockCallable.call(any())).thenAnswer((_) async => mockResult);

      provider = AICoachProvider(functions: mockFunctions);

      await provider.loadSuggestions(categories: [], currentHabits: []);

      // Verify API called
      verify(
        () => mockFunctions.httpsCallable('generateHabitSuggestions'),
      ).called(1);
      verify(() => mockCallable.call(any())).called(1);

      // Verify data loaded
      expect(provider.suggestions.length, 1);
      expect(provider.suggestions.first.title, 'Morning Jog');
      expect(provider.suggestions.first.category, HabitCategory.health);
    });

    test(
      'loads from cache and DOES NOT call API when valid cache exists',
      () async {
        // Setup valid cache
        final cachedSuggestion = AICoachSuggestion(
          id: '123',
          title: 'Cached Habit',
          description: 'From cache',
          whyThisHelps: 'Faster',
          category: HabitCategory.productivity,
          icon: HabitCategory.productivity.icon, // Not serialized but derived
          estimatedImpact: 'High',
          estimatedMinutes: 10,
          suggestedAt: DateTime.now(),
        );

        final cacheJson = {
          'timestamp': DateTime.now().toIso8601String(),
          'data': [cachedSuggestion.toJson()],
        };

        SharedPreferences.setMockInitialValues({
          'ai_suggestions_cache': jsonEncode(cacheJson),
        });

        provider = AICoachProvider(functions: mockFunctions);

        await provider.loadSuggestions(categories: [], currentHabits: []);

        // Verify API NOT called
        verifyNever(() => mockFunctions.httpsCallable(any()));

        // Verify data from cache
        expect(provider.suggestions.length, 1);
        expect(provider.suggestions.first.title, 'Cached Habit');
      },
    );

    test(
      'calls API when forceRefresh is true, even with valid cache',
      () async {
        // Setup valid cache
        final cacheJson = {
          'timestamp': DateTime.now().toIso8601String(),
          'data': [],
        };
        SharedPreferences.setMockInitialValues({
          'ai_suggestions_cache': jsonEncode(cacheJson),
        });

        final mockResult = MockHttpsCallableResult();
        when(() => mockResult.data).thenReturn(mockApiData);
        when(
          () => mockCallable.call(any()),
        ).thenAnswer((_) async => mockResult);

        provider = AICoachProvider(functions: mockFunctions);

        // Force refresh!
        await provider.loadSuggestions(
          categories: [],
          currentHabits: [],
          forceRefresh: true,
        );

        // Verify API CALLED
        verify(
          () => mockFunctions.httpsCallable('generateHabitSuggestions'),
        ).called(1);

        // Verify data from API (not empty cache)
        expect(provider.suggestions.length, 1);
        expect(provider.suggestions.first.title, 'Morning Jog');
      },
    );

    test('ignores expired cache and calls API', () async {
      // Setup EXPIRED cache (25 hours ago)
      final cacheJson = {
        'timestamp': DateTime.now()
            .subtract(const Duration(hours: 25))
            .toIso8601String(),
        'data': [],
      };
      SharedPreferences.setMockInitialValues({
        'ai_suggestions_cache': jsonEncode(cacheJson),
      });

      final mockResult = MockHttpsCallableResult();
      when(() => mockResult.data).thenReturn(mockApiData);
      when(() => mockCallable.call(any())).thenAnswer((_) async => mockResult);

      provider = AICoachProvider(functions: mockFunctions);

      await provider.loadSuggestions(categories: [], currentHabits: []);

      // Verify API CALLED because cache expired
      verify(
        () => mockFunctions.httpsCallable('generateHabitSuggestions'),
      ).called(1);
    });
  });
}
