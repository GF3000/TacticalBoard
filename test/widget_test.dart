import 'package:flutter_test/flutter_test.dart';

import 'package:tactical_board/main.dart';

void main() {
  testWidgets('TacticalBoard app loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TacticalBoardApp());

    // Verify that the control bar labels are present.
    expect(find.text('Red'), findsOneWidget);
    expect(find.text('White'), findsOneWidget);
    expect(find.text('Cone'), findsOneWidget);
    expect(find.text('Ball'), findsOneWidget);
    expect(find.text('Arrow'), findsOneWidget);

    // Verify initial player numbers are shown (1 for both)
    expect(find.text('1'), findsNWidgets(2)); // Red and White player tokens show "1"
  });
}
