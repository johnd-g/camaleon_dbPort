import 'package:camaleon_db_port/app.dart';
import 'package:camaleon_db_port/injection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await configureDependencies();
  });

  tearDown(() async {
    await sl.reset();
    await configureDependencies();
  });

  testWidgets('Importer home renders in English by default', (tester) async {
    await tester.pumpWidget(const CamaleonDbPortApp());
    await tester.pumpAndSettle();

    expect(find.text('Camaleon DB Importer'), findsOneWidget);
    expect(find.text('Start import'), findsOneWidget);
  });
}
