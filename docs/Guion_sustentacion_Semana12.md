# Guion de sustentación de cinco minutos

**Estado:** borrador para practicar. Sustituir las referencias a capturas por C1–C4 cuando existan. Duración objetivo: 5:00; ensayar con cronómetro.

| Tiempo | Qué mostrar | Guion sugerido |
|---|---|---|
| 0:00–0:40 | Portada y grafo de §4 | «ManosSeguras conserva `get_it` como constructor de repositorios y base de datos. Diez providers puente publican esas instancias a Riverpod. Tres `Notifier` gestionan tema, borrador y sesión.» |
| 0:40–1:35 | C1 y C2 | «La captura vive en `capturaProvider`. Al agregar se asigna un número correlativo; al quitar una fila las demás conservan sus números. La bienvenida lee el mismo borrador. `keepAlive` evita perderlo al navegar.» |
| 1:35–2:15 | Código de `guardar()` y nombres de pruebas | «El borrador se vacía después de que el repositorio confirma el guardado. Si ese repositorio falla, queda disponible para reintentar. Si falla solo la preferencia auxiliar, la auditoría ya guardada se considera exitosa para evitar duplicados.» |
| 2:15–3:05 | C3 | «La sesión se representa con sesión, progreso y último fallo. La guarda de reentrada bloquea una segunda pulsación mientras la primera operación sigue en curso. La interfaz muestra únicamente una huella del token; al cerrar se limpia el almacén y al restaurar se descarta un token vencido.» |
| 3:05–3:45 | C4 | «`ProviderObserver` registra creación, cambio, destrucción y fallo, con contadores. La traza muestra solo el nombre del provider; no vuelca valores, errores ni credenciales. Los contadores miden eventos de providers, no reconstrucciones de widgets.» |
| 3:45–4:30 | §8, texto de comandos | «Ejecutamos `flutter pub get`, `dart run build_runner build`, `flutter analyze --fatal-infos` y `flutter test`. El resultado final fue 140 pruebas aprobadas, una omitida y ningún hallazgo estático. La prueba omitida corresponde al esquema v2, fuera del alcance de esta semana.» |
| 4:30–5:00 | §10 y conclusión | «No adelantamos `AsyncNotifier` ni `AsyncValue`; los estados asíncronos de las otras pantallas siguen con `FutureBuilder` y `StreamBuilder`. Falta una versión auténtica de Semana 11 para cuantificar la comparación histórica y faltan las capturas censuradas para cerrar el informe.» |

## Preguntas previsibles

- **¿Por qué no eliminar `get_it`?** Ya construye una sola base y sus repositorios. Los providers puente reutilizan las mismas instancias; crear otro grafo duplicaría conexiones y responsabilidades.
- **¿Por qué `keepAlive` para el borrador?** La captura se consulta desde varias rutas y debe sobrevivir a la navegación. La prueba «es keepAlive: sin oyentes el borrador sigue ahí» lo comprueba.
- **¿Qué prueba la igualdad?** Dos `EstadoCaptura` equivalentes comparten `==` y `hashCode`; Riverpod 3 usa `==` para filtrar notificaciones. La prueba cubre el contrato, aunque aún no hay medición de reconstrucciones de widgets.
- **¿Qué significa una prueba omitida?** Es un `skip` explícito del esquema v2; no se cuenta como aprobación ni como fallo.
