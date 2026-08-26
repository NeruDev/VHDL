# Reglas de Agente y Estándares de Código (AGENTS.md)

Este documento contiene las reglas fundamentales de desarrollo, convenciones de nombres, codificación de archivos, metadatos estructurados y gestión de memoria y variables para todos los agentes y desarrolladores que trabajen en este repositorio.

---

## 1. Codificación, Metadatos y Formato de Archivos

- **Codificación Estándar:** Todos los archivos del proyecto (código fuente VHDL, scripts de soporte en Python/Shell, documentación Markdown y archivos de configuración) DEBEN guardarse en formato **UTF-8** sin BOM.
- **Nomenclatura General:** Los nombres de archivos y directorios de soporte y documentación deben seguir la convención **`snake_case`** en minúsculas (por ejemplo, `generador_testbench.py`, `guia_simulacion.md`).
- **Nomenclatura VHDL:**
  - Archivos de diseño: Nombres descriptivos en minúsculas (por ejemplo, `mux4a1.vhd`, `unidad_control.vhd`).
  - Testbenches: Usar el prefijo `tb_` o sufijo `_tb.vhd` (por ejemplo, `tb_alu.vhd`, `mux4a1_tb.vhd`).

### 1.1 Estándar de Frontmatter y Metadatos YAML
- **Excepción para código VHDL:** El código fuente VHDL (`.vhd`, `.vhdl`) **NO** debe incluir bloques de metadatos frontmatter YAML en el encabezado. Su documentación interna se realiza mediante comentarios estándar VHDL (`--`) en español siguiendo las plantillas del proyecto.
- **Obligatoriedad para Documentación y Scripts:** Todos los archivos de documentación Markdown (`.md`), archivos de configuración y scripts ejecutables (Python, JavaScript, etc.) que no estén en `sandbox/` o en el registro histórico `SEXTO SEMESTRE/` DEBEN incluir un bloque estructurado de metadatos YAML.

*Plantilla para Documentación (`.md`):*
```yaml
---
file: String (Ruta relativa desde la raíz)
description: String (1 sola línea con propósito funcional)
type: Enum/String (doc/guide, doc/architecture, doc/api, doc/manual, doc/theory)
version: SemVer (X.Y.Z)
date: ISO 8601 (YYYY-MM-DD)
covers: List[String] (Rutas de código fuente que este documento explica)
relations: List[String] (Documentos relacionados o de lectura previa)
keywords: List[String] (Conceptos en minúsculas/kebab-case para RAG)
---
```

*Plantilla para Scripts Ejecutables (`.py`, `.ts`, `.js`, etc.):*
```yaml
---
file: String (Ruta relativa física del código)
module: String (Ruta canónica de importación)
description: String (1 sola línea con responsabilidad única)
type: Enum/String (core/engine, tool/cli, sim/testbench, helper/util)
version: SemVer (X.Y.Z)
date: ISO 8601 (YYYY-MM-DD)
dependencies: List[String] (Módulos internos importados directamente)
relations: List[String] (Archivos acoplados lógicamente o contratos)
exports: List[Mapping] (Entidades públicas y rol funcional)
test: String (Comando CLI para verificar el módulo)
constraints: List[String] (Invariantes y reglas negativas críticas)
keywords: List[String] (Términos técnicos en minúsculas/kebab-case)
---
```

### 1.2 Estándar de Tipado Estricto Inline (*Type Hints*) en Scripts
Para cualquier script o herramienta de soporte en Python (ej. generadores de testbench, parsers o scripts CLI), es MANDATORIO el uso de **Type Hints nativos inline** (Python 3.10+ PEP 585 y PEP 604) en todas las firmas de funciones, métodos (`-> None` explícito en `__init__`) y atributos de clase, validado con `mypy --strict`.

*Ejemplo de uso:*
```python
def parse_vhdl_generics(
    raw_source: str,
    max_depth: int = 5,
    fallback_generic: GenericNode | None = None,
) -> list[GenericNode]:
    """Parsea las declaraciones de genéricos en un archivo VHDL."""
    ...
```

### 1.3 Estándar de Clases de Configuración Centralizada
Para definir y modificar los parámetros que gobiernan el comportamiento de un módulo o herramienta de soporte (límites, timeouts, frecuencias de reloj, constantes), se DEBE emplear una clase decorada con `@dataclass(frozen=True)` al inicio del archivo, proporcionando un punto único de control inmutable.

*Ejemplo de uso:*
```python
from dataclasses import dataclass

@dataclass(frozen=True)
class SimulationConfig:
    clock_period_ns: int = 20
    default_timeout_us: int = 100
    dump_vcd_waveform: bool = True

CONFIG = SimulationConfig()
```

### 1.4 Estándar de Entradas del Script y Variables de Entorno
Para scripts ejecutables, utilidades CLI y herramientas de compilación/simulación, se DEBE estructurar el procesamiento de variables de entorno (`os.environ`) con tipado seguro, argumentos CLI con `argparse` auto-documentados y una función `main(argv: Sequence[str] | None = None) -> int` testeable.

