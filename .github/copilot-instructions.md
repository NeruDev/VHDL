# Instrucciones de Contexto para GitHub Copilot

Este archivo resume las reglas y convenciones del repositorio VHDL para que los asistentes de IA mantengan coherencia con el curso y su estilo.

## Alcance del Proyecto
- Curso universitario enfocado en diseño digital con VHDL.
- Incluye lógica combinacional y secuencial, simulación, síntesis y asignación de pines a FPGA.

## Reglas de Desarrollo
- **Lenguaje:** VHDL.
- **Idioma de comentarios y documentación:** Español.
- **Estilo:** Nombres descriptivos para señales; procesos bien estructurados; evitar lógica duplicada; preferir arquitecturas claras y legibles.

## Estructura de Carpetas
- `Tema X/`: Unidades temáticas (ej. `Tema 1/`). Dentro se ubican los `.vhd` de cada práctica o ejemplo.
- `PLANTILLAS/`: Plantillas base para nuevos diseños y testbenches. Respetar estas estructuras al crear archivos.
- Archivos de referencia en raíz: `Asignacion de pines.md`, `Mapeo de placa.vhd`.

## Convenciones de Nombres
- Módulos/diseños: minúsculas descriptivas (`mux4a1.vhd`, `demux1a4.vhd`).
- Testbenches: sufijo `_tb` (ej. `mux4a1_tb.vhd`).
- Evitar caracteres especiales o espacios en nombres de archivos.

## Herramientas y Entorno Esperado
- Simulación: Testbenches VHDL y Logisim Evolution v3.8.0.
- Síntesis/Compilación: Quartus II 64-Bit 13.0.1 (Build 232).
- Hardware: Placa FPGA según asignación de pines descrita en `Asignacion de pines.md` y `Mapeo de placa.vhd`.

## Pautas para Nuevos Aportes de IA
- Mantener comentarios breves y útiles solo donde aclaren lógica no evidente.
- Priorizar corrección funcional y claridad sobre optimizaciones prematuras.
- Antes de proponer cambios de estructura, verificar compatibilidad con plantillas y con la herramienta de síntesis esperada.
- Para ejemplos o nuevas prácticas, seguir la organización por tema y utilizar las plantillas disponibles.

## Pruebas y Verificación
- Incluir testbenches cuando se agreguen nuevos módulos; nombrarlos con `_tb` y ubicarlos junto al diseño del mismo tema.
- Validar comportamiento en simulación antes de sugerir asignación de pines o síntesis.
