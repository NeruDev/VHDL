<!--
---
file: PROGRESS.md
description: Diario de avance y registro cronologico de tareas del proyecto
type: doc/manual
version: 1.0.0
date: 2026-08-26
covers: []
relations: [AGENTS.md, MEMORY.md]
keywords: [progreso, tareas, bitacora, vhdl]
---
-->

# Diario de Progreso y Tareas (PROGRESS.md)

## [2026-08-26 03:11:30]
- **Estado:** Completada la reorganización estructural del repositorio.
- **Acciones:**
  1. Movidas carpetas `procesador`, `procesador_vhdl`, `Proyecto`, `Tema 1` y `Tema 2` dentro de `SEXTO SEMESTRE/`.
  2. Creado el directorio `sandbox/` para pruebas temporales.
  3. Creado `AGENTS.md` adaptando los estándares de agentes y excluyendo frontmatter en archivos VHDL.
  4. Actualizado `vhdl_ls.toml` para reflejar las nuevas rutas relativas en `SEXTO SEMESTRE/`.

## [2026-08-26 03:16:00]
- **Estado:** Reubicación de documentación histórica y análisis de archivos raíz.
- **Acciones:**
  1. Movido `PROYECTO_COMPLETO.md` a `SEXTO SEMESTRE/PROYECTO_COMPLETO.md`.
  2. Analizada la utilidad de `modelsim.ini` y `vhdl_ls.toml` en el entorno Linux Codespaces.

## [2026-08-26 03:19:00]
- **Estado:** Reorganización de carpeta Teoria y archivo de configuraciones históricas.
- **Acciones:**
  1. Movidos `modelsim.ini` y `vhdl_ls.toml` a `SEXTO SEMESTRE/`.
  2. Creado el directorio `Teoria/` y movido `Teoria.md` a `Teoria/Teoria.md`.
  3. Agregado frontmatter YAML a `Teoria/Teoria.md` conforme al estándar `AGENTS.md`.

## [2026-08-26 03:26:00]
- **Estado:** Modularización de Teoría VHDL y actualización de estándar frontmatter.
- **Acciones:**
  1. Dividido `Teoria/Teoria.md` en 10 archivos markdown atómicos (`01_estructura_codigo.md` a `10_verificacion_testbenches_depuracion.md`).
  2. Creado `Teoria/README.md` con hipervínculos estructurados y mapa de aprendizaje Mermaid.
  3. Actualizado `AGENTS.md` para estipular que el frontmatter YAML en Markdown debe estar envuelto en comentarios HTML (`<!-- ... -->`).
  4. Actualizados `MEMORY.md` y `PROGRESS.md` con el nuevo formato de comentarios HTML.