*Ejemplo de uso:*
```python
import argparse
import sys
from collections.abc import Sequence

def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="CLI de simulación y compilación VHDL")
    parser.add_argument("-i", "--input", type=str, required=True, help="Ruta del archivo VHDL")
    args = parser.parse_args(argv)
    return 0

if __name__ == "__main__":
    sys.exit(main())
```

### 1.5 Docstrings y Estilo Google en Scripts
Es MANDATORIO el uso de **Google Style Docstrings** para toda la documentación interna de código ejecutable de soporte (módulos, clases, métodos y funciones), detallando explícitamente secciones `Args:`, `Returns:`, `Raises:`, `Yields:` y `Attributes:`.

---

## 2. Gestión de Memoria y Contexto (Ahorro de Tokens)

- **Inspección Previa:** Consultar e inspeccionar siempre en primer lugar `MEMORY.md` y `PROGRESS.md` para verificar el estado y avance del proyecto.
- **Registro en `MEMORY.md`:** Registrar fecha y hora (`YYYY-MM-DD HH:MM`) por cada lección, decisión arquitectural o acción relevante.
- **Registro en `PROGRESS.md`:** Registrar fecha, hora y segundos (`YYYY-MM-DD HH:MM:SS`) para cada actualización del diario de trabajo.
- **Lectura Eficiente de Contexto:** Al reanudar una tarea o cuando los archivos sean extensos, consultar únicamente la última fecha/marca de tiempo para continuar la ejecución de forma eficiente y ahorrar tokens.
- **Actualización Previa a Despliegue Remoto (`git push`):** Si el repositorio local va a subirse o enviarse al repositorio remoto, los archivos `MEMORY.md` y `PROGRESS.md` en la raíz DEBEN actualizarse e incluirse en el commit correspondiente ANTES de realizar el envío (`git push`), asegurando que el commit de despliegue sea atómico, completo y coherente sin generar commits residuales posteriores.

---

## 3. Mantenimiento de Documentación, Metadatos e Interdependencias

- **Sincronización de Documentación y Metadatos:** Si un script o documento cuenta con documentación o metadatos frontmatter YAML, estos DEBEN modificarse obligatoriamente si se modifica su lógica o alcance interno.
- **Navegación e Inspección por Metadatos:** Al buscar archivos, funciones o relaciones e interdependencias entre componentes del sistema, se DEBE realizar la inspección a través de sus metadatos básicos en formato YAML (frontmatter en Markdown y cabeceras YAML en docstrings), los cuales detallan la función, módulo y dependencias del archivo.
- **Verificación de Interdependencias:** Al realizar modificaciones en cualquier archivo o módulo VHDL, se DEBE revisar explícitamente que su interdependencia con paquetes (`*_pkg.vhd`), entidades superiores (top-level) y testbenches no sea afectada.

---

## 4. Estándares de Representación Visual en Documentación

- **Árbol de Directorios en Formato YAML:** Para la representación del árbol de directorios de cualquier archivo o paquete en la documentación, SIEMPRE se debe generar en formato **YAML** (` ```yaml ... ``` `), reemplazando esquemas e hilos ASCII.
- **Gráficos y Diagramas en Formato Mermaid:** Para representar flujos de trabajo, esquemas arquitecturales y máquinas de estado (FSM), se recurre obligatoriamente al formato **Mermaid** (` ```mermaid ... ``` `), eliminando el uso de sintaxis ASCII para representaciones visuales:
  - **FSMs (State Diagrams):** Usar `stateDiagram-v2`, con punto de inicio `RESET`, estado inicial `E_Inicial`, convención Moore (`entrada=valor`) y Mealy (`entrada/salida`), notas descriptivas y paleta de colores claros pastel.
  - **Diagramas de Bloques / RTL:** Usar `graph LR` con estilos diferenciados para registros, lógica de estado y salida.

---

## 5. Entorno de Pruebas (Sandbox) y Registro Histórico

- **Uso Obligatorio de `sandbox/`:** Todos los scripts temporales, utilidades *throwaway* de un solo uso, pruebas destructivas, simulaciones experimentales y borradores de documentación que no cuenten con metadatos estructurados DEBEN ser creados y almacenados únicamente dentro del directorio `sandbox/`.
- **Directorio de Registro Histórico `SEXTO SEMESTRE/`:**
  - Contiene el histórico de prácticas, tareas, procesadores y proyectos desarrollados durante semestres anteriores (incluyendo las carpetas `procesador/`, `procesador_vhdl/`, `Proyecto/`, `Tema 1/` y `Tema 2/`).
  - **Excepción de Metadatos:** Al igual que `sandbox/`, los archivos dentro de `SEXTO SEMESTRE/` forman parte del registro histórico y quedan exentos de la inclusión obligatoria de metadatos frontmatter YAML o refactorizaciones retrospectivas, manteniéndose como biblioteca de consulta.
- **Mantenimiento del Repositorio:** Está estrictamente prohibido crear scripts de prueba o archivos temporales en la raíz del proyecto o en directorios principales, a fin de evitar la acumulación de archivos residuales y mantener limpio el árbol de trabajo.
