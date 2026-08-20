import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:planificador_actividades/main.dart';

void main() {
  testWidgets('Al iniciar sin sesión guardada muestra la pantalla de login',
      (WidgetTester tester) async {
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(const PlanificadorApp());
    await tester.pumpAndSettle();

    expect(find.text('Inicia sesión'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
