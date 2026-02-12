# Contexto del Proyecto: Curso de VHDL

Este proyecto está dedicado al aprendizaje de VHDL siguiendo una estructura de curso universitario.

## Reglas de Desarrollo
- **Lenguaje:** VHDL.
- **Idioma:** Los comentarios y la documentación técnica deben estar en español.
- **Estilo de Código:** Seguir las mejores prácticas de diseño hardware (nombres descriptivos para señales, procesos bien estructurados).

## Estructura de Carpetas y Nomenclatura
- La organización se basa en unidades temáticas: `Tema X/` (ej. `Tema 1/`, `Tema 2/`).
- Cada carpeta temática contendrá los archivos `.vhd` correspondientes a las prácticas o ejemplos.
- **Nomenclatura de archivos:** 
  - Archivos de diseño: Nombres descriptivos en minúsculas (ej. `mux4a1.vhd`).
  - Testbenches: Usar el sufijo `_tb` (ej. `mux4a1_tb.vhd`).
- **Plantillas:** El directorio `PLANTILLAS/` contiene las bases para nuevos diseños y testbenches. Se deben respetar estas estructuras al crear nuevos archivos.

## Herramientas y Entorno
- **Simulación:** Testbenches VHDL y **Logisim Evolution v3.8.0**.
- **Síntesis/Compilación:** **Quartus II 64-Bit versión 13.0.1 (Build 232)**.
- **Hardware:** El proyecto incluye configuraciones para placas de desarrollo (ver `Asignacion de pines.md` y `Mapeo de placa.vhd`).

## Objetivos
- Implementación de circuitos combinacionales y secuenciales.
- Simulación mediante testbenches y herramientas visuales.
- Asignación de pines y síntesis para FPGA.
