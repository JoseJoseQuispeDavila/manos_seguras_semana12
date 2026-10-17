# Capturas y pendientes del informe técnico de la Semana 12

Estado: **borrador**. Las pruebas automatizadas quedaron verificadas y C1–C4 están guardadas en `docs/evidencias_semana12/capturas/`. Falta preparar e insertar las imágenes, confirmar los roles, completar los códigos y aportar la versión anterior para cerrar las comparaciones históricas.

## Capturas guardadas y procedimiento de obtención

1. **C1, bienvenida con borrador.** Abra la aplicación, entre en **Capturar oportunidades**, agregue tres oportunidades y vuelva a **ManosSeguras**. Debe verse la tarjeta **Estado compartido por Riverpod** con «3 oportunidades», el estado de sesión y el último establecimiento (si ya se guardó una auditoría). Oculte notificaciones, cuentas personales y cualquier dato real del dispositivo. Archivo sugerido: `C1_bienvenida_borrador.png`. Inserción: §4 y anexo C.
2. **C2, captura de oportunidades.** Desde bienvenida pulse **Continuar el borrador** o **Capturar oportunidades**. Agregue al menos tres oportunidades, elija más de una acción y, si desea demostrar el correlativo, quite la segunda. Deben verse las oportunidades restantes con sus números sin renumerar y el resumen de cumplimiento. Oculte cualquier dato personal real o identificador de una auditoría clínica. Archivo sugerido: `C2_captura_oportunidades.png`. Inserción: §6 y anexo C.
3. **C3, sesión protegida.** Abra **Sesión y token seguro** e inicie sesión solo con las credenciales simuladas del laboratorio. Deben verse «Sesión activa», el rol, el documento enmascarado, la **huella** y la caducidad del token; el valor del token no debe aparecer. Oculte nombres o documentos reales, notificaciones y cualquier información ajena. Archivo sugerido: `C3_sesion_huella.png`. Inserción: §7 y anexo C.
4. **C4, traza del observador.** Ejecute `flutter run`, abra bienvenida y captura, agregue una oportunidad y cambie el tema. Capture únicamente las líneas `[riverpod] +`, `[riverpod] ~` y, si ocurre, `[riverpod] -` de la consola. Deben verse nombres de providers y eventos, sin valores ni errores crudos. Oculte rutas de usuario, identificadores de dispositivo, datos personales y ventanas ajenas. Archivo sugerido: `C4_traza_observador.png`. Inserción: §9 y anexo C.

La salida de `flutter analyze --fatal-infos` y `flutter test --reporter expanded` se conserva como **texto** en `docs/evidencias_semana12/`; no haga capturas de la terminal para §8.

| Captura | Archivo en `capturas/` | Estado tras abrirla |
|---|---|---|
| C1 | `C1_bienvenida_borrador.png` | Guardada; se ve el borrador con tres oportunidades en bienvenida. |
| C2 | `C2_captura_oportunidades.png` | Guardada; se ven las oportunidades 01 y 03 sin renumerar. |
| C3 | `C3_sesion_huella.png` | Guardada; recortar el directorio simulado con nombres y documentos completos antes de insertarla. |
| C4 | `C4_traza_observador.png` | Guardada; recortar la línea de recarga de Flutter y conservar solo los eventos `[riverpod]`. |

**Faltantes entre C1–C4: ninguno.** Las imágenes aún no están insertadas en el informe paginado.

## Datos y acciones pendientes para cerrar el documento

1. Confirmar con el equipo los roles y responsabilidades propuestos en §1 y completar los códigos universitarios, que siguen como «Pendiente».
2. Indicar la URL y visibilidad del repositorio Git. La carpeta entregada no contiene `.git`, así que no se puede certificar un commit ni una comparación histórica desde este directorio.
3. Aportar la versión de la Semana 11 si se desea completar con datos verificables las columnas «antes» de §3, §6, §8 y anexo B. El ZIP inicial de esta revisión ya era de Semana 12.
4. Preparar C3 y C4 según la tabla anterior y revisar las cuatro capturas antes de insertarlas. Conservar los PNG originales como evidencia del proyecto ejecutado.
5. Medir reconstrucciones de widgets y tiempos solo si el equipo va a afirmar mejoras de rendimiento. Los contadores actuales del observador miden eventos de providers, no reconstrucciones ni tiempo.
6. Pasar el borrador al formato institucional A4 de la plantilla, revisar paginación entre 18 y 28 páginas sin anexos, insertar las capturas, generar el PDF y verificar visualmente todas las páginas.
7. Confirmar el SDK mínimo del equipo antes de incorporar `riverpod_lint`: esta máquina usa Dart 3.13.1; el material de origen registra Dart 3.12.2.

## Archivos de evidencia ya obtenidos

- `codigo_inicial.zip` y `sha256_inicial.txt`: referencia del estado recibido antes de las modificaciones.
- `01_flutter_pub_get.txt`, `02_build_runner.txt`, `03_flutter_analyze.txt`, `04_flutter_test.txt`: primera verificación.
- `05_flutter_pub_deps.txt`, `12_build_runner_final.txt`, `15_flutter_analyze_navegacion.txt`, `16_flutter_test_navegacion.txt`: dependencias y verificación final.
- `00_entorno.txt`: versiones de Windows, Flutter y Dart.

El resultado final medido es **140 pruebas aprobadas y 1 omitida**, con análisis estático sin hallazgos. La prueba omitida corresponde al esquema de base de datos v2 aún no implementado.
