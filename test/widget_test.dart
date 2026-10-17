import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:manos_seguras/presentation/pantallas/pantalla_establecimiento.dart';

void main() {
  testWidgets('el botón de regreso vuelve de establecimiento al inicio', (
    WidgetTester tester,
  ) async {
    final GoRouter router = GoRouter(
      initialLocation: '/establecimiento',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) =>
              const Scaffold(body: Center(child: Text('Inicio de prueba'))),
        ),
        GoRoute(
          path: '/establecimiento',
          builder: (BuildContext context, GoRouterState state) =>
              const PantallaEstablecimiento(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    expect(find.byTooltip('Volver al inicio'), findsOneWidget);

    await tester.tap(find.byTooltip('Volver al inicio'));
    await tester.pumpAndSettle();

    expect(find.text('Inicio de prueba'), findsOneWidget);
  });
}
