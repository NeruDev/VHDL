# Contexto del Proyecto: Curso de VHDL

Este proyecto está dedicado al aprendizaje de VHDL siguiendo una estructura de curso universitario.

> **IMPORTANTE:** Cuando se solicite textualmente "actualizar las directivas para la IA" o "actualizar las instrucciones de IA", se deben actualizar **AMBOS** archivos de contexto:
> - `.github/copilot-instructions.md`
> - `GEMINI.md` (este archivo)
>
> Mantener siempre la coherencia entre ambos archivos.

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

## Especificaciones de Diagramas de Estado (Mermaid)

Para diagramas de Máquinas de Estado Finito (FSM) en documentación teórica:

### Reglas Generales
- Usar formato `stateDiagram-v2` de Mermaid.
- **Punto de inicio:** `RESET` (no usar `[*]`).
- **Estado inicial:** Nombrar como `E_Inicial` (no IDLE ni S0).
- **Estados intermedios:** Usar nombres descriptivos (ej. CERO, DETECTADO) o S1, S2, S3... según contexto.
- Incluir notas explicativas con `note right of` para cada estado clave.

### Convenciones de Transiciones
- **Moore:** Formato `entrada=valor` en las transiciones. La salida se especifica en las notas del estado.
- **Mealy:** Formato `entrada/salida` en las transiciones. Ejemplo: `0/0`, `1/1`.

### Esquema de Colores
- Cada ejemplo debe tener su propia paleta de colores claros para diferenciarse visualmente.
- Usar `%%{init: {'theme':'base', 'themeVariables': {...}}}%%` al inicio del bloque Mermaid.
- Paletas recomendadas (tonos pasteles):
  - Azul claro: `primaryColor:'#e8eaf6'` (índigo suave)
  - Verde claro: `primaryColor:'#e8f5e9'` (verde agua)
  - Naranja claro: `primaryColor:'#fff3e0'` (naranja pastel)
  - Rosa claro: `primaryColor:'#fce4ec'` (rosa suave)
  - Turquesa claro: `primaryColor:'#e0f2f1'` (turquesa pastel)
  - Púrpura claro: `primaryColor:'#f3e5f5'` (púrpura suave)
- Fondo de notas: `noteBkgColor:'#fffde7'` (amarillo muy claro)

### Diagramas de Bloques Arquitecturales
- Usar `graph LR` (left-right).
- Estilizar bloques principales:
  - Registro de Estado: `fill:#bbdefb` (azul)
  - Lógica de Salida: `fill:#ffccbc` (naranja/coral)
  - Lógica de Estado Siguiente: `fill:#c8e6c9` (verde)
- Incluir señal de reloj (CLK) con flecha hacia el registro.

### Organización de Ejemplos
- Presentar ejemplos ordenados de simple a complejo: "01" → "101" → "001"
- Agrupar por tipo: primero todos los ejemplos Moore, luego todos los Mealy.
- Incluir comparación de número de estados al final de cada ejemplo paralelo.
