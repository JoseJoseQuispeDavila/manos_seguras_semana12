import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:manos_seguras/core/observador_riverpod.dart';

final NotifierProvider<_EstadoDePrueba, String> _estadoDePruebaProvider =
    NotifierProvider<_EstadoDePrueba, String>(
      _EstadoDePrueba.new,
      name: 'estadoDePrueba',
    );

class _EstadoDePrueba extends Notifier<String> {
  @override
  String build() => 'inicial';

  void cambiar(String valor) => state = valor;
}

void main() {
  test('el observador cuenta eventos sin registrar valores ni errores', () {
    const String secreto = 'TOKEN_SINTETICO_NO_PUBLICAR';
    final List<String> trazas = <String>[];
    final DebugPrintCallback anterior = debugPrint;
    debugPrint = (String? mensaje, {int? wrapWidth}) {
      if (mensaje != null) trazas.add(mensaje);
    };

    try {
      final RegistroDeProviders observador = RegistroDeProviders(activo: true);
      final ProviderContainer contenedor = ProviderContainer.test(
        observers: <ProviderObserver>[observador],
      );
      contenedor.read(_estadoDePruebaProvider);
      contenedor.read(_estadoDePruebaProvider.notifier).cambiar(secreto);

      final Provider<String> fallido = Provider<String>(
        (Ref ref) => throw StateError(secreto),
        name: 'fallido',
      );
      expect(() => contenedor.read(fallido), throwsA(anything));

      expect(observador.resumen['creados'], greaterThanOrEqualTo(1));
      expect(observador.resumen['actualizados'], 1);
      expect(observador.resumen['fallos'], 1);
      expect(trazas.join('\n'), isNot(contains(secreto)));
      expect(trazas.join('\n'), contains('[riverpod] ~ estadoDePrueba'));
      expect(trazas.join('\n'), contains('[riverpod] ! fallido'));
    } finally {
      debugPrint = anterior;
    }
  });
}
