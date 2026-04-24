import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:uni_market/view_models/browse_view_model.dart';
import 'package:uni_market/views/screens/unified_browse_for_you_screen.dart';

class MockBrowseViewModel extends Mock implements BrowseViewModel {
  @override
  Map<String, dynamic>? getCachedCatalog() {
    return super.noSuchMethod(Invocation.method(#getCachedCatalog, []), returnValue: null);
  }
  @override
  Map<String, dynamic>? getCachedRecommendations() {
    return super.noSuchMethod(Invocation.method(#getCachedRecommendations, []), returnValue: null);
  }
}

void main() {
  group('Offline Mode Simulation', () {
    late MockBrowseViewModel mockBrowseViewModel;

    setUp(() {
      mockBrowseViewModel = MockBrowseViewModel();
    });

    testWidgets('Verify cached data retrieval when offline', (WidgetTester tester) async {
      when(mockBrowseViewModel.getCachedCatalog()).thenReturn({
        '1': {'title': 'Cached Item 1', 'description': 'Description 1'},
      });
      when(mockBrowseViewModel.getCachedRecommendations()).thenReturn({
        '2': {'title': 'Recommendation 1', 'description': 'Description 2'},
      });

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<BrowseViewModel>.value(
            value: mockBrowseViewModel,
            child: UnifiedBrowseForYouScreen(),
          ),
        ),
      );

      expect(find.text('Cached Item 1'), findsOneWidget);
      expect(find.text('Recommendation 1'), findsOneWidget);
    });

    testWidgets('Verify fallback behavior when no cached data is available', (WidgetTester tester) async {
      when(mockBrowseViewModel.getCachedCatalog()).thenReturn(null);
      when(mockBrowseViewModel.getCachedRecommendations()).thenReturn(null);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<BrowseViewModel>.value(
            value: mockBrowseViewModel,
            child: UnifiedBrowseForYouScreen(),
          ),
        ),
      );

      expect(find.text('No cached data available. Please connect to the internet.'), findsOneWidget);
    });
  });
}
