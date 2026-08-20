import 'package:flutter_test/flutter_test.dart';

import 'package:planificador_actividades/main.dart';

void main() {
  testWidgets('Splash de la Fase 0 muestra el logo y el nombre de la app',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PlanificadorApp());

    expect(find.text('Planificador de Actividades'), findsOneWidget);
    expect(find.text('Actividades condicionadas por el clima'), findsOneWidget);
  });
}
