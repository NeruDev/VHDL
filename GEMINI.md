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
- Usar la directiva extendida definiendo colores base, bordes, texto y líneas para mantener consistencia:
  `%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'...','primaryTextColor':'...','primaryBorderColor':'...','lineColor':'...','noteBkgColor':'#fffde7','noteTextColor':'#333'}}}%%`
- Paletas recomendadas (tonos pasteles):
  - **Azul claro (Índigo):** `primaryColor:'#e8eaf6'`, `primaryTextColor:'#3f51b5'`, `primaryBorderColor:'#7986cb'`, `lineColor:'#5c6bc0'`
  - **Verde claro:** `primaryColor:'#e8f5e9'`, `primaryTextColor:'#2e7d32'`, `primaryBorderColor:'#81c784'`, `lineColor:'#4caf50'`
  - **Naranja claro:** `primaryColor:'#fff3e0'`, `primaryTextColor:'#e65100'`, `primaryBorderColor:'#ffb74d'`, `lineColor:'#ff9800'`
  - **Rosa claro:** `primaryColor:'#fce4ec'`, `primaryTextColor:'#880e4f'`, `primaryBorderColor:'#f06292'`, `lineColor:'#e91e63'`
  - **Turquesa claro:** `primaryColor:'#e0f2f1'`, `primaryTextColor:'#00695c'`, `primaryBorderColor:'#4db6ac'`, `lineColor:'#009688'`
  - **Púrpura claro:** `primaryColor:'#f3e5f5'`, `primaryTextColor:'#4a148c'`, `primaryBorderColor:'#ba68c8'`, `lineColor:'#9c27b0'`
- **Notas:** `noteBkgColor:'#fffde7'` (amarillo muy claro), `noteTextColor:'#333'` (gris oscuro)

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
