<!--
---
file: MEMORY.md
description: Registro de memoria, lecciones aprendidas y decisiones de diseno del proyecto
type: doc/manual
version: 1.0.0
date: 2026-08-26
covers: []
relations: [AGENTS.md, PROGRESS.md]
keywords: [memoria, lecciones-aprendidas, decisiones-diseno, vhdl]
---
-->

# Registro de Memoria y Lecciones Aprendidas (MEMORY.md)

## [2026-08-26 03:11] Inicialización de Estándares y Reorganización del Repositorio
- **Entorno de Simulación:** Configuración de GHDL como compilador y simulador principal en Linux/Codespaces integrado con TerosHDL.
- **Limpieza de Caché:** Eliminación de 73 archivos de artefactos de compilación intermedia de Quartus/ModelSim y actualización de `.gitignore`.
- **Estructura Histórica:** Creación del directorio `SEXTO SEMESTRE/` para archivar proyectos previos (`procesador/`, `procesador_vhdl/`, `Proyecto/`, `Tema 1/`, `Tema 2/`) con exención de metadatos frontmatter.
- **Entorno de Pruebas:** Creación del directorio `sandbox/` para archivos temporales y experimentos.
- **Estándares de Agente:** Creación de `AGENTS.md` adaptado a proyectos VHDL (sin frontmatter YAML en código VHDL, obligatorio en Markdown y scripts de soporte).

## [2026-08-26 03:16] Evaluación de Utilidad de Archivos Raíz
- **PROYECTO_COMPLETO.md:** Reubicado dentro de `SEXTO SEMESTRE/` como documentación complementaria del procesador.
- **modelsim.ini:** Archivo de configuración específico para el simulador ModelSim (Mentor Graphics / Intel FPGA). En Linux Codespaces es innecesario (se usa GHDL), pero puede preservarse en `SEXTO SEMESTRE/` o descartarse.
- **vhdl_ls.toml:** Archivo de configuración del Language Server (VHDL LS / RustHDL). Permite indexación de dependencias y navegación de símbolos en VS Code. Útil en la raíz para habilitar LSP global o reubicable a subproyectos.

## [2026-08-26 03:19] Creación de Directorio Teoria y Reubicación de Configuraciones Históricas
- **Teoria/:** Creación del directorio dedicado para manuales y conceptos teóricos (`Teoria/Teoria.md` con metadatos frontmatter YAML).
- **modelsim.ini y vhdl_ls.toml:** Reubicados en `SEXTO SEMESTRE/` como configuraciones históricas asociadas al procesador y ModelSim.

## [2026-08-26 03:26] Modularización de Teoría y Ocultamiento de Frontmatter en Markdown
- **Modularización:** División de `Teoria.md` en 10 archivos atómicos en `Teoria/` vinculados mediante un índice navegable `Teoria/README.md`.
- **Estándar de Metadatos Markdown:** Inclusión obligatoria de delimitadores HTML `<!-- ... -->` para encapsular frontmatter YAML en documentos Markdown, evitando interferencias visuales en previsualizadores.

## [2026-08-26 03:30] Validación y Enriquecimiento de Sintaxis VHDL en Teoría
- **Validación Automática:** Comprobación de todas las entidades, paquetes y arquitecturas con el compilador GHDL (`--std=08`).
- **Autocontención de Ejemplos:** Aseguramiento de declaraciones de biblioteca IEEE completas en cada ejemplo para que compilen de forma autónoma.
- **Circuitos Secuenciales:** Enriquecimiento del módulo 07 con código VHDL completo para Flip-Flop D y FSMs canónicas (Moore y Mealy de 2 procesos).
