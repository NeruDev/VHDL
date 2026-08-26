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

# Registro de Memoria y Lecciones Aprendidas (MEMORY.md)

## [2026-08-26 03:11] Inicialización de Estándares y Reorganización del Repositorio
- **Entorno de Simulación:** Configuración de GHDL como compilador y simulador principal en Linux/Codespaces integrado con TerosHDL.
- **Limpieza de Caché:** Eliminación de 73 archivos de artefactos de compilación intermedia de Quartus/ModelSim y actualización de `.gitignore`.
- **Estructura Histórica:** Creación del directorio `SEXTO SEMESTRE/` para archivar proyectos previos (`procesador/`, `procesador_vhdl/`, `Proyecto/`, `Tema 1/`, `Tema 2/`) con exención de metadatos frontmatter.
- **Entorno de Pruebas:** Creación del directorio `sandbox/` para archivos temporales y experimentos.
- **Estándares de Agente:** Creación de `AGENTS.md` adaptado a proyectos VHDL (sin frontmatter YAML en código VHDL, obligatorio en Markdown y scripts de soporte).
